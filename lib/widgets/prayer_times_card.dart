import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PrayerTimesCard extends StatefulWidget {
  final PrayerTimes times;
  final Map<String, TimeOfDay?> displayTimes;

  const PrayerTimesCard({
    super.key,
    required this.times,
    required this.displayTimes,
  });

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextPrayer = widget.times.nextPrayer();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPrayerItem('الفجر', widget.displayTimes['fajr'],
                  nextPrayer == Prayer.fajr, isDark),
              _buildPrayerItem('الشروق', widget.displayTimes['sunrise'],
                  nextPrayer == Prayer.sunrise, isDark),
              _buildPrayerItem('الظهر', widget.displayTimes['dhuhr'],
                  nextPrayer == Prayer.dhuhr, isDark),
              _buildPrayerItem('العصر', widget.displayTimes['asr'],
                  nextPrayer == Prayer.asr, isDark),
              _buildPrayerItem('المغرب', widget.displayTimes['maghrib'],
                  nextPrayer == Prayer.maghrib, isDark),
              _buildPrayerItem('العشاء', widget.displayTimes['isha'],
                  nextPrayer == Prayer.isha, isDark),
            ],
          ),
        ],
      ),
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
      String name, TimeOfDay? time, bool isActive, bool isDark) {
    final formattedTime = time != null
        ? DateFormat.jm('ar').format(
            DateTime(0, 0, 0, time.hour, time.minute),
          )
        : '--:--';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.sp,
              color: isActive
                  ? AppPalette.mainColor
                  : isDark
                      ? Colors.white
                      : Colors.black54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )),
        SizedBox(height: 4.h),
        FittedBox(
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
    );
  }
}
