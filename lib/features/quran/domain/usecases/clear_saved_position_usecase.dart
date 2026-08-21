import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';

class ClearSavedPositionUseCase extends UseCase<void, NoParams> {
  final QuranRepository quranRepository;

  ClearSavedPositionUseCase({required this.quranRepository});

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      quranRepository.clearSavedPosition();
}
