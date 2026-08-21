import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/prayer_times/presentation/widgets/prayer_time_tile.dart';
import 'package:azkar_app/features/prayer_times/presentation/widgets/time_adjustment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PrayerTimesSettingsScreen extends StatelessWidget {
  const PrayerTimesSettingsScreen({super.key});

  static const _prayers = [
    ('fajr', AppStrings.fajr, Icons.brightness_3_rounded),
    ('sunrise', AppStrings.sunrise, Icons.wb_twilight_rounded),
    ('dhuhr', AppStrings.dhuhr, Icons.wb_sunny_rounded),
    ('asr', AppStrings.asr, Icons.cloud_rounded),
    ('maghrib', AppStrings.maghrib, Icons.nights_stay_rounded),
    ('isha', AppStrings.isha, Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.prayerTimesSettings),
        actions: [
          Consumer<PrayerTimesProvider>(
            builder: (context, provider, _) {
              final hasAny = PrayerTimeService.prayerKeys
                  .any((key) => provider.isOverridden(key));
              if (!hasAny) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: InkWell(
                  onTap: () => _confirmResetAll(context, provider),
                  child: Text(
                    AppStrings.resetAll,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, _) {
          if (provider.prayerTimes == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_rounded,
                      size: 48.h, color: Colors.grey.shade400),
                  SizedBox(height: 12.h),
                  Text(
                    AppStrings.noLocationYet,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => provider.loadPrayerTimes(),
                    child: const Text(AppStrings.retry,
                        style: TextStyle(color: AppPalette.mainColor)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppPalette.mainColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppPalette.mainColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppPalette.mainColor, size: 18.h),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        AppStrings.prayerTimeInstruction,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppPalette.mainColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: ListView.separated(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: _prayers.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, i) {
                    final (key, name, icon) = _prayers[i];
                    final displayTime = provider.getDisplayTime(key);
                    final isOverridden = provider.isOverridden(key);

                    return PrayerTimeTile(
                      name: name,
                      icon: icon,
                      displayTime: displayTime,
                      isOverridden: isOverridden,
                      onTap: () => _showOffsetPicker(
                          context, provider, key, name, displayTime),
                      onReset: isOverridden
                          ? () => provider.clearOverride(key)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOffsetPicker(BuildContext context, PrayerTimesProvider provider,
      String key, String name, TimeOfDay? time) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))),
      builder: (context) {
        return TimeAdjustmentSheet(
          prayerName: name,
          initialTime: time ?? TimeOfDay.now(),
          onChanged: (newTime) {
            provider.setOverride(key, newTime);
            context.read<NotificationProvider>().applyNotificationStates();
          },
        );
      },
    );
  }

  void _confirmResetAll(BuildContext context, PrayerTimesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppStrings.resetAllConfirmTitle,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp),
        ),
        content: Text(
          AppStrings.resetAllConfirmBody,
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllOverrides();
              Navigator.pop(ctx);
              context.read<NotificationProvider>().applyNotificationStates();
            },
            child: const Text(
              AppStrings.reset,
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
