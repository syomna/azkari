import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class SaveLatestQuranSurahNumberUseCase {
  final QuranRepository quranRepository;

  SaveLatestQuranSurahNumberUseCase({required this.quranRepository});

  Future<void> call(int surahNumber) async {
    await quranRepository.saveLatestQuranSurahNumber(surahNumber);
  }
}