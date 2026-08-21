import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppDialog extends StatelessWidget {
  final PackageInfo? packageInfo;

  const AboutAppDialog({super.key, this.packageInfo});

  static void show(BuildContext context, PackageInfo? packageInfo) {
    showDialog(
      context: context,
      builder: (context) => AboutAppDialog(packageInfo: packageInfo),
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
            CircleAvatar(
              radius: 40.r,
              backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
              child: Image.asset('assets/images/pray.png', width: 50.w),
            ),
            SizedBox(height: 16.h),
            Text(
              AppStrings.shareSubject,
              style: TextStyle(
                fontFamily: AppPalette.amiriFontFamily,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الإصدار ${packageInfo?.version ?? ''}',
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
            SizedBox(height: 15.h),
            Text(
              AppStrings.appDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(
              color: AppPalette.mainColor.withValues(alpha: 0.1),
              thickness: 1,
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code_rounded,
                    size: 16.sp, color: AppPalette.mainColor),
                SizedBox(width: 8.w),
                Text(
                  AppStrings.developedBy,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.mainColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25.h),
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
              child: const Text(
                AppStrings.close,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
