import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class ClearQuranPositionUseCase {
  final QuranRepository quranRepository;

  ClearQuranPositionUseCase({required this.quranRepository});

  Future<void> call(int surahNumber) async {
    await quranRepository.clearSavedPosition(surahNumber);
  }
}