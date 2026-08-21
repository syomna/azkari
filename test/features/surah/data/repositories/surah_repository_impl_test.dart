import 'package:azkar_app/features/surah/data/datasources/surah_local_data_source.dart';
import 'package:azkar_app/features/surah/data/models/surah_model.dart';
import 'package:azkar_app/features/surah/data/repositories/surah_repository_impl.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'surah_repository_impl_test.mocks.dart';

@GenerateMocks([SurahLocalDataSource])
void main() {
  late SurahRepositoryImpl surahRepositoryImpl;
  late MockSurahLocalDataSource mockSurahLocalDataSource;

  setUp(() {
    mockSurahLocalDataSource = MockSurahLocalDataSource();
    surahRepositoryImpl =
        SurahRepositoryImpl(surahLocalDataSource: mockSurahLocalDataSource);
  });

  group('getSurah', () {
    final surahModelList = [
      const SurahModel(name: 'Surah 1', surah: 'Surah 1'),
      const SurahModel(name: 'Surah 2', surah: 'Surah 2'),
    ];
    final List<SurahEntity> surahEntityList = surahModelList;

    test('should return list<SurahEntity> when the call completes successfully',
        () async {
      when(mockSurahLocalDataSource.getSurah())
          .thenAnswer((_) async => surahModelList);
      final result = await surahRepositoryImpl.getSurah();
      expect(result, Right(surahEntityList));
      verify(mockSurahLocalDataSource.getSurah());
      verifyNoMoreInteractions(mockSurahLocalDataSource);
    });

    test('should return failure when the call throws an exception', () async {
      when(mockSurahLocalDataSource.getSurah())
          .thenThrow(Exception('test'));
      final result = await surahRepositoryImpl.getSurah();
      expect(result.isLeft(), true);
      verify(mockSurahLocalDataSource.getSurah());
      verifyNoMoreInteractions(mockSurahLocalDataSource);
    });
  });
}
