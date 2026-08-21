import 'package:azkar_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class QuranRepository {
  Future<Either<Failure, void>> saveLatestQuranSurahNumber(int surahNumber);
  Future<Either<Failure, int?>> getLatestQuranSurahNumber();
  Future<Either<Failure, void>> saveQuranPageNumber(int pageNumber);
  Future<Either<Failure, int?>> getSavedQuranPageNumber();
  Future<Either<Failure, void>> clearSavedPosition();
  Future<Either<Failure, void>> clearAllSavedQuranValues();
  Future<Either<Failure, void>> downloadSurah(String url, String savePath);
  Future<Either<Failure, String>> getSurahPath(int surahNumber);
  Future<Either<Failure, bool>> isSurahDownloaded(int surahNumber);
}
