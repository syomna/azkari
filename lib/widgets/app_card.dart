import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.blurRadius,
    this.border,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final double? blurRadius;
  final Border? border;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(20.r);

    final effectiveColor = glass
        ? (isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8))
        : (color ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white));

    final effectiveBorderColor = borderColor ??
        (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03));

    final effectiveBorder =
        border ?? Border.all(color: effectiveBorderColor, width: 0.5);

    final effectiveShadow = (shadowColor != null || blurRadius != null || !glass)
        ? [
            BoxShadow(
              color: shadowColor ??
                  Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: blurRadius ?? 10,
              offset: const Offset(0, 4),
            ),
          ]
        : null;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveBorderRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );
  }
}
