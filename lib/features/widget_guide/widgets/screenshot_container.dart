import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/widget_guide/models/widget_guide_step.dart';
import 'package:azkar_app/features/widget_guide/widgets/fullscreen_screenshot.dart';
import 'package:flutter/material.dart';

class ScreenshotContainer extends StatelessWidget {
  const ScreenshotContainer({
    super.key,
    required this.step,
  });

  final WidgetGuideStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final cardColor = colorScheme.surface;

    final imageBackgroundColor = isDarkMode
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF0F8F3);

    final borderColor = isDarkMode
        ? colorScheme.outline.withValues(alpha: 0.45)
        : AppPalette.mainColor.withValues(alpha: 0.08);

    final primaryShadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.30)
        : const Color(0xFF0E5E38).withValues(alpha: 0.08);

    final secondaryShadowColor = Colors.black.withValues(
      alpha: isDarkMode ? 0.18 : 0.03,
    );

    return Hero(
      tag: step.imagePath,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                opaque: false,
                barrierColor: Colors.black.withValues(alpha: 0.88),
                pageBuilder: (_, __, ___) {
                  return FullScreenScreenshot(
                    imagePath: step.imagePath,
                  );
                },
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryShadowColor,
                  blurRadius: isDarkMode ? 20 : 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: secondaryShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: imageBackgroundColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        step.imagePath,
                        fit: step.imageFit,
                        alignment: step.imageAlignment,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 14,
                    bottom: 14,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
