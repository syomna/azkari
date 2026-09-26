import 'package:flutter/material.dart';

/// Shared rounded "card" surface used across the app.
///
/// Provides a consistent white/light-dark rounded container with an optional
/// highlight overlay and ink ripple when [onTap] is provided. Content, color,
/// border, shadow, padding and radius are all configurable, so it safely
/// replaces ad-hoc rounded [Container]s without changing their look.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.border,
    this.boxShadow,
    this.padding = EdgeInsets.zero,
    this.radius = 18,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;

  /// Invoked on tap. When provided the card shows an ink ripple and attaches
  /// its own [InkWell]; if null the card is inert.
  final VoidCallback? onTap;

  /// Overrides the base surface color (defaults to white / dark tint).
  final Color? color;

  final Border? border;

  final List<BoxShadow>? boxShadow;

  final EdgeInsetsGeometry padding;

  final double radius;

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final resolvedColor =
        color ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white);

    final surface = AnimatedContainer(
      duration: duration,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap == null) return surface;

    // Clip + Material + InkWell so the ripple respects the rounded corners.
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: surface),
      ),
    );
  }
}
