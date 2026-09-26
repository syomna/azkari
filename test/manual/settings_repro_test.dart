import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/pages/prayer_times_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _notifChannel = 'dexterous.com/flutter/local_notifications';
const _tzChannel = 'flutter_timezone';

/// Records every notification-plugin call made by the app so tests can assert
/// exactly what was (re)scheduled.
final scheduled = <MethodCall>[];

/// True while a `cancelAll` plugin call is still in progress. Overlapping
/// `cancelAll` calls would prove two reschedule runs are racing each other.
var cancelAllInFlight = false;
var concurrentCancelCount = 0;

/// When true, the mock rejects any `zonedSchedule` that requests an exact
/// alarm (mirrors Android 12+ denying the "Alarms & reminders" permission).
var denyExactAlarms = false;

/// IANA name the mocked `flutter_timezone` plugin reports as the device zone.
var tzDeviceIana = 'Etc/UTC';

void _mockChannels() {
  scheduled.clear();
  concurrentCancelCount = 0;
  denyExactAlarms = false;
  tzDeviceIana = 'Etc/UTC';
  // In real app runs the engine registers the Android/iOS plugin, which sets
  // FlutterLocalNotificationsPlatform.instance. A widget/unit test must do it
  // itself or every plugin call throws LateInitializationError.
  fln.FlutterLocalNotificationsPlatform.instance =
      fln.AndroidFlutterLocalNotificationsPlugin();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(_notifChannel),
          (call) async {
    scheduled.add(call);
    if (call.method == 'zonedSchedule') {
      final mode = ((call.arguments as Map)['platformSpecifics']
          as Map)['scheduleMode'] as String;
      if (denyExactAlarms && mode == 'exactAllowWhileIdle') {
        throw PlatformException(
          code: 'exact_alarms_not_permitted',
          message: 'Exact alarms are not permitted',
        );
      }
    }
    if (call.method == 'requestNotificationsPermission') return true;
    if (call.method == 'requestExactAlarmsPermission') return true;
    if (call.method == 'pendingNotificationRequests') return <Map>[];
    if (call.method == 'cancelAll') {
      if (cancelAllInFlight) concurrentCancelCount++;
      cancelAllInFlight = true;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      cancelAllInFlight = false;
      return true;
    }
    return true;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel(_tzChannel), (call) async => tzDeviceIana);
}

Map<String, Object> _cairoPrefs({Map<String, Object> overrides = const {}}) {
  return {
    PrefsKeys.latitude: 30.0444,
    PrefsKeys.longitude: 31.2357,
    PrefsKeys.cityName: 'القاهرة',
    PrefsKeys.cityTimezone: 'Africa/Cairo',
    PrefsKeys.prayerTimeDate: '',
    'notificationsEnabled': true,
    // Calculated times (stored as city-local wall clock).
    'prayer_time_fajr': '4:50',
    'prayer_time_dhuhr': '12:0',
    'prayer_time_asr': '15:30',
    'prayer_time_maghrib': '18:10',
    'prayer_time_isha': '19:40',
    ...overrides,
  };
}

