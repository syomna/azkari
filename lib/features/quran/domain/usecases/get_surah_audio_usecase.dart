import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:dartz/dartz.dart';

import 'package:azkar_app/core/error/failures.dart';

class GetSurahAudioUseCase extends UseCase<String, SurahAudioParams> {
  final QuranRepository repository;

  GetSurahAudioUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(SurahAudioParams params) async {
    final pathResult = await repository.getSurahPath(params.surahNumber);
    return pathResult.fold(
      (failure) => Left(failure),
      (path) async {
        final existsResult =
            await repository.isSurahDownloaded(params.surahNumber);
        return existsResult.fold(
          (failure) => Left(failure),
          (exists) async {
            if (!exists) {
              final downloadResult =
                  await repository.downloadSurah(params.url, path);
              return downloadResult.fold(
                (failure) => Left(failure),
                (_) => Right(path),
              );
            }
            return Right(path);
          },
        );
      },
    );
  }
}

class SurahAudioParams {
  final int surahNumber;
  final String url;

  const SurahAudioParams({required this.surahNumber, required this.url});
}
