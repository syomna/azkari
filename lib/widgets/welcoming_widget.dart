import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomingWidget extends StatelessWidget {
  /// Optional control pinned to the end of the row, i.e. the left side in RTL.
  ///
  /// It is a slot rather than a concrete button so this widget stays free of
  /// navigation concerns: the caller decides what the control does. Hosting it
  /// here saves a whole row on a screen whose vertical space is the scarce one.
  final Widget? action;

  const WelcomingWidget({super.key, this.action});

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
            // min لا max: يقتصر العمود على ارتفاع نصه فقط. مع max كان يتمدد
            // ليأخذ كامل الارتفاع المتاح، فلا يتوسّط عموديًا إلا في صناديق
            // محددة الارتفاع، وقد يفيض نصه عند تكبير الخط. التمركز على المحور
            // الرأسي يوفّره Row نفسه عبر crossAxisAlignment.
            mainAxisSize: MainAxisSize.min,
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
                'ألا بذكر الله تطمئن القلوب 🌿',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamilyFallback: AppPalette.emojiFallback,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
        if (action != null) ...[
          SizedBox(width: 10.w),
          action!,
        ],
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
