import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Verifies the core promise of prayer notifications: whatever source set the
/// times — a picked city, automatic/GPS location, or a manual user override —
/// the scheduled local notification must fire at exactly the prayer time the
/// app displays for that source (the same `getEffectiveTimes` the home screen
/// rows use). The real flutter_local_notifications plugin is replaced with a
/// recording method-channel mock (proven pattern in settings_repro_test.dart),
/// so the assertions read the exact grid slots the OS would receive.

const _notifChannel = 'dexterous.com/flutter/local_notifications';
const _tzChannel = 'flutter_timezone';

final _zoned = <MethodCall>[];
var _tzDeviceIana = 'Etc/UTC';

void _mockChannels() {
  _zoned.clear();
  _tzDeviceIana = 'Etc/UTC';
  fln.FlutterLocalNotificationsPlatform.instance =
      fln.AndroidFlutterLocalNotificationsPlugin();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(_notifChannel),
          (call) async {
    if (call.method == 'zonedSchedule') _zoned.add(call);
    if (call.method == 'requestNotificationsPermission') return true;
    if (call.method == 'requestExactAlarmsPermission') return true;
    if (call.method == 'pendingNotificationRequests') return <Map>[];
    return true;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel(_tzChannel), (call) async => _tzDeviceIana);
}

/// Every notification slot the app can queue, keyed by its persistent id.
const _notificationIds = {
  'prayer_fajr': 100,
  'prayer_dhuhr': 101,
  'prayer_asr': 102,
  'prayer_maghrib': 103,
  'prayer_isha': 104,
  'azkar_morning': 10,
  'azkar_evening': 11,
  'preadhan_fajr': 200,
  'preadhan_dhuhr': 201,
  'preadhan_asr': 202,
  'preadhan_maghrib': 203,
  'preadhan_isha': 204,
  'quran_fajr': 300,
  'quran_dhuhr': 301,
  'quran_asr': 302,
  'quran_maghrib': 303,
  'quran_isha': 304,
};

Map<String, Object> _cairoSeed({
  Map<String, Object> overrides = const {},
  bool fixedCity = true,
}) {
  return {
    PrefsKeys.latitude: 30.0444,
    PrefsKeys.longitude: 31.2357,
    if (fixedCity) PrefsKeys.cityName: 'القاهرة',
    PrefsKeys.cityTimezone: 'Africa/Cairo',
    PrefsKeys.prayerTimeDate: '',
    'notificationsEnabled': true,
    // City-local wall-clock times as calculateAndStore would persist them.
    'prayer_time_fajr': '4:50',
    'prayer_time_sunrise': '6:10',
    'prayer_time_dhuhr': '12:0',
    'prayer_time_asr': '15:30',
    'prayer_time_maghrib': '18:10',
    'prayer_time_isha': '19:40',
    ...overrides,
  };
}

Map<String, Object> _dubaiSeed() {
  return {
    PrefsKeys.latitude: 25.2048,
    PrefsKeys.longitude: 55.2708,
    PrefsKeys.cityName: 'دبي',
    PrefsKeys.cityTimezone: 'Asia/Dubai',
    PrefsKeys.prayerTimeDate: '',
    'notificationsEnabled': true,
    'prayer_time_fajr': '4:20',
    'prayer_time_sunrise': '5:55',
    'prayer_time_dhuhr': '12:10',
    'prayer_time_asr': '15:30',
    'prayer_time_maghrib': '18:15',
    'prayer_time_isha': '19:35',
  };
}

Future<NotificationService> _service(SharedPreferences prefs) {
  _zoned.clear();
  NotificationService.resetForTesting();
  return NotificationService.init(
    prefs: prefs,
    prayerService: PrayerTimeService(),
  );
}

Future<void> _resetTz() async => tz.setLocalLocation(tz.getLocation('Etc/UTC'));

MethodCall _zonedById(int id) => _zoned.singleWhere((c) {
      final args = c.arguments as Map;
      return c.method == 'zonedSchedule' && args['id'] == id;
    });

