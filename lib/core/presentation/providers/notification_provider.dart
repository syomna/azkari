import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notificationsEnabled';

  // We only need one piece of state now
  bool _areNotificationsEnabled = true;
  bool get areNotificationsEnabled => _areNotificationsEnabled;

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

  /// Loads the single preference and applies the state
  void _loadNotificationPreferences() async {
    bool isGranted =
        await _notificationService.isNotificationPermissionGranted();
    if (isGranted) {
      _areNotificationsEnabled =
          _prefs.getBool(_notificationsEnabledKey) ?? true;
    }
    _applyNotificationStates();
  }

  /// Handles the actual scheduling/canceling logic
  void _applyNotificationStates() async {
    // Always start fresh by canceling
    _notificationService.cancelAllNotifications();

    // If the master switch is ON, enable all types of reminders
    if (_areNotificationsEnabled) {
      double? lat = _prefs.getDouble('lat');
      double? lng = _prefs.getDouble('lng');
      if (lat == null && lng == null) {
        final position = await _prayerTimeService.getCurrentLocation();
        lat = position?.latitude;
        lng = position?.longitude;
        if (lat != null && lng != null) {
          await _prefs.setDouble('lat', lat);
          await _prefs.setDouble('lng', lng);
        }
      }

      if (lat != null && lng != null) {
        await _notificationService.schedulePrayerNotifications();
        _notificationService.scheduleNotifications(lat, lng); // Morning
        _notificationService.scheduleNotifications(lat, lng,
            isDay: true); // Evening
      }

      _notificationService.periodicallyShowNotification(); // Periodic
      _notificationService.periodicallyShowDailyReminder(); // Daily
    }
  }

  /// The simplified toggle that handles UI and Logic
  Future<void> toggleAllNotifications(bool newValue) async {
    if (newValue == true) {
      // 1. Check if the OS actually allows notifications
      bool isGranted =
          await _notificationService.isNotificationPermissionGranted();

      if (!isGranted) {
        // 2. If not granted, try to request them now
        isGranted = await _notificationService.requestNotificationPermission();
      }

      // 3. If still not granted, the user must go to System Settings
      if (!isGranted) {
        _areNotificationsEnabled = false;
        notifyListeners();
      }
    }

    // 4. If we reach here, it's either turning OFF or permissions are fine
    _areNotificationsEnabled = newValue;
    _applyNotificationStates();
    _prefs.setBool(_notificationsEnabledKey, _areNotificationsEnabled);
    notifyListeners();
  }
}
