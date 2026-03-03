import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageNumberCard extends StatelessWidget {
  const PageNumberCard({
    super.key,
    required this.pageNumber,
    required this.juz,
  });

  final int pageNumber;
  final int juz;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 25.h, horizontal: 10.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Decorative Line (Background)
          Divider(
            color: AppPalette.mainColor.withValues(alpha: 0.2),
            thickness: 1,
            indent: 20.w,
            endIndent: 20.w,
          ),

          // 2. The Floating Capsule
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              // Semi-transparent background for a "Glass" look
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppPalette.mainColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.mainColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Shrinks to fit content
              children: [
                // Juz Label
                Text(
                  'الجزء ${AppHelpers.getArabicNumber(juz)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppPalette.mainColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Vertical Divider
                Container(
                  height: 12.h,
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  color: AppPalette.mainColor.withValues(alpha: 0.2),
                ),

                // Page Number with Amiri font for a spiritual feel
                Row(
                  children: [
                    Text(
                      'صفحة ',
                      style: TextStyle(
                        fontFamily: AppPalette.amiriFontFamily,
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      AppHelpers.getArabicNumber(pageNumber),
                      style: TextStyle(
                        fontFamily: AppPalette.amiriFontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.mainColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
