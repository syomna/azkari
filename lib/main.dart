import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_saved_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_page_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_surah_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/adhan_page.dart';
import 'package:azkar_app/pages/splash_page.dart';
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'di/injection_container.dart' as di;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Cold-start notifications fire the tap callback twice: once from the launch
// payload and once from the plugin's response callback. The dedupe guard keeps
// the SAME payload from navigating twice within a 3s window.
String? _lastTapPayload;
DateTime? _lastTapTime;

/// Handles notification taps — navigates to AdhanPage with the prayer key for
/// prayer notifications, and to the relevant azkar/quran screen otherwise.
void _handleNotificationTap(String payload) {
  final now = DateTime.now();
  if (payload == _lastTapPayload &&
      _lastTapTime != null &&
      now.difference(_lastTapTime!) < const Duration(seconds: 3)) {
    return;
  }
  _lastTapPayload = payload;
  _lastTapTime = now;

  // Pause Quran audio if playing before opening another screen.
  try {
    final quranProvider = navigatorKey.currentContext?.read<QuranProvider>();
    quranProvider?.pauseForNotification();
  } catch (e) {
    debugPrint('Error pausing Quran for notification: $e');
  }

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  // payload format: "prayer_fajr", "prayer_dhuhr", etc.
  if (payload.startsWith('prayer_')) {
    final prayerKey = payload.replaceFirst('prayer_', '');
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AdhanPage(prayerKey: prayerKey),
      ),
    );
    return;
  }

  switch (payload) {
    case 'azkar_morning':
      navigator.push(MaterialPageRoute(
        builder: (_) => const AzkarDetailsPage(
          title: AppConstants.morningAzkarCategory,
          categoryName: AppConstants.morningAzkarCategory,
        ),
      ));
      break;
    case 'azkar_evening':
      navigator.push(MaterialPageRoute(
        builder: (_) => const AzkarDetailsPage(
          title: AppConstants.eveningAzkarCategory,
          categoryName: AppConstants.eveningAzkarCategory,
        ),
      ));
      break;
    case 'quran_reminder':
      navigator.push(MaterialPageRoute(
        builder: (_) => const QuranDetailPage(),
      ));
      break;
    default:
      // periodic azkar, prophet blessings, and any unknown payload open the
      // azkar library so the tap is never a silent no-op.
      navigator.push(MaterialPageRoute(
        builder: (_) => const AllAzkarPage(),
      ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await di.init();
  // intl needs explicit locale data before any `DateFormat` with a locale like
  // 'ar' can format (prayer times card). Mirror this call in tests that pump
  // locale-aware widgets.
  await initializeDateFormatting('ar');
  await ScreenUtil.ensureScreenSize();
  await NotificationService.init(
    prefs: di.sl<SharedPreferences>(),
    prayerService: di.sl<PrayerTimeService>(),
  );
  // Ask for notification (+ exact-alarm) permission once on first launch only;
  // later launches never show the OS dialog unprompted.
  await NotificationService.instance.requestFirstRunPermissionsIfNeeded();

  // Register notification tap handler before runApp
  NotificationService.configureNotificationTap(
    onTap: _handleNotificationTap,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Configure the audio session before any audio playback. just_audio on iOS
  // requires an active AVAudioSession (playback category) or loading a local
  // file fails with AVFoundation error -11800.
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (e) {
    debugPrint('Failed to configure audio session: $e');
  }

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
              getCustomAzkarUseCase: di.sl<GetCustomAzkarUseCase>(),
              saveCustomAzkarUseCase: di.sl<SaveCustomAzkarUseCase>(),
              deleteCustomAzkarUseCase: di.sl<DeleteCustomAzkarUseCase>(),
              updateCustomAzkarUseCase:
                  di.sl<UpdateCustomAzkarUseCase>()),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(
            sharedPreferences: di.sl<SharedPreferences>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(
            prayerTimeService: di.sl<PrayerTimeService>(),
            sharedPreferences: di.sl<SharedPreferences>(),
          ),
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
                  saveQuranPageNumberUseCase:
                      di.sl<SaveQuranPageNumberUsecase>(),
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
                  saveQuranBookmarkUseCase:
                      di.sl<SaveQuranBookmarkUseCase>(),
                  getQuranBookmarkSurahUseCase:
                      di.sl<GetQuranBookmarkSurahUseCase>(),
                  getQuranBookmarkPageUseCase:
                      di.sl<GetQuranBookmarkPageUseCase>(),
                  clearQuranBookmarkUseCase:
                      di.sl<ClearQuranBookmarkUseCase>(),
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _initialPayload;
  bool _checkedInitialPayload = false;
  Timer? _dateCheckTimer;
  bool _isRefreshingDayChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialNotification();
    // Re-check the day boundary while the app stays open (cold splash only
    // reschedules on launch). Cheap: returns immediately when already today.
    _dateCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshIfDayChanged(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDayChanged();
    }
  }

  /// When the calendar day rolled over (resume or while running), recompute
  /// today's prayer times, refresh the home widget, and — only if something
  /// actually changed — reschedule all notifications.
  Future<void> _refreshIfDayChanged() async {
    if (_isRefreshingDayChange || !mounted) return;
    _isRefreshingDayChange = true;
    try {
      final prayerProvider = context.read<PrayerTimesProvider>();
      final changed = await prayerProvider.refreshIfStale();
      if (changed && mounted) {
        await context.read<NotificationProvider>().refreshNotifications();
      }
    } finally {
      _isRefreshingDayChange = false;
    }
  }

  Future<void> _checkInitialNotification() async {
    final payload =
        await NotificationService.instance.getInitialNotificationPayload();
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
                supportedLocales: const [Locale('ar', 'EG')],
                locale: const Locale('ar', 'EG'),
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
