import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class SaveQuranPositionUseCase {
  final QuranRepository quranRepository;

  SaveQuranPositionUseCase({required this.quranRepository});

  Future<void> call(int surahNumber, int ayahNumber) async {
    final position = QuranPositionEntity(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    await quranRepository.saveQuranPosition(position);
  }
}
