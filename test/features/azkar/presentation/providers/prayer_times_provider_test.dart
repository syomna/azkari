import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  const tzChannel = MethodChannel('flutter_timezone');
  final service = PrayerTimeService();

  // What the flutter_timezone plugin reports as the device timezone.
  String deviceTimezone = 'America/Los_Angeles';

  setUp(() {
    deviceTimezone = 'America/Los_Angeles';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tzChannel, (call) async {
      if (call.method == 'getLocalTimezone') return deviceTimezone;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tzChannel, null);
  });

  /// "Today" on the calendar that time zone is on right now — the same
  /// calendar [PrayerTimesProvider] stamps the stored times with, so the
  /// seeded `prayerTimeDate` always matches what the provider computes
  /// independently of which wall-clock date the test machine is on.
  String todayIn(String timezone) => tz.TZDateTime.now(tz.getLocation(timezone))
      .toIso8601String()
      .substring(0, 10);

  /// Emulates the emulator/phone that reported the bug: coordinates pinned by
  /// an earlier GPS fix, display timezone stored separately.
  const gpsLat = 37.4219983;
  const gpsLng = -122.084;

  DateTime fieldOf(PrayerTimes times, String key) => switch (key) {
        'fajr' => times.fajr,
        'sunrise' => times.sunrise,
        'dhuhr' => times.dhuhr,
        'asr' => times.asr,
        'maghrib' => times.maghrib,
        'isha' => times.isha,
        _ => throw ArgumentError(key),
      };

  /// The `H:mm` string [PrayerTimeService.calculateAndStore] would write for
  /// the given coordinates/timezone, recomputed independently of the provider.
  String expectedStored(double lat, double lng, String timezone, String key) {
    final times = service.getTimes(lat, lng, timezone: timezone);
    final wall = tz.TZDateTime.from(
        fieldOf(times, key).toUtc(), service.displayLocation(timezone));
    return '${wall.hour}:${wall.minute}';
  }

  Future<PrayerTimesProvider> construct(
      Map<String, Object> initialValues) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    final provider = PrayerTimesProvider(
      prayerTimeService: service,
      sharedPreferences: prefs,
    );
    // The constructor kicks off an unawaited load; wait for it to land.
    for (var i = 0; i < 100 && provider.prayerTimes == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(provider.prayerTimes, isNotNull,
        reason: 'constructor-triggered load never finished');
    return provider;
  }

  group('automatic location keeps the display timezone on the device one', () {
    test('a device timezone change recomputes today\'s stored times', () async {
      final provider = await construct({
        // GPS mode: no `city_name`, so the device is the reference.
        PrefsKeys.latitude: gpsLat,
        PrefsKeys.longitude: gpsLng,
        PrefsKeys.cityTimezone: 'America/Los_Angeles',
        PrefsKeys.prayerTimeDate: todayIn('America/Los_Angeles'),
      });
      final prefs = provider.sharedPreferences;

      expect(prefs.getString(PrefsKeys.cityTimezone), 'America/Los_Angeles');
      final before = prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr');
      expect(before,
          expectedStored(gpsLat, gpsLng, 'America/Los_Angeles', 'dhuhr'));

      // The system timezone moves (travel, DST, settings) while the day is
      // still today, so the stale-date check alone would never recompute.
      deviceTimezone = 'Africa/Cairo';

      final changed = await provider.refreshIfStale();

      expect(changed, isTrue,
          reason: 'a timezone change must be treated as a real change');
      expect(prefs.getString(PrefsKeys.cityTimezone), 'Africa/Cairo');
      final after = prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr');
      expect(after, expectedStored(gpsLat, gpsLng, 'Africa/Cairo', 'dhuhr'));
      expect(after, isNot(before),
          reason: 'times must move with the timezone, not stay stale');
      expect(
          prefs.getString(PrefsKeys.prayerTimeDate), todayIn('Africa/Cairo'));
    });

    test('unchanged timezone keeps the periodic recheck a no-op', () async {
      final provider = await construct({
        PrefsKeys.latitude: gpsLat,
        PrefsKeys.longitude: gpsLng,
        PrefsKeys.cityTimezone: 'America/Los_Angeles',
        PrefsKeys.prayerTimeDate: todayIn('America/Los_Angeles'),
      });
      final prefs = provider.sharedPreferences;
      final dhuhr = prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr');

      // The day-change timer calls this every minute; nothing moved.
      final changed = await provider.refreshIfStale();

      expect(changed, isFalse);
      expect(prefs.getString(PrefsKeys.cityTimezone), 'America/Los_Angeles');
      expect(prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr'), dhuhr);
    });

    test('a missing stored timezone is resolved from the device', () async {
      // Store written before the device timezone was ever resolved.
      final provider = await construct({
        PrefsKeys.latitude: gpsLat,
        PrefsKeys.longitude: gpsLng,
        PrefsKeys.prayerTimeDate: todayIn('America/Los_Angeles'),
      });
      final prefs = provider.sharedPreferences;

      expect(prefs.getString(PrefsKeys.cityTimezone), 'America/Los_Angeles');
      expect(prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr'),
          expectedStored(gpsLat, gpsLng, 'America/Los_Angeles', 'dhuhr'));
    });
  });

  group('a selected city keeps its own timezone', () {
    test('a device timezone change never touches the city\'s times', () async {
      final cairo = appCities.singleWhere((c) => c.name == 'القاهرة');
      final provider = await construct({
        PrefsKeys.cityName: cairo.name,
        PrefsKeys.cityTimezone: cairo.timezone,
        PrefsKeys.latitude: cairo.latitude,
        PrefsKeys.longitude: cairo.longitude,
        PrefsKeys.prayerTimeDate: todayIn(cairo.timezone),
      });
      final prefs = provider.sharedPreferences;

      expect(prefs.getString(PrefsKeys.cityTimezone), 'Africa/Cairo');
      expect(
          prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr'),
          expectedStored(
              cairo.latitude, cairo.longitude, cairo.timezone, 'dhuhr'));

      deviceTimezone = 'Asia/Tokyo';

      final changed = await provider.refreshIfStale();

      expect(changed, isFalse);
      expect(prefs.getString(PrefsKeys.cityTimezone), 'Africa/Cairo');
      expect(
          prefs.getString('${PrefsKeys.prayerTimePrefix}dhuhr'),
          expectedStored(
              cairo.latitude, cairo.longitude, cairo.timezone, 'dhuhr'));
    });
  });
}
