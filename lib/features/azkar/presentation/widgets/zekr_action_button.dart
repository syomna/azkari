import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ZekrActionButton extends StatelessWidget {
  const ZekrActionButton({
    super.key,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.child,
  });

  final bool isDark;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: AppPalette.mainColor.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Center(
          child: child ??
              Icon(
                icon,
                size: 18.sp,
                color: AppPalette.mainColor.withValues(alpha: 0.8),
              ),
        ),
      ),
    );
  }
}
