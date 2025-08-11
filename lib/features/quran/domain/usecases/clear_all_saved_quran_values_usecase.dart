import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';

class ClearAllSavedQuranValuesUseCase {
  final QuranRepository quranRepository;

  ClearAllSavedQuranValuesUseCase({required this.quranRepository});

  Future<void> call() async {
    await quranRepository.clearAllSavedQuranValues();
  }
}
