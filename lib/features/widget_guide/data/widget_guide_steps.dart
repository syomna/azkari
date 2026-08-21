import 'dart:io';

import 'package:azkar_app/core/constants/app_strings.dart';

import '../models/widget_guide_step.dart';

List<WidgetGuideStep> getWidgetGuideSteps() {
  if (Platform.isIOS) {
    return const [
      WidgetGuideStep(
        title: AppStrings.guidePrayerTimesOnScreen,
        description: AppStrings.guideIntroDescription,
        imagePath: 'assets/images/widget_guide/ios_home_widget.webp',
        isIntro: true,
      ),
      WidgetGuideStep(
        title: AppStrings.guideOpenWidgetMenu,
        description: AppStrings.guideIosOpenWidgetDesc,
        imagePath: 'assets/images/widget_guide/ios_add_widget_menu.webp',
      ),
      WidgetGuideStep(
        title: AppStrings.guideSearchAzkary,
        description: AppStrings.guideIosSearchDesc,
        imagePath: 'assets/images/widget_guide/ios_search_azkary.webp',
      ),
      WidgetGuideStep(
        title: AppStrings.guideAddWidget,
        description: AppStrings.guideIosAddWidgetDesc,
        imagePath: 'assets/images/widget_guide/ios_widget_preview.webp',
      ),
    ];
  }

  return const [
    WidgetGuideStep(
      title: AppStrings.guidePrayerTimesOnScreen,
      description: AppStrings.guideIntroDescription,
      imagePath: 'assets/images/widget_guide/android_home_widget.webp',
      isIntro: true,
    ),
    WidgetGuideStep(
      title: AppStrings.guideOpenWidgetMenu,
      description: AppStrings.guideAndroidOpenWidgetDesc,
      imagePath: 'assets/images/widget_guide/android_add_widget_menu.webp',
    ),
    WidgetGuideStep(
      title: AppStrings.guideSearchAzkary,
      description: AppStrings.guideAndroidSearchDesc,
      imagePath: 'assets/images/widget_guide/android_search_azkary.webp',
    ),
    WidgetGuideStep(
      title: AppStrings.guideAddWidget,
      description: AppStrings.guideAndroidAddWidgetDesc,
      imagePath: 'assets/images/widget_guide/android_widget_preview.webp',
    ),
  ];
}
