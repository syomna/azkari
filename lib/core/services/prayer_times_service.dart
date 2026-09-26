import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class PrayerTimeService {
  static final PrayerTimeService _prayerTimeService =
      PrayerTimeService._internal();
  factory PrayerTimeService() => _prayerTimeService;
  PrayerTimeService._internal();

  static const _timePrefix = PrefsKeys.prayerTimePrefix;
  static const _overridePrefix = PrefsKeys.prayerOverridePrefix;
  static const prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha'
  ];

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

  PrayerTimes getTimes(double lat, double lng,
      {CalculationMethod? method, String? timezone, tz.TZDateTime? date}) {
    final coordinates = Coordinates(lat, lng);
    final params = _paramsForMethod(method ?? methodForCoordinates(lat, lng));
    params.madhab = Madhab.shafi;
    // The calculation day must be "today" in the target display timezone so
    // prayer times (especially dawn/dusk) resolve to the correct calendar day.
    // adhan_dart returns UTC DateTimes; consumers convert via [_displayLocation].
    final location = _displayLocation(timezone);
    final today = date ?? tz.TZDateTime.now(location);
    return PrayerTimes(
      coordinates: coordinates,
      date: today,
      calculationParameters: params,
      precision: false,
    );
  }

  /// The [tz.Location] prayer times are displayed in; exposed for callers that
  /// build calendar dates themselves (e.g. the widget's multi-day snapshot).
  tz.Location displayLocation(String? timezone) => _displayLocation(timezone);

  /// Wall-clock times, in the display timezone, for the given calendar [date].
  /// Used to precompute the widget's rolling multi-day data without relying on
  /// today's stored values.
  Map<String, DateTime> dailyTimes(double lat, double lng, tz.TZDateTime date,
      {CalculationMethod? method, String? timezone}) {
    final times =
        getTimes(lat, lng, method: method, timezone: timezone, date: date);
    return _prayerTimesToMap(times, timezone);
  }

  static bool _tzInitialized = false;

  void _ensureTzData() {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  /// The device's IANA timezone name (e.g. "Africa/Cairo"), or `null` if it
  /// can't be resolved. Auto-location prayer times must be computed in this
  /// timezone explicitly — relying on the global `tz.local` is unsafe because
  /// it is still UTC at cold start until something else sets it.
  Future<String?> getDeviceTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      return null;
    }
  }

  /// The [tz.Location] prayer times are displayed in: the fixed city's IANA
  /// timezone when given, otherwise the device timezone. Falls back to the
  /// device timezone when the city timezone is not present in the bundled
  /// `timezone` data.
  tz.Location _displayLocation(String? timezone) {
    _ensureTzData();
    if (timezone != null) {
      try {
        return tz.getLocation(timezone);
      } catch (_) {
        // Not in the bundled DB subset -> fall through to device timezone.
      }
    }
    return tz.local;
  }

  /// Maps a [CalculationMethod] onto its pre-populated parameters. adhan_dart
  /// exposes one static factory per method (there is no `.getParameters()`).
  CalculationParameters _paramsForMethod(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.algerian:
        return CalculationMethodParameters.algerian();
      case CalculationMethod.dubai:
        return CalculationMethodParameters.dubai();
      case CalculationMethod.egyptian:
        return CalculationMethodParameters.egyptian();
      case CalculationMethod.france:
        return CalculationMethodParameters.france();
      case CalculationMethod.gulfRegion:
        return CalculationMethodParameters.gulfRegion();
      case CalculationMethod.indonesian:
        return CalculationMethodParameters.indonesian();
      case CalculationMethod.jafari:
        return CalculationMethodParameters.jafari();
      case CalculationMethod.jordan:
        return CalculationMethodParameters.jordan();
      case CalculationMethod.karachi:
        return CalculationMethodParameters.karachi();
      case CalculationMethod.kuwait:
        return CalculationMethodParameters.kuwait();
      case CalculationMethod.moonsightingCommittee:
        return CalculationMethodParameters.moonsightingCommittee();
      case CalculationMethod.morocco:
        return CalculationMethodParameters.morocco();
      case CalculationMethod.muslimWorldLeague:
        return CalculationMethodParameters.muslimWorldLeague();
      case CalculationMethod.northAmerica:
        return CalculationMethodParameters.northAmerica();
      case CalculationMethod.other:
        return CalculationMethodParameters.other();
      case CalculationMethod.portugal:
        return CalculationMethodParameters.portugal();
      case CalculationMethod.qatar:
        return CalculationMethodParameters.qatar();
      case CalculationMethod.russia:
        return CalculationMethodParameters.russia();
      case CalculationMethod.singapore:
        return CalculationMethodParameters.singapore();
      case CalculationMethod.tehran:
        return CalculationMethodParameters.tehran();
      case CalculationMethod.tunisia:
        return CalculationMethodParameters.tunisia();
      case CalculationMethod.turkiye:
        return CalculationMethodParameters.turkiye();
      case CalculationMethod.ummAlQura:
        return CalculationMethodParameters.ummAlQura();
    }
  }

  /// Picks a sensible [CalculationMethod] for a GPS/automatic location based on
  /// broad lat/lng ranges. Explicit cities carry their own method, so this is
  /// only used when the user relies on automatic location.
  CalculationMethod methodForCoordinates(double lat, double lng) {
    // Egypt & immediate surroundings
    if (lat >= 22 && lat <= 31.5 && lng >= 25 && lng <= 36) {
      return CalculationMethod.egyptian;
    }
    // Turkey
    if (lat >= 35.5 && lat <= 42.5 && lng >= 26 && lng <= 45) {
      return CalculationMethod.turkiye;
    }
    // Iran
    if (lat >= 25 && lat <= 40 && lng >= 44 && lng <= 63) {
      return CalculationMethod.tehran;
    }
    // Arabian peninsula & Gulf
    if (lat >= 12 && lat <= 32 && lng >= 34 && lng <= 60) {
      if (lng >= 47 && lng <= 49.7) return CalculationMethod.kuwait;
      if (lng >= 50.5 && lng <= 51.7) return CalculationMethod.qatar;
      return CalculationMethod.ummAlQura;
    }
    // Pakistan / India / Bangladesh / Afghanistan
    if (lat >= 5 && lat <= 38 && lng >= 61 && lng <= 96) {
      return CalculationMethod.karachi;
    }
    // South-East Asia
    if (lat >= -12 && lat <= 8 && lng >= 95 && lng <= 145) {
      return CalculationMethod.singapore;
    }
    // Americas (negative longitudes)
    if (lng < -25) return CalculationMethod.northAmerica;
    return CalculationMethod.muslimWorldLeague;
  }

  /// Calculate from package and persist calculated times to prefs.
  /// Call once on app start or when location changes.
  Future<void> calculateAndStore(
      double lat, double lng, SharedPreferences prefs,
      {CalculationMethod? method, String? timezone}) async {
    final times = getTimes(lat, lng, method: method, timezone: timezone);
    final map = _prayerTimesToMap(times, timezone);
    for (final key in prayerKeys) {
      final dt = map[key]!;
      prefs.setString('$_timePrefix$key', '${dt.hour}:${dt.minute}');
    }
  }

  /// Converts adhan_dart's UTC results into the display timezone's wall clock,
  /// keeping stored times (and thus every downstream consumer) city-local.
  Map<String, DateTime> _prayerTimesToMap(PrayerTimes times, String? timezone) {
    final loc = _displayLocation(timezone);
    DateTime inDisplayTz(DateTime utc) => tz.TZDateTime.from(utc.toUtc(), loc);
    return {
      'fajr': inDisplayTz(times.fajr),
      'sunrise': inDisplayTz(times.sunrise),
      'dhuhr': inDisplayTz(times.dhuhr),
      'asr': inDisplayTz(times.asr),
      'maghrib': inDisplayTz(times.maghrib),
      'isha': inDisplayTz(times.isha),
    };
  }

  /// Returns the effective TimeOfDay for each prayer.
  /// Override wins over calculated; falls back to calculated if no override.
  Map<String, TimeOfDay> getEffectiveTimes(SharedPreferences prefs) {
    final result = <String, TimeOfDay>{};
    for (final key in prayerKeys) {
      final raw = prefs.getString('$_overridePrefix$key') ??
          prefs.getString('$_timePrefix$key');
      if (raw != null) {
        final parsed = _parseTimeOfDay(raw);
        if (parsed != null) {
          result[key] = parsed;
        }
      }
    }
    return result;
  }

  /// Parses a stored "h:mm" override. Out-of-range (e.g. corrupted/legacy
  /// "25:99") or unparsable values return null so we never feed a bogus
  /// TimeOfDay into the prayer rows or notification scheduler.
  TimeOfDay? _parseTimeOfDay(String raw) {
    try {
      final parts = raw.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
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
