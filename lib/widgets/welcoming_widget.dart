import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomingWidget extends StatelessWidget {
  const WelcomingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image Container with a soft "glow" background
        Container(
          height: 60.h,
          width: 60.h,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppPalette.mainColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppPalette.mainColor.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Image.asset(
            'assets/images/pray.png',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 15.w),

        // Text Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getTimeBasedGreeting(), // Dynamic greeting based on time
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppPalette.mainColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 4.h),
              Text(
                'ألا بذكر الله تطمئن القلوب🌿',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // A helper to make the app feel alive
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير والذكر';
    if (hour < 17) return 'طاب يومك بذكر الله';
    return 'مساء الخير والسكينة';
  }
}
