import 'dart:io';

import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  static const String _kSavedAyahNumberKey = 'latest_ayah_Number_key';
  static const String _kSavedLatestQuranSurahNumberKey =
      'latest_quran_surah_number_key';
  static const String _kSavedQuranPageNumberKey = 'quran_page_number_key';
  static const String _kBookmarkSurahKey = 'quran_bookmark_surah_key';
  static const String _kBookmarkPageKey = 'quran_bookmark_page_key';

  @override
  Future<void> saveLatestQuranSurahNumber(int surahNumber) async {
    await sharedPreferences.setInt(
        _kSavedLatestQuranSurahNumberKey, surahNumber);
  }

  @override
  int? getLatestQuranSurahNumber() {
    return sharedPreferences.getInt(_kSavedLatestQuranSurahNumberKey);
  }

  @override
  Future<void> clearSavedPosition() async {
    await sharedPreferences.remove(_kSavedLatestQuranSurahNumberKey);
    await sharedPreferences.remove(_kSavedQuranPageNumberKey);
  }

  @override
  Future<void> clearAllSavedQuranValues() async {
    await sharedPreferences.remove(_kSavedAyahNumberKey);
    await sharedPreferences.remove(_kSavedLatestQuranSurahNumberKey);
    await sharedPreferences.remove(_kSavedQuranPageNumberKey);
  }

  @override
  Future<String> getSurahPath(int surahNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/surah_$surahNumber.mp3';
  }

  @override
  Future<bool> isDownloaded(int surahNumber) async {
    final path = await getSurahPath(surahNumber);
    return File(path).exists();
  }

  @override
  int? getSavedQuranPageNumber() {
    return sharedPreferences.getInt(_kSavedQuranPageNumberKey);
  }

  @override
  Future<void> saveQuranPageNumber(int pageNumber) {
    return sharedPreferences.setInt(_kSavedQuranPageNumberKey, pageNumber);
  }

  @override
  Future<void> saveQuranBookmark(int surahNumber, int pageNumber) async {
    await sharedPreferences.setInt(_kBookmarkSurahKey, surahNumber);
    await sharedPreferences.setInt(_kBookmarkPageKey, pageNumber);
  }

  @override
  int? getQuranBookmarkSurah() {
    return sharedPreferences.getInt(_kBookmarkSurahKey);
  }

  @override
  int? getQuranBookmarkPage() {
    return sharedPreferences.getInt(_kBookmarkPageKey);
  }

  @override
  Future<void> clearQuranBookmark() async {
    await sharedPreferences.remove(_kBookmarkSurahKey);
    await sharedPreferences.remove(_kBookmarkPageKey);
  }
}
