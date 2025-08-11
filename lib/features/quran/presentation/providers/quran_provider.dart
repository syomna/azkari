import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_quran_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_position_usecase.dart';
import 'package:flutter/widgets.dart';

class QuranProvider with ChangeNotifier {
  final GetSavedQuranPositionUseCase getSavedPositionUseCase;
  final SaveQuranPositionUseCase savePositionUseCase;
  final ClearQuranPositionUseCase clearPositionUseCase;
  final GetLatestQuranSurahNumberUseCase getLatestSurahNumberUseCase;
  final SaveLatestQuranSurahNumberUseCase saveLatestSurahNumberUseCase;
  final ClearAllSavedQuranValuesUseCase clearAllSavedQuranValuesUsecase;

  QuranProvider(
      {required this.getSavedPositionUseCase,
      required this.savePositionUseCase,
      required this.clearPositionUseCase,
      required this.getLatestSurahNumberUseCase,
      required this.saveLatestSurahNumberUseCase,
      required this.clearAllSavedQuranValuesUsecase});


  int? get savedLatestQuranSurahNumber => getLatestSurahNumberUseCase();

  QuranPositionEntity getSavedPosition(int surahNumber) {
    return getSavedPositionUseCase(surahNumber);
  }

  Future<void> saveQuranPosition(int surahNumber, double currentOffset) async {
    await savePositionUseCase(surahNumber, currentOffset);
    notifyListeners();
  }

  Future<void> clearSavedPosition(int surahNumber) async {
    await clearPositionUseCase(surahNumber);
    notifyListeners();
  }

  Future<void> clearAllSavedQuranValues() async {
    await clearAllSavedQuranValuesUsecase();
    notifyListeners();
  }

  Future<void> saveLatestQuranSurahNumber(int surahNumber) async {
    await saveLatestSurahNumberUseCase(surahNumber);
    notifyListeners();
  }
}
