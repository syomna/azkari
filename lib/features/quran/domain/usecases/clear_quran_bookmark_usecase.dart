import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class ClearQuranBookmarkUseCase {
  final QuranRepository quranRepository;

  ClearQuranBookmarkUseCase({required this.quranRepository});

  Future<void> call() async {
    await quranRepository.clearQuranBookmark();
  }
}
