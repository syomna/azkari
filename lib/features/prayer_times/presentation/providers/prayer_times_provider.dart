import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/models/city.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/services/prayer_times_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final PrayerTimeService prayerTimeService;
  final SharedPreferences sharedPreferences;

  PrayerTimesProvider({
    required this.prayerTimeService,
    required this.sharedPreferences,
  });

  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VoidCallback? onOverrideChanged;

  String? get selectedCityId =>
      sharedPreferences.getString(PrayerTimeService.selectedCityIdKey);

  String? get selectedCityName =>
      prayerTimeService.getSelectedCityDisplayName(sharedPreferences);

  bool get isAutoLocation =>
      !prayerTimeService.hasSelectedCity(sharedPreferences);

  bool get hasAnyOverrides => PrayerTimeService.prayerKeys
      .any((key) => prayerTimeService.hasOverride(key, sharedPreferences));

  Future<void> loadPrayerTimes({bool forceRecalc = false}) async {
    try {
      final location = await prayerTimeService.resolveLocation(sharedPreferences);
      final lat = location?.$1;
      final lng = location?.$2;

      if (lat != null && lng != null) {
        final storedDate = sharedPreferences.getString('prayer_time_date');
        final today = DateTime.now().toIso8601String().substring(0, 10);

        if (forceRecalc || storedDate != today) {
          await prayerTimeService.calculateAndStore(
              lat, lng, sharedPreferences);
          await sharedPreferences.setString('prayer_time_date', today);
        }

        _prayerTimes = prayerTimeService.getTimes(lat, lng);
        _errorMessage = null;
        notifyListeners();
        PrayerTimesWidgetService.updateWidget(
            prayerTimes: _prayerTimes, prefs: sharedPreferences);
      }
    } catch (e) {
      assert(() {
        debugPrint('[PrayerTimesProvider] Failed to load prayer times: $e');
        return true;
      }());
      _errorMessage = 'Failed to load prayer times';
      notifyListeners();
    }
  }

  Future<bool> selectCity(City? city) async {
    try {
      if (city != null) {
        await prayerTimeService.saveSelectedCity(city, sharedPreferences);
        await loadPrayerTimes(forceRecalc: true);
        return true;
      }

      final position = await prayerTimeService.getCurrentLocation();
      if (position == null) return false;

      await prayerTimeService.clearSelectedCity(sharedPreferences);
      await prayerTimeService.storeCurrentLocation(
          position, sharedPreferences);
      await loadPrayerTimes(forceRecalc: true);
      return true;
    } catch (e) {
      assert(() {
        debugPrint('[PrayerTimesProvider] selectCity failed: $e');
        return true;
      }());
      return false;
    }
  }

  Map<String, TimeOfDay> get allDisplayTimes =>
      prayerTimeService.getEffectiveTimes(sharedPreferences);

  TimeOfDay? getDisplayTime(String key) => allDisplayTimes[key];

  bool isOverridden(String key) =>
      prayerTimeService.hasOverride(key, sharedPreferences);

  void setOverride(String key, TimeOfDay time) {
    prayerTimeService.saveOverride(key, time, sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }

  void clearOverride(String key) {
    prayerTimeService.clearOverride(key, sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }

  void clearAllOverrides() {
    prayerTimeService.clearAllOverrides(sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
    PrayerTimesWidgetService.updateWidget(
        prayerTimes: _prayerTimes, prefs: sharedPreferences);
  }
}
