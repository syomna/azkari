import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/widget_guide/presentation/screens/widget_guide_screen.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WidgetPromoCard extends StatelessWidget {
  const WidgetPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
      padding: EdgeInsets.all(16.w),
      borderRadius: BorderRadius.circular(25.r),
      borderColor: AppPalette.mainColor.withValues(alpha: 0.15),
      shadowColor: AppPalette.mainColor.withValues(alpha: 0.1),
      blurRadius: 15,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25.r),
          onTap: () =>
              WidgetGuideScreen.open(context, openedFromSettings: true),
          child: Semantics(
            button: true,
            label: AppStrings.widgetGuideTitle,
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: AppPalette.mainColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.square_grid_2x2,
                    size: 26.sp,
                    color: AppPalette.mainColor,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.guidePrayerTimesOnScreen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppPalette.darkText
                              : AppPalette.lightText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        AppStrings.guideIntroDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.4,
                          color: isDark
                              ? AppPalette.darkMutedText
                              : AppPalette.lightMutedText,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        AppStrings.showHowToAdd,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.mainColor,
                        ),
                      ),
                    ],
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
