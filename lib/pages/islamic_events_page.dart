import 'package:azkar_app/core/services/islamic_events_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// Lists the upcoming Islamic events with their Hijri and Gregorian dates, a
/// countdown, and the hadith recorded for each occasion.
class IslamicEventsPage extends StatelessWidget {
  const IslamicEventsPage({super.key});

  /// "Today" on the calendar of the selected city, so the countdown agrees with
  /// the dates the rest of the app shows. Falls back to the device date when no
  /// city (or no timezone) has been resolved yet.
  static DateTime _today(BuildContext context) {
    final timezoneName =
        context.read<PrayerTimesProvider?>()?.cityTimezone;
    if (timezoneName != null && timezoneName.isNotEmpty) {
      try {
        final now = tz.TZDateTime.now(tz.getLocation(timezoneName));
        return DateTime(now.year, now.month, now.day);
      } catch (_) {
        // Unknown/obsolete IANA name — fall back to the device calendar.
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = _today(context);
    final occurrences = IslamicEventsService.upcoming(fromDate: today);

    return Scaffold(
      appBar:
          AppBar(title: const Text('المناسبات الإسلامية'), centerTitle: true),
      body: occurrences.isEmpty
          ? _EmptyState(isDark: isDark)
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: occurrences.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _EventCard(
                occurrence: occurrences[index],
                daysUntil: occurrences[index].daysUntil(today),
                isDark: isDark,
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          'لا توجد مناسبات قادمة في الفترة القادمة',
          style: TextStyle(
            color: isDark ? AppPalette.darkMutedText : AppPalette.lightMutedText,
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.occurrence,
    required this.daysUntil,
    required this.isDark,
  });

  final IslamicEventOccurrence occurrence;
  final int daysUntil;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppPalette.darkText : AppPalette.lightText;
    final muted =
        isDark ? AppPalette.darkMutedText : AppPalette.lightMutedText;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppPalette.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.1)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  occurrence.title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ),
              _CountdownBadge(daysUntil: daysUntil),
            ],
          ),
          SizedBox(height: 8.h),
          Text(_subtitle(), style: TextStyle(fontSize: 14.sp, color: muted)),
          if (occurrence.hadiths.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'الحديث المرتبط',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppPalette.mainColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  for (final hadith in occurrence.hadiths)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hadith.hadith,
                            style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.9,
                              fontFamily: AppPalette.amiriFontFamily,
                              color: foreground,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            hadith.bookInfo,
                            style: TextStyle(fontSize: 12.sp, color: muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle() {
    final hijri =
        '${occurrence.hijriDay}/${occurrence.hijriMonth}/${occurrence.hijriYear} هـ';
    final gregorian =
        '${occurrence.gregorianDate.day}/${occurrence.gregorianDate.month}/${occurrence.gregorianDate.year} م';
    final hedged = occurrence.isDateEstimate ? ' (تاريخ مُتوقَّع)' : '';
    return '$hijri • $gregorian$hedged';
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.daysUntil});

  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    final label = switch (daysUntil) {
      <= 0 => 'اليوم',
      1 => 'غدًا',
      _ => 'بعد $daysUntil يوم',
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppPalette.mainColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppPalette.mainColor,
        ),
      ),
    );
  }
}