import 'dart:async';
import 'dart:io';

import 'package:azkar_app/core/constants/duaa_notifications.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final SharedPreferences prefs;
  final PrayerTimeService prayerService;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
    // Android setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup - Modern Darwin settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Set to false to manual request later
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: true, // IMPORTANT for Adhan on Mute/DND
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Platform-Specific Runtime Requests
    if (Platform.isIOS) {
      final iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      // Requesting with 'Critical' sounds for Adhan
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // This allows the Adhan to bypass the mute switch
      );
    } else if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  // 1. For Azkar (Standard system sound)
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

// 2. For Prayer (Custom Adhan sound)
  NotificationDetails adhanDetails = const NotificationDetails(
    android: AndroidNotificationDetails(
      'adhan_channel_v3',
      'الأذان',
      importance: Importance.max,
      priority: Priority.high,
      sound:
          RawResourceAndroidNotificationSound('adhan'), // adhan.mp3 in res/raw
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      sound: 'adhan.wav',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    ),
  );

  Future<void> schedulePrayerNotifications() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);

    // Notification IDs per prayer
    const Map<String, int> prayerIds = {
      'fajr': 100,
      'dhuhr': 101,
      'asr': 102,
      'maghrib': 103,
      'isha': 104,
    };

    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    final now = tz.TZDateTime.now(tz.local);

    for (final key in prayerIds.keys) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      // If already passed today, skip — will be rescheduled tomorrow at midnight
      if (scheduledDate.isBefore(now)) continue;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        prayerIds[key]!,
        'حان وقت الصلاة',
        'الله أكبر، حان وقت ${AppHelpers.prayerNames[key]}',
        scheduledDate,
        adhanDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleNotifications(double lat, double lng,
      {bool isDay = false}) async {
    // await testRepeatingZoned();
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // int targetHour = isDay ? 5 : 17;
    // int targetMinutes = 30;
    final times = PrayerTimeService().getTimes(lat, lng);
    DateTime basePrayerTime = isDay ? times.fajr : times.asr;

// 2. Add exactly 30 minutes
    DateTime notificationTime = basePrayerTime.add(const Duration(minutes: 30));
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, notificationTime.hour, notificationTime.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      isDay ? 1 : 0,
      'أذكاري',
      isDay ? '🌞 حان وقت أذكار الصباح' : '🌙 حان وقت أذكار المساء',
      scheduledDate,
      azkarDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> periodicallyShowNotification() async {
    List<String> adhkarPool = DuaaNotifications.adhkarPool;
    // 1. Define your 4 time slots (Hours: 8am, 12pm, 4pm, 8pm)
    List<int> hours = [8, 12, 16, 20];

    for (int i = 0; i < hours.length; i++) {
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hours[i],
      );

      // If the time has already passed today, move to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        20 + i, // Unique ID for each of the 4 slots (20, 21, 22, 23)
        'أذكاري',
        // This picks a different Adhkar based on the time slot index
        adhkarPool[i % adhkarPool.length],
        scheduledDate,
        azkarDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> schedulePreAdhanReminders() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);

    final now = tz.TZDateTime.now(tz.local);

    for (final entry in AppHelpers.prayerNames.entries) {
      final timeOfDay = effectiveTimes[entry.key];
      if (timeOfDay == null) continue;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      // Subtract 10 minutes
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));

      if (scheduledDate.isBefore(now)) continue;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        200 + entry.key.hashCode, // Unique ID offset
        'استعد للصلاة',
        'بقي ١٠ دقائق على ${entry.value}، حان وقت الوضوء',
        scheduledDate,
        azkarDetails, // Standard sound for reminder
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleQuranReminderAfterSalah() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final now = tz.TZDateTime.now(tz.local);

    int i = 0;
    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      // Add 30 minutes after Salah
      scheduledDate = scheduledDate.add(const Duration(minutes: 30));

      if (scheduledDate.isBefore(now)) continue;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        400 + i++, // Unique ID range 400-404
        'وردك اليومي',
        'حان وقت قراءة وردك من القرآن الكريم',
        scheduledDate,
        azkarDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleProphetBlessings() async {
    final List<int> triggerHours = [10, 14, 17, 21]; // 10am, 2pm, 5pm, 9pm

    for (int i = 0; i < triggerHours.length; i++) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, triggerHours[i]);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        300 + i, // Unique ID range 300-303
        'الصلاة على النبي',
        DuaaNotifications.blessings[i % DuaaNotifications.blessings.length],
        scheduledDate,
        azkarDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationById(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<bool> requestNotificationPermission() async {
    // 1. Check current status
    var status = await Permission.notification.status;

    // 2. If it's permanently denied, we can't show the popup anymore
    if (status.isPermanentlyDenied) {
      // Open app settings so user can manually enable it
      await openAppSettings();
      return false;
    }

    // 3. Request the permission
    status = await Permission.notification.request();

    return status.isGranted;
  }

  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }
}
