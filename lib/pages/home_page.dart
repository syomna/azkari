import 'dart:math';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/ad3ya_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_dropdown_button.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/day_zekr_widget.dart';
import 'package:azkar_app/features/names_of_allah/presentation/pages/names_of_allah_page.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:azkar_app/features/qibla/presentation/pages/qibla_screen.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/tasbeh/presentation/pages/tasbeh_page.dart';
import 'package:azkar_app/features/widget_guide/widget_guide_helper.dart';
import 'package:azkar_app/pages/settings_page.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:azkar_app/widgets/prayer_times_card.dart';
import 'package:azkar_app/widgets/welcoming_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // إيقاع فراغات واحد للصفحة كلها: 8 أعلى الودجت، 16 بين الودجتات
  // المتتالية، 24 قبل شبكة التنقل، و32 أسفل الصفحة. كان كل سطر يستخدم رقماً
  // مختلفاً (5/10/12/15/18/24) فيبدو التخطيط غير متسق.
  static final double _gapTop = 8.h;
  static final double _gap = 16.h;
  static final double _gapSection = 24.h;
  static final double _gapBottom = 32.h;

  /// اسم من أسماء الله الحسنى يظهر في بطاقة اليوم، ويتغير بين فتحات الصفحة.
  int _randomNameIndex = 0;

  @override
  void initState() {
    super.initState();
    final namesList = context.read<NamesOfAllahProvider>().namesOfAllahList;
    if (namesList.isNotEmpty) {
      _randomNameIndex = Random().nextInt(namesList.length);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetGuideHelper.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(builder: (context) {
      final azkarStatus =
          context.select<AzkarProvider, AppLoadingStatus>((p) => p.azkarStatus);
      if (azkarStatus == AppLoadingStatus.initial ||
          azkarStatus == AppLoadingStatus.loading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppPalette.mainColor,
            ),
          ),
        );
      } else if (azkarStatus == AppLoadingStatus.error) {
        final error =
            context.select<AzkarProvider, String?>((p) => p.azkarErrorMessage);
        return Scaffold(
          body: Center(child: Text('حدث خطأ أثناء تحميل الأذكار: $error')),
        );
      } else {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppPalette.homeGradientDarkFrom,
                        AppPalette.homeGradientDarkTo
                      ]
                    : [
                        AppPalette.homeGradientLightFrom,
                        AppPalette.homeGradientLightTo
                      ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: _gapTop),
                      // The city picker moved into the prayer-times header and
                      // the settings entry point moved into the greeting row, so
                      // the home screen no longer spends two full rows on
                      // controls above the prayer times.
                      WelcomingWidget(
                        action: _buildHeaderAction(
                          context,
                          CupertinoIcons.settings,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage())),
                        ),
                      ),
                      SizedBox(height: _gap),
                      Consumer<PrayerTimesProvider>(
                        builder: (context, provider, _) {
                          if (provider.prayerTimes == null) {
                            return const SizedBox.shrink();
                          }
                          return PrayerTimesCard(
                            displayTimes: provider.allDisplayTimes,
                            timezone: provider.cityTimezone,
                            locationSlot:
                                const CityDropdownButton(compact: true),
                          );
                        },
                      ),
                      SizedBox(height: _gapSection),
                      const DayZekrWidget(),
                      SizedBox(height: _gapSection),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                        children: azkarList,
                      ),
                      // SizedBox(height: _gapSection),
                      Builder(builder: (context) {
                        // watch لا read: الأسماء تُحمَّل من شاشة البداية
                        // وقد تصل بعد بناء هذه البطاقة، وread لا يعيد البناء
                        // عند وصولها فتبقى البطاقة مختفية إلى حين تفتح الصفحة
                        // من جديد.
                        final names = context
                            .watch<NamesOfAllahProvider>()
                            .namesOfAllahList;
                        if (names.isEmpty) return const SizedBox.shrink();
                        return NamesOfAllahCard(
                          item: names[_randomNameIndex % names.length],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NamesOfAllahPage()),
                          ),
                        );
                      }),
                      SizedBox(height: _gapBottom),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  /// شبكة التنقل: ست وجهات في صفين، الصف الأول فيه ما يُستعمل يومياً والثاني
  /// فيه المراجع والأدوات. الأيقونات كلّها من طقم الأيقونات الإسلامية
  /// (مصحف، تكبير، دعاء، أسماء الله الحسنى، تسبيح، قبلة) بنمط solid واحد
  /// وباللون الأخضر الأساسي، حتى تبدو الشبكة وحدة واحدة.
  List<Component> get azkarList {
    return const [
      Component(
        text: AppConstants.holyQuran,
        icon: FlutterIslamicIcons.quran,
        page: QuranDetailPage(),
      ),
      Component(
        text: AppConstants.azkarCategory,
        icon: FlutterIslamicIcons.prayingPerson,
        page: AllAzkarPage(),
      ),
      Component(
        text: AppConstants.ad3yaCategory,
        icon: FlutterIslamicIcons.prayer,
        page: Ad3yaPage(),
      ),
      Component(
        text: AppConstants.namesOfAllah,
        icon: FlutterIslamicIcons.allah99,
        page: NamesOfAllahPage(),
      ),
      Component(
        text: AppConstants.tasbeh,
        icon: FlutterIslamicIcons.tasbih,
        page: TasbehPage(),
      ),
      Component(
        text: AppConstants.qibla,
        icon: FlutterIslamicIcons.qibla,
        page: QiblaScreen(),
      ),
    ];
  }

  Widget _buildHeaderAction(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppPalette.mainColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20.h, color: AppPalette.mainColor),
        ),
      ),
    );
  }
}
