import 'dart:io';

import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource quranLocalDataSource;
  final Dio _dio;

  QuranRepositoryImpl({required this.quranLocalDataSource, required Dio dio})
      : _dio = dio;

  @override
  Future<Either<Failure, void>> saveLatestQuranSurahNumber(
      int surahNumber) async {
    try {
      await quranLocalDataSource.saveLatestQuranSurahNumber(surahNumber);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> getLatestQuranSurahNumber() async {
    try {
      return Right(quranLocalDataSource.getLatestQuranSurahNumber());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearSavedPosition() async {
    try {
      await quranLocalDataSource.clearSavedPosition();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllSavedQuranValues() async {
    try {
      await quranLocalDataSource.clearAllSavedQuranValues();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> downloadSurah(
      String url, String savePath) async {
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
      await moveTempFile(tempPath, savePath);
      return const Right(null);
    } on DioException catch (e) {
      await _deleteTempFile(tempPath);
      if (e.type == DioExceptionType.connectionTimeout) {
        return Left(NetworkFailure(e.message ?? 'Connection timeout'));
      } else if (e.type == DioExceptionType.badResponse) {
        return Left(ServerFailure(e.message ?? 'Bad response'));
      }
      return Left(ServerFailure(e.message ?? 'Download failed'));
    } catch (e) {
      await _deleteTempFile(tempPath);
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> moveTempFile(String from, String to) async {
    await File(from).rename(to);
  }

  Future<void> _deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<Either<Failure, String>> getSurahPath(int surahNumber) async {
    try {
      return Right(await quranLocalDataSource.getSurahPath(surahNumber));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSurahDownloaded(int surahNumber) async {
    try {
      return Right(await quranLocalDataSource.isDownloaded(surahNumber));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> getSavedQuranPageNumber() async {
    try {
      return Right(quranLocalDataSource.getSavedQuranPageNumber());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveQuranPageNumber(int pageNumber) async {
    try {
      await quranLocalDataSource.saveQuranPageNumber(pageNumber);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
