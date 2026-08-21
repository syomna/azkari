import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';

class CheckSurahDownloadedUseCase extends UseCase<bool, int> {
  final QuranRepository repository;

  CheckSurahDownloadedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(int params) =>
      repository.isSurahDownloaded(params);
}
