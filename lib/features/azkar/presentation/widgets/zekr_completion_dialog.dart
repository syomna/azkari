import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ZekrCompletionDialog extends StatelessWidget {
  const ZekrCompletionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ZekrCompletionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 90.r,
              color: AppPalette.mainColor,
            ),
            SizedBox(height: 16.h),
            Text(
              AppStrings.azkarCompletedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? AppPalette.darkText : AppPalette.lightText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.azkarCompletedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 14.sp,
                color:
                    isDark ? AppPalette.darkMutedText : AppPalette.lightMutedText,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                minimumSize: Size(double.infinity, 45.h),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppStrings.azkarCompletedButton,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
