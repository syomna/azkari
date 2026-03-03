import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:azkar_app/features/quran/domain/usecases/check_surah_downloaded_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_all_saved_quran_values_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/clear_quran_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_position_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_surah_audio_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_latest_quran_surah_number_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_position_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

class QuranProvider with ChangeNotifier {
  final GetSavedQuranPositionUseCase getSavedPositionUseCase;
  final SaveQuranPositionUseCase savePositionUseCase;
  final ClearQuranPositionUseCase clearPositionUseCase;
  final GetLatestQuranSurahNumberUseCase getLatestSurahNumberUseCase;
  final SaveLatestQuranSurahNumberUseCase saveLatestSurahNumberUseCase;
  final ClearAllSavedQuranValuesUseCase clearAllSavedQuranValuesUsecase;
  final GetSurahAudioUseCase getSurahAudioUseCase;
  final CheckSurahDownloadedUseCase checkSurahDownloadedUseCase;

  QuranProvider(
      {required this.getSavedPositionUseCase,
      required this.savePositionUseCase,
      required this.clearPositionUseCase,
      required this.getLatestSurahNumberUseCase,
      required this.saveLatestSurahNumberUseCase,
      required this.clearAllSavedQuranValuesUsecase,
      required this.getSurahAudioUseCase,
      required this.checkSurahDownloadedUseCase});

  int? get savedLatestQuranSurahNumber => getLatestSurahNumberUseCase();

  QuranPositionEntity getSavedPosition(int surahNumber) {
    return getSavedPositionUseCase(surahNumber);
  }

  Future<void> saveQuranPosition(int surahNumber, int ayahNumber) async {
    await savePositionUseCase(surahNumber, ayahNumber);
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

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleAudio(int surahNumber, String url) async {
    _currentPlayingSurah = surahNumber;
    // Check if we are interacting with the same surah already loaded
    final bool isSameSurah = _player.audioSource != null;

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
      // If it's a new surah or nothing is loaded, check download
      final bool alreadyExists = await checkSurahDownloadedUseCase(surahNumber);

      if (!alreadyExists) {
        _isDownloading = true;
        _progress = 0;
        notifyListeners();
      }

      final String path = await getSurahAudioUseCase(
        surahNumber: surahNumber,
        url: url,
      );

      _isDownloading = false;
      await _player.setFilePath(path);
      _player.play();

      // Global listener to ensure UI updates whenever player state changes internally
      _player.playbackEventStream.listen((event) {
        notifyListeners();
      }, onError: (Object e, StackTrace st) {
        _isDownloading = false;
        notifyListeners();
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _player.stop();
          _player.seek(Duration.zero);
          notifyListeners();
        }
      });
    } catch (e) {
      _isDownloading = false;
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
}
