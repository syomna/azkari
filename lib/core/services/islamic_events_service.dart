import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hijri_date/hijri_date.dart';
import 'package:hijri_date/religious_event.dart';

/// A single upcoming date on which an Islamic event falls, resolved from the
/// Hijri calendar into an absolute Gregorian calendar day.
@immutable
class IslamicEventOccurrence {
  /// Stable id of the source event (1..12 as declared by `hijri_date`).
  final int eventId;

  final IslamicEventType type;

  /// Arabic title, already suffixed with "(مُتوقَّع)" when [isDateEstimate].
  final String title;

  final int hijriYear;
  final int hijriMonth;
  final int hijriDay;

  /// Date-only value (time components are midnight) of the Gregorian day the
  /// event falls on.
  final DateTime gregorianDate;

  /// True when the date is computed arithmetically and may legitimately differ
  /// by a day from what a given country observes.
  final bool isDateEstimate;

  final List<HadithInfo> hadiths;

  /// Whole days from [from] until this occurrence; 0 means "today".
  int daysUntil(DateTime from) {
    final a = DateTime(from.year, from.month, from.day);
    final b =
        DateTime(gregorianDate.year, gregorianDate.month, gregorianDate.day);
    return b.difference(a).inDays;
  }

  const IslamicEventOccurrence({
    required this.eventId,
    required this.type,
    required this.title,
    required this.hijriYear,
    required this.hijriMonth,
    required this.hijriDay,
    required this.gregorianDate,
    required this.isDateEstimate,
    required this.hadiths,
  });
}

/// Turns the `hijri_date` package's static event table into concrete, dated
/// occurrences that can be scheduled.
///
/// The package exposes event definitions (Hijri month + list of days) but its
/// `getUpcomingEvents()` helper resolves them against `DateTime.now()` only,
/// which makes it impossible to test and mishandles the Hijri year rollover.
/// This class keeps the curated event data and hadiths from the package but
/// performs the date resolution itself against an explicit [fromDate].
class IslamicEventsService {
  const IslamicEventsService._();

  /// How far ahead occurrences are resolved. Occurrences are scheduled as
  /// one-off notifications (a lunar month cannot be expressed as an OS repeat
  /// rule), so this window bounds how far ahead a notification is committed
  /// to the OS before the app re-arms it.
  static const int lookaheadDays = 30;

  /// Horizon for the events *page*: the full upcoming Islamic year, so the
  /// list stays useful in the long empty stretch between occasions.
  /// Notifications deliberately keep the tighter [lookaheadDays].
  static const int pageLookaheadDays = 365;

  /// Hard ceiling on how many occurrences are ever scheduled at once, so the
  /// total pending count stays well clear of iOS's 64-notification limit.
  static const int maxOccurrences = 10;

  /// Occurrences are announced in the morning after Fajr, which is a time the
  /// user is already awake for and which rides the existing daily rhythm
  /// instead of fighting Doze at midnight.
  static const int eventNotifyMinutesAfterFajr = 60;

  /// Fallback announcement time when no effective Fajr time is stored yet.
  static const TimeOfDay fallbackNotifyTime = TimeOfDay(hour: 6, minute: 30);

  /// Base of the notification id range reserved for Islamic events.
  static const int notificationIdBase = 500;

  /// Eids are announced with a hedged wording. Both are observed up to a day
  /// earlier in some countries than the arithmetic Hijri date implies, and
  /// claiming an exact date would make the app visibly wrong on the highest-
  /// stakes dates it reports.
  static const Set<IslamicEventType> _estimatedTypes = {
    IslamicEventType.eidAlFitr,
    IslamicEventType.eidAlAdha,
  };

  static const String _estimateSuffix = ' (مُتوقَّع)';

