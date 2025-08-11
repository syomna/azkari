import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';

abstract class QuranRepository {
  Future<void> saveLatestQuranSurahNumber(int surahNumber);
  int? getLatestQuranSurahNumber();
  Future<void> saveQuranPosition(QuranPositionEntity position);
  QuranPositionEntity getSavedPosition(int surahNumber);
  Future<void> clearSavedPosition(int surahNumber);
  Future<void> clearAllSavedQuranValues();
}
