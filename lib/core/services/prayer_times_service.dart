import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/models/city.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
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
  static const selectedCityIdKey = 'selected_city_id';
  static const _selectedCityNameKey = 'selected_city_name';
  static const _selectedCityArabicNameKey = 'selected_city_arabic_name';
  static const _latKey = 'lat';
  static const _lngKey = 'lng';
  static final prayerKeys = AppHelpers.prayerNames.keys.toList();

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
    return PrayerTimes(
        coordinates, DateComponents.from(DateTime.now()), params);
  }

  Future<void> calculateAndStore(
      double lat, double lng, SharedPreferences prefs) async {
    final times = getTimes(lat, lng);
    final map = _prayerTimesToMap(times);
    for (final key in prayerKeys) {
      final dt = map[key]!;
      prefs.setString('$_timePrefix$key', '${dt.hour}:${dt.minute}');
    }
  }

  Map<String, DateTime> _prayerTimesToMap(PrayerTimes times) => {
        'fajr': times.fajr,
        'sunrise': times.sunrise,
        'dhuhr': times.dhuhr,
        'asr': times.asr,
        'maghrib': times.maghrib,
        'isha': times.isha,
      };

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

  Future<(double lat, double lng)?> resolveLocation(
      SharedPreferences prefs) async {
    if (prefs.getString(selectedCityIdKey) != null) {
      final lat = prefs.getDouble(_latKey);
      final lng = prefs.getDouble(_lngKey);
      if (lat != null && lng != null) return (lat, lng);
    }

    double? lat = prefs.getDouble(_latKey);
    double? lng = prefs.getDouble(_lngKey);
    final cachedAt = prefs.getInt('location_cached_at');
    final isStale = cachedAt == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cachedAt))
                .inHours >
            24;

    if (lat == null || lng == null || isStale) {
      final position = await getCurrentLocation();
      lat = position?.latitude;
      lng = position?.longitude;
      if (lat != null && lng != null) {
        await prefs.setDouble(_latKey, lat);
        await prefs.setDouble(_lngKey, lng);
        await prefs.setInt(
            'location_cached_at', DateTime.now().millisecondsSinceEpoch);
      }
    }

    if (lat != null && lng != null) return (lat, lng);
    return null;
  }

  bool hasSelectedCity(SharedPreferences prefs) =>
      prefs.getString(selectedCityIdKey) != null;

  String? getSelectedCityDisplayName(SharedPreferences prefs) {
    final arabicName = prefs.getString(_selectedCityArabicNameKey);
    if (arabicName != null && arabicName.isNotEmpty) return arabicName;
    return prefs.getString(_selectedCityNameKey);
  }

  Future<void> saveSelectedCity(City city, SharedPreferences prefs) async {
    await prefs.setString(selectedCityIdKey, '${city.id}');
    await prefs.setString(_selectedCityNameKey, city.name);
    await prefs.setString(_selectedCityArabicNameKey, city.arabicName);
    await prefs.setDouble(_latKey, city.lat);
    await prefs.setDouble(_lngKey, city.lng);
    await prefs.setInt(
        'location_cached_at', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> storeCurrentLocation(
      Position position, SharedPreferences prefs) async {
    await prefs.setDouble(_latKey, position.latitude);
    await prefs.setDouble(_lngKey, position.longitude);
    await prefs.setInt(
        'location_cached_at', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearSelectedCity(SharedPreferences prefs) async {
    await prefs.remove(selectedCityIdKey);
    await prefs.remove(_selectedCityNameKey);
    await prefs.remove(_selectedCityArabicNameKey);
    await prefs.remove(_latKey);
    await prefs.remove(_lngKey);
    await prefs.remove('location_cached_at');
  }
}
