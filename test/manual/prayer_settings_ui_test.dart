import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_dropdown_button.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/adhan_page.dart';
import 'package:azkar_app/pages/contact_us_page.dart';
import 'package:azkar_app/pages/notifications_screen.dart';
import 'package:azkar_app/pages/prayer_times_settings_page.dart';
import 'package:azkar_app/features/widget_guide/presentation/widget_guide_page.dart';
import 'package:azkar_app/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _notificationChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);
const _timezoneChannel = MethodChannel('flutter_timezone');
const _homeWidgetChannel = MethodChannel('home_widget');
const _toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

final _scheduledNotifications = <MethodCall>[];
final _launchedUrls = <String>[];

class _FakeNotificationService implements NotificationService {
  int cancelCalls = 0;
  bool permissionGranted = true;

  @override
  Future<void> cancelAllNotifications() async {
    cancelCalls++;
  }

  @override
  Future<bool> isNotificationPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestNotificationPermission() async => permissionGranted;

  @override
  Future<void> requestExactAlarmsPermission() async {}

  @override
  Future<String?> periodicallyShowNotification() async => null;

  @override
  Future<String?> scheduleDayNightNotifications(
    double latitude,
    double longitude, {
    bool isDay = false,
  }) async =>
      null;

  @override
  Future<String?> schedulePrayerNotifications() async => null;

  @override
  Future<String?> schedulePreAdhanReminders() async => null;

  @override
  Future<String?> scheduleProphetBlessings() async => null;

  @override
  Future<String?> scheduleQuranReminderAfterSalah() async => null;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} is not implemented by the fake',
      );
}

class _FakeQuranProvider extends ChangeNotifier implements QuranProvider {
  bool cleared = false;

  @override
  Future<void> clearAllSavedQuranValues() async {
    cleared = true;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} is not implemented by the fake',
      );
}

class _FakeJustAudioPlatform extends JustAudioPlatform {
  final players = <_FakeAudioPlayerPlatform>[];

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final player = _FakeAudioPlayerPlatform(request.id);
    players.add(player);
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async =>
      DisposePlayerResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async =>
      DisposeAllPlayersResponse.fromMap(const <dynamic, dynamic>{});
}

class _FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  _FakeAudioPlayerPlatform(super.id);

  final _events = StreamController<PlaybackEventMessage>.broadcast();
  final _data = StreamController<PlayerDataMessage>.broadcast();
  int loadCalls = 0;
  int playCalls = 0;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => _data.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    loadCalls++;
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    playCalls++;
    return PlayResponse.fromMap(const <dynamic, dynamic>{});
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async =>
      SeekResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<SetLoopModeResponse> setLoopMode(
    SetLoopModeRequest request,
  ) async =>
      SetLoopModeResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async =>
      SetShuffleModeResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} is not implemented by the fake',
      );
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);

Map<String, Object> _cairoPreferences(
    {Map<String, Object> overrides = const {}}) {
  return <String, Object>{
    PrefsKeys.latitude: 30.0444,
    PrefsKeys.longitude: 31.2357,
    PrefsKeys.cityName: 'القاهرة',
    PrefsKeys.cityTimezone: 'Africa/Cairo',
    PrefsKeys.prayerTimeDate: _today(),
    'notificationsEnabled': false,
    'prayer_time_fajr': '4:50',
    'prayer_time_sunrise': '6:10',
    'prayer_time_dhuhr': '12:0',
    'prayer_time_asr': '15:30',
    'prayer_time_maghrib': '18:10',
    'prayer_time_isha': '19:40',
    ...overrides,
  };
}

Future<SharedPreferences> _preferences(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _pumpChecked(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 100),
]) async {
  await tester.pump(duration);
  expect(tester.takeException(), isNull);
}

