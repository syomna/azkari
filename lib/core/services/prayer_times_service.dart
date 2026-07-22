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

  Future<Position?>? _ongoingLocationFetch;

  Future<Position?> getCurrentLocation() async {
    return _ongoingLocationFetch ??= _fetchLocation();
  }

  Future<Position?> _fetchLocation() async {
    try {
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

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      return null;
    } finally {
      _ongoingLocationFetch = null;
    }
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
      final raw = prefs.getString('$_overridePrefix$key') ??
          prefs.getString('$_timePrefix$key');
      if (raw != null) {
        result[key] = _parseTimeOfDay(raw);
      }
    }
    return result;
  }

  TimeOfDay _parseTimeOfDay(String raw) {
    try {
      final parts = raw.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: parts.length > 1 ? int.parse(parts[1]) : 0,
      );
    } catch (_) {
      return TimeOfDay.now();
    }
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