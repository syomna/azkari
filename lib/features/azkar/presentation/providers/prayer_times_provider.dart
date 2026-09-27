import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/services/prayer_times_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles prayer times + manual time overrides for a user's location.
///
/// Kept separate from [AzkarProvider] so prayer-time concerns don't weigh down
/// the azkar feature provider.
class PrayerTimesProvider extends ChangeNotifier {
  final PrayerTimeService prayerTimeService;
  final SharedPreferences sharedPreferences;

  PrayerTimesProvider({
    required this.prayerTimeService,
    required this.sharedPreferences,
  }) {
    loadPrayerTimes();
  }

  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  /// The currently selected city name, or `null` if the user is relying on
  /// automatic GPS location.
  String? get cityName => sharedPreferences.getString(PrefsKeys.cityName);

  /// Switches the app to a fixed city's coordinates and recalculates today's
  /// prayer times (and the home-screen widget) right away.
  Future<void> setCity(AppCity city) async {
    await sharedPreferences.setString(PrefsKeys.cityName, city.name);
    await sharedPreferences.setString(PrefsKeys.cityTimezone, city.timezone);
    await sharedPreferences.setDouble(PrefsKeys.latitude, city.latitude);
    await sharedPreferences.setDouble(PrefsKeys.longitude, city.longitude);

    await prayerTimeService.calculateAndStore(
        city.latitude, city.longitude, sharedPreferences,
        method: city.method, timezone: city.timezone);
    await sharedPreferences.setString(
      PrefsKeys.prayerTimeDate,
      DateTime.now().toIso8601String().substring(0, 10),
    );

    _prayerTimes = prayerTimeService.getTimes(city.latitude, city.longitude,
        method: city.method, timezone: city.timezone);
    notifyListeners();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }

  /// Switches back to automatic (GPS) location: clears the fixed [cityName]
  /// and recalculates from the user's current coordinates.
  ///
  /// Returns `false` if the location could not be resolved (e.g. permissions
  /// denied or GPS disabled).
  Future<bool> useCurrentLocation() async {
    final position = await prayerTimeService.getCurrentLocation();
    if (position == null) return false;

    await sharedPreferences.remove(PrefsKeys.cityName);
    await _storeDeviceTimezone();
    await sharedPreferences.setDouble(PrefsKeys.latitude, position.latitude);
    await sharedPreferences.setDouble(PrefsKeys.longitude, position.longitude);

    final deviceTz = sharedPreferences.getString(PrefsKeys.cityTimezone);
    await prayerTimeService.calculateAndStore(
        position.latitude, position.longitude, sharedPreferences,
        timezone: deviceTz);
    await sharedPreferences.setString(
      PrefsKeys.prayerTimeDate,
      DateTime.now().toIso8601String().substring(0, 10),
    );

    _prayerTimes = prayerTimeService
        .getTimes(position.latitude, position.longitude, timezone: deviceTz);
    notifyListeners();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
    return true;
  }

  /// Persists the device IANA timezone for automatic (GPS) prayer times so
  /// every consumer (this provider, the app home screen and notification
  /// scheduling) uses the same display timezone. Without this the first
  /// cold-start calculation can fall back to the still-UTC `tz.local` and
  /// store shifted times until a re-run happens to win the race.
  Future<void> _storeDeviceTimezone() async {
    final tzName = await prayerTimeService.getDeviceTimezone();
    if (tzName != null) {
      await sharedPreferences.setString(PrefsKeys.cityTimezone, tzName);
    } else {
      await sharedPreferences.remove(PrefsKeys.cityTimezone);
    }
  }

