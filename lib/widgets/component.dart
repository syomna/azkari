import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Component extends StatelessWidget {
  const Component(
      {super.key,
      required this.text,
      required this.img,
      required this.page,
      this.isColumn = true});

  final String text;
  final String img;
  final Widget page;
  final bool isColumn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(25.r),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/$img.png',
                  height: 32.h, width: 32.h),
            ),
            SizedBox(height: 10.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
