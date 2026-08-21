import 'package:adhan/adhan.dart';
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

  Future<void> loadPrayerTimes() async {
    try {
      final location = await prayerTimeService.resolveLocation(sharedPreferences);
      final lat = location?.$1;
      final lng = location?.$2;

      if (lat != null && lng != null) {
        final storedDate = sharedPreferences.getString('prayer_time_date');
        final today = DateTime.now().toIso8601String().substring(0, 10);

        if (storedDate != today) {
          await prayerTimeService.calculateAndStore(lat, lng, sharedPreferences);
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
