import 'dart:convert';

import 'package:azkar_app/core/models/city.dart';
import 'package:flutter/services.dart';

class CityService {
  CityService._();

  static const _citiesAsset = 'assets/data/world_cities.json';
  static const _countriesAsset = 'assets/data/world_countries.json';

  static const int maxSearchResults = 120;

  static const List<String> arabCountryCodes = [
    'SA', 'YE', 'EG', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'LB',
    'SY', 'IQ', 'PS', 'MA', 'DZ', 'TN', 'LY', 'SD', 'MR', 'DJ',
    'KM', 'SO',
  ];

  static const Map<String, String> arabCountryNames = {
    'SA': 'السعودية',
    'YE': 'اليمن',
    'EG': 'مصر',
    'AE': 'الإمارات',
    'KW': 'الكويت',
    'QA': 'قطر',
    'BH': 'البحرين',
    'OM': 'عُمان',
    'JO': 'الأردن',
    'LB': 'لبنان',
    'SY': 'سوريا',
    'IQ': 'العراق',
    'PS': 'فلسطين',
    'MA': 'المغرب',
    'DZ': 'الجزائر',
    'TN': 'تونس',
    'LY': 'ليبيا',
    'SD': 'السودان',
    'MR': 'موريتانيا',
    'DJ': 'جيبوتي',
    'KM': 'جزر القمر',
    'SO': 'الصومال',
  };

  static bool isArabCountry(String countryCode) =>
      arabCountryCodes.contains(countryCode);

  static Future<List<City>>? _citiesFuture;
  static Map<String, String>? _countryNames;

  static Future<List<City>> loadCities() {
    return _citiesFuture ??= rootBundle.loadString(_citiesAsset).then((raw) {
      final rows = json.decode(raw) as List;
      return rows.map<City>((row) => City.fromList(row as List)).toList();
    });
  }

  static Future<Map<String, String>> loadCountryNames() async {
    if (_countryNames != null) return _countryNames!;
    final raw = await rootBundle.loadString(_countriesAsset);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return _countryNames =
        decoded.map((key, value) => MapEntry(key, value as String));
  }

  /// Returns [arabCount] — the number of Arab cities at the start of the
  /// loaded list, used to build section headers in pickers.
  static int arabCitiesCount(List<City> cities) {
    var count = 0;
    for (final city in cities) {
      if (!isArabCountry(city.countryCode)) break;
      count++;
    }
    return count;
  }

  static String normalize(String input) {
    var result = input.toLowerCase().trim();
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
    const replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
      'ؤ': 'و',
      'ئ': 'ي',
    };
    result = result.split('').map((ch) => replacements[ch] ?? ch).join();
    return result;
  }

  static List<City> search(List<City> cities, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return cities;

    final matches = <City>[];
    for (final city in cities) {
      final name = normalize(city.name);
      final arabicName = normalize(city.arabicName);
      if (name.contains(normalizedQuery) ||
          arabicName.contains(normalizedQuery)) {
        matches.add(city);
        if (matches.length >= maxSearchResults) break;
      }
    }
    return matches;
  }

  static Future<String> countryDisplayName(String countryCode) async {
    final arabicName = arabCountryNames[countryCode];
    if (arabicName != null) return arabicName;
    final names = await loadCountryNames();
    return names[countryCode] ?? countryCode;
  }
}
