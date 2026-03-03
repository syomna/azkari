import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/day_zekr_widget.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_widget.dart';
import 'package:azkar_app/features/qibla/presentation/pages/qibla_screen.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/tasbeh/presentation/pages/tasbeh_page.dart';
import 'package:azkar_app/pages/contact_us_page.dart';
import 'package:azkar_app/pages/settings_page.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:azkar_app/widgets/prayer_times_card.dart';
import 'package:azkar_app/widgets/welcoming_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final azkarProvider = Provider.of<AzkarProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (azkarProvider.azkarStatus == AppLoadingStatus.initial ||
        azkarProvider.azkarStatus == AppLoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppPalette.mainColor,
        ),
      );
    } else if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
      return Center(
          child:
              Text('Error loading Azkar: ${azkarProvider.azkarErrorMessage}'));
    } else {
      return Scaffold(
          body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                : [const Color(0xFFFDFDFD), const Color(0xFFF5F5F5)],
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
                  SizedBox(
                    height: 5.h,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderAction(
                            context,
                            isDark
                                ? CupertinoIcons.sun_max
                                : CupertinoIcons.moon_stars,
                            () => context
                                .read<ThemeProvider>()
                                .toggleTheme() // Example toggle function
                            ),
                        SizedBox(width: 12.w),
                        _buildHeaderAction(
                            context,
                            CupertinoIcons.bubble_left_bubble_right,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ContactUsPage()))),
                        SizedBox(width: 12.w),
                        _buildHeaderAction(
                            context,
                            CupertinoIcons.settings,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()))),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  const WelcomingWidget(),
                  SizedBox(
                    height: 15.h,
                  ),
                  if (context.read<AzkarProvider>().prayerTimes != null)
                    PrayerTimesCard(
                      times: context.read<AzkarProvider>().prayerTimes!,
                    ),
                  SizedBox(
                    height: 10.h,
                  ),
                  _buildTitle('ذكر اليوم'),
                  SizedBox(
                    height: 10.h,
                  ),
                  const DayZekrWidget(),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTitle('الأذكار والأدعية'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AllAzkarPage()));
                        },
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                              color: AppPalette.mainColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  GridView(
                    shrinkWrap: true, // Prevents infinite height error
                    physics:
                        const NeverScrollableScrollPhysics(), // Disables scrolling
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    children: azkarList,
                  ),
                  _buildTitle('أسماء الله الحسنى'),
                  SizedBox(
                    height: 10.h,
                  ),
                  const NamesOfAllahWidget(),
                  SizedBox(
                    height: 40.h,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }

  Text _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<Component> get azkarList {
    return const [
      Component(
        text: AppConstants.holyQuran,
        img: 'quran',
        page: QuranDetailPage(),
        isColumn: true,
      ),
      Component(
        text: AppConstants.morningAzkarCategory,
        img: 'sun',
        page: AzkarCategoryPage(
          title: AppConstants.morningAzkarCategory,
          categoryName: AppConstants.morningAzkarCategory,
        ),
        isColumn: true,
      ),
      Component(
        text: AppConstants.eveningAzkarCategory,
        img: 'night',
        page: AzkarCategoryPage(
          title: AppConstants.eveningAzkarCategory,
          categoryName: AppConstants.eveningAzkarCategory,
        ),
        isColumn: true,
      ),
      Component(
        text: AppConstants.tasbeh,
        img: 'tasbih',
        page: TasbehPage(),
        isColumn: true,
      ),
      Component(
        text: AppConstants.variousDuaaCategory,
        img: 'duaa',
        page: AzkarCategoryPage(
          title: AppConstants.variousDuaaCategory,
          categoryName: AppConstants.variousDuaaCategory,
        ),
        isColumn: true,
      ),
      Component(
        text: AppConstants.qibla,
        img: 'qibla',
        page: QiblaScreen(),
        isColumn: true,
      ),
    ];
  }

  Widget _buildHeaderAction(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppPalette.mainColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20.h, color: AppPalette.mainColor),
      ),
    );
  }
}
