import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/widget_guide_page.dart';

class WidgetGuideHelper {
  const WidgetGuideHelper._();

  static Future<void> showIfNeeded(
    BuildContext context,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final hasSeenGuide = preferences.getBool(
          WidgetGuidePage.seenPreferenceKey,
        ) ??
        false;

    if (hasSeenGuide || !context.mounted) return;

    // ننتظر قليلًا حتى تظهر الصفحة الرئيسية أولًا.
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    if (!context.mounted) return;

    await WidgetGuidePage.open(context);
  }
}