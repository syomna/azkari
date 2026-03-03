// test/data/repositories/quran_repository_impl_test.dart

import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/models/quran_position_model.dart';
import 'package:azkar_app/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:azkar_app/features/quran/domain/entities/quran_position_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'quran_repository_impl_test.mocks.dart';

@GenerateMocks([QuranLocalDataSource, Dio])
void main() {
  late QuranRepositoryImpl repository;
  late MockQuranLocalDataSource mockLocalDataSource;
  late MockDio mockDio;

  setUp(() {
    mockLocalDataSource = MockQuranLocalDataSource();
    mockDio = MockDio();
    repository = QuranRepositoryImpl(
        quranLocalDataSource: mockLocalDataSource, dio: mockDio);
  });

  group('QuranRepositoryImpl', () {
    test('should return a QuranPositionEntity when getSavedPosition is called',
        () {
      final tSurahNumber = 1;
      final tAyahNumber = 50;
      final tQuranPositionModel = QuranPositionModel(
        surahNumber: tSurahNumber,
        ayahNumber: tAyahNumber,
      );

      when(mockLocalDataSource.getSavedPosition(tSurahNumber))
          .thenReturn(tQuranPositionModel);

      // Act
      final result = repository.getSavedPosition(tSurahNumber);

      // Assert
      expect(result, isA<QuranPositionEntity>());
      expect(result.surahNumber, tSurahNumber);
      expect(result.ayahNumber, tAyahNumber);
      verify(mockLocalDataSource.getSavedPosition(tSurahNumber)).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call the local data source to save a QuranPositionModel',
        () async {
      // Arrange
      final tSurahNumber = 2;
      final tAyahNumber = 100;
      final tQuranPositionEntity = QuranPositionEntity(
        surahNumber: tSurahNumber,
        ayahNumber: tAyahNumber,
      );
      final tQuranPositionModel = QuranPositionModel(
        surahNumber: tSurahNumber,
        ayahNumber: tAyahNumber,
      );
      when(mockLocalDataSource.saveQuranPosition(tQuranPositionModel))
          .thenAnswer((_) async => {});

      // Act
      await repository.saveQuranPosition(tQuranPositionEntity);

      // Assert
      verify(mockLocalDataSource.saveQuranPosition(argThat(
        isA<QuranPositionModel>()
            .having((model) => model.surahNumber, 'surahNumber', tSurahNumber)
            .having((model) => model.ayahNumber, 'ayahNumber', tAyahNumber),
      ))).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call the local data source to save the latest surah number',
        () async {
      // Arrange
      final tSurahNumber = 3;
      when(mockLocalDataSource.saveLatestQuranSurahNumber(tSurahNumber))
          .thenAnswer((_) async => {});

      // Act
      await repository.saveLatestQuranSurahNumber(tSurahNumber);

      // Assert
      verify(mockLocalDataSource.saveLatestQuranSurahNumber(tSurahNumber))
          .called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call the local data source to get the latest surah number',
        () {
      // Arrange
      final tSurahNumber = 4;
      when(mockLocalDataSource.getLatestQuranSurahNumber())
          .thenReturn(tSurahNumber);

      // Act
      final result = repository.getLatestQuranSurahNumber();

      // Assert
      expect(result, tSurahNumber);
      verify(mockLocalDataSource.getLatestQuranSurahNumber()).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call the local data source to clear a saved position',
        () async {
      // Arrange
      final tSurahNumber = 5;
      when(mockLocalDataSource.clearSavedPosition(tSurahNumber))
          .thenAnswer((_) async {});

      // Act
      await repository.clearSavedPosition(tSurahNumber);

      // Assert
      verify(mockLocalDataSource.clearSavedPosition(tSurahNumber)).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });
}
