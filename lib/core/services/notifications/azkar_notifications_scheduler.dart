import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/constants/duaa_notifications.dart';
import 'package:azkar_app/core/services/notifications/notification_scheduler_mixin.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class AzkarNotificationsScheduler with NotificationSchedulerMixin {
  final FlutterLocalNotificationsPlugin _plugin;
  final PrayerTimeService prayerService;
  final SharedPreferences prefs;

  AzkarNotificationsScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required this.prayerService,
    required this.prefs,
  }) : _plugin = plugin;

  @override
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _plugin;

  Future<void> scheduleDayNightNotifications(double lat, double lng,
      {bool isDay = false}) async {
    final now = tz.TZDateTime.now(tz.local);

    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final prayerKey = isDay ? 'fajr' : 'asr';
    final timeOfDay = effectiveTimes[prayerKey];
    if (timeOfDay == null) return;

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

    logSchedule('day_night_azkar', id, scheduledDate, details: label);

    await safeSchedule(
      id: id,
      title: AppStrings.appName,
      body: isDay
          ? AppStrings.morningAzkarNotification
          : AppStrings.eveningAzkarNotification,
      scheduledDate: scheduledDate,
      details: azkarDetails,
    );
  }

  Future<void> periodicallyShowNotification() async {
    List<String> adhkarPool = DuaaNotifications.adhkarPool;
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

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final id = notificationIds['periodic_${i + 1}']!;

      logSchedule('periodic_azkar', id, scheduledDate);

      await safeSchedule(
        id: id,
        title: AppStrings.appName,
        body: adhkarPool[i % adhkarPool.length],
        scheduledDate: scheduledDate,
        details: azkarDetailsNoSound,
      );
    }
  }

  Future<void> scheduleProphetBlessings() async {
    final List<int> triggerHours = [10, 14, 17, 21];

    for (int i = 0; i < triggerHours.length; i++) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, triggerHours[i]);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final id = notificationIds['blessing_${i + 1}']!;

      logSchedule('prophet_blessing', id, scheduledDate);

      await safeSchedule(
        id: id,
        title: AppStrings.prophetBlessingTitle,
        body: DuaaNotifications
            .blessings[i % DuaaNotifications.blessings.length],
        scheduledDate: scheduledDate,
        details: azkarDetailsNoSound,
      );
    }
  }
}
