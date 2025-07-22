import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:dartz/dartz.dart';

abstract class SurahLocalDataSource {
  Future<Either<Failure, List<SurahModel>>> getSurah();
}
