import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetSurahAudioUseCase {
  final QuranRepository repository;

  GetSurahAudioUseCase(this.repository);

  Future<String> call({
    required int surahNumber,
    required String url,
  }) async {
    final path = await repository.getSurahPath(surahNumber);
    final exists = await repository.isSurahDownloaded(surahNumber);

    if (!exists) {
      await repository.downloadSurah(url, path);
    }
    return path;
  }
}
