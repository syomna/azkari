import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/screens/widget_guide_screen.dart';

class WidgetGuideHelper {
  const WidgetGuideHelper._();

  static Future<void> showIfNeeded(
    BuildContext context,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final hasSeenGuide = preferences.getBool(
          WidgetGuideScreen.seenPreferenceKey,
        ) ??
        false;

    if (hasSeenGuide || !context.mounted) return;

    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    if (!context.mounted) return;

    await WidgetGuideScreen.open(context);
  }
}
