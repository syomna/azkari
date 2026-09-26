import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetQuranBookmarkPageUseCase {
  final QuranRepository quranRepository;

  GetQuranBookmarkPageUseCase({required this.quranRepository});

  int? call() {
    return quranRepository.getQuranBookmarkPage();
  }
}