Future<void> _pumpRoute(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await _pumpChecked(tester, const Duration(milliseconds: 100));
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget home,
  List<SingleChildWidget> providers = const <SingleChildWidget>[],
  ThemeProvider? themeProvider,
  Size size = const Size(430, 932),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, child) {
        ScreenUtil.init(context, designSize: const Size(430, 932));
        Widget app = MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const <Locale>[Locale('ar', 'EG')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: themeProvider?.themeMode == ThemeMode.dark
              ? AppPalette.darkTheme
              : AppPalette.lightTheme,
          darkTheme: AppPalette.darkTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: home,
        );
        if (themeProvider != null) {
          app = AnimatedBuilder(
            animation: themeProvider,
            builder: (context, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: const Locale('ar', 'EG'),
                supportedLocales: const <Locale>[Locale('ar', 'EG')],
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: themeProvider.themeMode == ThemeMode.dark
                    ? AppPalette.darkTheme
                    : AppPalette.lightTheme,
                darkTheme: AppPalette.darkTheme,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(textScale),
                    ),
                    child: child!,
                  );
                },
                home: home,
              );
            },
          );
        }
        if (providers.isEmpty) return app;
        return MultiProvider(providers: providers, child: app);
      },
      child: const SizedBox.shrink(),
    ),
  );
  expect(tester.takeException(), isNull);
  await _pumpChecked(tester, const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar');
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    PackageInfo.setMockInitialValues(
      appName: 'أذكاري',
      packageName: 'com.yomna.azkar_app',
      version: '4.3.31',
      buildNumber: '78',
      buildSignature: '',
    );
    JustAudioPlatform.instance = _FakeJustAudioPlatform();
    fln.FlutterLocalNotificationsPlatform.instance =
        fln.AndroidFlutterLocalNotificationsPlugin();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_notificationChannel, (call) async {
      if (call.method == 'zonedSchedule') {
        _scheduledNotifications.add(call);
      }
      if (call.method == 'pendingNotificationRequests') {
        return <Map<String, Object?>>[];
      }
      return true;
    });
    messenger.setMockMethodCallHandler(
      _timezoneChannel,
      (call) async => 'Etc/UTC',
    );
    messenger.setMockMethodCallHandler(
        _homeWidgetChannel, (call) async => true);
    messenger.setMockMethodCallHandler(_toastChannel, (call) async => true);
    messenger.setMockMethodCallHandler(
        _pathProviderChannel, (call) async => '/tmp/azkar_test');
    messenger.setMockMethodCallHandler(_urlLauncherChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      if (call.method == 'canLaunch') {
        return true;
      }
      if (call.method == 'launch') {
        _launchedUrls.add(args['url']! as String);
        return true;
      }
      return null;
    });
  });

  tearDownAll(() async {
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
  });

  test('PrayerTimeService matches adhan_dart across a DST date rollover', () {
    final service = PrayerTimeService();
    final location = tz.getLocation('America/New_York');
    final firstDate = tz.TZDateTime(location, 2026, 3, 8, 12);
    final secondDate = tz.TZDateTime(location, 2026, 3, 9, 12);
    final parameters = CalculationMethodParameters.muslimWorldLeague()
      ..madhab = Madhab.shafi;

    PrayerTimes expectedFor(tz.TZDateTime date) => PrayerTimes(
          coordinates: const Coordinates(40.7128, -74.0060),
          date: date,
          calculationParameters: parameters,
          precision: false,
        );

    final first = service.getTimes(
      40.7128,
      -74.0060,
      method: CalculationMethod.muslimWorldLeague,
      timezone: location.name,
      date: firstDate,
    );
    final second = service.getTimes(
      40.7128,
      -74.0060,
      method: CalculationMethod.muslimWorldLeague,
      timezone: location.name,
      date: secondDate,
    );
    final expectedFirst = expectedFor(firstDate);

    expect(first.fajr.toUtc(), expectedFirst.fajr.toUtc());
    expect(first.sunrise.toUtc(), expectedFirst.sunrise.toUtc());
    expect(first.dhuhr.toUtc(), expectedFirst.dhuhr.toUtc());
    expect(first.asr.toUtc(), expectedFirst.asr.toUtc());
    expect(first.maghrib.toUtc(), expectedFirst.maghrib.toUtc());
    expect(first.isha.toUtc(), expectedFirst.isha.toUtc());
    expect(
        second.fajr.difference(first.fajr).inHours, inInclusiveRange(23, 25));
    expect(
      tz.TZDateTime.from(second.fajr.toUtc(), location).day,
      9,
    );
  });

  test('stale prayer date is recalculated on provider load', () async {
    final preferences = await _preferences(
      _cairoPreferences(overrides: <String, Object>{
        PrefsKeys.prayerTimeDate: '2020-01-01',
      }),
    );
    final provider = PrayerTimesProvider(
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    addTearDown(provider.dispose);

    await provider.loadPrayerTimes();

    expect(provider.prayerTimes, isNotNull);
    expect(preferences.getString(PrefsKeys.prayerTimeDate), _today());
  });

  test('malformed stored time is ignored safely', () async {
    final preferences = await _preferences(
      _cairoPreferences(overrides: <String, Object>{
        '${PrefsKeys.prayerOverridePrefix}fajr': '25:99',
      }),
    );

    final times = PrayerTimeService().getEffectiveTimes(preferences);

    expect(times['fajr'], isNull);
  });

  test('quran reminder scheduling queues five valid payloads', () async {
    final preferences = await _preferences(
      _cairoPreferences(overrides: <String, Object>{
        'notificationsEnabled': true,
      }),
    );
    NotificationService.resetForTesting();
    final service = await NotificationService.init(
      prefs: preferences,
      prayerService: PrayerTimeService(),
    );
    addTearDown(NotificationService.resetForTesting);
    _scheduledNotifications.clear();

    final error = await service.scheduleQuranReminderAfterSalah();

    expect(error, isNull);
    final calls = _scheduledNotifications
        .where((call) => call.method == 'zonedSchedule')
        .toList();
    expect(calls, hasLength(5));
    expect(
      calls
          .map((call) => (call.arguments as Map<Object?, Object?>)['id'])
          .toSet(),
      <int>{300, 301, 302, 303, 304},
    );
    for (final call in calls) {
      final args = call.arguments as Map<Object?, Object?>;
      expect(args['payload'], 'quran_reminder');
      expect(args['body'], isNotEmpty);
    }
  });

  testWidgets('prayer settings edit and reset persist without errors',
      (tester) async {
    final preferences = await _preferences(
      _cairoPreferences(overrides: <String, Object>{
        '${PrefsKeys.prayerOverridePrefix}fajr': '5:0',
      }),
    );
    final prayerProvider = PrayerTimesProvider(
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    final notificationService = _FakeNotificationService();
    final notificationProvider = NotificationProvider(
      notificationService: notificationService,
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    addTearDown(prayerProvider.dispose);
    addTearDown(notificationProvider.dispose);

    await _pumpApp(
      tester,
      home: const PrayerTimesSettingsScreen(),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<PrayerTimesProvider>.value(
            value: prayerProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
    );

    expect(find.text('الفجر'), findsOneWidget);
    await tester.tap(find.text('الفجر'));
    await _pumpRoute(tester);
    expect(find.text('تعديل وقت صلاة الفجر'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.add).last);
    await _pumpChecked(tester);
    await tester.tap(find.text('حفظ التعديل'));
    await _pumpRoute(tester);

    expect(
      preferences.getString('${PrefsKeys.prayerOverridePrefix}fajr'),
      '5:1',
    );

    await tester.tap(find.text('إعادة ضبط الكل'));
    await _pumpRoute(tester);
    expect(find.text('إعادة ضبط جميع الأوقات؟'), findsOneWidget);
    await tester.tap(find.text('إعادة ضبط').last);
    await _pumpRoute(tester);
    expect(
      preferences.containsKey('${PrefsKeys.prayerOverridePrefix}fajr'),
      isFalse,
    );
    await _pumpChecked(tester, const Duration(seconds: 3));
  });

  testWidgets('prayer settings and adjustment sheet fit 320px at 2x text',
      (tester) async {
    final preferences = await _preferences(
      _cairoPreferences(overrides: <String, Object>{
        '${PrefsKeys.prayerOverridePrefix}fajr': '5:0',
      }),
    );
    final prayerProvider = PrayerTimesProvider(
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    final notificationProvider = NotificationProvider(
      notificationService: _FakeNotificationService(),
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    addTearDown(prayerProvider.dispose);
    addTearDown(notificationProvider.dispose);

    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      home: const PrayerTimesSettingsScreen(),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<PrayerTimesProvider>.value(
            value: prayerProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await _pumpChecked(tester);
    await tester.ensureVisible(find.text('الفجر'));
    await _pumpChecked(tester);
    await tester.tap(find.text('الفجر'));
    await _pumpRoute(tester);

    expect(find.text('تعديل وقت صلاة الفجر'), findsOneWidget);
    expect(find.text('حفظ التعديل'), findsOneWidget);
  });

  testWidgets('every notification toggle updates state and preference',
      (tester) async {
    final preferences = await _preferences(_cairoPreferences());
    final service = _FakeNotificationService();
    final provider = NotificationProvider(
      notificationService: service,
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    addTearDown(provider.dispose);

    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      home: const NotificationsScreen(),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<NotificationProvider>.value(value: provider),
      ],
    );

    expect(find.text('أذان الصلاة'), findsNothing);
    final masterSwitch = find.byType(Switch).first;
    await tester.ensureVisible(masterSwitch);
    await _pumpChecked(tester);
    await tester.tap(masterSwitch);
    await _pumpChecked(tester, const Duration(milliseconds: 200));
    expect(find.text('أذان الصلاة'), findsOneWidget);

    const entries = <String, String>{
      'أذان الصلاة': NotificationProvider.prayerAdhanKey,
      'أذكار الصباح والمساء': NotificationProvider.morningEveningAzkarKey,
      'تذكيرات عشوائية': NotificationProvider.periodicAzkarKey,
      'تذكير ما قبل الأذان': NotificationProvider.preAdhanKey,
      'ورد القرآن بعد الصلاة': NotificationProvider.quranAfterSalahKey,
      'الصلاة على النبي ﷺ': NotificationProvider.prophetBlessingsKey,
    };
    for (var index = 0; index < entries.length; index++) {
      final entry = entries.entries.elementAt(index);
      final typeSwitch = find.byType(Switch).at(index + 1);
      await tester.ensureVisible(typeSwitch);
      await _pumpChecked(tester);
      await tester.tap(typeSwitch);
      await _pumpChecked(tester, const Duration(milliseconds: 200));
      expect(preferences.getBool(entry.value), isFalse);
    }

    await tester.ensureVisible(masterSwitch);
    await _pumpChecked(tester);
    await tester.tap(masterSwitch);
    await _pumpChecked(tester, const Duration(milliseconds: 200));
    expect(preferences.getBool('notificationsEnabled'), isFalse);
    expect(service.cancelCalls, greaterThanOrEqualTo(8));
    await _pumpChecked(tester, const Duration(seconds: 3));
  });

  testWidgets('city search selects a fixed city and persists its timezone',
      (tester) async {
    final preferences = await _preferences(_cairoPreferences());
    final prayerProvider = PrayerTimesProvider(
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    final fakeNotificationService = _FakeNotificationService();
    final notificationProvider = NotificationProvider(
      notificationService: fakeNotificationService,
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: preferences,
    );
    addTearDown(prayerProvider.dispose);
    addTearDown(notificationProvider.dispose);

    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      home: Scaffold(
        appBar: AppBar(title: const CityDropdownButton()),
        body: const SizedBox.shrink(),
      ),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<PrayerTimesProvider>.value(
            value: prayerProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
    );

    await tester.tap(find.text('القاهرة'));
    await _pumpRoute(tester);
    expect(find.text('اختر المدينة'), findsOneWidget);
    // Construction-time reschedule already ran once; baseline before picking.
    final reschedulesBefore = fakeNotificationService.cancelCalls;
    await tester.enterText(find.byType(TextField), 'دبي');
    await _pumpChecked(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await _pumpChecked(tester);
    final dubaiTile = find.widgetWithText(ListTile, 'دبي');
    expect(dubaiTile, findsOneWidget);
    await tester.tap(dubaiTile);
    await _pumpRoute(tester);

    expect(preferences.getString(PrefsKeys.cityName), 'دبي');
    expect(preferences.getString(PrefsKeys.cityTimezone), 'Asia/Dubai');
    expect(preferences.getDouble(PrefsKeys.latitude), closeTo(25.2048, 0.0001));
    expect(
        preferences.getDouble(PrefsKeys.longitude), closeTo(55.2708, 0.0001));
    expect(prayerProvider.cityName, 'دبي');
    // Picking a city must re-plan notifications for the new city.
    expect(fakeNotificationService.cancelCalls, greaterThan(reschedulesBefore),
        reason: 'selecting a city must trigger a notification reschedule');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'settings theme, font, and clear dialogs work at 320px and 2x text',
      (tester) async {
    final preferences = await _preferences(<String, Object>{});
    final themeProvider = ThemeProvider(prefs: preferences);
    final tasbehProvider = TasbehProvider(sharedPreferences: preferences);
    final quranProvider = _FakeQuranProvider();
    addTearDown(themeProvider.dispose);
    addTearDown(tasbehProvider.dispose);
    addTearDown(quranProvider.dispose);

    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      themeProvider: themeProvider,
      home: const SettingsPage(),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<TasbehProvider>.value(value: tasbehProvider),
        ChangeNotifierProvider<QuranProvider>.value(value: quranProvider),
      ],
    );

    await tester.tap(find.text('تلقائي'));
    await _pumpRoute(tester);
    await tester.tap(find.text('داكن').last);
    await _pumpChecked(tester);
    expect(themeProvider.themeMode, ThemeMode.dark);

    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    await _pumpChecked(tester);
    await tester.drag(slider, const Offset(-120, 0));
    await _pumpChecked(tester);
    expect(preferences.getDouble('textScaleFactor'), greaterThan(1));

    await tester.ensureVisible(find.text('مسح عداد التسبيح'));
    await _pumpChecked(tester);
    await tester.tap(find.text('مسح عداد التسبيح'));
    await _pumpRoute(tester);
    expect(find.text('مسح عداد التسبيح؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await _pumpRoute(tester);

    await tester.ensureVisible(find.text('مسح تقدم القرآن'));
    await _pumpChecked(tester);
    await tester.tap(find.text('مسح تقدم القرآن'));
    await _pumpRoute(tester);
    expect(find.text('مسح تقدم القرآن؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await _pumpRoute(tester);
    expect(quranProvider.cleared, isFalse);
  });

  testWidgets(
      'prayer times section holds the home widget card and does not mark the '
      'guide as seen', (tester) async {
    final preferences = await _preferences(<String, Object>{});
    final themeProvider = ThemeProvider(prefs: preferences);
    final tasbehProvider = TasbehProvider(sharedPreferences: preferences);
    final quranProvider = _FakeQuranProvider();
    addTearDown(themeProvider.dispose);
    addTearDown(tasbehProvider.dispose);
    addTearDown(quranProvider.dispose);

    await _pumpApp(
      tester,
      home: const SettingsPage(),
      themeProvider: themeProvider,
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<TasbehProvider>.value(value: tasbehProvider),
        ChangeNotifierProvider<QuranProvider>.value(value: quranProvider),
      ],
    );
    await _pumpChecked(tester);

    // البطاقة داخل قسم مواقيت الصلاة: بعد صف المواقيت وقبل "المظهر العام".
    final Finder widgetRow = find.text('إضافة ويدجت مواقيت الصلاة');
    expect(widgetRow, findsOneWidget);
    final double prayerTileBottom =
        tester.getBottomLeft(find.text('مواقيت الصلاة والأذكار')).dy;
    final double rowTop = tester.getTopLeft(widgetRow).dy;
    final double appearanceTop =
        tester.getTopLeft(find.text('المظهر العام')).dy;
    expect(rowTop, greaterThan(prayerTileBottom));
    expect(rowTop, lessThan(appearanceTop));

    // الصف بنفس واجهة بقية بطاقات الإعدادات: نفس حجم ووزن خط العنوان،
    // ونفس الأيقونة (لون التطبيق وحجمها)، داخل بطاقة بنفس الحد والفاصل.
    TextStyle titleStyleOf(String text) =>
        tester.widget<Text>(find.text(text)).style!;
    final String prayerTitle = 'مواقيت الصلاة والأذكار';
    expect(titleStyleOf('إضافة ويدجت مواقيت الصلاة').fontSize,
        titleStyleOf(prayerTitle).fontSize);
    expect(titleStyleOf('إضافة ويدجت مواقيت الصلاة').fontWeight,
        titleStyleOf(prayerTitle).fontWeight);
    Finder leadingIconOf(String text) => find.descendant(
          of: find.ancestor(
              of: find.text(text), matching: find.byType(ListTile)),
          matching: find.byType(Icon),
        );
    final Finder prayerIcon = leadingIconOf(prayerTitle);
    final Finder widgetIcon = leadingIconOf('إضافة ويدجت مواقيت الصلاة');
    expect(tester.widget<Icon>(widgetIcon.first).color,
        tester.widget<Icon>(prayerIcon.first).color);
    expect(tester.getSize(widgetIcon.first).height,
        closeTo(tester.getSize(prayerIcon.first).height, 0.01));
    final Finder settingsCards = find.byWidgetPredicate(
      (Widget widget) =>
          widget is Material &&
          widget.shape is RoundedRectangleBorder &&
          (widget.shape as RoundedRectangleBorder).side.width > 0,
    );
    // أربع بطاقات أقسام + بطاقة الودجت.
    expect(settingsCards, findsNWidgets(5));

    await tester.tap(widgetRow);
    await _pumpRoute(tester);
    expect(find.byType(WidgetGuidePage), findsOneWidget);

    // إغلاق الدليل من هنا لا يُسجَّل كـ"شوهد من قبل"، فدليل أول التشغيل في
    // الرئيسية يبقى ظاهراً لمن لم يره بعد.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGuidePage), findsNothing);
    expect(preferences.getBool(WidgetGuidePage.seenPreferenceKey), isNull);
  });

  testWidgets('about dialog has no overflow at 320px and 2x text',
      (tester) async {
    final preferences = await _preferences(<String, Object>{});
    final themeProvider = ThemeProvider(prefs: preferences);
    final tasbehProvider = TasbehProvider(sharedPreferences: preferences);
    final quranProvider = _FakeQuranProvider();
    addTearDown(themeProvider.dispose);
    addTearDown(tasbehProvider.dispose);
    addTearDown(quranProvider.dispose);

    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      themeProvider: themeProvider,
      home: const SettingsPage(),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<TasbehProvider>.value(value: tasbehProvider),
        ChangeNotifierProvider<QuranProvider>.value(value: quranProvider),
      ],
    );

    await tester.ensureVisible(find.text('عن التطبيق'));
    await _pumpChecked(tester);
    await tester.tap(find.text('عن التطبيق'));
    await _pumpRoute(tester);

    expect(find.text('تطبيق أذكاري'), findsOneWidget);
    expect(find.text('تم التطوير بواسطة: يمنى'), findsOneWidget);
  });

  testWidgets('contact validation and mailto flow survive 320px and 2x text',
      (tester) async {
    _launchedUrls.clear();
    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      home: const ContactUsPage(),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'مشكلة');
    await tester.enterText(fields.at(1), 'تفاصيل المشكلة');
    final send = find.text('إرسال الآن');
    await tester.ensureVisible(send);
    await _pumpChecked(tester);
    await tester.tap(send);
    await _pumpChecked(tester, const Duration(milliseconds: 300));

    expect(_launchedUrls, hasLength(1));
    final uri = Uri.parse(_launchedUrls.single);
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'syomna444@gmail.com');
    expect(uri.queryParameters['subject'], '[AZKARI-SUPPORT] مشكلة');
    expect(uri.queryParameters['body'], contains('تفاصيل المشكلة'));
    expect(uri.queryParameters['body'], contains('App: Azkari'));
  });

  testWidgets('adhan page opens and dismisses without errors', (tester) async {
    await _pumpApp(
      tester,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AdhanPage(prayerKey: 'fajr'),
                ),
              ),
              child: const Text('فتح الأذان'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح الأذان'));
    await _pumpRoute(tester);
    expect(find.text('صلاة الفجر'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    for (var i = 0; i < 10; i++) {
      await _pumpChecked(tester);
    }

    expect(find.text('فتح الأذان'), findsOneWidget);
    expect(find.text('صلاة الفجر'), findsNothing);
  });

  testWidgets('adhan page fits 320px at 2x text', (tester) async {
    await _pumpApp(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      home: const AdhanPage(prayerKey: 'maghrib'),
    );

    expect(find.text('صلاة المغرب'), findsOneWidget);
    expect(find.text('إغلاق'), findsOneWidget);
  });
}
