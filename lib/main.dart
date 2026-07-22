import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_saved_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/adhan_page.dart';
import 'package:azkar_app/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'di/injection_container.dart' as di;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handles notification taps — navigates to AdhanPage with the prayer key.
void _handleNotificationTap(String payload) {
  // Pause Quran audio if playing before opening Adhan
  try {
    final quranProvider =
        navigatorKey.currentContext?.read<QuranProvider>();
    quranProvider?.pauseForNotification();
  } catch (e) {
    debugPrint('Error pausing Quran for notification: $e');
  }

  // payload format: "prayer_fajr", "prayer_dhuhr", etc.
  if (payload.startsWith('prayer_')) {
    final prayerKey = payload.replaceFirst('prayer_', '');
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AdhanPage(prayerKey: prayerKey),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await di.init();
  await ScreenUtil.ensureScreenSize();
  await NotificationService.init(
    prefs: di.sl<SharedPreferences>(),
    prayerService: di.sl<PrayerTimeService>(),
  );

  // Register notification tap handler before runApp
  NotificationService.configureNotificationTap(
    onTap: _handleNotificationTap,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(
                  prefs: di.sl<SharedPreferences>(),
                )),
        ChangeNotifierProvider(
          create: (_) => AzkarProvider(
              getAzkarUseCase: di.sl<GetAzkarUseCase>(),
              prayerTimeService: di.sl<PrayerTimeService>(),
              sharedPreferences: di.sl<SharedPreferences>(),
              getCustomAzkarUseCase: di.sl<GetCustomAzkarUseCase>(),
              saveCustomAzkarUseCase: di.sl<SaveCustomAzkarUseCase>(),
              deleteCustomAzkarUseCase: di.sl<DeleteCustomAzkarUseCase>()),
        ),
        ChangeNotifierProvider(
          create: (_) => NamesOfAllahProvider(
            getNamesOfAllahUseCase: di.sl<GetNamesOfAllahUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SurahProvider(
            getSurahUseCase: di.sl<GetSurahUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
            create: (_) => TasbehProvider(
                  sharedPreferences: di.sl<SharedPreferences>(),
                )),
        ChangeNotifierProvider(
            create: (_) => QuranProvider(
                  saveQuranPageNumberUseCase: di.sl<SaveQuranPageNumberUsecase>(),
                  getQuranPageNumberUseCase:
                      di.sl<GetSavedQuranPageNumberUsecase>(),
                  saveLatestSurahNumberUseCase:
                      di.sl<SaveLatestQuranSurahNumberUseCase>(),
                  getLatestSurahNumberUseCase:
                      di.sl<GetLatestQuranSurahNumberUseCase>(),
                  clearAllSavedQuranValuesUsecase:
                      di.sl<ClearAllSavedQuranValuesUseCase>(),
                  clearSavedPositionUseCase: di.sl<ClearSavedPositionUseCase>(),
                  getSurahAudioUseCase: di.sl<GetSurahAudioUseCase>(),
                  checkSurahDownloadedUseCase:
                      di.sl<CheckSurahDownloadedUseCase>(),
                )),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(
                notificationService: di.sl<NotificationService>(),
                prayerTimeService: di.sl<PrayerTimeService>(),
                sharedPreferences: di.sl<SharedPreferences>())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialPayload;
  bool _checkedInitialPayload = false;

  @override
  void initState() {
    super.initState();
    _checkInitialNotification();
  }

  Future<void> _checkInitialNotification() async {
    final payload = await NotificationService.instance
        .getInitialNotificationPayload();
    if (payload != null && mounted) {
      setState(() {
        _initialPayload = payload;
      });
    }
    _checkedInitialPayload = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (ctx, screenUtilChild) {
            ScreenUtil.init(ctx);
            return MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(themeProvider.textScaleFactor),
              ),
              child: MaterialApp(
                navigatorKey: navigatorKey,
                title: 'أذكاري | Azkari',
                supportedLocales: const [Locale('ar')],
                locale: const Locale('ar'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                theme: themeProvider.isLight
                    ? AppPalette.lightTheme
                    : AppPalette.darkTheme,
                home: screenUtilChild,
              ),
            );
          },
          child: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_checkedInitialPayload && _initialPayload != null) {
      // App launched from notification tap — go to AdhanPage after splash
      return SplashPage(
        onReady: () {
          _handleNotificationTap(_initialPayload!);
        },
      );
    }
    return const SplashPage();
  }
}
