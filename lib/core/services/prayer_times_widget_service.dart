import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesWidgetService {
  static const _androidWidgetName = 'PrayerTimesWidgetProvider';
  static const _iosWidgetName = 'PrayerTimesWidget';
  static const _appGroupId = 'group.com.yomna.azkarApp';

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
  }) async {
    try {
      if (prayerTimes == null) return;

      await HomeWidget.setAppGroupId(_appGroupId);

      for (final key in _prayerKeys) {
        final raw = prefs.getString('prayer_override_$key') ??
            prefs.getString('prayer_time_$key');
        final displayTime = _to12Hour(raw ?? '');
        await HomeWidget.saveWidgetData<String>('prayer_$key', displayTime);
        await HomeWidget.saveWidgetData<String>(
            'prayer_name_$key', _arabicNames[key] ?? key);
      }

      final now = DateTime.now();
      await HomeWidget.saveWidgetData<String>('widget_date',
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');

      HijriDate.setLocal('ar');
      final hijri = HijriDate.fromDate(now);
      final hijriDate =
          '${hijri.dayWeName}، ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDate);

      final gregorianDay = _getArabicDay(now.weekday);
      final gregorianMonth = _getArabicGregorianMonth(now.month);
      final gregorianDate =
          '$gregorianDay ${now.day} $gregorianMonth ${now.year}';
      await HomeWidget.saveWidgetData<String>('gregorian_date', gregorianDate);

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
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
