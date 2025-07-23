import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/names_of_allah/data/repositories/names_of_allah_repositoy_impl.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'names_of_allah_repository_impl_test.mocks.mocks.dart';

void main() {
  late NamesOfAllahRepositoyImpl repository;
  late MockNamesOfAllahLocalDataSource mockNamesOfAllahLocalDataSource;

  setUp(() {
    mockNamesOfAllahLocalDataSource = MockNamesOfAllahLocalDataSource();
    repository = NamesOfAllahRepositoyImpl(
      namesOfAllahLocalDataSource: mockNamesOfAllahLocalDataSource,
    );
  });

  group('getNamesOfAllah', () {
    final tNamesOfAllahModelList = [
      const NamesOfAllahModel(
          id: 1, name: 'Name of allah 1', text: 'Name of allah 1'),
      const NamesOfAllahModel(
          id: 2, name: 'Name of allah 2', text: 'Name of allah 2'),
    ];
    List<NamesOfAllahEntity> tNamesOfAllahEntityList = tNamesOfAllahModelList;
    test(
        'should return a List<NamesOfAllahModel> when the call completes successfully',
        () async {
      when(mockNamesOfAllahLocalDataSource.getNamesOfAllah())
          .thenAnswer((_) async => Right(tNamesOfAllahModelList));
      final result = await repository.getNamesOfAllah();
      expect(result, Right(tNamesOfAllahEntityList));
      verify(mockNamesOfAllahLocalDataSource.getNamesOfAllah());
      verifyNoMoreInteractions(mockNamesOfAllahLocalDataSource);
    });

    test('should return failure when the call throws an Exception', () async {
      const tFailure = JsonParsingFailure();
      when(mockNamesOfAllahLocalDataSource.getNamesOfAllah())
          .thenAnswer((_) async => const Left(tFailure));
      final result = await repository.getNamesOfAllah();
      expect(result, const Left(tFailure));
      verify(mockNamesOfAllahLocalDataSource.getNamesOfAllah());
      verifyNoMoreInteractions(mockNamesOfAllahLocalDataSource);
    });
  });
}
