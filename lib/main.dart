import 'package:azkar_app/core/providers/favorites_provider.dart';
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
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_saved_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  tz.initializeTimeZones();
  await di.init();
  await ScreenUtil.ensureScreenSize();
  await NotificationService.init(
    prefs: di.sl<SharedPreferences>(),
    prayerService: di.sl<PrayerTimeService>(),
  );

  NotificationService.configureNotificationTap(
    onTap: (payload) {},
  );

  final prefs = di.sl<SharedPreferences>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<AzkarProvider>(
          create: (_) => AzkarProvider(
            getAzkarUseCase: di.sl<GetAzkarUseCase>(),
            getCustomAzkarUseCase: di.sl<GetCustomAzkarUseCase>(),
            saveCustomAzkarUseCase: di.sl<SaveCustomAzkarUseCase>(),
            deleteCustomAzkarUseCase: di.sl<DeleteCustomAzkarUseCase>(),
          ),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(sharedPreferences: prefs),
        ),
        ChangeNotifierProvider<PrayerTimesProvider>(
          create: (_) => PrayerTimesProvider(
            prayerTimeService: di.sl<PrayerTimeService>(),
            sharedPreferences: prefs,
          ),
        ),
        ChangeNotifierProvider<NamesOfAllahProvider>(
          create: (_) => NamesOfAllahProvider(
            getNamesOfAllahUseCase: di.sl<GetNamesOfAllahUseCase>(),
          ),
        ),
        ChangeNotifierProvider<SurahProvider>(
          create: (_) => SurahProvider(
            getSurahUseCase: di.sl<GetSurahUseCase>(),
          ),
        ),
        ChangeNotifierProvider<TasbehProvider>(
          create: (_) => TasbehProvider(sharedPreferences: prefs),
        ),
        ChangeNotifierProvider<QuranProvider>(
          create: (_) => QuranProvider(
            saveQuranPageNumberUseCase: di.sl<SaveQuranPageNumberUseCase>(),
            getQuranPageNumberUseCase: di.sl<GetSavedQuranPageNumberUseCase>(),
            saveLatestSurahNumberUseCase:
                di.sl<SaveLatestQuranSurahNumberUseCase>(),
            getLatestSurahNumberUseCase:
                di.sl<GetLatestQuranSurahNumberUseCase>(),
            clearAllSavedQuranValuesUseCase:
                di.sl<ClearAllSavedQuranValuesUseCase>(),
            clearSavedPositionUseCase: di.sl<ClearSavedPositionUseCase>(),
            getSurahAudioUseCase: di.sl<GetSurahAudioUseCase>(),
            checkSurahDownloadedUseCase: di.sl<CheckSurahDownloadedUseCase>(),
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            notificationService: di.sl<NotificationService>(),
            prayerTimeService: di.sl<PrayerTimeService>(),
            sharedPreferences: prefs,
          ),
        ),
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
                title: 'أذكاري | Azkari',
                supportedLocales: const [Locale('ar')],
                locale: const Locale('ar'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                theme: AppPalette.lightTheme,
                darkTheme: AppPalette.darkTheme,
                themeMode: themeProvider.themeMode,
                home: screenUtilChild,
              ),
            );
          },
          child: const SplashScreen(),
        );
      },
    );
  }
}
