import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Flag to ensure initialization only happens once
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if it's the first time didChangeDependencies is called and we haven't initialized yet
    if (!_initialized) {
      _initialized = true; // Set flag to true to prevent future calls
      _initializeAndNavigate(); // Now call the async initialization here
    }
  }

  Future<void> _initializeAndNavigate() async {
    // We are now in didChangeDependencies, where `context` is fully available
    // for Provider lookups. `listen: false` is still appropriate here.

    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    final namesOfAllahProvider =
        Provider.of<NamesOfAllahProvider>(context, listen: false);
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);
    final tasbehProvider = Provider.of<TasbehProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final dataLoadingFutures = <Future>[];

    dataLoadingFutures.add(themeProvider.loadTheme());

    // Ensure your load methods return Future<void>
    dataLoadingFutures.add(azkarProvider.loadAzkar());
    dataLoadingFutures.add(namesOfAllahProvider.loadNamesOfAllah());
    dataLoadingFutures.add(surahProvider
        .loadSurah()); // Use loadSurahs() if that's the method name
    dataLoadingFutures.add(
        tasbehProvider.loadCount()); // Assuming this loads the initial count

    // Set a minimum splash duration (e.g., 2 seconds)
    final minSplashDuration = Future.delayed(const Duration(seconds: 2));

    // Wait for all data loading futures AND the minimum splash duration
    await Future.wait([
      minSplashDuration,
      Future.wait(dataLoadingFutures),
    ]);

    // Only navigate if the widget is still in the tree
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LayoutPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash UI remains the same
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/pray.png'))),
            ),
            SizedBox(
              height: 40.h,
            ),
            Text(
              'أذكــــاري | Azkari',
              style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
