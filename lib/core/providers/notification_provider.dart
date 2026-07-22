import 'dart:developer';

import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notificationsEnabled';

  // Per-notification type preference keys
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
    // Always read the saved preference — never gate on permission status.
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    await _rescheduleNotifications();
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> toggleAllNotifications(bool newValue) async {
    // Always persist the user's choice immediately.
    _areNotificationsEnabled = newValue;
    await _prefs.setBool(_notificationsEnabledKey, newValue);
    notifyListeners();

    if (newValue == true) {
      // Try to ensure we have permission; don't block on the result.
      try {
        bool isGranted =
            await _notificationService.isNotificationPermissionGranted();
        if (!isGranted) {
          isGranted =
              await _notificationService.requestNotificationPermission();
        }
        if (!isGranted) {
          _areNotificationsEnabled = false;
          await _prefs.setBool(_notificationsEnabledKey, newValue);
          notifyListeners();
          return 'يرجى تفعيل صلاحية الإشعارات من إعدادات الجهاز';
        }
      } catch (e) {
        debugPrint('[NotificationProvider] Permission check failed: $e');
      }
    }

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
      log('Notifications refreshed on app launch');
    }
  }

  /// Schedules notifications based on current toggle state.
  /// Returns an error message if scheduling failed, null on success.
  Future<String?> _rescheduleNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Error canceling notifications: $e');
    }

    if (!_areNotificationsEnabled) return null;

    String? error;

    // --- Location-dependent notifications ---
    try {
      double? lat = _prefs.getDouble('lat');
      double? lng = _prefs.getDouble('lng');
      if (lat == null || lng == null) {
        final position = await _prayerTimeService.getCurrentLocation();
        lat = position?.latitude;
        lng = position?.longitude;
        if (lat != null && lng != null) {
          await _prefs.setDouble('lat', lat);
          await _prefs.setDouble('lng', lng);
        }
      }

      if (lat != null && lng != null) {
        if (isPrayerAdhanEnabled) {
          await _notificationService.schedulePrayerNotifications();
        }
        if (isMorningEveningAzkarEnabled) {
          await _notificationService.scheduleDayNightNotifications(lat, lng);
          await _notificationService.scheduleDayNightNotifications(lat, lng,
              isDay: true);
        }
        if (isPreAdhanEnabled) {
          await _notificationService.schedulePreAdhanReminders();
        }
        if (isQuranAfterSalahEnabled) {
          await _notificationService.scheduleQuranReminderAfterSalah();
        }
      } else {
        error = 'تعذر تحديد الموقع لجدولة إشعارات الصلاة';
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error scheduling prayers: $e');
      error = 'خطأ في جدولة إشعارات الصلاة';
    }

    // --- Location-independent notifications ---
    try {
      if (isPeriodicAzkarEnabled) {
        await _notificationService.periodicallyShowNotification();
      }
      if (isProphetBlessingsEnabled) {
        await _notificationService.scheduleProphetBlessings();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error scheduling reminders: $e');
      error ??= 'خطأ في جدولة التذكيرات';
    }

    return error;
  }

  /// Public entry point for external callers (e.g. prayer times settings).
  Future<void> applyNotificationStates() => _rescheduleNotifications();
}
