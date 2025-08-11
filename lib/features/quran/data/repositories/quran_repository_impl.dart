import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';
import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource quranLocalDataSource;

  QuranRepositoryImpl({required this.quranLocalDataSource});

  @override
  Future<void> saveLatestQuranSurahNumber(int surahNumber) async {
    await quranLocalDataSource.saveLatestQuranSurahNumber(surahNumber);
  }

  @override
  int? getLatestQuranSurahNumber() {
    return quranLocalDataSource.getLatestQuranSurahNumber();
  }

  @override
  Future<void> saveQuranPosition(QuranPositionEntity position) async {
    final quranPositionModel = QuranPositionModel(
      surahNumber: position.surahNumber,
      scrollOffset: position.scrollOffset,
    );
    await quranLocalDataSource.saveQuranPosition(quranPositionModel);
  }

  @override
  QuranPositionEntity getSavedPosition(int surahNumber) {
    final model = quranLocalDataSource.getSavedPosition(surahNumber);
    return QuranPositionEntity(
      surahNumber: model.surahNumber,
      scrollOffset: model.scrollOffset,
    );
  }

  @override
  Future<void> clearSavedPosition(int surahNumber) async {
    await quranLocalDataSource.clearSavedPosition(surahNumber);
  }
  
  @override
  Future<void> clearAllSavedQuranValues() async {
    await quranLocalDataSource.clearAllSavedQuranValues();
  }
}