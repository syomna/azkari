import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';
import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dio/dio.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource quranLocalDataSource;
  final Dio _dio;

  QuranRepositoryImpl({required this.quranLocalDataSource, required Dio dio})
      : _dio = dio;

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
      ayahNumber: position.ayahNumber,
    );
    await quranLocalDataSource.saveQuranPosition(quranPositionModel);
  }

  @override
  QuranPositionEntity getSavedPosition(int surahNumber) {
    final model = quranLocalDataSource.getSavedPosition(surahNumber);
    return QuranPositionEntity(
      surahNumber: model.surahNumber,
      ayahNumber: model.ayahNumber,
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

  @override
  Future<void> downloadSurah(String url, String savePath) async {
    await _dio.download(
      url,
      savePath,
      // onReceiveProgress: (received, total) {
      //   log('received: $received, total: $total');
      //   if (total > 0) {
      //     final double progress = received / total;
      //     onProgress(progress);
      //   } else {
      //     // If server doesn't provide total size,
      //     // send a dummy "loading" value like 0.01
      //     onProgress(0.01);
      //   }
      // },
    );
  }

  @override
  Future<String> getSurahPath(int surahNumber) {
    return quranLocalDataSource.getSurahPath(surahNumber);
  }

  @override
  Future<bool> isSurahDownloaded(int surahNumber) {
    return quranLocalDataSource.isDownloaded(surahNumber);
  }
}
