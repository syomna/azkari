import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:azkar_app/core/services/notifications/azkar_notifications_scheduler.dart';
import 'package:azkar_app/core/services/notifications/prayer_notifications_scheduler.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final SharedPreferences prefs;
  final PrayerTimeService prayerService;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late final PrayerNotificationsScheduler _prayerScheduler;
  late final AzkarNotificationsScheduler _azkarScheduler;

  NotificationService._internal({
    required this.prefs,
    required this.prayerService,
  }) {
    _prayerScheduler = PrayerNotificationsScheduler(
      plugin: flutterLocalNotificationsPlugin,
      prayerService: prayerService,
      prefs: prefs,
    );
    _azkarScheduler = AzkarNotificationsScheduler(
      plugin: flutterLocalNotificationsPlugin,
      prayerService: prayerService,
      prefs: prefs,
    );
  }

  static NotificationService? _instance;

  static Future<NotificationService> init({
    required SharedPreferences prefs,
    required PrayerTimeService prayerService,
  }) async {
    if (_instance == null) {
      _instance = NotificationService._internal(
        prefs: prefs,
        prayerService: prayerService,
      );
      await _instance!._initNotification();
    }
    return _instance!;
  }

  static NotificationService get instance {
    if (_instance == null) {
      throw Exception(
          'NotificationService must be initialized with init() first');
    }
    return _instance!;
  }

  Future<void> _initNotification() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
      );

      if (Platform.isIOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
      } else if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
      }
    } catch (e) {
      assert(() {
        debugPrint('[NotificationService] Init failed: $e');
        return true;
      }());
    }
  }

  static Function(String payload)? _onTapCallback;

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && _onTapCallback != null) {
      _onTapCallback!(payload);
    }
  }

  static void configureNotificationTap({
    required Function(String payload) onTap,
  }) {
    _onTapCallback = onTap;
  }

  Future<String?> getInitialNotificationPayload() async {
    final details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse != null) {
      return details.notificationResponse!.payload;
    }
    return null;
  }

  Future<void> ensureTimezone() async {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  }

  Future<void> schedulePrayerNotifications() =>
      _prayerScheduler.schedulePrayerNotifications();

  Future<void> schedulePreAdhanReminders() =>
      _prayerScheduler.schedulePreAdhanReminders();

  Future<void> scheduleQuranReminderAfterSalah() =>
      _prayerScheduler.scheduleQuranReminderAfterSalah();

  Future<void> scheduleDayNightNotifications(double lat, double lng,
          {bool isDay = false}) =>
      _azkarScheduler.scheduleDayNightNotifications(lat, lng, isDay: isDay);

  Future<void> periodicallyShowNotification() =>
      _azkarScheduler.periodicallyShowNotification();

  Future<void> scheduleProphetBlessings() =>
      _azkarScheduler.scheduleProphetBlessings();

  Future<void> debugPrintPendingNotifications() async {
    assert(() {
      final pending =
          flutterLocalNotificationsPlugin.pendingNotificationRequests();
      pending.then((list) {
        log('[Notification] Pending notifications (${list.length}):');
        for (final n in list) {
          log('  id=${n.id} title=${n.title} body=${n.body}');
        }
      });
      return true;
    }());
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationById(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    var status = await Permission.notification.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    status = await Permission.notification.request();

    return status.isGranted;
  }

  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return await Permission.notification.isGranted;
  }
}
