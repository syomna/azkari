import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PrayerTimesCard extends StatelessWidget {
  final PrayerTimes times;
  const PrayerTimesCard({super.key, required this.times});

  // A stream that ticks every minute to update the 'active' highlight
  Stream<DateTime> _minuteStream() {
    return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DateTime>(
      stream: _minuteStream(),
      builder: (context, snapshot) {
        // Re-calculate the next prayer every time the stream ticks
        final nextPrayer = times.nextPrayer();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(15.w), // Slightly reduced padding for safety
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppPalette.mainColor.withValues(alpha: 0.2),
                      Colors.black12
                    ]
                  : [AppPalette.mainColor.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: AppPalette.mainColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 12.h),
              // Using a Row with Expanded children to prevent overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPrayerItem(
                      'الفجر', times.fajr, nextPrayer == Prayer.fajr, isDark),
                  _buildPrayerItem('الشروق', times.sunrise,
                      nextPrayer == Prayer.sunrise, isDark),
                  _buildPrayerItem(
                      'الظهر', times.dhuhr, nextPrayer == Prayer.dhuhr, isDark),
                  _buildPrayerItem(
                      'العصر', times.asr, nextPrayer == Prayer.asr, isDark),
                  _buildPrayerItem('المغرب', times.maghrib,
                      nextPrayer == Prayer.maghrib, isDark),
                  _buildPrayerItem(
                      'العشاء', times.isha, nextPrayer == Prayer.isha, isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('مواقيت الصلاة',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppPalette.mainColor)),
        Icon(Icons.access_time_filled, size: 18.h, color: AppPalette.mainColor),
      ],
    );
  }

  Widget _buildPrayerItem(
      String name, DateTime time, bool isActive, bool isDark) {
    String formattedTime = DateFormat.jm('ar').format(time);

    return Expanded(
      // Ensures each column takes equal space and doesn't push others out
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.sp, // Reduced slightly for Arabic text width
                color: isActive
                    ? AppPalette.mainColor
                    : isDark
                        ? Colors.white
                        : Colors.black54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              )),
          SizedBox(height: 4.h),
          FittedBox(
            // Automatically scales text down if the Arabic AM/PM is too long
            fit: BoxFit.scaleDown,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isActive ? AppPalette.mainColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(formattedTime,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isActive ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
