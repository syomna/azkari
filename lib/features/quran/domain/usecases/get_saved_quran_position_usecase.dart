import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetSavedQuranPositionUseCase {
  final QuranRepository quranRepository;

  GetSavedQuranPositionUseCase({required this.quranRepository});

  QuranPositionEntity call(int surahNumber) {
    return quranRepository.getSavedPosition(surahNumber);
  }
}