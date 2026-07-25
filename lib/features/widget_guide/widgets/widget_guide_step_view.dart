import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/widget_guide/models/widget_guide_step.dart';
import 'package:azkar_app/features/widget_guide/widgets/screenshot_container.dart';
import 'package:flutter/material.dart';

class WidgetGuideStepView extends StatelessWidget {
  const WidgetGuideStepView({
    super.key,
    required this.step,
    required this.index,
  });

  final WidgetGuideStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mutedTextColor = theme.brightness == Brightness.dark
        ? AppPalette.darkMutedText
        : AppPalette.lightMutedText;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        22,
        12,
        22,
        4,
      ),
      child: Column(
        children: [
          if (step.isIntro) _buildNewFeatureBadge(context),
          if (step.isIntro) const SizedBox(height: 12),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Text(
              step.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: mutedTextColor,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 410,
                  maxHeight: screenHeight * 0.56,
                ),
                child: ScreenshotContainer(
                  step: step,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewFeatureBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppPalette.mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppPalette.mainColor.withValues(alpha: 0.14),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppPalette.mainColor,
          ),
          SizedBox(width: 6),
          Text(
            'ميزة جديدة',
            style: TextStyle(
              color: AppPalette.mainColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
