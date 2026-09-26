import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  final service = PrayerTimeService();

  setUpAll(tzdata.initializeTimeZones);

  /// adhan_dart computes times as UTC instants; the city-local wall clock is
  /// obtained by converting into the city's timezone (same as the app does).
  tz.TZDateTime cityLocal(DateTime utc, String iana) =>
      tz.TZDateTime.from(utc.toUtc(), tz.getLocation(iana));

  test('all world cities produce correctly ordered prayer times', () {
    for (final city in appCities) {
      final t = service.getTimes(city.latitude, city.longitude,
          method: city.method, timezone: city.timezone);
      expect(
        t.fajr.isBefore(t.sunrise) &&
            t.sunrise.isBefore(t.dhuhr) &&
            t.dhuhr.isBefore(t.asr) &&
            t.asr.isBefore(t.maghrib) &&
            t.maghrib.isBefore(t.isha),
        isTrue,
        reason: '${city.name} (${city.country}) times out of order',
      );
    }
  });

  test('Tokyo timezone is UTC+9 regardless of device timezone', () {
    final tokyo = appCities.firstWhere((c) => c.name == 'طوكيو');
    final t = service.getTimes(tokyo.latitude, tokyo.longitude,
        method: tokyo.method, timezone: tokyo.timezone);
    // Fajr on an Aug 2026 date in Tokyo is ~03:40 local; Dhuhr ~11:43.
    final fajr = cityLocal(t.fajr, tokyo.timezone);
    final dhuhr = cityLocal(t.dhuhr, tokyo.timezone);
    final maghrib = cityLocal(t.maghrib, tokyo.timezone);
    expect(fajr.hour, inInclusiveRange(3, 5));
    expect(dhuhr.hour, inInclusiveRange(11, 13));
    expect(maghrib.hour, inInclusiveRange(17, 19));
  });

  test('Cairo egyptian-method Fajr is early morning (3-5h)', () {
    final cairo = appCities.firstWhere((c) => c.name == 'القاهرة');
    final t = service.getTimes(cairo.latitude, cairo.longitude,
        method: cairo.method, timezone: cairo.timezone);
    final fajr = cityLocal(t.fajr, cairo.timezone);
    expect(fajr.hour, inInclusiveRange(3, 5));
  });
}