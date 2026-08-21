import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notificationsEnabled';

  static const String prayerAdhanKey = 'notif_prayer_adhan';
  static const String morningEveningAzkarKey = 'notif_morning_evening_azkar';
  static const String periodicAzkarKey = 'notif_periodic_azkar';
  static const String preAdhanKey = 'notif_pre_adhan';
  static const String quranAfterSalahKey = 'notif_quran_after_salah';
  static const String prophetBlessingsKey = 'notif_prophet_blessings';

  bool _areNotificationsEnabled = true;
  bool get areNotificationsEnabled => _areNotificationsEnabled;

  bool get isPrayerAdhanEnabled => _prefs.getBool(prayerAdhanKey) ?? true;
  bool get isMorningEveningAzkarEnabled =>
      _prefs.getBool(morningEveningAzkarKey) ?? true;
  bool get isPeriodicAzkarEnabled => _prefs.getBool(periodicAzkarKey) ?? true;
  bool get isPreAdhanEnabled => _prefs.getBool(preAdhanKey) ?? true;
  bool get isQuranAfterSalahEnabled =>
      _prefs.getBool(quranAfterSalahKey) ?? true;
  bool get isProphetBlessingsEnabled =>
      _prefs.getBool(prophetBlessingsKey) ?? true;

  final NotificationService _notificationService;
  final PrayerTimeService _prayerTimeService;
  final SharedPreferences _prefs;

  NotificationProvider({
    required NotificationService notificationService,
    required PrayerTimeService prayerTimeService,
    required SharedPreferences sharedPreferences,
  })  : _notificationService = notificationService,
        _prayerTimeService = prayerTimeService,
        _prefs = sharedPreferences {
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    await _rescheduleNotifications();
  }

  Future<String?> toggleAllNotifications(bool newValue) async {
    _areNotificationsEnabled = newValue;
    notifyListeners();

    if (newValue == true) {
      try {
        bool isGranted =
            await _notificationService.isNotificationPermissionGranted();
        if (!isGranted) {
          isGranted =
              await _notificationService.requestNotificationPermission();
        }
        if (!isGranted) {
          _areNotificationsEnabled = false;
          notifyListeners();
          return AppStrings.enableNotificationsPerm;
        }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Permission check failed: $e');
        return true;
      }());
    }
    }

    await _prefs.setBool(_notificationsEnabledKey, newValue);
    return await _rescheduleNotifications();
  }

  Future<void> toggleNotificationType(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
    await _rescheduleNotifications();
  }

  Future<void> refreshNotifications() async {
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;

    if (_areNotificationsEnabled) {
      await _rescheduleNotifications();
    }
  }

  Future<String?> _rescheduleNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Error canceling notifications: $e');
        return true;
      }());
    }

    if (!_areNotificationsEnabled) return null;

    String? error;

    final location = await _prayerTimeService.resolveLocation(_prefs);
    final lat = location?.$1;
    final lng = location?.$2;

    if (lat == null || lng == null) {
      return AppStrings.locationError;
    }

    try {
      await _notificationService.ensureTimezone();
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Timezone init failed: $e');
        return true;
      }());
    }

    try {
      if (isPrayerAdhanEnabled) {
        await _notificationService.schedulePrayerNotifications();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Prayer notifications failed: $e');
        return true;
      }());
      error = AppStrings.prayerSchedulingError;
    }

    try {
      if (isMorningEveningAzkarEnabled) {
        await _notificationService.scheduleDayNightNotifications(lat, lng);
        await _notificationService.scheduleDayNightNotifications(lat, lng,
            isDay: true);
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Day/night azkar failed: $e');
        return true;
      }());
      error ??= AppStrings.reminderSchedulingError;
    }

    try {
      if (isPreAdhanEnabled) {
        await _notificationService.schedulePreAdhanReminders();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Pre-adhan reminders failed: $e');
        return true;
      }());
    }

    try {
      if (isQuranAfterSalahEnabled) {
        await _notificationService.scheduleQuranReminderAfterSalah();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Quran after salah failed: $e');
        return true;
      }());
    }

    try {
      if (isPeriodicAzkarEnabled) {
        await _notificationService.periodicallyShowNotification();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Periodic azkar failed: $e');
        return true;
      }());
      error ??= AppStrings.reminderSchedulingError;
    }

    try {
      if (isProphetBlessingsEnabled) {
        await _notificationService.scheduleProphetBlessings();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationProvider] Prophet blessings failed: $e');
        return true;
      }());
    }

    return error;
  }

  Future<void> applyNotificationStates() => _rescheduleNotifications();
}
