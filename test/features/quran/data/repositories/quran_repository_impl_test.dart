import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'quran_repository_impl_test.mocks.dart';

@GenerateMocks([QuranLocalDataSource, Dio])
class TestableQuranRepositoryImpl extends QuranRepositoryImpl {
  TestableQuranRepositoryImpl({
    required super.quranLocalDataSource,
    required super.dio,
  });

  @override
  Future<void> moveTempFile(String from, String to) async {}
}

void main() {
  late TestableQuranRepositoryImpl repository;
  late MockQuranLocalDataSource mockLocalDataSource;
  late MockDio mockDio;

  setUp(() {
    mockLocalDataSource = MockQuranLocalDataSource();
    mockDio = MockDio();
    repository = TestableQuranRepositoryImpl(
      quranLocalDataSource: mockLocalDataSource,
      dio: mockDio,
    );
  });

  group('QuranRepositoryImpl - Local Data', () {
    test('should return page number from local data source', () async {
      const tPageNumber = 50;
      when(mockLocalDataSource.getSavedQuranPageNumber())
          .thenReturn(tPageNumber);

      final result = await repository.getSavedQuranPageNumber();

      expect(result, const Right(tPageNumber));
      verify(mockLocalDataSource.getSavedQuranPageNumber()).called(1);
    });

    test('should call local data source to save page number', () async {
      const tPageNumber = 100;
      when(mockLocalDataSource.saveQuranPageNumber(tPageNumber))
          .thenAnswer((_) async => {});

      final result = await repository.saveQuranPageNumber(tPageNumber);

      expect(result, const Right(null));
      verify(mockLocalDataSource.saveQuranPageNumber(tPageNumber)).called(1);
    });

    test('should return latest surah number from local data source', () async {
      const tSurahNumber = 18;
      when(mockLocalDataSource.getLatestQuranSurahNumber())
          .thenReturn(tSurahNumber);

      final result = await repository.getLatestQuranSurahNumber();

      expect(result, const Right(tSurahNumber));
      verify(mockLocalDataSource.getLatestQuranSurahNumber()).called(1);
    });

    test('should call local data source to clear all saved values', () async {
      when(mockLocalDataSource.clearAllSavedQuranValues())
          .thenAnswer((_) async => {});

      final result = await repository.clearAllSavedQuranValues();

      expect(result, const Right(null));
      verify(mockLocalDataSource.clearAllSavedQuranValues()).called(1);
    });
  });

  group('QuranRepositoryImpl - Dio Download', () {
    const tUrl = 'https://example.com/audio.mp3';
    const tPath = '/storage/emulated/0/audio.mp3';

    test(
        'should complete download successfully when Dio returns success',
        () async {
      when(mockDio.download(
        any,
        any,
        options: anyNamed('options'),
      )).thenAnswer(
          (_) async => Response(requestOptions: RequestOptions(path: tUrl)));

      final result = await repository.downloadSurah(tUrl, tPath);
      expect(result, isA<Right<Failure, void>>());
      verify(mockDio.download(tUrl, '$tPath.tmp', options: anyNamed('options')))
          .called(1);
    });

    test(
        'should return Left with NetworkFailure when DioException is timeout',
        () async {
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: tUrl),
      ));

      final result = await repository.downloadSurah(tUrl, tPath);
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
        'should return Left with ServerFailure when server returns error (404/500)',
        () async {
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: tUrl),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: tUrl),
        ),
      ));

      final result = await repository.downloadSurah(tUrl, tPath);
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
        'should return Left with ServerFailure on generic exception', () async {
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(Exception());

      final result = await repository.downloadSurah(tUrl, tPath);
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
