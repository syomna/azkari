import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class GuidePageIndicator extends StatelessWidget {
  const GuidePageIndicator({
    super.key,
    required this.currentIndex,
    required this.count,
  });

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    Color mutedColor = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.darkMutedText
        : AppPalette.lightMutedText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: isActive ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppPalette.mainColor : mutedColor,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
