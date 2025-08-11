import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';

abstract class QuranLocalDataSource {
  Future<void> saveLatestQuranSurahNumber(int surahNumber);
  int? getLatestQuranSurahNumber();
  Future<void> saveQuranPosition(QuranPositionModel position);
  QuranPositionModel getSavedPosition(int surahNumber);
  Future<void> clearSavedPosition(int surahNumber);
  Future<void> clearAllSavedQuranValues();
}
