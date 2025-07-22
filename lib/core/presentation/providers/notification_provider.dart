// lib/core/presentation/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkar_app/core/services/notifications_service.dart'; // Import your notification service

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

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService {
    _loadNotificationPreferencesAndSchedule(); // Call this new method
  }

  // Modified method to load preferences AND then schedule based on them
  Future<void> _loadNotificationPreferencesAndSchedule() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load preferences
    _areNotificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _isMorningAzkarNotificationEnabled =
        prefs.getBool(_morningAzkarNotificationKey) ?? true;
    _isEveningAzkarNotificationEnabled =
        prefs.getBool(_eveningAzkarNotificationKey) ?? true;
    _isPeriodicNotificationEnabled =
        prefs.getBool(_periodicNotificationKey) ?? true;

    // After loading, schedule/cancel based on the loaded state
    _applyNotificationStates();

    // Notify listeners ONLY if you want to rebuild UI components
    // that depend on the initial state immediately after loading.
    // However, usually, widgets will read the state on their first build.
    // notifyListeners(); // Only if UI needs to react to initial load
  }

  // New private method to apply the current notification states
  void _applyNotificationStates() {
    // First, ensure all existing notifications are cancelled to avoid duplicates
    _notificationService.cancelAllNotifications();

    if (_areNotificationsEnabled) {
      if (_isMorningAzkarNotificationEnabled) {
        _notificationService.scheduleNotifications(); // Schedule morning
      }
      if (_isEveningAzkarNotificationEnabled) {
        _notificationService.scheduleNotifications(
            isDay: true); // Schedule evening
      }
      if (_isPeriodicNotificationEnabled) {
        _notificationService
            .periodicallyShowNotification(); // Schedule periodic
      }
    }
    // If _areNotificationsEnabled is false, no notifications will be scheduled,
    // and cancelAllNotifications above ensures none are active.
  }

  Future<void> _saveNotificationPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, _areNotificationsEnabled);
    await prefs.setBool(
        _morningAzkarNotificationKey, _isMorningAzkarNotificationEnabled);
    await prefs.setBool(
        _eveningAzkarNotificationKey, _isEveningAzkarNotificationEnabled);
    await prefs.setBool(
        _periodicNotificationKey, _isPeriodicNotificationEnabled);
  }

  void toggleAllNotifications(bool newValue) {
    if (_areNotificationsEnabled != newValue) {
      _areNotificationsEnabled = newValue;
      // When master toggle changes, update all relevant states and scheduling
      _isMorningAzkarNotificationEnabled =
          newValue; // Sync sub-toggles with master
      _isEveningAzkarNotificationEnabled = newValue;
      _isPeriodicNotificationEnabled = newValue;

      _applyNotificationStates(); // Apply new state after changes

      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void toggleMorningAzkarNotification(bool newValue) {
    if (_isMorningAzkarNotificationEnabled != newValue) {
      _isMorningAzkarNotificationEnabled = newValue;
      _applyNotificationStates(); // Re-apply all states to ensure correctness
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void toggleEveningAzkarNotification(bool newValue) {
    if (_isEveningAzkarNotificationEnabled != newValue) {
      _isEveningAzkarNotificationEnabled = newValue;
      _applyNotificationStates(); // Re-apply all states to ensure correctness
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void togglePeriodicNotification(bool newValue) {
    if (_isPeriodicNotificationEnabled != newValue) {
      _isPeriodicNotificationEnabled = newValue;
      _applyNotificationStates(); // Re-apply all states to ensure correctness
      _saveNotificationPreferences();
      notifyListeners();
    }
  }

  void clearTasbehCount() {
    // Implement logic to clear Tasbeh count.
  }
}
