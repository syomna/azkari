import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SurahRepository {
  Future<Either<Failure, List<SurahEntity>>> getSurah();
}
