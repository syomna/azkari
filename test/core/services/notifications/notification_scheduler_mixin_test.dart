import 'package:azkar_app/core/services/notifications/notification_scheduler_mixin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TestScheduler with NotificationSchedulerMixin {
  final FlutterLocalNotificationsPlugin _plugin;

  TestScheduler(this._plugin);

  @override
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _plugin;
}

void main() {
  late TestScheduler scheduler;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    scheduler = TestScheduler(FlutterLocalNotificationsPlugin());
  });

  group('NotificationSchedulerMixin', () {
    test('notificationIds contains all expected keys', () {
      expect(scheduler.notificationIds, contains('prayer_fajr'));
      expect(scheduler.notificationIds, contains('prayer_dhuhr'));
      expect(scheduler.notificationIds, contains('prayer_asr'));
      expect(scheduler.notificationIds, contains('prayer_maghrib'));
      expect(scheduler.notificationIds, contains('prayer_isha'));
      expect(scheduler.notificationIds, contains('azkar_morning'));
      expect(scheduler.notificationIds, contains('azkar_evening'));
      expect(scheduler.notificationIds, contains('periodic_1'));
      expect(scheduler.notificationIds, contains('periodic_4'));
      expect(scheduler.notificationIds, contains('preadhan_fajr'));
      expect(scheduler.notificationIds, contains('preadhan_isha'));
      expect(scheduler.notificationIds, contains('quran_fajr'));
      expect(scheduler.notificationIds, contains('quran_isha'));
      expect(scheduler.notificationIds, contains('blessing_1'));
      expect(scheduler.notificationIds, contains('blessing_4'));
    });

    test('prayer IDs are in 100-104 range', () {
      expect(scheduler.notificationIds['prayer_fajr'], 100);
      expect(scheduler.notificationIds['prayer_isha'], 104);
    });

    test('azkar morning/evening IDs are 10 and 11', () {
      expect(scheduler.notificationIds['azkar_morning'], 10);
      expect(scheduler.notificationIds['azkar_evening'], 11);
    });

    test('periodic IDs are in 20-23 range', () {
      expect(scheduler.notificationIds['periodic_1'], 20);
      expect(scheduler.notificationIds['periodic_4'], 23);
    });

    test('preadhan IDs are in 200-204 range', () {
      expect(scheduler.notificationIds['preadhan_fajr'], 200);
      expect(scheduler.notificationIds['preadhan_isha'], 204);
    });

    test('quran IDs are in 300-304 range', () {
      expect(scheduler.notificationIds['quran_fajr'], 300);
      expect(scheduler.notificationIds['quran_isha'], 304);
    });

    test('blessing IDs are in 400-403 range', () {
      expect(scheduler.notificationIds['blessing_1'], 400);
      expect(scheduler.notificationIds['blessing_4'], 403);
    });

    test('notification IDs have no collisions', () {
      final allIds = scheduler.notificationIds.values.toList();
      final uniqueIds = allIds.toSet();
      expect(allIds.length, uniqueIds.length,
          reason: 'All notification IDs should be unique');
    });

    test('azkarDetails has correct channel', () {
      final details = scheduler.azkarDetails;
      expect(details, isNotNull);
    });

    test('azkarDetailsNoSound has correct channel', () {
      final details = scheduler.azkarDetailsNoSound;
      expect(details, isNotNull);
    });

    test('adhanDetails has correct channel', () {
      final details = scheduler.adhanDetails;
      expect(details, isNotNull);
    });

    test('logSchedule does not throw', () {
      final now = tz.TZDateTime.now(tz.local);
      expect(
        () => scheduler.logSchedule('test', 1, now, details: 'debug'),
        returnsNormally,
      );
    });
  });
}
