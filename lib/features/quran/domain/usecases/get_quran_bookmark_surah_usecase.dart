import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetQuranBookmarkSurahUseCase {
  final QuranRepository quranRepository;

  GetQuranBookmarkSurahUseCase({required this.quranRepository});

  int? call() {
    return quranRepository.getQuranBookmarkSurah();
  }
}
