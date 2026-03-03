import 'dart:async';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/constants/duaa_notifications.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initNotification() async {
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

  Future<void> schedulePrayerNotifications(double lat, double lng) async {
    final prayerService = PrayerTimeService();
    final times = prayerService.getTimes(lat, lng);

    // // Map of prayer names for the notification body
    Map<Prayer, String> prayerNames = {
      Prayer.fajr: 'صلاة الفجر',
      Prayer.dhuhr: 'صلاة الظهر',
      Prayer.asr: 'صلاة العصر',
      Prayer.maghrib: 'صلاة المغرب',
      Prayer.isha: 'صلاة العشاء',
    };

    for (var prayer in prayerNames.keys) {
      // 1. Get the specific time for this prayer
      final DateTime prayerTime = times.timeForPrayer(prayer)!;

      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      // 2. Convert to TZDateTime for zonedSchedule
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(prayerTime, tz.local);

      // 3. Only schedule if it's in the future
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          100 + prayer.index, // Unique IDs 100-105
          'حان وقت الصلاة',
          'الله أكبر، حان وقت ${prayerNames[prayer]}',
          scheduledDate,
          adhanDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> testRepeatingZoned() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Start 5 seconds from now
    final tz.TZDateTime firstTick = now.add(const Duration(minutes: 5));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      123,
      'تذكير الصلاة',
      'هذا الإشعار سيتكرر كل دقيقة',
      firstTick,
      adhanDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // This tells the OS to repeat every time the "seconds" match
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleNotifications(double lat, double lng,
      {bool isDay = false}) async {
    testRepeatingZoned();
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

  Future<void> periodicallyShowDailyReminder() async {
    await flutterLocalNotificationsPlugin.periodicallyShow(30, 'تذكير يومي',
        'لا تنسى وردك اليومي', RepeatInterval.daily, azkarDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
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
