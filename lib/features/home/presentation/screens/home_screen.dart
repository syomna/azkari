import 'dart:io';
import 'dart:math';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/screens/all_azkar_screen.dart';
import 'package:azkar_app/features/azkar/presentation/screens/azkar_details_screen.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/day_zekr_widget.dart';
import 'package:azkar_app/features/contact_us/presentation/screens/contact_us_screen.dart';
import 'package:azkar_app/features/home/presentation/widgets/welcoming_widget.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/screens/names_of_allah_screen.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/prayer_times/presentation/widgets/city_selector_chip.dart';
import 'package:azkar_app/features/prayer_times/presentation/widgets/prayer_times_card.dart';
import 'package:azkar_app/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:azkar_app/features/quran/presentation/screens/quran_details_screen.dart';
import 'package:azkar_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:azkar_app/features/tasbeh/presentation/screens/tasbeh_screen.dart';
import 'package:azkar_app/features/widget_guide/widget_guide_helper.dart';
import 'package:azkar_app/features/widget_guide/widgets/widget_promo_card.dart';
import 'package:azkar_app/widgets/app_error_widget.dart';
import 'package:azkar_app/widgets/app_loading_widget.dart';
import 'package:azkar_app/widgets/fade_slide_page_route.dart';
import 'package:azkar_app/widgets/feature_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Consumer<AzkarProvider>(
      builder: (context, azkarProvider, _) {
        if (azkarProvider.azkarStatus == AppLoadingStatus.initial ||
            azkarProvider.azkarStatus == AppLoadingStatus.loading) {
          return const Scaffold(
            body: AppLoadingWidget(),
          );
        } else if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
          return Scaffold(
            body: AppErrorWidget(
              errorMessage:
                  azkarProvider.azkarErrorMessage ?? AppStrings.loadError,
              onRetry: () => azkarProvider.loadAzkar(),
            ),
          );
        }
        return _HomeContent(randomNameIndex: _randomNameIndex);
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.randomNameIndex});

  final int randomNameIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppPalette.darkScaffoldGradientStart,
                    AppPalette.darkScaffoldGradientEnd
                  ]
                : [
                    AppPalette.lightScaffoldGradientStart,
                    AppPalette.lightScaffoldGradientEnd
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppPalette.mainColor,
            onRefresh: () async {
              await context.read<PrayerTimesProvider>().loadPrayerTimes();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      const CitySelectorChip(),
                      const Spacer(),
                      Semantics(
                        label: 'Toggle theme',
                        child: _buildHeaderAction(
                            context,
                            _themeModeIcon(
                                context.read<ThemeProvider>().themeMode),
                            () => context
                                .read<ThemeProvider>()
                                .cycleThemeMode()),
                      ),
                      SizedBox(width: 16.w),
                      Semantics(
                        label: 'Contact us',
                        child: _buildHeaderAction(
                            context,
                            CupertinoIcons.bubble_left_bubble_right,
                            () => Navigator.push(
                                context,
                                FadeSlidePageRoute(
                                    page: const ContactUsScreen()))),
                      ),
                      SizedBox(width: 16.w),
                      Semantics(
                        label: 'Settings',
                        child: _buildHeaderAction(
                            context,
                            CupertinoIcons.settings,
                            () => Navigator.push(
                                context,
                                FadeSlidePageRoute(
                                    page: const SettingsScreen()))),
                      ),
                    ],
                  ),
                    SizedBox(height: 10.h),
                    const WelcomingWidget(),
                    SizedBox(height: 15.h),
                    Consumer<PrayerTimesProvider>(
                      builder: (context, provider, _) {
                        if (provider.errorMessage != null) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: AppErrorWidget(
                              errorMessage: provider.errorMessage!,
                              onRetry: () => provider.loadPrayerTimes(),
                            ),
                          );
                        }
                        if (provider.prayerTimes == null) {
                          return const SizedBox.shrink();
                        }
                        return PrayerTimesCard(
                          times: provider.prayerTimes!,
                          displayTimes: provider.allDisplayTimes,
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    const WidgetPromoCard(),
                    SizedBox(height: 10.h),
                    _buildTitle(AppStrings.dayOfZikr),
                    SizedBox(height: 15.h),
                    const DayZekrWidget(),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildTitle(AppStrings.azkarAndDuaas)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                FadeSlidePageRoute(
                                    page: const AllAzkarScreen()));
                          },
                          child: Text(
                            AppStrings.viewAll,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: AppPalette.mainColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      children: _azkarList,
                    ),
                    if (Platform.isAndroid) SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildTitle(AppStrings.namesOfAllah)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                FadeSlidePageRoute(
                                    page: const NamesOfAllahScreen()));
                          },
                          child: Text(
                            AppStrings.viewAll,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: AppPalette.mainColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    if (context
                            .read<NamesOfAllahProvider>()
                            .namesOfAllahList
                            .isNotEmpty &&
                        randomNameIndex <
                            context
                                .read<NamesOfAllahProvider>()
                                .namesOfAllahList
                                .length)
                      NamesOfAllahCard(
                        item: context
                            .read<NamesOfAllahProvider>()
                            .namesOfAllahList[randomNameIndex],
                      ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Text _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static const _azkarList = [
    FeatureCard(
      text: AppStrings.holyQuran,
      img: 'quran',
      page: QuranDetailsScreen(),
      isColumn: true,
    ),
    FeatureCard(
      text: AppStrings.morningAzkar,
      img: 'sun',
      page: AzkarDetailsScreen(
        title: AppStrings.morningAzkar,
        categoryName: AppStrings.morningAzkar,
      ),
      isColumn: true,
    ),
    FeatureCard(
      text: AppStrings.eveningAzkar,
      img: 'night',
      page: AzkarDetailsScreen(
        title: AppStrings.eveningAzkar,
        categoryName: AppStrings.eveningAzkar,
      ),
      isColumn: true,
    ),
    FeatureCard(
      text: AppStrings.tasbeh,
      img: 'tasbih',
      page: TasbehScreen(),
      isColumn: true,
    ),
    FeatureCard(
      text: AppStrings.favorites,
      img: 'duaa',
      page: AllAzkarScreen(
        selectedFilter: AppStrings.favorites,
      ),
      isColumn: true,
    ),
    FeatureCard(
      text: AppStrings.qibla,
      img: 'qibla',
      page: QiblaScreen(),
      isColumn: true,
    ),
  ];

  static IconData _themeModeIcon(ThemeMode mode) {
    return mode == ThemeMode.dark
        ? CupertinoIcons.sun_max
        : CupertinoIcons.moon_stars;
  }

  static Widget _buildHeaderAction(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
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
