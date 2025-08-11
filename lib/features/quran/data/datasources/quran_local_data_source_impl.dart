import 'dart:convert';

import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  static const String _kSavedQuranPositionsKey = 'quran_positions_key';
  static const String _kSavedLatestQuranSurahNumberKey =
      'latest_quran_surah_number_key';

  List<QuranPositionModel> _savedQuranPositions = [];

  void _loadPositionsFromPrefs() {
    final List<String>? jsonList =
        sharedPreferences.getStringList(_kSavedQuranPositionsKey);
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

    await sharedPreferences.setStringList(_kSavedQuranPositionsKey, jsonList);
  }

  @override
  QuranPositionModel getSavedPosition(int surahNumber) {
    _loadPositionsFromPrefs();

    final position = _savedQuranPositions.firstWhere(
      (position) => position.surahNumber == surahNumber,
      orElse: () =>
          QuranPositionModel(surahNumber: surahNumber, scrollOffset: 0.0),
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

    await sharedPreferences.setStringList(_kSavedQuranPositionsKey, jsonList);
  }

  @override
  Future<void> clearAllSavedQuranValues() async {
    await sharedPreferences.remove(_kSavedQuranPositionsKey);
    await sharedPreferences.remove(_kSavedLatestQuranSurahNumberKey);
    _savedQuranPositions = [];
  }
}
