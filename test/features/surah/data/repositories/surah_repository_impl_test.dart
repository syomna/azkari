import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:azkar_app/features/surah/data/repositories/surah_repositoy_impl.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'surah_repository_impl_test.mocks.mocks.dart';

void main() {
  late SurahRepositoyImpl surahRepositoryImpl;
  late MockSurahLocalDataSource mockSurahLocalDataSource;

  setUp(() {
    mockSurahLocalDataSource = MockSurahLocalDataSource();
    surahRepositoryImpl =
        SurahRepositoyImpl(surahLocalDataSource: mockSurahLocalDataSource);
  });

  group('getSurah', () {
    final surahModelList = [
      const SurahModel(name: 'Surah 1', surah: 'Surah 1'),
      const SurahModel(name: 'Surah 2', surah: 'Surah 2'),
    ];
    final List<SurahEntity> surahEntityList = surahModelList;
    test('should return list<SurahModel> when the call completes successfully',
        () async {
      when(mockSurahLocalDataSource.getSurah())
          .thenAnswer((_) async => Right(surahModelList));
      final result = await surahRepositoryImpl.getSurah();
      expect(result, Right(surahEntityList));
      verify(mockSurahLocalDataSource.getSurah());
      verifyNoMoreInteractions(mockSurahLocalDataSource);
    });

    test('should return failure when the call throws an exception', () async {
      const tFailure = JsonParsingFailure();
      when(mockSurahLocalDataSource.getSurah())
          .thenAnswer((_) async => const Left(tFailure));
      final result = await surahRepositoryImpl.getSurah();
      expect(result, const Left(tFailure));
      verify(mockSurahLocalDataSource.getSurah());
      verifyNoMoreInteractions(mockSurahLocalDataSource);
    });
  });
}
