import 'dart:io';

import '../models/widget_guide_step.dart';

List<WidgetGuideStep> getWidgetGuideSteps() {
  if (Platform.isIOS) {
    return const [
      WidgetGuideStep(
        title: 'مواقيت الصلاة على شاشتك',
        description:
            'تابع الصلاة القادمة ومواقيت اليوم مباشرةً من الشاشة الرئيسية.',
        imagePath: 'assets/images/widget_guide/ios_home_widget.webp',
        isIntro: true,
      ),
      WidgetGuideStep(
        title: 'افتح قائمة الويدجت',
        description:
            'اضغط مطولًا على مساحة فارغة في الشاشة الرئيسية، ثم اختر Add Widget.',
        imagePath: 'assets/images/widget_guide/ios_add_widget_menu.webp',
      ),
      WidgetGuideStep(
        title: 'ابحث عن أذكاري',
        description: 'اكتب أذكاري في خانة البحث، ثم اختر التطبيق من النتائج.',
        imagePath: 'assets/images/widget_guide/ios_search_azkary.webp',
      ),
      WidgetGuideStep(
        title: 'أضف الويدجت',
        description: 'اختر ويدجت مواقيت الصلاة، ثم اضغط على Add Widget.',
        imagePath: 'assets/images/widget_guide/ios_widget_preview.webp',
      ),
    ];
  }

  return const [
    WidgetGuideStep(
      title: 'مواقيت الصلاة على شاشتك',
      description:
          'تابع الصلاة القادمة ومواقيت اليوم مباشرةً من الشاشة الرئيسية.',
      imagePath: 'assets/images/widget_guide/android_home_widget.webp',
      isIntro: true,
    ),
    WidgetGuideStep(
      title: 'افتح قائمة الويدجت',
      description:
          'اضغط مطولًا على مساحة فارغة في الشاشة الرئيسية، ثم اختر Widgets.',
      imagePath: 'assets/images/widget_guide/android_add_widget_menu.webp',
    ),
    WidgetGuideStep(
      title: 'ابحث عن أذكاري',
      description: 'ابحث عن تطبيق أذكاري داخل قائمة الويدجت، ثم افتح خياراته.',
      imagePath: 'assets/images/widget_guide/android_search_azkary.webp',
    ),
    WidgetGuideStep(
      title: 'أضف الويدجت',
      description:
          'اضغط مطولًا على الويدجت واسحبها إلى المكان المناسب على الشاشة.',
      imagePath: 'assets/images/widget_guide/android_widget_preview.webp',
    ),
  ];
}
