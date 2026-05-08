import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class GetSavedQuranPageNumberUsecase {
  final QuranRepository quranRepository;

  GetSavedQuranPageNumberUsecase({required this.quranRepository});
  int? call() {
    return quranRepository.getSavedQuranPageNumber();
  }
}