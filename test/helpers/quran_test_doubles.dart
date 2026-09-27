import 'dart:async';

import 'package:azkar_app/features/quran/domain/repositories/quran_repository.dart';
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
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';

/// قاعدة مستودع ترمي أي استدعاء غير متوقع فوراً؛ تُستخدم فقط كسلف لـ
/// usecases وهمية بسيطة في الاختبارات.
class ThrowingRepo implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.toString());
}

class FakeDownloadedCheck extends CheckSurahDownloadedUseCase {
  FakeDownloadedCheck(this.downloaded) : super(ThrowingRepo());

  final Set<int> downloaded;

  @override
  Future<bool> call(int surahNumber) async => downloaded.contains(surahNumber);
}

class FakeSurahAudio extends GetSurahAudioUseCase {
  FakeSurahAudio({this.result = '/tmp/azkar_test/surah.mp3'})
      : super(ThrowingRepo());

  final String result;

  @override
  Future<String> call({
    required int surahNumber,
    required String url,
  }) async =>
      result;
}

class _MGetPage extends Mock implements GetSavedQuranPageNumberUsecase {}

class _MSavePage extends Mock implements SaveQuranPageNumberUsecase {}

class _MGetSurah extends Mock implements GetLatestQuranSurahNumberUseCase {}

class _MSaveSurah extends Mock implements SaveLatestQuranSurahNumberUseCase {}

class _MClearAll extends Mock implements ClearAllSavedQuranValuesUseCase {}

class _MClearPosition extends Mock implements ClearSavedPositionUseCase {}

class _MSaveBookmark extends Mock implements SaveQuranBookmarkUseCase {}

class _MGetBookmarkSurah extends Mock implements GetQuranBookmarkSurahUseCase {}

class _MGetBookmarkPage extends Mock implements GetQuranBookmarkPageUseCase {}

class _MClearBookmark extends Mock implements ClearQuranBookmarkUseCase {}

/// يبني [QuranProvider] بقيم افتراضية آمنة للاختبارات (moock) مع إمكانية
/// حقن تنفيذات حقيقية للـ usecases التي تحتاجها كل حالة اختبار.
QuranProvider buildTestQuranProvider({
  GetQuranBookmarkSurahUseCase? getQuranBookmarkSurahUseCase,
  GetQuranBookmarkPageUseCase? getQuranBookmarkPageUseCase,
  SaveQuranBookmarkUseCase? saveQuranBookmarkUseCase,
  ClearQuranBookmarkUseCase? clearQuranBookmarkUseCase,
  CheckSurahDownloadedUseCase? checkSurahDownloadedUseCase,
  GetSurahAudioUseCase? getSurahAudioUseCase,
  GetSavedQuranPageNumberUsecase? getQuranPageNumberUseCase,
}) {
  return QuranProvider(
    getQuranPageNumberUseCase: getQuranPageNumberUseCase ?? _MGetPage(),
    saveQuranPageNumberUseCase: _MSavePage(),
    getLatestSurahNumberUseCase: _MGetSurah(),
    saveLatestSurahNumberUseCase: _MSaveSurah(),
    clearAllSavedQuranValuesUsecase: _MClearAll(),
    clearSavedPositionUseCase: _MClearPosition(),
    getSurahAudioUseCase: getSurahAudioUseCase ?? FakeSurahAudio(),
    checkSurahDownloadedUseCase:
        checkSurahDownloadedUseCase ?? FakeDownloadedCheck(const {}),
    saveQuranBookmarkUseCase: saveQuranBookmarkUseCase ?? _MSaveBookmark(),
    getQuranBookmarkSurahUseCase:
        getQuranBookmarkSurahUseCase ?? _MGetBookmarkSurah(),
    getQuranBookmarkPageUseCase:
        getQuranBookmarkPageUseCase ?? _MGetBookmarkPage(),
    clearQuranBookmarkUseCase: clearQuranBookmarkUseCase ?? _MClearBookmark(),
  );
}

/// [QuranProvider] يتحكم فيه الاختبار مباشرة في موضع التشغيل ورقم السورة
/// المشغَّلة، دون الاعتماد على أحداث just_audio الداخلية.
class ControllableQuranProvider extends QuranProvider {
  ControllableQuranProvider({Set<int> downloaded = const {}})
      : super(
          getQuranPageNumberUseCase: _MGetPage(),
          saveQuranPageNumberUseCase: _MSavePage(),
          getLatestSurahNumberUseCase: _MGetSurah(),
          saveLatestSurahNumberUseCase: _MSaveSurah(),
          clearAllSavedQuranValuesUsecase: _MClearAll(),
          clearSavedPositionUseCase: _MClearPosition(),
          getSurahAudioUseCase: FakeSurahAudio(),
          checkSurahDownloadedUseCase: FakeDownloadedCheck(downloaded),
          saveQuranBookmarkUseCase: _MSaveBookmark(),
          getQuranBookmarkSurahUseCase: _MGetBookmarkSurah(),
          getQuranBookmarkPageUseCase: _MGetBookmarkPage(),
          clearQuranBookmarkUseCase: _MClearBookmark(),
        );

  final StreamController<Duration?> _positionController =
      StreamController<Duration?>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  int? playingSurah;

  @override
  Stream<Duration?> get positionStream => _positionController.stream;

  @override
  int? get currentPlayingSurah => playingSurah;

  /// يحاكي وصول موضع تشغيل جديد؛ `null` يعني "لم يُعرف موضع بعد".
  void emitPosition(Duration? position) => _positionController.add(position);

  /// تحاكي وصول المدة_total بعد انتهاء التحميل (just_audio لا يبثّ أي حدث
  /// موضع قبل بدء التشغيل).
  @override
  AudioPlayer get player => _fakePlayer;

  late final AudioPlayer _fakePlayer = _TestAudioPlayer(this);

  void emitDuration(Duration? duration) => _durationController.add(duration);
}

/// مشغّل وهمي يكشف `durationStream` الخاص بـ just_audio لاختبار العدّاد.
class _TestAudioPlayer extends AudioPlayer {
  _TestAudioPlayer(this.owner);

  final ControllableQuranProvider owner;

  @override
  Stream<Duration?> get durationStream => owner._durationController.stream;
}
