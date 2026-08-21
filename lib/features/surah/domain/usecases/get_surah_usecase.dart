import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:azkar_app/core/error/failures.dart';

class GetSurahUseCase extends UseCase<List<SurahEntity>, NoParams> {
  final SurahRepository surahRepository;

  GetSurahUseCase({required this.surahRepository});

  @override
  Future<Either<Failure, List<SurahEntity>>> call(NoParams params) async {
    return surahRepository.getSurah();
  }
}
