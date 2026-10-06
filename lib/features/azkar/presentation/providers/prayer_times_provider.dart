import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/services/prayer_times_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

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

  /// The IANA timezone the displayed prayer times are expressed in, or `null`
  /// when no city has been resolved yet. Kept alongside [cityName] so surfaces
  /// that reason about dates (e.g. Islamic events) can anchor "today" on the
  /// same calendar the prayer times use.
  String? get cityTimezone =>
      sharedPreferences.getString(PrefsKeys.cityTimezone);

  /// "Today" on the calendar the stored times are expressed in. With a city
  /// picked in another timezone, the day must roll at the city's midnight, not
  /// the device's: stamping the device date near a city's midnight would mark
  /// the freshly-recalculated times stale an hour too early (or late) and doom
  /// them until the next rollover. Falls back to the device calendar when no
  /// timezone is available. Uses the service's own location resolution (lazy
  /// tz-data load + unknown-zone fallback) so this never throws.
  static String _todayString(String? timezone) {
    final now =
        tz.TZDateTime.now(PrayerTimeService().displayLocation(timezone));
    return now.toIso8601String().substring(0, 10);
  }

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
      _todayString(city.timezone),
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
      _todayString(deviceTz),
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

  /// Re-pins the stored display timezone to the device's current one while the
  /// user relies on automatic (GPS) location, returning whether it changed.
  ///
  /// The coordinates come from the device, so the times have to be shown in the
  /// device's timezone. That value was only ever written when the location was
  /// first resolved, so a timezone change (travelling, DST, or the system
  /// timezone being changed while the app kept its old coordinates) left the
  /// stored zone describing a different place than the coordinates — shifting
  /// every prayer by the whole offset between the two, for as long as the
  /// mismatched pair stayed stored.
  ///
  /// A change has to force a recompute: the day-stale check would otherwise
  /// keep today's already-stored (wrong) times until tomorrow.
  Future<bool> _syncDeviceTimezone() async {
    final stored = sharedPreferences.getString(PrefsKeys.cityTimezone);
    final device = await prayerTimeService.getDeviceTimezone();
    if (device == null || device == stored) return false;
    await sharedPreferences.setString(PrefsKeys.cityTimezone, device);
    return true;
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
      var timezone = city?.timezone;
      var timezoneChanged = false;
      if (city == null) {
        // Automatic location: the coordinates are the device's, so the times
        // must be expressed in the device's timezone.
        timezoneChanged = await _syncDeviceTimezone();
        timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
        if (timezone == null) {
          // GPS mode without a stored timezone (e.g. a store written by an
          // older build): resolve it before computing.
          await _storeDeviceTimezone();
          timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
        }
      }
      await _refresh(lat, lng, city, timezone, forceRecompute: timezoneChanged);
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
    var timezone = city?.timezone;
    var timezoneChanged = false;
    if (city == null) {
      timezoneChanged = await _syncDeviceTimezone();
      timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
      if (timezone == null) {
        await _storeDeviceTimezone();
        timezone = sharedPreferences.getString(PrefsKeys.cityTimezone);
      }
    }
    return _refresh(lat, lng, city, timezone, forceRecompute: timezoneChanged);
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

  Future<bool> _refresh(double lat, double lng, AppCity? city, String? timezone,
      {bool forceRecompute = false}) async {
    final storedDate = sharedPreferences.getString(PrefsKeys.prayerTimeDate);
    final today = _todayString(timezone);
    final wasUnset = _prayerTimes == null;
    // `forceRecompute` is how the caller says the inputs themselves changed
    // (e.g. the display timezone) rather than only the calendar day.
    final changed = forceRecompute || wasUnset || storedDate != today;

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
