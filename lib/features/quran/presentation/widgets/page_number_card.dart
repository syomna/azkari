import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageNumberCard extends StatelessWidget {
  const PageNumberCard({
    super.key,
    required this.pageNumber,
  });

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppPalette.mainColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'الصفحة ',
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
              Text(
                pageNumber.toString(),
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