/// The scheduled instant as an absolute [tz.TZDateTime] (viewed in [loc]).
tz.TZDateTime _instant(MethodCall call, tz.Location loc) {
  final iso = (call.arguments as Map)['scheduledDateTimeISO8601'] as String;
  final utc = tz.TZDateTime.parse(tz.getLocation('Etc/UTC'), iso);
  return tz.TZDateTime.from(utc, loc);
}

String _hhmm(tz.TZDateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Asserts a prayer notification fires at the same wall-clock time the home
/// rows show, converted to the device clock. [expectedLocal] is the stored
/// "HH:mm" in the city's timezone [cityTzName].
void _expectPrayerMatches(int id, String expectedLocal, String cityTzName,
    {required String deviceTzName}) {
  final call = _zonedById(id);
  final cityView = _instant(call, tz.getLocation(cityTzName));
  final expectedPadded =
      expectedLocal.length == 4 ? '0$expectedLocal' : expectedLocal;
  expect(
    _hhmm(cityView),
    expectedPadded,
    reason: 'id=$id must fire when display shows $expectedLocal'
        ' ($cityTzName), scheduled in $deviceTzName',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _mockChannels();
  tzdata.initializeTimeZones();

  group('picked city', () {
    test(
        'Cairo city on a UTC device: every prayer fires at its exact '
        'city-local time converted to UTC (Cairo = UTC+3)', () async {
      SharedPreferences.setMockInitialValues(_cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);

      final error = await service.schedulePrayerNotifications();
      expect(error, isNull);

      // 4:50 Cairo == 1:50 UTC, 12:00 -> 09:00, 15:30 -> 12:30,
      // 18:10 -> 15:10, 19:40 -> 16:40.
      _expectPrayerMatches(
          _notificationIds['prayer_fajr']!, '4:50', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_dhuhr']!, '12:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_asr']!, '15:30', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_maghrib']!, '18:10', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_isha']!, '19:40', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');

      // Every scheduled slot also carries the device zone the OS must use.
      final ids = _zoned.map((c) => (c.arguments as Map)['id'] as int).toSet();
      expect(ids, {100, 101, 102, 103, 104});
    });

    test(
        'Dubai city on a Los Angeles device: fired instant matches the '
        'Dubai wall clock even across the city/device date border', () async {
      SharedPreferences.setMockInitialValues(_dubaiSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      _tzDeviceIana = 'America/Los_Angeles';
      addTearDown(() => _tzDeviceIana = 'Etc/UTC');
      final service = await _service(prefs);

      final error = await service.schedulePrayerNotifications();
      expect(error, isNull);

      final la = tz.getLocation('America/Los_Angeles');
      final before = tz.TZDateTime.now(tz.local);

      _expectPrayerMatches(
          _notificationIds['prayer_fajr']!, '4:20', 'Asia/Dubai',
          deviceTzName: 'America/Los_Angeles');
      _expectPrayerMatches(
          _notificationIds['prayer_dhuhr']!, '12:10', 'Asia/Dubai',
          deviceTzName: 'America/Los_Angeles');
      _expectPrayerMatches(
          _notificationIds['prayer_asr']!, '15:30', 'Asia/Dubai',
          deviceTzName: 'America/Los_Angeles');
      _expectPrayerMatches(
          _notificationIds['prayer_maghrib']!, '18:15', 'Asia/Dubai',
          deviceTzName: 'America/Los_Angeles');
      _expectPrayerMatches(
          _notificationIds['prayer_isha']!, '19:35', 'Asia/Dubai',
          deviceTzName: 'America/Los_Angeles');

      // No notification may be scheduled in the past; the next-future
      // occurrence guard must have bumped past-due slots by a day.
      for (final call in _zoned) {
        final t = _instant(call, la);
        expect(t.isBefore(before), isFalse,
            reason: 'id=${(call.arguments as Map)['id']} must be future');
      }
    });
  });

  group('automatic / GPS city', () {
    test(
        'GPS mode (no fixed city): notifications fire at the stored times '
        'which are already in the device timezone', () async {
      SharedPreferences.setMockInitialValues(
        _cairoSeed(fixedCity: false),
      );
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      _tzDeviceIana = 'Africa/Cairo';
      addTearDown(() => _tzDeviceIana = 'Etc/UTC');
      final service = await _service(prefs);

      final error = await service.schedulePrayerNotifications();
      expect(error, isNull);

      // GPS mode = device clock == stored clock, so the wall-clock match is
      // identity — must NOT apply a city offset.
      _expectPrayerMatches(
          _notificationIds['prayer_fajr']!, '4:50', 'Africa/Cairo',
          deviceTzName: 'Africa/Cairo');
      _expectPrayerMatches(
          _notificationIds['prayer_asr']!, '15:30', 'Africa/Cairo',
          deviceTzName: 'Africa/Cairo');
      _expectPrayerMatches(
          _notificationIds['prayer_isha']!, '19:40', 'Africa/Cairo',
          deviceTzName: 'Africa/Cairo');
    });

    test(
        'GPS cold start: production calculator -> stored -> scheduled all '
        'agree, and the device timezone (not UTC) drives the result', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.latitude: 30.0,
        PrefsKeys.longitude: 31.2,
        PrefsKeys.cityTimezone: 'Africa/Cairo',
        PrefsKeys.prayerTimeDate: '',
        'notificationsEnabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      _tzDeviceIana = 'Africa/Cairo';
      addTearDown(() => _tzDeviceIana = 'Etc/UTC');

      await PrayerTimeService()
          .calculateAndStore(30.0, 31.2, prefs, timezone: 'Africa/Cairo');

      final service = await _service(prefs);
      final error = await service.schedulePrayerNotifications();
      expect(error, isNull);

      // The notification must fire at the same wish the stored (City-local)
      // times describe, never at the UTC wall clock that the cold-start
      // `tz.local` would otherwise produce.
      for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final stored = prefs.getString('${PrefsKeys.prayerTimePrefix}$key')!;
        final expected = _hhmm(tz.TZDateTime(
            tz.getLocation('Africa/Cairo'),
            2000,
            1,
            1,
            int.parse(stored.split(':')[0]),
            int.parse(stored.split(':')[1])));
        _expectPrayerMatches(
            _notificationIds['prayer_$key']!, expected, 'Africa/Cairo',
            deviceTzName: 'Africa/Cairo');
      }
    });
  });

  group('manual user input (prayer-time overrides)', () {
    test(
        'overridden rows fire at the user-entered time; untouched rows keep '
        'the calculated time', () async {
      SharedPreferences.setMockInitialValues(
        _cairoSeed(overrides: {
          'prayer_override_fajr': '3:10',
          'prayer_override_asr': '16:30',
          'prayer_override_maghrib': '19:0',
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);

      final error = await service.schedulePrayerNotifications();
      expect(error, isNull);

      _expectPrayerMatches(
          _notificationIds['prayer_fajr']!, '3:10', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_asr']!, '16:30', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['prayer_maghrib']!, '19:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      // Not overridden: still the calculated noon (12:00 Cairo).
      _expectPrayerMatches(
          _notificationIds['prayer_dhuhr']!, '12:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
    });
  });

  group('derived notification times stay tied to the prayer times', () {
    test('pre-adhan = prayer -10m and quran reminder = prayer +30m', () async {
      SharedPreferences.setMockInitialValues(_cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);

      expect(await service.schedulePreAdhanReminders(), isNull);
      // 4:50 Cairo - 10min = 4:40 Cairo.
      _expectPrayerMatches(
          _notificationIds['preadhan_fajr']!, '4:40', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      // 18:10 Cairo - 10min = 18:00 Cairo.
      _expectPrayerMatches(
          _notificationIds['preadhan_maghrib']!, '18:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');

      expect(await service.scheduleQuranReminderAfterSalah(), isNull);
      // 15:30 Cairo + 30 = 16:00 Cairo.
      _expectPrayerMatches(
          _notificationIds['quran_asr']!, '16:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
    });

    test('morning azkar = fajr+30 and evening azkar = asr+30 by default',
        () async {
      SharedPreferences.setMockInitialValues(_cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);

      expect(await service.scheduleDayNightNotifications(30.0444, 31.2357),
          isNull);
      expect(
          await service.scheduleDayNightNotifications(30.0444, 31.2357,
              isDay: true),
          isNull);

      _expectPrayerMatches(
          _notificationIds['azkar_morning']!, '5:20', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
      _expectPrayerMatches(
          _notificationIds['azkar_evening']!, '16:00', 'Africa/Cairo',
          deviceTzName: 'Etc/UTC');
    });

    test('a user-set custom azkar time overrides the prayer-derived default',
        () async {
      SharedPreferences.setMockInitialValues(_cairoSeed(overrides: {
        PrefsKeys.morningAzkarTime: '06:15',
        PrefsKeys.eveningAzkarTime: '18:45',
      }));
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);

      expect(await service.scheduleDayNightNotifications(30.0444, 31.2357),
          isNull);
      expect(
          await service.scheduleDayNightNotifications(30.0444, 31.2357,
              isDay: true),
          isNull);

      // Custom times live on the device clock, so they fire at exactly the
      // wall-clock the user picked.
      final morning = _zonedById(_notificationIds['azkar_morning']!);
      final evening = _zonedById(_notificationIds['azkar_evening']!);
      final morningIso =
          (morning.arguments as Map)['scheduledDateTimeISO8601'] as String;
      final eveningIso =
          (evening.arguments as Map)['scheduledDateTimeISO8601'] as String;
      expect(morningIso.substring(11, 16), '06:15');
      expect(eveningIso.substring(11, 16), '18:45');
    });
  });

  group('switching source reschedules to the new prayer times', () {
    test(
        'picking Dubai recalculates and re-plans every adhan to Dubai '
        'times', () async {
      SharedPreferences.setMockInitialValues(_cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);
      final notify = NotificationProvider(
        notificationService: service,
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      final provider = PrayerTimesProvider(
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      // Let the constructor-triggered reschedule (Cairo plan) settle.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _zoned.clear();

      final dubai = appCities.singleWhere((c) => c.name == 'دبي');
      await provider.setCity(dubai);
      await notify.applyNotificationStates();

      final effective = provider.allDisplayTimes;
      for (final entry in effective.entries) {
        final id = NotificationService.notificationIds['prayer_${entry.key}'];
        if (id == null) continue;
        final expected = '${entry.value.hour.toString().padLeft(2, '0')}:'
            '${entry.value.minute.toString().padLeft(2, '0')}';
        _expectPrayerMatches(id, expected, 'Asia/Dubai',
            deviceTzName: 'Etc/UTC');
      }
      expect(prefs.getString(PrefsKeys.cityName), 'دبي');
    });

    test(
        'editing a prayer time manually re-schedules that prayer to the '
        'new override', () async {
      SharedPreferences.setMockInitialValues(_cairoSeed());
      final prefs = await SharedPreferences.getInstance();
      await _resetTz();
      final service = await _service(prefs);
      final notify = NotificationProvider(
        notificationService: service,
        prayerTimeService: PrayerTimeService(),
        sharedPreferences: prefs,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _zoned.clear();

      PrayerTimeService()
          .saveOverride('fajr', const TimeOfDay(hour: 2, minute: 0), prefs);
      await notify.applyNotificationStates();

      final fajr = _zonedById(_notificationIds['prayer_fajr']!);
      final iso = (fajr.arguments as Map)['scheduledDateTimeISO8601'] as String;
      // 02:00 Cairo == 23:00 UTC, so the fired instant must read 23:00 UTC.
      expect(iso.substring(11, 16), '23:00');
    });
  });
}
