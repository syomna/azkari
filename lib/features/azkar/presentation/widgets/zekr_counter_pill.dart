
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ZekrCounterPill extends StatelessWidget {
  const ZekrCounterPill({
    super.key,
    required this.remaining,
    required this.total,
    required this.isDone,
    required this.isDark,
    required this.onTap,
  });

  final int remaining;
  final int total;
  final bool isDone;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDone
              ? Colors.grey.withValues(alpha: isDark ? 0.2 : 0.15)
              : AppPalette.mainColor,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hand tap icon
            if (!isDone) ...[
              Icon(
                Icons.touch_app_rounded,
                size: 15.sp,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              SizedBox(width: 5.w),
            ],

            // Remaining count
            Text(
              isDone ? '✓' : AppHelpers.getArabicNumber(remaining),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDone
                    ? (isDark ? Colors.white38 : Colors.black38)
                    : Colors.white,
              ),
            ),

            // Total
            if (!isDone && total > 1) ...[
              SizedBox(width: 3.w),
              Text(
                '/ ${AppHelpers.getArabicNumber(total)}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
