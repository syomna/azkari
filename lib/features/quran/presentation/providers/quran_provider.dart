import 'dart:async';

import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_saved_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_page_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_surah_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_page_number_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

class QuranProvider with ChangeNotifier {
  final GetSavedQuranPageNumberUsecase getQuranPageNumberUseCase;
  final SaveQuranPageNumberUsecase saveQuranPageNumberUseCase;
  final GetLatestQuranSurahNumberUseCase getLatestSurahNumberUseCase;
  final SaveLatestQuranSurahNumberUseCase saveLatestSurahNumberUseCase;
  final ClearAllSavedQuranValuesUseCase clearAllSavedQuranValuesUsecase;
  final ClearSavedPositionUseCase clearSavedPositionUseCase;
  final GetSurahAudioUseCase getSurahAudioUseCase;
  final CheckSurahDownloadedUseCase checkSurahDownloadedUseCase;
  final SaveQuranBookmarkUseCase saveQuranBookmarkUseCase;
  final GetQuranBookmarkSurahUseCase getQuranBookmarkSurahUseCase;
  final GetQuranBookmarkPageUseCase getQuranBookmarkPageUseCase;
  final ClearQuranBookmarkUseCase clearQuranBookmarkUseCase;

  QuranProvider(
      {required this.getQuranPageNumberUseCase,
      required this.saveQuranPageNumberUseCase,
      required this.getLatestSurahNumberUseCase,
      required this.saveLatestSurahNumberUseCase,
      required this.clearAllSavedQuranValuesUsecase,
      required this.clearSavedPositionUseCase,
      required this.getSurahAudioUseCase,
      required this.checkSurahDownloadedUseCase,
      required this.saveQuranBookmarkUseCase,
      required this.getQuranBookmarkSurahUseCase,
      required this.getQuranBookmarkPageUseCase,
      required this.clearQuranBookmarkUseCase}) {
    _playerSubscription = _player.playbackEventStream.listen(
      (event) => notifyListeners(),
      onError: (Object e, StackTrace st) {
        _isDownloading = false;
        _errorMessage = 'حدث خطأ في مشغل الصوت';
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<PlaybackEvent> _playerSubscription;

  @override
  void dispose() {
    _playerSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  int? get savedLatestQuranSurahNumber => getLatestSurahNumberUseCase();
  int? get savedLatestQuranPageNumber => getQuranPageNumberUseCase();

  // The user's explicit bookmark is kept SEPARATE from the auto-resume
  // position (which is re-saved on every page turn): bookmarking must not be
  // silently overwritten by simply flipping pages.
  int? get bookmarkSurah => getQuranBookmarkSurahUseCase();
  int? get bookmarkPage => getQuranBookmarkPageUseCase();

  // QuranPositionEntity getSavedPosition(int surahNumber) {
  //   return getSavedPositionUseCase(surahNumber);
  // }

  // Future<void> saveQuranPosition(int surahNumber, int ayahNumber) async {
  //   await savePositionUseCase(surahNumber, ayahNumber);
  //   notifyListeners();
  // }
  Future<void> saveQuranPageNumber(int pageNumber) async {
    await saveQuranPageNumberUseCase(pageNumber);
    notifyListeners();
  }

  // Future<void> clearSavedPosition(int surahNumber) async {
  //   await clearPositionUseCase(surahNumber);
  //   notifyListeners();
  // }

  Future<void> clearAllSavedQuranValues() async {
    await clearAllSavedQuranValuesUsecase();
    notifyListeners();
  }

  Future<void> clearSavedPosition() async {
    await clearSavedPositionUseCase();
    notifyListeners();
  }

  Future<void> saveBookmark({required int surahNumber, required int pageNumber}) async {
    await saveQuranBookmarkUseCase(surahNumber: surahNumber, pageNumber: pageNumber);
    notifyListeners();
  }

  Future<void> clearBookmark() async {
    await clearQuranBookmarkUseCase();
    notifyListeners();
  }

  Future<void> saveLatestQuranSurahNumber(int surahNumber) async {
    await saveLatestSurahNumberUseCase(surahNumber);
    notifyListeners();
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  double _progress = 0;
  bool _isDownloading = false;
  // bool _isPlaying = false;

  double get progress => _progress;
  bool get isDownloading => _isDownloading;
  // bool get isPlaying => _isPlaying;

// Inside QuranProvider class

// Stream for the current position/duration/buffered state
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

// Use the player's native playing state instead of a manual bool
  bool get isActuallyPlaying => _player.playing;

  int? _currentPlayingSurah;
  int? get currentPlayingSurah => _currentPlayingSurah;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Helper to clear error after showing toast
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleAudio(int surahNumber, String url) async {
    _errorMessage = null;

    // The player holds exactly one file; `_currentPlayingSurah` remembers
    // whose file that is. Read it BEFORE reassigning below so tapping the
    // already-loaded surah pauses/resumes while tapping a *different* surah
    // switches the source even when audio is currently playing.
    final int? loadedSurah = _currentPlayingSurah;
    final bool isSameSurah =
        _player.audioSource != null && loadedSurah == surahNumber;

    if (isSameSurah && _player.playing) {
      await _player.pause();
      notifyListeners();
      return;
    }

    if (isSameSurah &&
        !_player.playing &&
        _player.processingState == ProcessingState.ready) {
      await _player.play();
      notifyListeners();
      return;
    }

    _currentPlayingSurah = surahNumber;

    try {
      final bool alreadyExists = await checkSurahDownloadedUseCase(surahNumber);

      if (!alreadyExists) {
        _isDownloading = true;
        notifyListeners();
      }

      // getSurahAudioUseCase calls the Repository's downloadSurah internally
      final String path = await getSurahAudioUseCase(
        surahNumber: surahNumber,
        url: url,
      );

      _isDownloading = false;
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      _isDownloading = false;
      // This catches the string thrown by your RepositoryImpl
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void resetAudio() {
    // Stop playing and move the playhead back to the start
    _player.stop();
    _player.seek(Duration.zero);

    // If you were in the middle of a download, you might want to cancel it
    // depending on your preference. For now, we just reset the UI state.
    _isDownloading = false;
    _progress = 0;
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
