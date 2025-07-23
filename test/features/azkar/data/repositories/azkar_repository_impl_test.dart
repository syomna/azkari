import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:azkar_app/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'azkar_repository_impl_test.mocks.mocks.dart';

void main() {
  late AzkarRepositoryImpl repository;
  late MockAzkarLocalDataSource mockAzkarLocalDataSource;

  setUp(() {
    mockAzkarLocalDataSource = MockAzkarLocalDataSource();
    repository = AzkarRepositoryImpl(
      azkarLocalDataSource: mockAzkarLocalDataSource,
    );
  });

  group('getAzkar', () {
    final tAzkarModelList = [
      const AzkarModel(
        category: 'Morning',
        zekr: 'Zekr 1',
        description: 'Desc 1',
        count: '1',
        reference: 'Ref 1',
      ),
      const AzkarModel(
        category: 'Morning',
        zekr: 'Zekr 2',
        description: 'Desc 2',
        count: '3',
        reference: 'Ref 2',
      ),
    ];

    final List<ZekrEntity> tZekrEntityList = tAzkarModelList;

    test(
      'should return List<ZekrEntity> when the call to local data source is successful',
      () async {
        // Arrange (Set up the mock's behavior)
        when(mockAzkarLocalDataSource.getAzkar())
            .thenAnswer((_) async => Right(tAzkarModelList));

        // Act (Call the method being tested)
        final result = await repository.getAzkar();

        // Assert (Verify the outcome)
        // Check if the result is a Right containing the expected ZekrEntity list
        expect(result, Right(tZekrEntityList));
        // Verify that the getAzkar method was called on the mock data source
        verify(mockAzkarLocalDataSource.getAzkar());
        // Ensure no other unexpected interactions happened with the mock
        verifyNoMoreInteractions(mockAzkarLocalDataSource);
      },
    );

    // Test case 2: Unsuccessful data retrieval (failure)
    test(
      'should return a Failure when the call to local data source is unsuccessful',
      () async {
        // Arrange (Set up the mock's behavior to return a failure)
        const tFailure =
            CacheFailure('No cached data found'); // Example failure
        when(mockAzkarLocalDataSource.getAzkar())
            .thenAnswer((_) async => const Left(tFailure));

        // Act (Call the method being tested)
        final result = await repository.getAzkar();

        // Assert (Verify the outcome)
        // Check if the result is a Left containing the expected Failure
        expect(result, const Left(tFailure));
        // Verify that the getAzkar method was called on the mock data source
        verify(mockAzkarLocalDataSource.getAzkar());
        // Ensure no other unexpected interactions happened with the mock
        verifyNoMoreInteractions(mockAzkarLocalDataSource);
      },
    );
  });
}
