class AppConstants {
  static const String morningAzkarCategory = 'أذكار الصباح';
  static const String eveningAzkarCategory = 'أذكار المساء';
  static const String favoriteCategory = 'المفضلة';
  static const String holyQuran = 'القرآن الكريم';

  static const String shortSurahsTitle = 'سور قصيرة للصلاة';
  static const String surahs = 'السور الكريمة';

  static const String allAzkarPageTitle = 'أذكار و أدعية';
  static const String dayOfZikr = 'ذكر اليوم';
  static const String tasbeh = 'تسبيح';
  static const String mesbaha = 'المسبحة الإلكترونية';
  static const String namesOfAllah = 'أسماء الله الحسنى';
  static const String qibla = 'القبلة';

  // Links
  static const String playStoreURL =
      'https://play.google.com/store/apps/details?id=com.yomna.azkar_app';
  static const String appStoreURL =
      'https://apps.apple.com/eg/app/أذكــــاري-azkari/id6479560831';
}

/// Centralized [SharedPreferences] storage keys used across the app.
class PrefsKeys {
  PrefsKeys._();

  static const String favoriteCategories = 'fav_categories';
  static const String favoriteItems = 'fav_items';

  static const String latitude = 'lat';
  static const String longitude = 'lng';
  static const String cityName = 'city_name';
  static const String cityTimezone = 'city_timezone';
  static const String prayerTimeDate = 'prayer_time_date';

  /// Prefix for stored (calculated) prayer times, e.g. "prayer_time_fajr".
  static const String prayerTimePrefix = 'prayer_time_';

  /// Prefix for manually overridden prayer times, e.g. "prayer_override_fajr".
  static const String prayerOverridePrefix = 'prayer_override_';

  /// Optional custom times (stored as "HH:mm") for morning/evening azkar.
  /// When unset, the app falls back to the prayer-derived default.
  static const String morningAzkarTime = 'azkar_morning_time';
  static const String eveningAzkarTime = 'azkar_evening_time';
}
