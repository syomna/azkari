import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';

class GetSavedQuranPageNumberUseCase extends UseCase<int?, NoParams> {
  final QuranRepository quranRepository;

  GetSavedQuranPageNumberUseCase({required this.quranRepository});

  @override
  Future<Either<Failure, int?>> call(NoParams params) =>
      quranRepository.getSavedQuranPageNumber();
}
