import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class ClearSavedPositionUseCase {
  final QuranRepository quranRepository;

  ClearSavedPositionUseCase({required this.quranRepository});

  Future<void> call() async {
    await quranRepository.clearSavedPosition();
  }
}
