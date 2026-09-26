import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/widget_guide/presentation/widget_guide_page.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Simple home-screen card that opens the prayer-times widget setup guide.
class WidgetGuideCard extends StatelessWidget {
  const WidgetGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: () => WidgetGuidePage.open(context),
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppPalette.mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.widgets_rounded,
                color: AppPalette.mainColor, size: 22.h),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              'إضافة ويدجيت مواقيت الصلاة',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black26),
        ],
      ),
    );
  }
}
