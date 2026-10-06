import 'dart:async';
import 'dart:developer';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
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
  static const String islamicEventsKey = 'notif_islamic_events';

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
  bool get isIslamicEventsEnabled => _prefs.getBool(islamicEventsKey) ?? true;

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
    // Same schedule as last run? Nothing to re-create — skip the expensive
    // cancelAll+reschedule that used to run on every cold start.
    if (_areNotificationsEnabled && _hasUnchangedSchedulePlan()) return;
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
          await _prefs.setBool(_notificationsEnabledKey, false);
          notifyListeners();
          // Permission denied while notifications were previously scheduled:
          // cancel whatever is already queued so stale alerts don't fire.
          await _rescheduleNotifications();
          return 'يرجى تفعيل صلاحية الإشعارات من إعدادات الجهاز';
        }
        // Constant exact alarms on Android need the "Alarms & reminders"
        // special access; ask for it right here while the user is engaged.
        await _notificationService.requestExactAlarmsPermission();
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

  /// Reads the stored "HH:mm" custom azkar time for [key], or `null` when the
  /// default (prayer-derived) time should be used. Out-of-range values (e.g. a
  /// corrupted "25:99") are treated as unset rather than scheduled as-is.
  TimeOfDay? azkarTime(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  /// Stores a custom azkar time ("HH:mm") for [key] and reschedules. Passing
  /// `null` clears the custom time and reverts to the default. Returns an
  /// error message on scheduling failure, null on success.
  Future<String?> setAzkarTime(String key, TimeOfDay? time) async {
    if (time == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key,
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    }
    notifyListeners();
    return _rescheduleNotifications();
  }

  Future<void> refreshNotifications() async {
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;

    if (_areNotificationsEnabled && !_hasUnchangedSchedulePlan()) {
      await _rescheduleNotifications();
      log('Notifications refreshed on app launch');
    }
  }

  static const String _scheduleSignatureKey = 'notif_schedule_signature';

  /// Serializes every setting that affects what [NotificationService] queues,
  /// so a later run can detect "same plan as before" and skip a redundant
  /// cancel+reschedule. Returns `null` when the location — the one thing the
  /// schedulers need to start at all — isn't resolved yet.
  String? _computeScheduleSignature() {
    double? lat = _prefs.getDouble(PrefsKeys.latitude);
    double? lng = _prefs.getDouble(PrefsKeys.longitude);
    if (lat == null || lng == null) return null;

    final effectiveTimes = _prayerTimeService.getEffectiveTimes(_prefs);
    final parts = <String>[
      _prefs.getString(PrefsKeys.prayerTimeDate) ?? '',
      _prefs.getString(PrefsKeys.cityTimezone) ?? '',
      _prefs.getString(PrefsKeys.cityName) ?? '',
      _areNotificationsEnabled.toString(),
      isPrayerAdhanEnabled.toString(),
      isMorningEveningAzkarEnabled.toString(),
      isPeriodicAzkarEnabled.toString(),
      isPreAdhanEnabled.toString(),
      isQuranAfterSalahEnabled.toString(),
      isProphetBlessingsEnabled.toString(),
      isIslamicEventsEnabled.toString(),
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
      _prefs.getString(PrefsKeys.morningAzkarTime) ?? '',
      _prefs.getString(PrefsKeys.eveningAzkarTime) ?? '',
    ];
    for (final key in AppHelpers.prayerNames.keys) {
      final t = effectiveTimes[key];
      parts.add(t == null ? '' : '${t.hour}:${t.minute}');
    }
    return parts.join('|');
  }

  bool _hasUnchangedSchedulePlan() {
    final stored = _prefs.getString(_scheduleSignatureKey);
    if (stored == null) return false;
    final current = _computeScheduleSignature();
    if (current == null) return false;
    return stored == current;
  }

  /// Serializes reschedule runs so rapid successive edits/toggles cannot run
  /// `cancelAll`/reschedule concurrently (which would interleave and silently
  /// drop notifications, e.g. after editing a prayer or azkar time).
  Future<String?> _rescheduleQueue = Future.value();

  Future<String?> _rescheduleNotifications() {
    final completer = Completer<String?>();
    _rescheduleQueue = _rescheduleQueue.then((_) async {
      String? result;
      try {
        result = await _rescheduleNotificationsInner();
      } catch (e) {
        debugPrint('[NotificationProvider] Reschedule failure: $e');
        result = 'خطأ في جدولة الإشعارات';
      }
      completer.complete(result);
      return result;
    });
    return completer.future;
  }

  /// Schedules notifications based on current toggle state.
  /// Returns an error message if scheduling failed, null on success.
  Future<String?> _rescheduleNotificationsInner() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Error canceling notifications: $e');
    }

    if (!_areNotificationsEnabled) return null;

    String? error;

    // --- Location-dependent notifications ---
    try {
      double? lat = _prefs.getDouble(PrefsKeys.latitude);
      double? lng = _prefs.getDouble(PrefsKeys.longitude);
      if (lat == null || lng == null) {
        final position = await _prayerTimeService.getCurrentLocation();
        lat = position?.latitude;
        lng = position?.longitude;
        if (lat != null && lng != null) {
          await _prefs.setDouble(PrefsKeys.latitude, lat);
          await _prefs.setDouble(PrefsKeys.longitude, lng);
        }
      }

      if (lat != null && lng != null) {
        String? e;
        if (isPrayerAdhanEnabled) {
          e = await _notificationService.schedulePrayerNotifications();
          error ??= e;
        }
        if (isMorningEveningAzkarEnabled) {
          e = await _notificationService.scheduleDayNightNotifications(
              lat, lng);
          error ??= e;
          e = await _notificationService.scheduleDayNightNotifications(lat, lng,
              isDay: true);
          error ??= e;
        }
        if (isPreAdhanEnabled) {
          e = await _notificationService.schedulePreAdhanReminders();
          error ??= e;
        }
        if (isQuranAfterSalahEnabled) {
          e = await _notificationService.scheduleQuranReminderAfterSalah();
          error ??= e;
        }
      } else {
        error = 'تعذر تحديد الموقع لجدولة إشعارات الصلاة';
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error scheduling prayers: $e');
      error ??= 'خطأ في جدولة إشعارات الصلاة';
    }

    // --- Location-independent notifications ---
    try {
      if (isPeriodicAzkarEnabled) {
        final e = await _notificationService.periodicallyShowNotification();
        error ??= e;
      }
      if (isProphetBlessingsEnabled) {
        final e = await _notificationService.scheduleProphetBlessings();
        error ??= e;
      }
      // Islamic events are calendar-based and need no location, so they live
      // here rather than behind the latitude/longitude guard: a user who has
      // not granted location should still be told about Ashura or Laylatul Qadr.
      if (isIslamicEventsEnabled) {
        final e =
            await _notificationService.scheduleIslamicEventNotifications();
        error ??= e;
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error scheduling reminders: $e');
      error ??= 'خطأ في جدولة التذكيرات';
    }

    // Record the plan we just queued so the next cold start can skip this
    // whole reschedule. Only a fully-successful, prayer-times-ready run is
    // cached (otherwise the next launch re-runs and heals the gap).
    if (error == null && _areNotificationsEnabled) {
      final prayerTimeDate = _prefs.getString(PrefsKeys.prayerTimeDate);
      if (prayerTimeDate != null && prayerTimeDate.isNotEmpty) {
        final signature = _computeScheduleSignature();
        if (signature != null) {
          await _prefs.setString(_scheduleSignatureKey, signature);
        }
      }
    }

    return error;
  }

  /// Public entry point for external callers (e.g. prayer times settings).
  Future<String?> applyNotificationStates() => _rescheduleNotifications();
}
