import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerTimeTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final TimeOfDay? displayTime;
  final bool isOverridden;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const PrayerTimeTile({
    super.key,
    required this.name,
    required this.icon,
    required this.displayTime,
    required this.isOverridden,
    required this.onTap,
    this.onReset,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final h = AppHelpers.getArabicNumber(hour).padLeft(2, '٠');
    final m = AppHelpers.getArabicNumber(t.minute).padLeft(2, '٠');
    final period = t.period == DayPeriod.am ? 'ص' : 'م';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeColor = isOverridden
        ? AppPalette.mainColor
        : (isDark ? Colors.white : Colors.black87);

    return AppCard(
      onTap: onTap,
      radius: 18.r,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      color: isOverridden
          ? Colors.green.withValues(alpha: 0.06)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
      border: Border.all(
        color: isOverridden
            ? Colors.green.withValues(alpha: 0.3)
            : AppPalette.mainColor.withValues(alpha: 0.1),
        width: isOverridden ? 1.5 : 1,
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
                      color: AppPalette.deepGreenLight,
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
            SizedBox(width: 4.w),
            // IconButton بمقيّدات صفرية بدل GestureDetector: tooltip تمنح اسماً
            // لمحصّلي الوصول (قارئ الشاشة)، وقيود عرض صارمة (40px) كانت تفيض
            // الصف 4px على 320px عند خط 2×.
            IconButton(
              onPressed: onReset,
              tooltip: 'استعادة التوقيت الأصلي',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.refresh_rounded,
                  size: 18.h,
                  color: isDark
                      ? AppPalette.darkMutedText
                      : AppPalette.lightMutedText),
            ),
          ] else ...[
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? AppPalette.darkMutedText
                    : AppPalette.lightMutedText,
                size: 20.h),
          ],
        ],
      ),
    );
  }
}
