import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:azkar_app/widgets/fade_slide_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard(
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
    return InkWell(
      onTap: () => Navigator.push(
          context, FadeSlidePageRoute(page: page)),
      borderRadius: BorderRadius.circular(25.r),
      child: AppCard(
        borderRadius: BorderRadius.circular(25.r),
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
