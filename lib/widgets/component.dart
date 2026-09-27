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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Ink(
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.03)),
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
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
