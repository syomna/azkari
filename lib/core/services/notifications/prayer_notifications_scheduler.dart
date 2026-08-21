import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/services/notifications/notification_scheduler_mixin.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationsScheduler with NotificationSchedulerMixin {
  final FlutterLocalNotificationsPlugin _plugin;
  final PrayerTimeService prayerService;
  final SharedPreferences prefs;

  PrayerNotificationsScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required this.prayerService,
    required this.prefs,
  }) : _plugin = plugin;

  @override
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _plugin;

  Future<void> schedulePrayerNotifications() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final now = tz.TZDateTime.now(tz.local);

    for (final key in AppHelpers.prayerNames.keys) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['prayer_$key'];
      if (id == null) continue;

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

      logSchedule('prayer_adhan', id, scheduledDate, details: 'key=$key');

      await safeSchedule(
        id: id,
        title: AppStrings.prayerTimeNotificationTitle,
        body: '${AppStrings.prayerTimeNotificationBody} ${AppHelpers.prayerNames[key]}',
        payload: 'prayer_$key',
        scheduledDate: scheduledDate,
        details: adhanDetails,
      );
    }
  }

  Future<void> schedulePreAdhanReminders() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final now = tz.TZDateTime.now(tz.local);

    for (final entry in AppHelpers.prayerNames.entries) {
      final timeOfDay = effectiveTimes[entry.key];
      if (timeOfDay == null) continue;

      final id = notificationIds['preadhan_${entry.key}'];
      if (id == null) continue;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      logSchedule('pre_adhan', id, scheduledDate, details: entry.key);

      await safeSchedule(
        id: id,
        title: AppStrings.preAdhanTitle,
        body: '${AppStrings.preAdhanBody} ${entry.value}${AppStrings.preAdhanBodySuffix}',
        scheduledDate: scheduledDate,
        details: azkarDetails,
      );
    }
  }

  Future<void> scheduleQuranReminderAfterSalah() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final now = tz.TZDateTime.now(tz.local);

    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['quran_$key'];
      if (id == null) continue;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          timeOfDay.hour, timeOfDay.minute);

      scheduledDate = scheduledDate.add(const Duration(minutes: 30));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      logSchedule('quran_reminder', id, scheduledDate, details: key);

      await safeSchedule(
        id: id,
        title: AppStrings.dailyPortion,
        body: AppStrings.dailyPortionBody,
        scheduledDate: scheduledDate,
        details: azkarDetailsNoSound,
      );
    }
  }
}
