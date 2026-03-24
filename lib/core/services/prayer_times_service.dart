import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimeService {
  static final PrayerTimeService _prayerTimeService =
      PrayerTimeService._internal();
  factory PrayerTimeService() => _prayerTimeService;
  PrayerTimeService._internal();

  static const _timePrefix = 'prayer_time_';
  static const _overridePrefix = 'prayer_override_';
  static const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        return null;
      }
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  PrayerTimes getTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes(coordinates, DateComponents.from(DateTime.now()), params);
  }

  /// Calculate from package and persist calculated times to prefs.
  /// Call once on app start or when location changes.
  Future<void> calculateAndStore(double lat, double lng, SharedPreferences prefs) async {
    final times = getTimes(lat, lng);
    final map = _prayerTimesToMap(times);
    for (final key in prayerKeys) {
      final dt = map[key]!;
      prefs.setString('$_timePrefix$key', '${dt.hour}:${dt.minute}');
    }
  }

  Map<String, DateTime> _prayerTimesToMap(PrayerTimes times) => {
    'fajr':    times.fajr,
    'sunrise': times.sunrise,
    'dhuhr':   times.dhuhr,
    'asr':     times.asr,
    'maghrib': times.maghrib,
    'isha':    times.isha,
  };

  /// Returns the effective TimeOfDay for each prayer.
  /// Override wins over calculated; falls back to calculated if no override.
  Map<String, TimeOfDay> getEffectiveTimes(SharedPreferences prefs) {
    final result = <String, TimeOfDay>{};
    for (final key in prayerKeys) {
      // Check override first
      final override = prefs.getString('$_overridePrefix$key');
      if (override != null) {
        final parts = override.split(':');
        result[key] = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        continue;
      }
      // Fall back to calculated
      final calculated = prefs.getString('$_timePrefix$key');
      if (calculated != null) {
        final parts = calculated.split(':');
        result[key] = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    return result;
  }

  void saveOverride(String key, TimeOfDay time, SharedPreferences prefs) {
    prefs.setString('$_overridePrefix$key', '${time.hour}:${time.minute}');
  }

  void clearOverride(String key, SharedPreferences prefs) {
    prefs.remove('$_overridePrefix$key');
  }

  void clearAllOverrides(SharedPreferences prefs) {
    for (final key in prayerKeys) {
      prefs.remove('$_overridePrefix$key');
    }
  }

  bool hasOverride(String key, SharedPreferences prefs) {
    return prefs.containsKey('$_overridePrefix$key');
  }

  String getNextPrayerName(PrayerTimes times) => times.nextPrayer().name;
}