import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/islamic_events_service.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Islamic events are the only notifications in the app that are anchored to a
/// calendar date rather than a daily clock time. A lunar month alternates
/// between 29 and 30 days, so the OS cannot express "every Ramadan" as a repeat
/// rule — these tests pin the two properties that make the dated approach safe:
/// the resolved dates are correct, and nothing is ever queued as a repeating
/// notification that would re-fire on the same Gregorian day each month.

const _notifChannel = 'dexterous.com/flutter/local_notifications';
const _tzChannel = 'flutter_timezone';

final _zoned = <MethodCall>[];

void _mockChannels({String deviceIana = 'Etc/UTC'}) {
  _zoned.clear();
  fln.FlutterLocalNotificationsPlatform.instance =
      fln.AndroidFlutterLocalNotificationsPlugin();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(_notifChannel),
          (call) async {
    if (call.method == 'zonedSchedule') _zoned.add(call);
    if (call.method == 'requestNotificationsPermission') return true;
    if (call.method == 'requestExactAlarmsPermission') return true;
    if (call.method == 'pendingNotificationRequests') return <Map>[];
    return true;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel(_tzChannel), (call) async => deviceIana);
}

tz.TZDateTime _instantOf(MethodCall call, tz.Location loc) {
  final iso = (call.arguments as Map)['scheduledDateTimeISO8601'] as String;
  return tz.TZDateTime.from(
    tz.TZDateTime.parse(tz.getLocation('Etc/UTC'), iso),
    loc,
  );
}

