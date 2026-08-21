import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

mixin NotificationSchedulerMixin {
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin;

  final Map<String, int> notificationIds = const {
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

  NotificationDetails get azkarDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'azkar_channel_v3',
          AppStrings.channelAzkar,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      );

  NotificationDetails get azkarDetailsNoSound => const NotificationDetails(
        android: AndroidNotificationDetails(
          'azkar_channel_no_sound_v4',
          AppStrings.channelAzkar,
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      );

  NotificationDetails get adhanDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel_v5',
          AppStrings.channelAdhan,
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

  void logSchedule(String category, int id, tz.TZDateTime scheduled,
      {String? details}) {
    assert(() {
      debugPrint(
        '[Notification] id=$id | category=$category | '
        'scheduled=${scheduled.toIso8601String()} | tz=${tz.local.name}'
        '${details != null ? ' | $details' : ''}',
      );
      return true;
    }());
  }

  Future<void> safeSchedule({
    required int id,
    required String title,
    required String body,
    String? payload,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      assert(() {
        debugPrint('[Notification] Failed to schedule id=$id: $e');
        return true;
      }());
    }
  }
}
