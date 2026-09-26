import 'package:azkar_app/features/quran/presentation/utils/quran_audio_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuranAudioSource.surahArabicNames', () {
    test('holds exactly the 114 surahs', () {
      expect(QuranAudioSource.surahArabicNames.length, 114);
      expect(QuranAudioSource.surahArabicNames.first, 'الفاتحة');
      expect(QuranAudioSource.surahArabicNames.last, 'الناس');
    });

    test('surahName maps 1-based numbers to the expected names', () {
      expect(QuranAudioSource.surahName(1), 'الفاتحة');
      expect(QuranAudioSource.surahName(2), 'البقرة');
      expect(QuranAudioSource.surahName(36), 'يس');
      expect(QuranAudioSource.surahName(112), 'الإخلاص');
      expect(QuranAudioSource.surahName(114), 'الناس');
    });

    test('surahName falls back gracefully for invalid numbers', () {
      expect(QuranAudioSource.surahName(0), 'سورة');
      expect(QuranAudioSource.surahName(115), 'سورة');
      expect(QuranAudioSource.surahName(-3), 'سورة');
    });
  });

  group('QuranAudioSource.urlForSurah', () {
    test('builds the expected CDN mp3 url with default reciter', () {
      expect(
        QuranAudioSource.urlForSurah(1),
        'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/1.mp3',
      );
      expect(
        QuranAudioSource.urlForSurah(114),
        'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/114.mp3',
      );
    });

    test('honours reciter and bitrate overrides', () {
      expect(
        QuranAudioSource.urlForSurah(2, reciter: 'ar.husary', bitrate: 192),
        'https://cdn.islamic.network/quran/audio-surah/192/ar.husary/2.mp3',
      );
    });
  });
}
