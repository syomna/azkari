import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:dartz/dartz.dart';

class GetSurahUseCase {
  final SurahRepository surahRepository;
  GetSurahUseCase({required this.surahRepository});
  Future<Either<Failure, List<SurahEntity>>> call() async {
    return surahRepository.getSurah();
  }
}
