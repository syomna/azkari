import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'surah_provider_test.mocks.dart';

@GenerateMocks([GetSurahUseCase])
void main() {
  late SurahProvider provider;
  late MockGetSurahUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetSurahUseCase();
    provider = SurahProvider(getSurahUseCase: mockUseCase);
  });

  final tSurahList = [
    const SurahEntity(name: 'Al-Fatiha', surah: '1'),
    const SurahEntity(name: 'Al-Baqara', surah: '2'),
  ];

  group('SurahProvider', () {
    test('initial state is initial with empty list', () {
      expect(provider.surahStatus, AppLoadingStatus.initial);
      expect(provider.surahList, isEmpty);
      expect(provider.surahErrorMessage, isNull);
    });

    test('loadSurah success sets loaded and populates list', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tSurahList));

      await provider.loadSurah();

      expect(provider.surahStatus, AppLoadingStatus.loaded);
      expect(provider.surahList, tSurahList);
      expect(provider.surahErrorMessage, isNull);
    });

    test('loadSurah failure sets error state', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => const Left(CacheFailure('Load failed')));

      await provider.loadSurah();

      expect(provider.surahStatus, AppLoadingStatus.error);
      expect(provider.surahErrorMessage, 'Load failed');
      expect(provider.surahList, isEmpty);
    });

    test('loadSurah guard returns early if already loading', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tSurahList));

      final future1 = provider.loadSurah();
      final future2 = provider.loadSurah();

      await Future.wait([future1, future2]);

      verify(mockUseCase(const NoParams())).called(1);
    });

    test('loadSurah notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tSurahList));

      await provider.loadSurah();

      expect(notifyCount, 1); // only loaded (no separate loading notify)
    });
  });
}
