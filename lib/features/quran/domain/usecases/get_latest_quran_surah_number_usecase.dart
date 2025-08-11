import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetLatestQuranSurahNumberUseCase {
  final QuranRepository quranRepository;

  GetLatestQuranSurahNumberUseCase({required this.quranRepository});

  int? call() {
    return quranRepository.getLatestQuranSurahNumber();
  }
}