import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class CheckSurahDownloadedUseCase {
  final QuranRepository repository;

  CheckSurahDownloadedUseCase(this.repository);

  Future<bool> call(int surahNumber) {
    return repository.isSurahDownloaded(surahNumber);
  }
}