  /// Higher wins when two events fall on the same calendar day. Keeps the app
  /// from firing two notifications for the same occasion (12/8 Dhul Hijjah is
  /// both "first ten days" and "Arafah fasting reminder").
  static const Map<IslamicEventType, int> _priority = {
    IslamicEventType.ramadan: 100,
    IslamicEventType.eidAlFitr: 100,
    IslamicEventType.eidAlAdha: 100,
    IslamicEventType.laylatAlQadr: 95,
    IslamicEventType.arafah: 85,
    IslamicEventType.ashura: 80,
    IslamicEventType.newYear: 75,
    IslamicEventType.tenDaysOfDhulHijjah: 60,
    IslamicEventType.arafahReminder: 55,
    IslamicEventType.ashuraReminder: 50,
    IslamicEventType.tasooaReminder: 45,
    IslamicEventType.sixOfShawwal: 40,
  };

  /// Every event definition, main and reminder alike. `hijri_date` splits the
  /// table into two private-backed lists, so both are concatenated to get all
  /// of it.
  static List<IslamicEvent> _allEvents() => [
        ...IslamicEventsManager.getMainEvents(),
        ...IslamicEventsManager.getReminders(),
      ];

  /// Deterministic notification id for one dated occurrence.
  ///
  /// Ids must be stable (they replace a pending request) yet distinct for every
  /// occurrence currently queued. `(eventId, hijriDay)` is unique across the
  /// scheduling window because a given event recurs on the same Hijri day only
  /// once per lunar year.
  static int notificationIdFor(int eventId, int hijriDay) =>
      notificationIdBase + eventId * 100 + hijriDay;

  /// Resolves occurrences falling in `[fromDate, fromDate + lookaheadDays]`,
  /// de-duplicated to at most one notification per calendar day and sorted
  /// chronologically.
  static List<IslamicEventOccurrence> upcoming({
    required DateTime fromDate,
    int lookaheadDays = IslamicEventsService.lookaheadDays,
    int limit = IslamicEventsService.maxOccurrences,
  }) {
    // Month names are looked up through a static locale map; set it once so
    // titles render in Arabic.
    HijriDate.setLocal('ar');

    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final horizon = from.add(Duration(days: lookaheadDays));

    final currentHijri = HijriDate.fromDate(from);

    final resolved = <IslamicEventOccurrence>[];

    // Scan the neighbouring Hijri years too: an event on 1 Muharram can fall
    // inside the window while the Gregorian year still belongs to the previous
    // Hijri year, and vice versa.
    for (var hijriYear = currentHijri.hYear - 1;
        hijriYear <= currentHijri.hYear + 1;
        hijriYear++) {
      for (final event in _allEvents()) {
        for (final day in event.days) {
          final DateTime gregorian;
          try {
            gregorian = HijriDate.fromHijri(hijriYear, event.month, day)
                .hijriToGregorian(hijriYear, event.month, day);
          } on ArgumentError {
            // The package rejects a Hijri day that the month does not have
            // (e.g. day 30 of a 29-day month), so such a date simply does not
            // exist in that year.
            continue;
          }

          final date = DateTime(gregorian.year, gregorian.month, gregorian.day);
          if (date.isBefore(from) || date.isAfter(horizon)) continue;

          final isEstimate = _estimatedTypes.contains(event.type);
          resolved.add(
            IslamicEventOccurrence(
              eventId: event.id,
              type: event.type,
              title: isEstimate
                  ? '${event.titleArabic}$_estimateSuffix'
                  : event.titleArabic,
              hijriYear: hijriYear,
              hijriMonth: event.month,
              hijriDay: day,
              gregorianDate: date,
              isDateEstimate: isEstimate,
              hadiths: event.hadiths,
            ),
          );
        }
      }
    }

    resolved.sort((a, b) {
      final byDate = a.gregorianDate.compareTo(b.gregorianDate);
      if (byDate != 0) return byDate;
      return _priority[b.type]!.compareTo(_priority[a.type]!);
    });

    final deduped = <IslamicEventOccurrence>[];
    final seenDates = <int>{};
    for (final occurrence in resolved) {
      final key = DateTime(
        occurrence.gregorianDate.year,
        occurrence.gregorianDate.month,
        occurrence.gregorianDate.day,
      ).millisecondsSinceEpoch;
      if (!seenDates.add(key)) continue;
      deduped.add(occurrence);
      if (deduped.length >= limit) break;
    }

    return deduped;
  }
}
