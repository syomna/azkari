import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _morningAzkarNotificationKey = 'morningAzkarNotification';
  static const String _eveningAzkarNotificationKey = 'eveningAzkarNotification';
  static const String _periodicNotificationKey = 'periodicNotification';
  static const String _periodicReminderNotificationKey =
      'periodicRemiderNotification';

  bool _areNotificationsEnabled = false;
  bool _isMorningAzkarNotificationEnabled = false;
  bool _isEveningAzkarNotificationEnabled = false;
  bool _isPeriodicNotificationEnabled = false;
  bool _isPeriodicReminderNotificationEnabled = false;

  bool get areNotificationsEnabled => _areNotificationsEnabled;
  bool get isMorningAzkarNotificationEnabled =>
      _isMorningAzkarNotificationEnabled;
  bool get isEveningAzkarNotificationEnabled =>
      _isEveningAzkarNotificationEnabled;
  bool get isPeriodicNotificationEnabled => _isPeriodicNotificationEnabled;
  bool get isPeriodicReminderNotificationEnabled =>
      _isPeriodicReminderNotificationEnabled;

  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  NotificationProvider({
    required NotificationService notificationService,
    required SharedPreferences sharedPreferences,
  })  : _notificationService = notificationService,
        _prefs = sharedPreferences {
    _loadNotificationPreferencesAndSchedule();
  }

  // Inside your NotificationService class

  Future<void> _loadNotificationPreferencesAndSchedule() async {
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    _isMorningAzkarNotificationEnabled =
        _prefs.getBool(_morningAzkarNotificationKey) ?? false;
    _isEveningAzkarNotificationEnabled =
        _prefs.getBool(_eveningAzkarNotificationKey) ?? false;
    _isPeriodicNotificationEnabled =
        _prefs.getBool(_periodicNotificationKey) ?? false;
    _isPeriodicReminderNotificationEnabled =
        _prefs.getBool(_periodicReminderNotificationKey) ?? false;

    _applyNotificationStates();
  }

  void _applyNotificationStates() {
    _notificationService.cancelAllNotifications();

    if (_areNotificationsEnabled) {
      if (_isMorningAzkarNotificationEnabled) {
        _notificationService.scheduleNotifications();
      }
      if (_isEveningAzkarNotificationEnabled) {
        _notificationService.scheduleNotifications(isDay: true);
      }
      if (_isPeriodicNotificationEnabled) {
        _notificationService.periodicallyShowNotification();
      }
      if (_isPeriodicReminderNotificationEnabled) {
        _notificationService.periodicallyShowDailyReminder();
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    await _prefs.setBool(_notificationsEnabledKey, _areNotificationsEnabled);
    await _prefs.setBool(
        _morningAzkarNotificationKey, _isMorningAzkarNotificationEnabled);
    await _prefs.setBool(
        _eveningAzkarNotificationKey, _isEveningAzkarNotificationEnabled);
    await _prefs.setBool(
        _periodicNotificationKey, _isPeriodicNotificationEnabled);
    await _prefs.setBool(_periodicReminderNotificationKey,
        _isPeriodicReminderNotificationEnabled);
  }

  void toggleAllNotifications(bool newValue) {
    if (_areNotificationsEnabled != newValue) {
      _areNotificationsEnabled = newValue;
      _isMorningAzkarNotificationEnabled = newValue;
      _isEveningAzkarNotificationEnabled = newValue;
      _isPeriodicNotificationEnabled = newValue;
      _isPeriodicReminderNotificationEnabled = newValue;

      _applyNotificationStates();

      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void toggleMorningAzkarNotification(bool newValue) {
    if (_isMorningAzkarNotificationEnabled != newValue) {
      _isMorningAzkarNotificationEnabled = newValue;
      _applyNotificationStates();
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void toggleEveningAzkarNotification(bool newValue) {
    if (_isEveningAzkarNotificationEnabled != newValue) {
      _isEveningAzkarNotificationEnabled = newValue;
      _applyNotificationStates();
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void togglePeriodicNotification(bool newValue) {
    if (_isPeriodicNotificationEnabled != newValue) {
      _isPeriodicNotificationEnabled = newValue;
      _isPeriodicReminderNotificationEnabled = newValue;
      _applyNotificationStates();
      _saveNotificationPreferences();
      notifyListeners();
    }
  }
}
