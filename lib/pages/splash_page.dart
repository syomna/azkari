import 'dart:async';

import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _initialized = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger the fade-in animation shortly after boot
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeAndNavigate();
    }
  }

  Future<void> _initializeAndNavigate() async {
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    final namesOfAllahProvider =
        Provider.of<NamesOfAllahProvider>(context, listen: false);
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);
    final tasbehProvider = Provider.of<TasbehProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final dataLoadingFutures = <Future>[
      themeProvider.loadTheme(),
      azkarProvider.loadAzkar(),
      namesOfAllahProvider.loadNamesOfAllah(),
      surahProvider.loadSurah(),
      tasbehProvider.loadCount(),
    ];

    // Minimum 2.5 seconds for branding impact
    final minSplashDuration =
        Future.delayed(const Duration(milliseconds: 2500));

    await Future.wait([
      minSplashDuration,
      ...dataLoadingFutures,
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          // const LayoutPage(),
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
                  // Logo Animation
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

                  // Arabic Title
                  Text(
                    'أذكــــاري',
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.mainColor,
                      letterSpacing: 1.5,
                    ),
                  ),

                  // English Subtitle
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

              // Bottom Loading Indicator
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
                      'ألا بذكر الله تطمئن القلوب',
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
