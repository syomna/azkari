import 'package:azkar_app/core/presentation/providers/notification_provider.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PrayerTimesSettingsScreen extends StatelessWidget {
  const PrayerTimesSettingsScreen({super.key});

  static const _prayers = [
    ('fajr', 'الفجر', Icons.brightness_3_rounded),
    ('sunrise', 'الشروق', Icons.wb_twilight_rounded),
    ('dhuhr', 'الظهر', Icons.wb_sunny_rounded),
    ('asr', 'العصر', Icons.cloud_rounded),
    ('maghrib', 'المغرب', Icons.nights_stay_rounded),
    ('isha', 'العشاء', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: false,
        actions: [
          Consumer<AzkarProvider>(
            builder: (context, provider, _) {
              final hasAny = PrayerTimeService.prayerKeys
                  .any((key) => provider.isOverridden(key));
              if (!hasAny) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: InkWell(
                  onTap: () => _confirmResetAll(context, provider),
                  child: Text(
                    'إعادة ضبط الكل',
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
      body: Consumer<AzkarProvider>(
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
                    'لم يتم تحديد الموقع بعد',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => provider.loadPrayerTimes(),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(color: AppPalette.mainColor)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info banner
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
                        'اضغط على وقت الصلاة لتعديله يدوياً. الأوقات المعدّلة تظهر باللون الأخضر.',
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

                    return _PrayerTimeTile(
                      name: name,
                      icon: icon,
                      displayTime: displayTime,
                      isOverridden: isOverridden,
                      onTap: () =>
                          _pickTime(context, provider, key, displayTime),
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

  Future<void> _pickTime(
    BuildContext context,
    AzkarProvider provider,
    String key,
    TimeOfDay? initial,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      provider.setOverride(key, picked);
      context.read<NotificationProvider>().applyNotificationStates();
    }
  }

  void _confirmResetAll(BuildContext context, AzkarProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'إعادة ضبط جميع الأوقات؟',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp),
        ),
        content: Text(
          'سيتم حذف جميع الأوقات المعدّلة والرجوع للأوقات المحسوبة.',
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllOverrides();
              Navigator.pop(ctx);
              context.read<NotificationProvider>().applyNotificationStates();
            },
            child: const Text(
              'إعادة ضبط',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final TimeOfDay? displayTime;
  final bool isOverridden;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const _PrayerTimeTile({
    required this.name,
    required this.icon,
    required this.displayTime,
    required this.isOverridden,
    required this.onTap,
    this.onReset,
  });

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeColor = isOverridden
        ? AppPalette.mainColor
        : (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isOverridden
              ? Colors.green.withValues(alpha: 0.06)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isOverridden
                ? Colors.green.withValues(alpha: 0.3)
                : AppPalette.mainColor.withValues(alpha: 0.1),
            width: isOverridden ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: timeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: timeColor, size: 20.h),
            ),
            SizedBox(width: 14.w),

            // Prayer name + override label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isOverridden)
                    Text(
                      'وقت معدّل يدوياً',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
            ),

            // Time
            Text(
              displayTime != null ? _formatTime(displayTime!) : '--:--',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: timeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),

            // Reset or chevron
            if (onReset != null) ...[
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onReset,
                child:
                    Icon(Icons.refresh_rounded, color: Colors.grey, size: 18.h),
              ),
            ] else ...[
              SizedBox(width: 8.w),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20.h),
            ],
          ],
        ),
      ),
    );
  }
}
