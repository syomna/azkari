import 'dart:convert';
import 'dart:io';

import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  static const String _kSavedAyahNumberKey = 'latest_ayah_Number_key';
  static const String _kSavedLatestQuranSurahNumberKey =
      'latest_quran_surah_number_key';

  List<QuranPositionModel> _savedQuranPositions = [];

  void _loadPositionsFromPrefs() {
    final List<String>? jsonList =
        sharedPreferences.getStringList(_kSavedAyahNumberKey);
    if (jsonList != null) {
      _savedQuranPositions = jsonList
          .map((jsonString) =>
              QuranPositionModel.fromJson(jsonDecode(jsonString)))
          .toList();
    }
  }

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
  Future<void> saveQuranPosition(QuranPositionModel newPosition) async {
    _loadPositionsFromPrefs();

    final index = _savedQuranPositions.indexWhere(
        (position) => position.surahNumber == newPosition.surahNumber);

    if (index != -1) {
      _savedQuranPositions[index] = newPosition;
    } else {
      _savedQuranPositions.add(newPosition);
    }
    _savedQuranPositions.sort((a, b) => a.surahNumber.compareTo(b.surahNumber));

    final List<String> jsonList = _savedQuranPositions
        .map((position) => jsonEncode(position.toJson()))
        .toList();

    await sharedPreferences.setStringList(_kSavedAyahNumberKey, jsonList);
  }

  @override
  QuranPositionModel getSavedPosition(int surahNumber) {
    _loadPositionsFromPrefs();

    final position = _savedQuranPositions.firstWhere(
      (position) => position.surahNumber == surahNumber,
      orElse: () =>
          QuranPositionModel(surahNumber: surahNumber, ayahNumber: 1),
    );
    return position;
  }

  @override
  Future<void> clearSavedPosition(int surahNumber) async {
    _loadPositionsFromPrefs();
    _savedQuranPositions
        .removeWhere((position) => position.surahNumber == surahNumber);

    final List<String> jsonList = _savedQuranPositions
        .map((position) => jsonEncode(position.toJson()))
        .toList();

    await sharedPreferences.setStringList(_kSavedAyahNumberKey, jsonList);
  }

  @override
  Future<void> clearAllSavedQuranValues() async {
    await sharedPreferences.remove(_kSavedAyahNumberKey);
    await sharedPreferences.remove(_kSavedLatestQuranSurahNumberKey);
    _savedQuranPositions = [];
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
}
