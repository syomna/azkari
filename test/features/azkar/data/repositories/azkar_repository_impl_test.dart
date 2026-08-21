import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:azkar_app/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'azkar_repository_impl_test.mocks.dart';

@GenerateMocks([AzkarLocalDataSource])
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
        count: 1,
        reference: 'Ref 1',
      ),
      const AzkarModel(
        category: 'Morning',
        zekr: 'Zekr 2',
        description: 'Desc 2',
        count: 3,
        reference: 'Ref 2',
      ),
    ];

    final List<ZekrEntity> tZekrEntityList = tAzkarModelList;

    test(
      'should return List<ZekrEntity> when the call to local data source is successful',
      () async {
        when(mockAzkarLocalDataSource.getAzkar())
            .thenAnswer((_) async => tAzkarModelList);

        final result = await repository.getAzkar();

        expect(result, Right(tZekrEntityList));
        verify(mockAzkarLocalDataSource.getAzkar());
        verifyNoMoreInteractions(mockAzkarLocalDataSource);
      },
    );

    test(
      'should return a Failure when the call to local data source throws an exception',
      () async {
        when(mockAzkarLocalDataSource.getAzkar()).thenThrow(Exception('test'));

        final result = await repository.getAzkar();

        expect(result.isLeft(), true);
        verify(mockAzkarLocalDataSource.getAzkar());
        verifyNoMoreInteractions(mockAzkarLocalDataSource);
      },
    );
  });

  group('getCustomAzkar', () {
    final tCustomModels = [
      const AzkarModel(
        category: 'My Duas',
        zekr: 'Dua 1',
        description: '',
        count: 1,
        reference: '',
      ),
    ];

    test(
      'should return List<ZekrEntity> when call is successful',
      () async {
        when(mockAzkarLocalDataSource.getCustomAzkar())
            .thenAnswer((_) async => tCustomModels);

        final result = await repository.getCustomAzkar();

        expect(result.isRight(), true);
        expect(result.getOrElse(() => []), tCustomModels);
        verify(mockAzkarLocalDataSource.getCustomAzkar());
      },
    );

    test(
      'should return DatabaseFailure when call throws',
      () async {
        when(mockAzkarLocalDataSource.getCustomAzkar())
            .thenThrow(Exception('DB error'));

        final result = await repository.getCustomAzkar();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should be Left'),
        );
      },
    );
  });

  group('saveCustomAzkar', () {
    final tEntitiesToSave = [
      const ZekrEntity(
        category: 'My Duas',
        zekr: 'Dua 1',
        count: 1,
        description: '',
        reference: '',
      ),
    ];

    test(
      'should save and return Right(unit) on success',
      () async {
        when(mockAzkarLocalDataSource.saveCustomAzkar(any))
            .thenAnswer((_) async {});

        final result = await repository.saveCustomAzkar(tEntitiesToSave);

        expect(result, const Right(unit));
        verify(mockAzkarLocalDataSource.saveCustomAzkar(any)).called(1);
      },
    );

    test(
      'should return DatabaseFailure when save throws',
      () async {
        when(mockAzkarLocalDataSource.saveCustomAzkar(any))
            .thenThrow(Exception('DB write error'));

        final result = await repository.saveCustomAzkar(tEntitiesToSave);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should be Left'),
        );
      },
    );
  });

  group('deleteCustomCategory', () {
    test(
      'should delete and return Right(null) on success',
      () async {
        when(mockAzkarLocalDataSource.deleteCustomCategory('My Duas'))
            .thenAnswer((_) async {});

        final result = await repository.deleteCustomCategory('My Duas');

        expect(result.isRight(), true);
        verify(mockAzkarLocalDataSource.deleteCustomCategory('My Duas'));
      },
    );

    test(
      'should return DatabaseFailure when delete throws',
      () async {
        when(mockAzkarLocalDataSource.deleteCustomCategory('My Duas'))
            .thenThrow(Exception('DB delete error'));

        final result = await repository.deleteCustomCategory('My Duas');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should be Left'),
        );
      },
    );
  });
}
