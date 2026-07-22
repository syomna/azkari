import 'dart:io';

import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
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
  Future<void> clearSavedPosition() async {
    await quranLocalDataSource.clearSavedPosition();
  }

  @override
  Future<void> clearAllSavedQuranValues() async {
    await quranLocalDataSource.clearAllSavedQuranValues();
  }

  @override
  Future<void> downloadSurah(String url, String savePath) async {
    final tempPath = '$savePath.tmp';
    try {
      await _dio.download(
        url,
        tempPath,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      await File(tempPath).rename(savePath);
    } on DioException catch (e) {
      await _deleteTempFile(tempPath);
      String errorMessage = 'حدث خطأ أثناء التحميل';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال، تحقق من الشبكة';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = 'الملف غير موجود على الخادم';
      }
      throw errorMessage;
    } catch (e) {
      await _deleteTempFile(tempPath);
      throw 'فشل التحميل، تأكد من وجود مساحة كافية';
    }
  }

  Future<void> _deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<String> getSurahPath(int surahNumber) {
    return quranLocalDataSource.getSurahPath(surahNumber);
  }

  @override
  Future<bool> isSurahDownloaded(int surahNumber) {
    return quranLocalDataSource.isDownloaded(surahNumber);
  }

  @override
  int? getSavedQuranPageNumber() {
    return quranLocalDataSource.getSavedQuranPageNumber();
  }

  @override
  Future<void> saveQuranPageNumber(int pageNumber) async {
    await quranLocalDataSource.saveQuranPageNumber(pageNumber);
  }
}
