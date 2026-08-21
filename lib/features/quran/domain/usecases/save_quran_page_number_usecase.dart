import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';

class SaveQuranPageNumberUseCase extends UseCase<void, int> {
  final QuranRepository quranRepository;

  SaveQuranPageNumberUseCase({required this.quranRepository});

  @override
  Future<Either<Failure, void>> call(int params) =>
      quranRepository.saveQuranPageNumber(params);
}
