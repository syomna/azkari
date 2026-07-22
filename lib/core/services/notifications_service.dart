import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:azkar_app/core/constants/duaa_notifications.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
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

  // Deterministic notification ID map — single source of truth.
  // Never use hashCode or runtime counters for persistent notification IDs.
  static const Map<String, int> notificationIds = {
    'prayer_fajr': 100,
    'prayer_dhuhr': 101,
    'prayer_asr': 102,
    'prayer_maghrib': 103,
    'prayer_isha': 104,
    'azkar_morning': 10,
    'azkar_evening': 11,
    'periodic_1': 20,
    'periodic_2': 21,
    'periodic_3': 22,
    'periodic_4': 23,
    'preadhan_fajr': 200,
    'preadhan_dhuhr': 201,
    'preadhan_asr': 202,
    'preadhan_maghrib': 203,
    'preadhan_isha': 204,
    'quran_fajr': 300,
    'quran_dhuhr': 301,
    'quran_asr': 302,
    'quran_maghrib': 303,
    'quran_isha': 304,
    'blessing_1': 400,
    'blessing_2': 401,
    'blessing_3': 402,
    'blessing_4': 403,
  };

  // 1. Private Constructor with required dependencies
  NotificationService._internal({
    required this.prefs,
    required this.prayerService,
  });

  // 2. Static instance for Singleton pattern
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
      final iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
    } else if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  /// Static tap handler — set [_onTapCallback] from outside to navigate.
  static Function(String payload)? _onTapCallback;

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && _onTapCallback != null) {
      _onTapCallback!(payload);
    }
  }

  /// Called from main.dart to register navigation callback.
  static void configureNotificationTap({
    required Function(String payload) onTap,
  }) {
    _onTapCallback = onTap;
  }

  /// Check if app was launched by tapping a notification.
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

  NotificationDetails azkarDetails = const NotificationDetails(
    android: AndroidNotificationDetails(
      'azkar_channel_v3',
      'الأذكار',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(presentSound: true),
  );

  NotificationDetails azkarDetailsNoSound = const NotificationDetails(
    android: AndroidNotificationDetails(
      'azkar_channel_no_sound_v4',
      'الأذكار',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
    ),
    iOS: DarwinNotificationDetails(presentSound: false),
  );

  NotificationDetails adhanDetails = const NotificationDetails(
    android: AndroidNotificationDetails(
      'adhan_channel_v5',
      'الأذان',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adhan_chime'),
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
    ),
    iOS: DarwinNotificationDetails(
      sound: 'adhan.wav',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    ),
  );

  /// Ensures the local timezone is set before any scheduling call.
  Future<void> _ensureTimezone() async {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  }

  void _logSchedule(String category, int id, tz.TZDateTime scheduled,
      {String? details}) {
    assert(() {
      log(
        '[Notification] id=$id | category=$category | '
        'scheduled=${scheduled.toIso8601String()} | tz=${tz.local.name}'
        '${details != null ? ' | $details' : ''}',
      );
      return true;
    }());
  }

  Future<void> schedulePrayerNotifications() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    await _ensureTimezone();
    final now = tz.TZDateTime.now(tz.local);

    for (final key in AppHelpers.prayerNames.keys) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['prayer_$key']!;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('prayer_adhan', id, scheduledDate, details: 'key=$key');

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'حان وقت الصلاة',
          body: 'الله أكبر، حان وقت ${AppHelpers.prayerNames[key]}',
          payload: 'prayer_$key',
          scheduledDate: scheduledDate,
          notificationDetails: adhanDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[Notification] Failed to schedule prayer $key: $e');
      }
    }
  }

  Future<void> scheduleDayNightNotifications(double lat, double lng,
      {bool isDay = false}) async {
    await _ensureTimezone();
    final now = tz.TZDateTime.now(tz.local);

    // Use getEffectiveTimes to respect user overrides
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final prayerKey = isDay ? 'fajr' : 'asr';
    final timeOfDay = effectiveTimes[prayerKey];
    if (timeOfDay == null) return;

    // Add 30 minutes to the prayer time
    final totalMinutes = timeOfDay.hour * 60 + timeOfDay.minute + 30;
    final notificationHour = (totalMinutes ~/ 60) % 24;
    final notificationMinute = totalMinutes % 60;

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationHour,
      notificationMinute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final id = isDay
        ? notificationIds['azkar_morning']!
        : notificationIds['azkar_evening']!;
    final label = isDay ? 'morning' : 'evening';

    _logSchedule('day_night_azkar', id, scheduledDate, details: label);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: 'أذكاري',
        body: isDay ? '🌞 حان وقت أذكار الصباح' : '🌙 حان وقت أذكار المساء',
        scheduledDate: scheduledDate,
        notificationDetails: azkarDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[Notification] Failed to schedule day/night azkar: $e');
    }
  }

  Future<void> periodicallyShowNotification() async {
    List<String> adhkarPool = DuaaNotifications.adhkarPool;
    List<int> hours = [8, 12, 16, 20];
    await _ensureTimezone();

    for (int i = 0; i < hours.length; i++) {
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hours[i],
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final id = notificationIds['periodic_${i + 1}']!;

      _logSchedule('periodic_azkar', id, scheduledDate);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'أذكاري',
          body: adhkarPool[i % adhkarPool.length],
          scheduledDate: scheduledDate,
          notificationDetails: azkarDetailsNoSound,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[Notification] Failed to schedule periodic $i: $e');
      }
    }
  }

  Future<void> schedulePreAdhanReminders() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    await _ensureTimezone();
    final now = tz.TZDateTime.now(tz.local);

    for (final entry in AppHelpers.prayerNames.entries) {
      final timeOfDay = effectiveTimes[entry.key];
      if (timeOfDay == null) continue;

      final id = notificationIds['preadhan_${entry.key}']!;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));

      // If this pre-Adhan time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('pre_adhan', id, scheduledDate, details: entry.key);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'استعد للصلاة',
          body: 'بقي ١٠ دقائق على ${entry.value}، حان وقت الوضوء',
          scheduledDate: scheduledDate,
          notificationDetails: azkarDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint(
            '[Notification] Failed to schedule pre-adhan ${entry.key}: $e');
      }
    }
  }

  Future<void> scheduleQuranReminderAfterSalah() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    await _ensureTimezone();
    final now = tz.TZDateTime.now(tz.local);

    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['quran_$key']!;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      scheduledDate = scheduledDate.add(const Duration(minutes: 30));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('quran_reminder', id, scheduledDate, details: key);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'وردك اليومي',
          body: 'حان وقت قراءة وردك من القرآن الكريم',
          scheduledDate: scheduledDate,
          notificationDetails: azkarDetailsNoSound,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[Notification] Failed to schedule quran $key: $e');
      }
    }
  }

  Future<void> scheduleProphetBlessings() async {
    final List<int> triggerHours = [10, 14, 17, 21];
    await _ensureTimezone();

    for (int i = 0; i < triggerHours.length; i++) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, triggerHours[i]);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final id = notificationIds['blessing_${i + 1}']!;

      _logSchedule('prophet_blessing', id, scheduledDate);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'الصلاة على النبي',
          body: DuaaNotifications
              .blessings[i % DuaaNotifications.blessings.length],
          scheduledDate: scheduledDate,
          notificationDetails: azkarDetailsNoSound,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[Notification] Failed to schedule blessing $i: $e');
      }
    }
  }

  /// Debug-only: prints all currently pending notification requests.
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
    var status = await Permission.notification.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    status = await Permission.notification.request();

    return status.isGranted;
  }

  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }
}
