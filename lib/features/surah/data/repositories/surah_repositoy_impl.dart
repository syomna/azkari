import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source.dart';
import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:dartz/dartz.dart';

class SurahRepositoyImpl extends SurahRepository {
  SurahLocalDataSource surahLocalDataSource;
  SurahRepositoyImpl({required this.surahLocalDataSource});
  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async {
    Either<Failure, List<SurahModel>> result =
        await surahLocalDataSource.getSurah();
    return result.fold(
        (failure) => Left(failure), (surahModels) => Right(surahModels));
  }
}