Future<NotificationService> _service(SharedPreferences prefs) {
  // The production service caches a singleton; reset it so every test gets an
  // instance bound to its own prefs and prayer-time state.
  NotificationService.resetForTesting();
  return NotificationService.init(
    prefs: prefs,
    prayerService: PrayerTimeService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _mockChannels();
  tzdata.initializeTimeZones();

  Future<void> resetTz() async {
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
  }

  group('edited prayer time scheduling', () {
    test('asr override schedules at the overridden time, in device tz',
        () async {
      SharedPreferences.setMockInitialValues(
        _cairoPrefs(overrides: {'prayer_override_asr': '16:30'}),
      );
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      final service = await _service(prefs);
      scheduled.clear();

      await service.schedulePrayerNotifications();

      final asr = scheduled.singleWhere((c) =>
          c.method == 'zonedSchedule' && (c.arguments as Map)['id'] == 102);
      final args = asr.arguments as Map;
      // Cairo is UTC+3 year-round (Egypt has no DST): 16:30 Cairo == 13:30 UTC.
      expect(args['timeZoneName'], 'Etc/UTC');
      expect(args['scheduledDateTimeISO8601'], contains('13:30:00'));

      final before = tz.TZDateTime.now(tz.local);
      final parsed = tz.TZDateTime.parse(tz.getLocation('Etc/UTC'),
          args['scheduledDateTimeISO8601'] as String);
      final inDevice = tz.TZDateTime.from(parsed, tz.local);
      final diff = inDevice.isBefore(before)
          ? inDevice.add(const Duration(days: 1))
          : inDevice;
      expect(diff.hour, 13);
      expect(diff.minute, 30);
    });

    test('override also wins for pre-adhan reminders', () async {
      SharedPreferences.setMockInitialValues(
        _cairoPrefs(overrides: {'prayer_override_asr': '16:30'}),
      );
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      final service = await _service(prefs);
      scheduled.clear();

      await service.schedulePreAdhanReminders();

      final asr = scheduled.singleWhere((c) =>
          c.method == 'zonedSchedule' && (c.arguments as Map)['id'] == 202);
      final args = asr.arguments as Map;
      final parsed = tz.TZDateTime.parse(tz.getLocation('Etc/UTC'),
          args['scheduledDateTimeISO8601'] as String);
      // 16:30 Cairo minus 10 min == 13:20 UTC.
      expect(parsed.hour, 13);
      expect(parsed.minute, 20);
    });

    test('concurrent reschedules do not drop notifications', () async {
      SharedPreferences.setMockInitialValues(_cairoPrefs());
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      final service = await _service(prefs);
      final notify = NotificationProvider(
        notificationService: service,
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      // Let the constructor-triggered reschedule settle before measuring.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      scheduled.clear();
      concurrentCancelCount = 0;

      // Simulate fast successive edits without awaiting each reschedule.
      await Future.wait([
        notify.applyNotificationStates(),
        notify.applyNotificationStates(),
        notify.applyNotificationStates(),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final zoned = scheduled.where((c) => c.method == 'zonedSchedule');
      // Every enabled type must be represented (5 prayer + 2 day/night azkar
      // + 5 pre-adhan + 5 quran + 4 periodic + 4 blessings = 25).
      final ids = zoned.map((c) => (c.arguments as Map)['id']).toSet();
      expect(
          ids,
          containsAll([
            100, 101, 102, 103, 104, // prayers
            10, 11, // morning/evening azkar
            200, 201, 202, 203, 204, // pre-adhan
            300, 301, 302, 303, 304, // quran
            20, 21, 22, 23, // periodic
            400, 401, 402, 403, // blessings
          ]));
      expect(zoned.length, greaterThanOrEqualTo(25));

      // The provider serializes reschedules: cancel/reschedule runs must never
      // overlap, or interleaved cancelAll calls would wipe freshly scheduled
      // notifications (the reported "edited time" notifications bug).
      expect(concurrentCancelCount, 0);
    });

    test(
        'location failure no longer cancels location-independent notifications',
        () async {
      // No coordinates stored and no geolocation available: the
      // location-dependent schedulers (prayers, day/night, pre-adhan, quran)
      // fail, but periodic azkar and prophet blessings must STILL be scheduled
      // — previously the first error short-circuited the remaining `error ??=`
      // chains after cancelAll, wiping every reminder.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      final service = await _service(prefs);
      final notify = NotificationProvider(
        notificationService: service,
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      scheduled.clear();

      final error = await notify.applyNotificationStates();

      expect(error, isNotNull); // location error is surfaced to the caller
      final ids = scheduled
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => (c.arguments as Map)['id'])
          .toSet();
      // Location-independent categories must not be dropped by the failure.
      expect(ids, containsAll([20, 21, 22, 23])); // periodic azkar
      expect(ids, containsAll([400, 401, 402, 403])); // prophet blessings
    });
  });

  test('falls back to an inexact alarm when exact alarms are denied', () async {
    SharedPreferences.setMockInitialValues(
      _cairoPrefs(overrides: {PrefsKeys.eveningAzkarTime: '18:30'}),
    );
    final prefs = await SharedPreferences.getInstance();
    await resetTz();
    denyExactAlarms = true;
    addTearDown(() => denyExactAlarms = false);
    scheduled.clear();

    final service = await _service(prefs);
    final error = await service.scheduleDayNightNotifications(30.0444, 31.2357);

    // The denial must be handled internally (falls back to an inexact
    // alarm) — never surfaced to the caller as a failure.
    expect(error, isNull);
    expect(denyExactAlarms, isTrue);

    final evening = scheduled
        .where((c) =>
            c.method == 'zonedSchedule' && (c.arguments as Map)['id'] == 11)
        .toList();
    // First attempt with an exact alarm is rejected, then retried inexactly.
    expect(evening.length, 2);
    final firstMode =
        (evening.first.arguments as Map)['platformSpecifics'] as Map;
    final secondMode =
        (evening.last.arguments as Map)['platformSpecifics'] as Map;
    expect(firstMode['scheduleMode'], 'exactAllowWhileIdle');
    expect(secondMode['scheduleMode'], 'inexactAllowWhileIdle');
    // The custom evening-azkar time ("HH:mm" on the device clock) must be
    // honored: the device is mocked as UTC here, so it fires at 18:30 UTC.
    final firstIso =
        (evening.first.arguments as Map)['scheduledDateTimeISO8601'] as String;
    expect(firstIso.substring(11, 16), '18:30');
  });

  test(
      'cold start with GPS but no stored timezone computes in the device '
      'timezone, not the still-UTC tz.local', () async {
    // Fresh install: coordinates were planted by the location-permission
    // flow, but no city, no timezone and no calculated times exist, while
    // the global tz.local is still UTC (cold start) and the true device
    // timezone is Cairo (+03:00).
    SharedPreferences.setMockInitialValues({
      PrefsKeys.latitude: 30.0,
      PrefsKeys.longitude: 31.2,
      PrefsKeys.prayerTimeDate: '',
    });
    final prefs = await SharedPreferences.getInstance();
    tzDeviceIana = 'Africa/Cairo';
    addTearDown(() => tzDeviceIana = 'Etc/UTC');

    PrayerTimesProvider(
      prayerTimeService: PrayerTimeService(),
      sharedPreferences: prefs,
    );
    // The constructor kicks off loadPrayerTimes() in the background.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The device timezone must be resolved and persisted for GPS mode.
    expect(prefs.getString(PrefsKeys.cityTimezone), 'Africa/Cairo');

    final storedFajr = prefs.getString('${PrefsKeys.prayerTimePrefix}fajr');
    expect(storedFajr, isNotNull);

    // Expected: fajr wall-clock in Cairo for these coordinates today.
    final expected =
        PrayerTimeService().getTimes(30.0, 31.2, timezone: 'Africa/Cairo');
    final cairoFajr = tz.TZDateTime.from(
        expected.fajr.toUtc(), tz.getLocation('Africa/Cairo'));
    expect(storedFajr, '${cairoFajr.hour}:${cairoFajr.minute}');

    // Regression: it must NOT be the UTC wall clock (the cold-start bug
    // where the first calculation fell back to the still-UTC tz.local).
    final utcFajr =
        tz.TZDateTime.from(expected.fajr.toUtc(), tz.getLocation('Etc/UTC'));
    expect(storedFajr, isNot('${utcFajr.hour}:${utcFajr.minute}'));
  });

  group('time picker keyboard crash', () {
    // The provider's reschedule chain runs on real-async timers (the mock
    // cancelAll delays 40ms). pumpAndSettle stops once no frame is scheduled,
    // which can leave that chain mid-flight — pumping a sweep of fake time
    // guarantees every pending timer fires so `scheduled` is stable.
    Future<void> drainReschedule(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> pumpSettingsPage(
        WidgetTester tester, SharedPreferences prefs) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final service = await _service(prefs);
      final notify = NotificationProvider(
        notificationService: service,
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      final prayerTimes = PrayerTimesProvider(
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            ScreenUtil.init(context);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                supportedLocales: const [Locale('ar', 'EG')],
                locale: const Locale('ar', 'EG'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: AppPalette.lightTheme,
                home: MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: prayerTimes),
                    ChangeNotifierProvider.value(value: notify),
                  ],
                  child: const PrayerTimesSettingsScreen(),
                ),
              ),
            );
          },
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();
      await drainReschedule(tester);
    }

    testWidgets('stepper time picker shows Arabic digits and increments',
        (tester) async {
      SharedPreferences.setMockInitialValues(_cairoPrefs());
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      await pumpSettingsPage(tester, prefs);

      // Tap the Fajr tile to open the stepper time picker.
      await tester.tap(find.text('الفجر'));
      await tester.pumpAndSettle();

      // Lock in the picker UX: stepper buttons (no TextField), AM/PM toggle
      // and Arabic-Indic digits rendered in the hour/minute labels.
      expect(find.byType(TextField), findsNothing,
          reason: 'stepper time picker uses + / - buttons, not text fields');
      expect(find.byIcon(Icons.add), findsWidgets,
          reason: 'should show the add stepper button');
      expect(find.byIcon(Icons.remove), findsWidgets,
          reason: 'should show the remove stepper button');
      expect(find.text('ص'), findsOneWidget, reason: 'should show AM toggle');
      expect(find.text('م'), findsOneWidget, reason: 'should show PM toggle');

      // The displayed hour/minute values must be Arabic-Indic digits.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      final arabicDigits = texts.where((t) => RegExp(r'[٠-٩]').hasMatch(t));
      expect(arabicDigits, isNotEmpty,
          reason: 'stepper values should render Arabic-Indic digits');

      expect(tester.takeException(), isNull);
    });

    testWidgets('stepper time picker increments and persists selection',
        (tester) async {
      SharedPreferences.setMockInitialValues(_cairoPrefs());
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      await pumpSettingsPage(tester, prefs);

      // العصر row is below the fold; scroll the settings list until visible.
      await tester.scrollUntilVisible(find.text('العصر'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('العصر'));
      await tester.pumpAndSettle();

      // The stepper sheet has two "adjuster" rows (hour, minute) each with a
      // disabled-look value label; the topmost + is for hours, and the next +
      // for minutes. Tap the hour + once.
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsNWidgets(2),
          reason: 'one add button for hours and one for minutes');
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('editing an azkar time reschedules morning azkar',
        (tester) async {
      SharedPreferences.setMockInitialValues(_cairoPrefs());
      final prefs = await SharedPreferences.getInstance();
      await resetTz();
      await pumpSettingsPage(tester, prefs);
      scheduled.clear();

      // Tap the morning azkar row (top of the list, no scrolling needed).
      await tester.tap(find.text('أذكار الصباح'));
      await tester.pumpAndSettle();

      // Bump the minute value up by one using the minute add button.
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsNWidgets(2),
          reason: 'hour add + minute add buttons');
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      // Commit the edit via the sheet's save button.
      await tester.tap(find.text('حفظ التعديل'));
      await tester.pumpAndSettle();

      // Drain the reschedule triggered by the commit so the final scheduled
      // state is stable before asserting.
      await drainReschedule(tester);

      expect(tester.takeException(), isNull);
      final stored = prefs.getString(PrefsKeys.morningAzkarTime);
      expect(stored, isNotNull, reason: 'the custom azkar time should be set');

      // Exactly one full reschedule ran (25 notifications), with morning azkar
      // scheduled at the picked (stored) time.
      final zoned =
          scheduled.where((c) => c.method == 'zonedSchedule').toList();
      final morning =
          zoned.singleWhere((c) => (c.arguments as Map)['id'] == 10);
      final args = morning.arguments as Map;
      final iso = args['scheduledDateTimeISO8601'] as String;
      // The scheduled wall-clock time must equal the stored custom time.
      expect('$stored:00', iso.substring(11, 19),
          reason: 'morning azkar must be scheduled at the picked time');
    });
  });
}
