import 'dart:async';
import 'dart:io';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/home/presentation/screens/home_screen.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>();
      }
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeAndNavigate();
      });
    }
  }

  Future<void> _initializeAndNavigate() async {
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final prayerTimesProvider =
        Provider.of<PrayerTimesProvider>(context, listen: false);
    final namesOfAllahProvider =
        Provider.of<NamesOfAllahProvider>(context, listen: false);
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);
    final tasbehProvider = Provider.of<TasbehProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final dataLoadingFutures = <Future>[
      themeProvider.loadTheme(),
      azkarProvider.loadAzkar(),
      azkarProvider.loadCustomAzkar(),
      favoritesProvider.loadFavorites(),
      prayerTimesProvider.loadPrayerTimes(),
      namesOfAllahProvider.loadNamesOfAllah(),
      surahProvider.loadSurah(),
      tasbehProvider.loadCount(),
    ];

    final imageAssets = [
      'assets/images/pray.png',
      'assets/images/quran.png',
      'assets/images/sun.png',
      'assets/images/night.png',
      'assets/images/tasbih.png',
      'assets/images/duaa.png',
      'assets/images/qibla.png',
    ];
    final imageFutures = imageAssets.map((path) {
      return precacheImage(AssetImage(path), context);
    });

    final minSplashDuration =
        Future.delayed(const Duration(milliseconds: 2500));

    await Future.wait([
      minSplashDuration,
      ...dataLoadingFutures,
      ...imageFutures,
    ]).catchError((_) => <void>[]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => UpgradeAlert(
              dialogStyle: Platform.isIOS
                  ? UpgradeDialogStyle.cupertino
                  : UpgradeDialogStyle.material,
              child: const HomeScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF2F7F5)],
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          opacity: _opacity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      height: 160.h,
                      width: 160.h,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/pray.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  Text(
                    AppStrings.splashAppName,
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.mainColor,
                      letterSpacing: 1.5,
                    ),
                  ),

                  Text(
                    'A Z K A R I',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      letterSpacing: 10,
                    ),
                  ),
                ],
              ),

              Positioned(
                bottom: 80.h,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 2.h,
                          backgroundColor:
                              AppPalette.mainColor.withValues(alpha: .1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppPalette.mainColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      AppStrings.splashSubtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
