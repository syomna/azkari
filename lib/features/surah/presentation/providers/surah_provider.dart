import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:flutter/material.dart';

class SurahProvider extends ChangeNotifier {
  final GetSurahUseCase getSurahUseCase;
  SurahProvider({required this.getSurahUseCase});

// Surah
  List<SurahEntity> _surahList = [];
  AppLoadingStatus _surahStatus = AppLoadingStatus.initial;
  String? _surahErrorMessage;
  List<SurahEntity> get surahList => _surahList;
  AppLoadingStatus get surahStatus => _surahStatus;
  String? get surahErrorMessage => _surahErrorMessage;

  Future<void> loadSurah() async {
    if (_surahStatus == AppLoadingStatus.loading) {
      // Prevent multiple concurrent calls if already loading
      return;
    }
    _surahStatus = AppLoadingStatus.loading;
    _surahErrorMessage = null;
    final result = await getSurahUseCase();
    result.fold((failure) {
      _surahStatus = AppLoadingStatus.error;
      _surahErrorMessage = failure.message;
      _surahList = [];
      notifyListeners();
    }, (surahList) {
      _surahStatus = AppLoadingStatus.loaded;
      _surahList = surahList;
      notifyListeners();
    });
  }
}
