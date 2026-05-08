import 'package:azkar_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar_app/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// سيتم إنشاء هذا الملف بعد تشغيل build_runner
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
      quranLocalDataSource: mockLocalDataSource,
      dio: mockDio,
    );
  });

  group('QuranRepositoryImpl - Local Data', () {
    test('should return page number from local data source', () {
      // Arrange
      const tPageNumber = 50;
      when(mockLocalDataSource.getSavedQuranPageNumber()).thenReturn(tPageNumber);

      // Act
      final result = repository.getSavedQuranPageNumber();

      // Assert
      expect(result, tPageNumber);
      verify(mockLocalDataSource.getSavedQuranPageNumber()).called(1);
    });

    test('should call local data source to save page number', () async {
      // Arrange
      const tPageNumber = 100;
      when(mockLocalDataSource.saveQuranPageNumber(tPageNumber))
          .thenAnswer((_) async => {});

      // Act
      await repository.saveQuranPageNumber(tPageNumber);

      // Assert
      verify(mockLocalDataSource.saveQuranPageNumber(tPageNumber)).called(1);
    });

    test('should return latest surah number from local data source', () {
      // Arrange
      const tSurahNumber = 18;
      when(mockLocalDataSource.getLatestQuranSurahNumber()).thenReturn(tSurahNumber);

      // Act
      final result = repository.getLatestQuranSurahNumber();

      // Assert
      expect(result, tSurahNumber);
      verify(mockLocalDataSource.getLatestQuranSurahNumber()).called(1);
    });

    test('should call local data source to clear all saved values', () async {
      // Arrange
      when(mockLocalDataSource.clearAllSavedQuranValues())
          .thenAnswer((_) async => {});

      // Act
      await repository.clearAllSavedQuranValues();

      // Assert
      verify(mockLocalDataSource.clearAllSavedQuranValues()).called(1);
    });
  });

  group('QuranRepositoryImpl - Dio Download', () {
    const tUrl = 'https://example.com/audio.mp3';
    const tPath = '/storage/emulated/0/audio.mp3';

    test('should complete download successfully when Dio returns success', () async {
      // Arrange
      when(mockDio.download(
        any,
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: tUrl)));

      // Act & Assert
      await expectLater(repository.downloadSurah(tUrl, tPath), completes);
      verify(mockDio.download(tUrl, tPath, options: anyNamed('options'))).called(1);
    });

    test('should throw connection timeout message when DioException is timeout', () async {
      // Arrange
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: tUrl),
      ));

      // Act & Assert
      expect(
        () => repository.downloadSurah(tUrl, tPath),
        throwsA('انتهت مهلة الاتصال، تحقق من الشبكة'),
      );
    });

    test('should throw bad response message when server returns error (404/500)', () async {
      // Arrange
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: tUrl),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: tUrl),
        ),
      ));

      // Act & Assert
      expect(
        () => repository.downloadSurah(tUrl, tPath),
        throwsA('الملف غير موجود على الخادم'),
      );
    });

    test('should throw default failure message on generic exception', () async {
      // Arrange
      when(mockDio.download(any, any, options: anyNamed('options')))
          .thenThrow(Exception());

      // Act & Assert
      expect(
        () => repository.downloadSurah(tUrl, tPath),
        throwsA('فشل التحميل، تأكد من وجود مساحة كافية'),
      );
    });
  });
}