  Future<void> loadPrayerTimes() async {
    double? lat = sharedPreferences.getDouble(PrefsKeys.latitude);
    double? lng = sharedPreferences.getDouble(PrefsKeys.longitude);

    if (lat == null || lng == null) {
      final position = await prayerTimeService.getCurrentLocation();
      lat = position?.latitude;
      lng = position?.longitude;
      if (lat != null && lng != null) {
        await sharedPreferences.setDouble(PrefsKeys.latitude, lat);
        await sharedPreferences.setDouble(PrefsKeys.longitude, lng);
        // Fresh install / no saved location: resolve the device timezone now
        // so the calculation below is deterministic, not dependent on whether
        // the background notification service has set the global tz.local yet.
        await _storeDeviceTimezone();
      }
    }

    if (lat != null && lng != null) {
      final city = _cityFromPrefs();
      var timezone =
          city?.timezone ?? sharedPreferences.getString(PrefsKeys.cityTimezone);
      if (timezone == null) {
        // GPS mode without a stored timezone (e.g. a store written by an older
        // build): resolve and persist the device timezone before computing.
        await _storeDeviceTimezone();
        timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
      }
      await _refresh(lat, lng, city, timezone);
    }
  }

  /// Recomputes today's prayer times when the stored date is stale (day rolled
  /// over while the app was running or backgrounded) and refreshes the widget.
  ///
  /// Returns `true` when new times were stored (and the widget updated), so
  /// callers can decide — e.g. to reschedule notifications — whether anything
  /// actually changed. Never triggers a location fetch; it only works with the
  /// already-persisted coordinates so it is safe to call periodically.
  Future<bool> refreshIfStale() async {
    final lat = sharedPreferences.getDouble(PrefsKeys.latitude);
    final lng = sharedPreferences.getDouble(PrefsKeys.longitude);
    if (lat == null || lng == null) return false;

    final city = _cityFromPrefs();
    var timezone =
        city?.timezone ?? sharedPreferences.getString(PrefsKeys.cityTimezone);
    if (timezone == null) {
      await _storeDeviceTimezone();
      timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
    }
    return _refresh(lat, lng, city, timezone);
  }

  /// Recover the fixed city's calculation method + timezone so that
  /// recalculated times stay in the city's local time (not the device
  /// timezone), which would otherwise shift every prayer notification by the
  /// city↔device offset the day after selection.
  AppCity? _cityFromPrefs() {
    final storedCityName = sharedPreferences.getString(PrefsKeys.cityName);
    if (storedCityName == null) return null;
    for (final c in appCities) {
      if (c.name == storedCityName) return c;
    }
    return null;
  }

  Future<bool> _refresh(
      double lat, double lng, AppCity? city, String? timezone) async {
    final storedDate = sharedPreferences.getString(PrefsKeys.prayerTimeDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final wasUnset = _prayerTimes == null;
    final changed = wasUnset || storedDate != today;

    // Same date and we already hold this session's times: nothing to recompute.
    // The 60s day-change timer calls this constantly, and the calculation is
    // pure (no I/O), but skipping it keeps hot-path work out of the timer.
    if (!changed && _prayerTimes != null) return false;

    if (changed) {
      await prayerTimeService.calculateAndStore(lat, lng, sharedPreferences,
          method: city?.method, timezone: timezone);
      await sharedPreferences.setString(PrefsKeys.prayerTimeDate, today);
    }

    _prayerTimes = prayerTimeService.getTimes(lat, lng,
        method: city?.method, timezone: timezone);

    if (changed || wasUnset) {
      notifyListeners();
      PrayerTimesWidgetService.updateWidget(
          prayerTimes: _prayerTimes, prefs: sharedPreferences);
    }
    return changed;
  }

  // --- Overrides ---
  Map<String, TimeOfDay> get allDisplayTimes =>
      prayerTimeService.getEffectiveTimes(sharedPreferences);

  TimeOfDay? getDisplayTime(String key) => allDisplayTimes[key];

  bool isOverridden(String key) =>
      prayerTimeService.hasOverride(key, sharedPreferences);

  void setOverride(String key, TimeOfDay time) {
    prayerTimeService.saveOverride(key, time, sharedPreferences);
    notifyListeners();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }

  void clearOverride(String key) {
    prayerTimeService.clearOverride(key, sharedPreferences);
    notifyListeners();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }

  void clearAllOverrides() {
    prayerTimeService.clearAllOverrides(sharedPreferences);
    notifyListeners();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }
}
