import 'dart:async';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_saved_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_page_number_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

class QuranProvider with ChangeNotifier {
  final GetSavedQuranPageNumberUseCase getQuranPageNumberUseCase;
  final SaveQuranPageNumberUseCase saveQuranPageNumberUseCase;
  final GetLatestQuranSurahNumberUseCase getLatestSurahNumberUseCase;
  final SaveLatestQuranSurahNumberUseCase saveLatestSurahNumberUseCase;
  final ClearAllSavedQuranValuesUseCase clearAllSavedQuranValuesUseCase;
  final ClearSavedPositionUseCase clearSavedPositionUseCase;
  final GetSurahAudioUseCase getSurahAudioUseCase;
  final CheckSurahDownloadedUseCase checkSurahDownloadedUseCase;

  QuranProvider(
      {required this.getQuranPageNumberUseCase,
      required this.saveQuranPageNumberUseCase,
      required this.getLatestSurahNumberUseCase,
      required this.saveLatestSurahNumberUseCase,
      required this.clearAllSavedQuranValuesUseCase,
      required this.clearSavedPositionUseCase,
      required this.getSurahAudioUseCase,
      required this.checkSurahDownloadedUseCase}) {
    _playerSubscription = _player.playbackEventStream.listen(
      (event) => notifyListeners(),
      onError: (Object e, StackTrace st) {
        _isDownloading = false;
        _errorMessage = AppStrings.audioError;
        notifyListeners();
      },
    );
    loadSavedPositions();
  }

  late final StreamSubscription<PlaybackEvent> _playerSubscription;

  @override
  void dispose() {
    _playerSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  int? _savedLatestQuranSurahNumber;
  int? _savedLatestQuranPageNumber;

  int? get savedLatestQuranSurahNumber => _savedLatestQuranSurahNumber;
  int? get savedLatestQuranPageNumber => _savedLatestQuranPageNumber;

  Future<void> loadSavedPositions() async {
    final surahResult = await getLatestSurahNumberUseCase(const NoParams());
    surahResult.fold(
      (_) {},
      (value) => _savedLatestQuranSurahNumber = value,
    );
    final pageResult = await getQuranPageNumberUseCase(const NoParams());
    pageResult.fold(
      (_) {},
      (value) => _savedLatestQuranPageNumber = value,
    );
    notifyListeners();
  }

  Future<void> saveQuranPageNumber(int pageNumber) async {
    final result = await saveQuranPageNumberUseCase(pageNumber);
    result.fold(
      (_) {},
      (_) => _savedLatestQuranPageNumber = pageNumber,
    );
    notifyListeners();
  }

  Future<void> clearAllSavedQuranValues() async {
    final result = await clearAllSavedQuranValuesUseCase(const NoParams());
    result.fold(
      (_) {},
      (_) {
        _savedLatestQuranSurahNumber = null;
        _savedLatestQuranPageNumber = null;
      },
    );
    notifyListeners();
  }

  Future<void> clearSavedPosition() async {
    final result = await clearSavedPositionUseCase(const NoParams());
    result.fold(
      (_) {},
      (_) {
        _savedLatestQuranSurahNumber = null;
        _savedLatestQuranPageNumber = null;
      },
    );
    notifyListeners();
  }

  Future<void> saveLatestQuranSurahNumber(int surahNumber) async {
    final result = await saveLatestSurahNumberUseCase(surahNumber);
    result.fold(
      (_) {},
      (_) => _savedLatestQuranSurahNumber = surahNumber,
    );
    notifyListeners();
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  bool get isActuallyPlaying => _player.playing;

  int? _currentPlayingSurah;
  int? get currentPlayingSurah => _currentPlayingSurah;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleAudio(int surahNumber, String url) async {
    _errorMessage = null;
    _currentPlayingSurah = surahNumber;

    final bool isSameSurah =
        _player.audioSource != null && _currentPlayingSurah == surahNumber;

    if (isSameSurah && _player.playing) {
      await _player.pause();
      notifyListeners();
      return;
    }

    if (isSameSurah &&
        !(_player.playing) &&
        _player.processingState == ProcessingState.ready) {
      await _player.play();
      notifyListeners();
      return;
    }

    try {
      final checkResult =
          await checkSurahDownloadedUseCase(surahNumber);
      final bool alreadyExists = checkResult.fold(
        (_) => false,
        (downloaded) => downloaded,
      );

      if (!alreadyExists) {
        _isDownloading = true;
        notifyListeners();
      }

      final audioResult = await getSurahAudioUseCase(
        SurahAudioParams(surahNumber: surahNumber, url: url),
      );

      final String path = audioResult.fold(
        (failure) => throw Exception(failure.message),
        (path) => path,
      );

      _isDownloading = false;
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      _isDownloading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void resetAudio() {
    _player.stop();
    _player.seek(Duration.zero);

    _isDownloading = false;
    _currentPlayingSurah = null;

    notifyListeners();
  }

  void pauseForNotification() {
    if (_player.playing) {
      _player.pause();
      notifyListeners();
    }
  }
}
