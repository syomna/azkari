import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class SaveQuranBookmarkUseCase {
  final QuranRepository quranRepository;

  SaveQuranBookmarkUseCase({required this.quranRepository});

  Future<void> call({required int surahNumber, required int pageNumber}) async {
    await quranRepository.saveQuranBookmark(surahNumber, pageNumber);
  }
}
