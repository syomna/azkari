import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class SaveQuranPageNumberUsecase {
  final QuranRepository quranRepository;

  SaveQuranPageNumberUsecase({required this.quranRepository});

  Future<void> call(int pageNumber) async {
    await quranRepository.saveQuranPageNumber(pageNumber);
  }
}