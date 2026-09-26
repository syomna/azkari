import 'dart:convert';

import 'package:azkar_app/core/services/prayer_times_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildMultiDayTimes produces 14 sequential, fully populated days',
      () async {
    SharedPreferences.setMockInitialValues({
      'lat': 30.0444,
      'lng': 31.2357,
      'city_name': 'القاهرة',
      'city_timezone': 'Africa/Cairo',
    });
    final prefs = await SharedPreferences.getInstance();

    final map = PrayerTimesWidgetService.buildMultiDayTimes(prefs: prefs);

    expect(map.length, PrayerTimesWidgetService.widgetDays);
    final keys = map.keys.toList();
    final first = DateTime.parse(keys.first);
    for (var i = 0; i < keys.length; i++) {
      final d = DateTime.parse(keys[i]);
      expect(d.difference(first).inDays, i, reason: 'days must be sequential');
      final day = map[keys[i]]!;
      for (final prayer in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final raw = day[prayer]!;
        expect(
          RegExp(r'^\d{1,2}:\d{2} (ص|م)$').hasMatch(raw),
          isTrue,
          reason: '$prayer = "$raw" should be a 12-hour Arabic time',
        );
      }
      expect(day['hijri'], isNotEmpty);
      expect(day['gregorian'], isNotEmpty);
    }

    // Snapshot must round-trip through JSON (that is how the widget reads it).
    expect(jsonDecode(jsonEncode(map)), map);
  });

  test('manual override wins over the calculated time in every snapshot day',
      () async {
    SharedPreferences.setMockInitialValues({
      'lat': 30.0444,
      'lng': 31.2357,
      'city_name': 'القاهرة',
      'prayer_override_fajr': '3:00',
    });
    final prefs = await SharedPreferences.getInstance();

    final map = PrayerTimesWidgetService.buildMultiDayTimes(prefs: prefs);

    for (final day in map.values) {
      expect(day['fajr'], '3:00 ص');
    }
  });

  test('returns empty map when no location is available', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(PrayerTimesWidgetService.buildMultiDayTimes(prefs: prefs), isEmpty);
  });
}