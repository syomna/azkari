
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerTimeTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final TimeOfDay? displayTime;
  final bool isOverridden;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const PrayerTimeTile({super.key, 
    required this.name,
    required this.icon,
    required this.displayTime,
    required this.isOverridden,
    required this.onTap,
    this.onReset,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final h = hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'ص' : 'م';
    return '$h:$m $period';
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
