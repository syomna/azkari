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
    return Align(
      alignment:
          Alignment.bottomCenter, // Changed to bottomCenter for a footer look
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppPalette.mainColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // 1. Left side: Juz info
            Expanded(
              flex: 1,
              child: Text(
                'الجزء ${AppHelpers.getArabicNumber(juz)}',
                style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                textAlign: TextAlign.right, // Since it's Arabic
              ),
            ),

            // 2. Middle: Page number (Perfectly Centered)
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الصفحة ',
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppHelpers.getArabicNumber(pageNumber),
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // 3. Right side: Empty spacer to balance the Row
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