String _hhmm(tz.TZDateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Future<NotificationService> _service(SharedPreferences prefs) async {
  _zoned.clear();
  NotificationService.resetForTesting();
  return NotificationService.init(
    prefs: prefs,
    prayerService: PrayerTimeService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  group('IslamicEventsService.upcoming', () {
    test('resolves 1 Ramadan 1447 to its real Gregorian date', () {
      // 1 Ramadan 1447 began 18 Feb 2026. If the resolver's Hijri -> Gregorian
      // arithmetic ever drifts, the whole feature silently reports wrong dates.
      final occurrences =
          IslamicEventsService.upcoming(fromDate: DateTime(2026, 2, 10));
      final ramadan = occurrences.firstWhere((o) => o.type.name == 'ramadan');
      expect(ramadan.gregorianDate, DateTime(2026, 2, 18));
      expect(ramadan.hijriDay, 1);
      expect(ramadan.hijriMonth, 9);
      expect(ramadan.hijriYear, 1447);
    });

    test('every occurrence is today or later and inside the window', () {
      final from = DateTime(2026, 2, 10);
      final occurrences = IslamicEventsService.upcoming(
        fromDate: from,
        lookaheadDays: 30,
      );
      expect(occurrences, isNotEmpty);
      for (final o in occurrences) {
        expect(o.gregorianDate.isBefore(from), isFalse,
            reason: '${o.type.name} resolved before the window start');
        expect(
          o.gregorianDate.isAfter(from.add(const Duration(days: 30))),
          isFalse,
          reason: '${o.type.name} resolved past the window end',
        );
      }
    });

    test('is sorted chronologically', () {
      final occurrences =
          IslamicEventsService.upcoming(fromDate: DateTime(2026, 2, 10));
      for (var i = 1; i < occurrences.length; i++) {
        expect(
          occurrences[i - 1].gregorianDate
              .isAfter(occurrences[i].gregorianDate),
          isFalse,
          reason: 'occurrence $i is out of order',
        );
      }
    });

    test('at most one notification per calendar day', () {
      // 12/8 Dhu al-Hijjah is both "first ten days" and the Arafah fasting
      // reminder; two notifications for one day would be noise.
      final occurrences =
          IslamicEventsService.upcoming(fromDate: DateTime(2026, 2, 10));
      final days = occurrences
          .map((o) => DateTime(o.gregorianDate.year, o.gregorianDate.month,
              o.gregorianDate.day))
          .toList();
      expect(days.toSet().length, days.length);
    });

    test('both Eids are hedged as expected dates, other events are not', () {
      // Each Eid is looked up in a window that actually contains it.
      final fitr = IslamicEventsService.upcoming(
          fromDate: DateTime(2026, 3, 15)).where((o) => o.isDateEstimate);
      final adha = IslamicEventsService.upcoming(
          fromDate: DateTime(2026, 5, 22)).where((o) => o.isDateEstimate);

      expect(fitr.map((o) => o.type.name), contains('eidAlFitr'));
      expect(adha.map((o) => o.type.name), contains('eidAlAdha'));
      for (final eid in [...fitr, ...adha]) {
        expect(eid.title, contains('مُتوقَّع'));
      }
      // A non-Eid event in the same table must stay unhedged.
      for (final o in IslamicEventsService.upcoming(
          fromDate: DateTime(2026, 3, 15))
          .where((o) => !o.isDateEstimate)) {
        expect(o.title, isNot(contains('مُتوقَّع')));
      }
    });

    test('honours the occurrence limit', () {
      final occurrences = IslamicEventsService.upcoming(
        fromDate: DateTime(2026, 2, 10),
        limit: 3,
      );
      expect(occurrences.length, lessThanOrEqualTo(3));
    });

    test('notification ids are unique and outside every existing range', () {
      final occurrences =
          IslamicEventsService.upcoming(fromDate: DateTime(2026, 2, 10));
      final ids = occurrences
          .map((o) => IslamicEventsService.notificationIdFor(
              o.eventId, o.hijriDay))
          .toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate notification id');
      for (final id in ids) {
        expect(id, greaterThanOrEqualTo(
            NotificationService.notificationIds['islamic_event']!));
        // Existing ids top out at 403.
        expect(id, greaterThan(403));
      }
    });
  });

  group('scheduleIslamicEventNotifications', () {
    Map<String, Object> cairoSeed() => {
          PrefsKeys.latitude: 30.0444,
          PrefsKeys.longitude: 31.2357,
          PrefsKeys.cityName: 'القاهرة',
          PrefsKeys.cityTimezone: 'Africa/Cairo',
          'prayer_time_fajr': '4:50',
        };

    /// A reference date in the real future that is guaranteed to have an event
    /// inside its 30-day window.
    ///
    /// Events only fall in Hijri months 1, 9, 10 and 12, so roughly eight
    /// months of the year have none at all. Picking "today" would make these
    /// tests pass vacuously for most of the year, so instead the next
    /// occurrence is looked up over a wide window and used as the reference.
    DateTime futureReference() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final candidates = IslamicEventsService.upcoming(
        fromDate: today,
        lookaheadDays: 400,
        limit: 40,
      ).where((o) => o.gregorianDate.isAfter(today));
      expect(candidates, isNotEmpty,
          reason: 'no Islamic event found in the next 400 days');
      return candidates.first.gregorianDate;
    }

    test('queues dated notifications in the reserved id range', () async {
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      final error = await service
          .scheduleIslamicEventNotifications(referenceDate: futureReference());
      expect(error, isNull);
      expect(_zoned, isNotEmpty);

      for (final call in _zoned) {
        final args = call.arguments as Map;
        expect(args['id'], greaterThan(403));
        expect(args['payload'], startsWith('islamic_event_'));
      }
    });

    test('never schedules a repeating notification', () async {
      // This is the load-bearing assertion of the whole feature: a repeating
      // rule would re-fire on the same Gregorian day every month, which for a
      // lunar event means announcing Ashura on the wrong date forever.
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      await service
          .scheduleIslamicEventNotifications(referenceDate: futureReference());
      expect(_zoned, isNotEmpty);
      for (final call in _zoned) {
        expect((call.arguments as Map).containsKey('matchDateTimeComponents'),
            isFalse);
      }
    });

    test('schedules each occurrence on its own Gregorian date', () async {
      // A dated event must keep its own date. An earlier revision rolled a past
      // occurrence forward day-by-day, which collapsed every event in the
      // window onto the same near-future date.
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      final reference = futureReference();
      await service
          .scheduleIslamicEventNotifications(referenceDate: reference);

      final cairo = tz.getLocation('Africa/Cairo');
      final dates = _zoned
          .map((c) {
            final local = _instantOf(c, cairo);
            return DateTime(local.year, local.month, local.day);
          })
          .toSet();
      expect(dates.length, greaterThan(1),
          reason: 'all occurrences collapsed onto one date');
      for (final day in dates) {
        expect(day.isBefore(reference), isFalse,
            reason: 'an occurrence was scheduled before the window start');
      }
    });

    test('announces at Fajr + 60 in the city timezone', () async {
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      await service
          .scheduleIslamicEventNotifications(referenceDate: futureReference());
      expect(_zoned, isNotEmpty);
      final cairo = tz.getLocation('Africa/Cairo');
      for (final call in _zoned) {
        expect(_hhmm(_instantOf(call, cairo)), '05:50');
      }
    });

    test('every scheduled instant is in the future', () async {
      // The plugin throws on a past one-off schedule, so a bug here surfaces as
      // an error string rather than a silent miss.
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      final error = await service
          .scheduleIslamicEventNotifications(referenceDate: futureReference());
      expect(error, isNull);
      expect(_zoned, isNotEmpty);
      final deviceNow = tz.TZDateTime.now(tz.local);
      for (final call in _zoned) {
        final iso =
            (call.arguments as Map)['scheduledDateTimeISO8601'] as String;
        final utc = tz.TZDateTime.parse(tz.getLocation('Etc/UTC'), iso);
        expect(utc.isAfter(deviceNow.toUtc()), isTrue);
      }
    });

    test('falls back to a fixed morning time before prayer times exist', () async {
      _mockChannels();
      SharedPreferences.setMockInitialValues({
        PrefsKeys.latitude: 30.0444,
        PrefsKeys.longitude: 31.2357,
        PrefsKeys.cityTimezone: 'Africa/Cairo',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      final error = await service
          .scheduleIslamicEventNotifications(referenceDate: futureReference());
      expect(error, isNull);
      expect(_zoned, isNotEmpty);
      final cairo = tz.getLocation('Africa/Cairo');
      for (final call in _zoned) {
        expect(_hhmm(_instantOf(call, cairo)), '06:30');
      }
    });

    test('a window entirely in the past schedules nothing', () async {
      // Locks the skip-don't-roll-forward behaviour: occurrences already behind
      // the device clock are dropped rather than pushed to a bogus near-future
      // date, which would announce the wrong occasion.
      _mockChannels();
      SharedPreferences.setMockInitialValues(cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      final service = await _service(prefs);

      final error = await service.scheduleIslamicEventNotifications(
          referenceDate: DateTime(2020, 1, 1));
      expect(error, isNull);
      expect(_zoned, isEmpty);
    });
  });
}
