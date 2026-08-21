import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:dartz/dartz.dart';

class SurahRepositoryImpl extends SurahRepository {
  final SurahLocalDataSource surahLocalDataSource;
  SurahRepositoryImpl({required this.surahLocalDataSource});

  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async {
    try {
      final surahModels = await surahLocalDataSource.getSurah();
      return Right(surahModels);
    } catch (e) {
      return Left(JsonParsingFailure(e.toString()));
    }
  }
}
