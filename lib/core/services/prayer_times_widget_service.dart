import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTimesWidgetService {
  static const _androidWidgetName = 'PrayerTimesWidgetProvider';
  static const _iosWidgetName = 'PrayerTimesWidget';
  static const _appGroupId = 'group.com.yomna.azkarApp';

  static const _widgetTimesJsonKey = 'widget_times_json';

  /// How many calendar days (including today) the multi-day snapshot covers.
  /// With this the widgets stay correct even when the app stays fully closed
  /// for up to two weeks.
  static const widgetDays = 14;

  static const _prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha'
  ];
  static const _arabicNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static Future<void> updateWidget({
    required PrayerTimes? prayerTimes,
    required SharedPreferences prefs,
    double? lat,
    double? lng,
    CalculationMethod? method,
    String? timezone,
  }) async {
    try {
      if (prayerTimes == null) return;

      await HomeWidget.setAppGroupId(_appGroupId);

      for (final key in _prayerKeys) {
        final raw = prefs.getString('${PrefsKeys.prayerOverridePrefix}$key') ??
            prefs.getString('${PrefsKeys.prayerTimePrefix}$key');
        final displayTime = _to12Hour(raw ?? '');
        await HomeWidget.saveWidgetData<String>('prayer_$key', displayTime);
        await HomeWidget.saveWidgetData<String>(
            'prayer_name_$key', _arabicNames[key] ?? key);
      }

      final now = DateTime.now();
      await HomeWidget.saveWidgetData<String>('widget_date',
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
      await HomeWidget.saveWidgetData<String>('hijri_date', _hijriDate(now));
      await HomeWidget.saveWidgetData<String>(
          'gregorian_date', _gregorianDate(now));

      // Rolling multi-day snapshot: lets the widgets keep showing correct
      // times for this day and the next ~13 even while the app is closed.
      final multiDay = buildMultiDayTimes(
        prefs: prefs,
        lat: lat,
        lng: lng,
        method: method,
        timezone: timezone,
      );
      if (multiDay.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
            _widgetTimesJsonKey, jsonEncode(multiDay));
      }

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Builds the rolling multi-day snapshots consumed by the iOS and Android
  /// widgets. Every day gets the effective times (manual override wins over
  /// calculation) plus the hijri/gregorian date labels the platforms can't
  /// compute themselves. Keyed by `yyyy-MM-dd` in the display timezone.
  @visibleForTesting
  static Map<String, Map<String, String>> buildMultiDayTimes({
    required SharedPreferences prefs,
    double? lat,
    double? lng,
    CalculationMethod? method,
    String? timezone,
  }) {
    final la = lat ?? prefs.getDouble(PrefsKeys.latitude);
    final ln = lng ?? prefs.getDouble(PrefsKeys.longitude);
    if (la == null || ln == null) return {};

    final city = _cityFromPrefs(prefs);
    final m = method ?? city?.method;
    final tzName =
        timezone ?? city?.timezone ?? prefs.getString(PrefsKeys.cityTimezone);

    final service = PrayerTimeService();
    final loc = service.displayLocation(tzName);
    final base = tz.TZDateTime.now(loc);

    final map = <String, Map<String, String>>{};
    for (var offset = 0; offset < widgetDays; offset++) {
      final date = tz.TZDateTime(loc, base.year, base.month, base.day + offset);
      final daily = service.dailyTimes(la, ln, date, method: m, timezone: tzName);

      final entry = <String, String>{};
      for (final key in _prayerKeys) {
        final override =
            prefs.getString('${PrefsKeys.prayerOverridePrefix}$key');
        final raw = override ??
            '${daily[key]!.hour}:${daily[key]!.minute}';
        entry[key] = _to12Hour(raw);
      }
      entry['hijri'] = _hijriDate(date);
      entry['gregorian'] = _gregorianDate(date);

      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map[key] = entry;
    }
    return map;
  }

  static AppCity? _cityFromPrefs(SharedPreferences prefs) {
    final storedCityName = prefs.getString(PrefsKeys.cityName);
    if (storedCityName == null) return null;
    for (final c in appCities) {
      if (c.name == storedCityName) return c;
    }
    return null;
  }

  static String _hijriDate(DateTime date) {
    HijriDate.setLocal('ar');
    final hijri = HijriDate.fromDate(date);
    return '${hijri.dayWeName}، ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
  }

  static String _gregorianDate(DateTime date) {
    final day = _getArabicDay(date.weekday);
    final month = _getArabicGregorianMonth(date.month);
    return '$day ${date.day} $month ${date.year}';
  }

  static String _to12Hour(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;
    final isAm = hour < 12;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final suffix = isAm ? 'ص' : 'م';
    return '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }

  static String _getArabicDay(int weekday) {
    const days = [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return days[weekday];
  }

  static String _getArabicGregorianMonth(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month];
  }
}