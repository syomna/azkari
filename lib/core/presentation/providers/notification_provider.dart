import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkar_app/core/services/notifications_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _morningAzkarNotificationKey = 'morningAzkarNotification';
  static const String _eveningAzkarNotificationKey = 'eveningAzkarNotification';
  static const String _periodicNotificationKey = 'periodicNotification';

  bool _areNotificationsEnabled = true;
  bool _isMorningAzkarNotificationEnabled = true;
  bool _isEveningAzkarNotificationEnabled = true;
  bool _isPeriodicNotificationEnabled = true;

  bool get areNotificationsEnabled => _areNotificationsEnabled;
  bool get isMorningAzkarNotificationEnabled =>
      _isMorningAzkarNotificationEnabled;
  bool get isEveningAzkarNotificationEnabled =>
      _isEveningAzkarNotificationEnabled;
  bool get isPeriodicNotificationEnabled => _isPeriodicNotificationEnabled;

  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  NotificationProvider({
    required NotificationService notificationService,
    required SharedPreferences sharedPreferences,
  })  : _notificationService = notificationService,
        _prefs = sharedPreferences {
    _loadNotificationPreferencesAndSchedule();
  }

  Future<void> _loadNotificationPreferencesAndSchedule() async {
    _areNotificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    _isMorningAzkarNotificationEnabled =
        _prefs.getBool(_morningAzkarNotificationKey) ?? true;
    _isEveningAzkarNotificationEnabled =
        _prefs.getBool(_eveningAzkarNotificationKey) ?? true;
    _isPeriodicNotificationEnabled =
        _prefs.getBool(_periodicNotificationKey) ?? true;

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
  }

  void toggleAllNotifications(bool newValue) {
    if (_areNotificationsEnabled != newValue) {
      _areNotificationsEnabled = newValue;
      _isMorningAzkarNotificationEnabled = newValue;
      _isEveningAzkarNotificationEnabled = newValue;
      _isPeriodicNotificationEnabled = newValue;

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
      _applyNotificationStates();
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void clearTasbehCount() {
    // This method is in TasbehProvider, not NotificationProvider
  }
}
