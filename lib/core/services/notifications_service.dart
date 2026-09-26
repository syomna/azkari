import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:azkar_app/core/constants/duaa_notifications.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  /// Test hook: drops the cached singleton so [init] builds a fresh service
  /// bound to a caller-provided [prefs] next time it is called.
  static void resetForTesting() {
    _instance = null;
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
  }

  /// Prompts for notification (+ exact-alarm) permission on the very first
  /// launch only. Every later launch goes through [toggleAllNotifications] in
  /// the UI, so a returning user isn't nagged with OS dialogs on each cold
  /// start.
  Future<void> requestFirstRunPermissionsIfNeeded() async {
    const key = 'notif_permission_prompted';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    try {
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
      debugPrint('[NotificationService] First-run permission request failed: $e');
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
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  NotificationDetails azkarDetailsNoSound = const NotificationDetails(
    android: AndroidNotificationDetails(
      'azkar_channel_no_sound_v4',
      'الأذكار',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    ),
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

  /// Ensures the local timezone is set before any scheduling call. If the
  /// device timezone name is not present in the bundled `timezone` data
  /// (e.g. an obscure IANA name), returns `false` so the caller can abort
  /// scheduling instead of silently firing at the wrong (UTC) wall-clock time.
  Future<bool> _ensureTimezone() async {
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Timezone resolve failed: $e');
      return false;
    }
  }

  /// Guards every scheduler against an unresolved device timezone: scheduling
  /// with the still-default (UTC) `tz.local` would fire notifications at the
  /// wrong times, so it is better to surface an error than to schedule wrong.
  Future<String?> _guardTimezone() async {
    return await _ensureTimezone()
        ? null
        : 'تعذر تحديد المنطقة الزمنية للجهاز';
  }

  /// The IANA timezone of the selected city, or `null` when relying on the
  /// device's own location (GPS/automatic or no fixed city).
  tz.Location? get _cityTimezone {
    final name = prefs.getString(PrefsKeys.cityTimezone);
    if (name == null) return null;
    try {
      return tz.getLocation(name);
    } catch (_) {
      return null;
    }
  }

  /// Builds a device-local [tz.TZDateTime] for today at a prayer time that is
  /// stored in the selected city's local time.
  ///
  /// When a fixed city is in use, the stored times are expressed in the city's
  /// timezone, so they are first interpreted in the city timezone and then
  /// converted to the device timezone before scheduling. When there is no
  /// fixed city the prayer times are already in the device timezone.
  tz.TZDateTime _deviceDateForPrayer(TimeOfDay timeOfDay,
      {int addMinutes = 0}) {
    final deviceNow = tz.TZDateTime.now(tz.local);
    final cityTz = _cityTimezone;

    tz.TZDateTime scheduled;
    if (cityTz == null) {
      scheduled = tz.TZDateTime(tz.local, deviceNow.year, deviceNow.month,
              deviceNow.day, timeOfDay.hour, timeOfDay.minute)
          .add(Duration(minutes: addMinutes));
    } else {
      // Anchor the "today" day on the CITY calendar, not the device's: the
      // stored times are city-local, so interpret the wall-clock in the city's
      // current date and convert to the device clock. Building from the
      // device's calendar day here misses the city's date whenever the two
      // clocks diverge (e.g. device in LA while Dubai is already Tuesday),
      // yielding an instant in the past that a single +1-day bump cannot fix —
      // which made `zonedSchedule` fire a spurious adhan immediately.
      final cityNow = tz.TZDateTime.now(cityTz);
      scheduled = tz.TZDateTime.from(
        tz.TZDateTime(cityTz, cityNow.year, cityNow.month, cityNow.day,
                timeOfDay.hour, timeOfDay.minute)
            .add(Duration(minutes: addMinutes)),
        tz.local,
      );
    }

    // Schedule the next strictly-future occurrence. Loop instead of a single
    // +1-day bump because a city↔device date divergence can push the anchor
    // more than one day into the past.
    while (scheduled.isBefore(deviceNow)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Parses a stored "HH:mm" custom time into a [TimeOfDay], or `null` when the
  /// raw value is absent, malformed, or out of range (corrupted "25:99").
  TimeOfDay? _parseStoredTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  /// The prayer-derived default for morning (Fajr) / evening (Asr) azkar, or
  /// `null` when that prayer has no effective time to anchor on.
  TimeOfDay? _defaultDayNightTime(bool isDay) {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final key = isDay ? 'fajr' : 'asr';
    return effectiveTimes[key];
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

  /// Schedules one notification, preferring an exact alarm. When the OS
  /// rejects exact alarms (Android 12+ "Alarms & reminders" special access not
  /// granted), it retries with an inexact alarm so the notification still
  /// fires. Returns an error message on failure, null on success.
  Future<String?> _scheduleExact({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    String payload = '',
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode) {
      return flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: mode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      return null;
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') {
        return 'تعذر جدولة الإشعار (خطأ: ${e.code})';
      }
      // Exact alarms are denied on this device — retry inexactly below.
    } catch (e) {
      return 'تعذر جدولة الإشعار';
    }

    debugPrint(
        '[Notification] Exact alarms denied (id=$id); using an inexact alarm.');
    try {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      return null;
    } catch (e) {
      debugPrint('[Notification] Failed to schedule id=$id: $e');
      return 'تعذر جدولة الإشعار';
    }
  }

  /// Opens the Android "Alarms & reminders" settings so the user can grant
  /// exact alarms when notifications are enabled. No-op on other platforms.
  Future<void> requestExactAlarmsPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[NotificationService] Exact alarms request failed: $e');
    }
  }

  Future<String?> schedulePrayerNotifications() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;
    final now = tz.TZDateTime.now(tz.local);

    String? firstError;
    for (final key in AppHelpers.prayerNames.keys) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['prayer_$key']!;

      var scheduledDate = _deviceDateForPrayer(timeOfDay);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('prayer_adhan', id, scheduledDate, details: 'key=$key');

      final error = await _scheduleExact(
        id: id,
        title: 'حان وقت الصلاة',
        body: 'الله أكبر، حان وقت ${AppHelpers.prayerNames[key]}',
        payload: 'prayer_$key',
        scheduledDate: scheduledDate,
        notificationDetails: adhanDetails,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      firstError ??= error;
    }
    return firstError;
  }

  Future<String?> scheduleDayNightNotifications(double lat, double lng,
      {bool isDay = false}) async {
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;
    final now = tz.TZDateTime.now(tz.local);

    // A user-set custom time ("HH:mm", in the device local timezone) wins over
    // the prayer-derived default. When unset, fall back to Fajr+30 (morning)
    // / Asr+30 (evening) in the selected city's local time.
    final customKey =
        isDay ? PrefsKeys.morningAzkarTime : PrefsKeys.eveningAzkarTime;
    final customTime = _parseStoredTime(prefs.getString(customKey));

    tz.TZDateTime scheduledDate;
    // A user-set custom time is stored as a bare wall-clock "HH:mm" that the
    // user picks on the device, so it is inherently expressed on the device
    // clock (not the selected city's clock). Scheduling it directly in
    // [tz.local] fires at exactly the wall-clock time the user picked, which
    // is what the settings stepper commits and what users expect.
    if (customTime != null) {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          customTime.hour, customTime.minute);
    } else {
      final defaultTime = _defaultDayNightTime(isDay);
      if (defaultTime == null) return null;
      scheduledDate = _deviceDateForPrayer(defaultTime, addMinutes: 30);
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final id = isDay
        ? notificationIds['azkar_morning']!
        : notificationIds['azkar_evening']!;
    final label = isDay ? 'morning' : 'evening';

    _logSchedule('day_night_azkar', id, scheduledDate, details: label);

    return _scheduleExact(
      id: id,
      title: 'أذكاري',
      body: isDay ? '🌞 حان وقت أذكار الصباح' : '🌙 حان وقت أذكار المساء',
      payload: isDay ? 'azkar_morning' : 'azkar_evening',
      scheduledDate: scheduledDate,
      notificationDetails: azkarDetails,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<String?> periodicallyShowNotification() async {
    List<String> adhkarPool = DuaaNotifications.adhkarPool;
    List<int> hours = [8, 12, 16, 20];
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;

    String? firstError;
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

      final error = await _scheduleExact(
        id: id,
        title: 'أذكاري',
        body: adhkarPool[i % adhkarPool.length],
        payload: 'periodic_azkar',
        scheduledDate: scheduledDate,
        notificationDetails: azkarDetailsNoSound,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      firstError ??= error;
    }
    return firstError;
  }

  Future<String?> schedulePreAdhanReminders() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;
    final now = tz.TZDateTime.now(tz.local);

    String? firstError;
    for (final entry in AppHelpers.prayerNames.entries) {
      final timeOfDay = effectiveTimes[entry.key];
      if (timeOfDay == null) continue;

      final id = notificationIds['preadhan_${entry.key}']!;

      var scheduledDate =
          _deviceDateForPrayer(timeOfDay).subtract(const Duration(minutes: 10));

      // If this pre-Adhan time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('pre_adhan', id, scheduledDate, details: entry.key);

      final error = await _scheduleExact(
        id: id,
        title: 'استعد للصلاة',
        body: 'بقي ١٠ دقائق على ${entry.value}، حان وقت الوضوء',
        payload: 'preadhan_${entry.key}',
        scheduledDate: scheduledDate,
        notificationDetails: azkarDetails,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      firstError ??= error;
    }
    return firstError;
  }

  Future<String?> scheduleQuranReminderAfterSalah() async {
    final effectiveTimes = prayerService.getEffectiveTimes(prefs);
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;
    final now = tz.TZDateTime.now(tz.local);

    String? firstError;
    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final timeOfDay = effectiveTimes[key];
      if (timeOfDay == null) continue;

      final id = notificationIds['quran_$key']!;

      var scheduledDate = _deviceDateForPrayer(timeOfDay, addMinutes: 30);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _logSchedule('quran_reminder', id, scheduledDate, details: key);

      final error = await _scheduleExact(
        id: id,
        title: 'وردك اليومي',
        body: 'حان وقت قراءة وردك من القرآن الكريم',
        payload: 'quran_reminder',
        scheduledDate: scheduledDate,
        notificationDetails: azkarDetailsNoSound,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      firstError ??= error;
    }
    return firstError;
  }

  Future<String?> scheduleProphetBlessings() async {
    final List<int> triggerHours = [10, 14, 17, 21];
    final timezoneError = await _guardTimezone();
    if (timezoneError != null) return timezoneError;

    String? firstError;
    for (int i = 0; i < triggerHours.length; i++) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, triggerHours[i]);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final id = notificationIds['blessing_${i + 1}']!;

      _logSchedule('prophet_blessing', id, scheduledDate);

      final error = await _scheduleExact(
        id: id,
        title: 'الصلاة على النبي',
        body: DuaaNotifications
            .blessings[i % DuaaNotifications.blessings.length],
        payload: 'prophet_blessing',
        scheduledDate: scheduledDate,
        notificationDetails: azkarDetailsNoSound,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      firstError ??= error;
    }
    return firstError;
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
    if (Platform.isAndroid) {
      final impl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return (await impl?.requestNotificationsPermission()) ?? false;
    }
    // iOS: ask for the flags our notifications actually use.
    final impl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    return (await impl?.requestPermissions(
            alert: true, badge: true, sound: true)) ??
        false;
  }

  Future<bool> isNotificationPermissionGranted() async {
    // Query the notification plugin itself so the check reflects exactly what
    // the OS reports for the app (permission_handler can disagree with the
    // system state, e.g. on iOS Simulator after granting in Settings).
    if (Platform.isAndroid) {
      final impl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return (await impl?.areNotificationsEnabled()) ?? false;
    }
    final impl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final enabled = await impl?.checkPermissions();
    return enabled?.isAlertEnabled ?? enabled?.isEnabled ?? false;
  }
}
