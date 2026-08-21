import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/names_of_allah/data/repositories/names_of_allah_repository_impl.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'names_of_allah_repository_impl_test.mocks.dart';

@GenerateMocks([NamesOfAllahLocalDataSource])
void main() {
  late NamesOfAllahRepositoryImpl repository;
  late MockNamesOfAllahLocalDataSource mockNamesOfAllahLocalDataSource;

  setUp(() {
    mockNamesOfAllahLocalDataSource = MockNamesOfAllahLocalDataSource();
    repository = NamesOfAllahRepositoryImpl(
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
        'should return a List<NamesOfAllahEntity> when the call completes successfully',
        () async {
      when(mockNamesOfAllahLocalDataSource.getNamesOfAllah())
          .thenAnswer((_) async => tNamesOfAllahModelList);
      final result = await repository.getNamesOfAllah();
      expect(result, Right(tNamesOfAllahEntityList));
      verify(mockNamesOfAllahLocalDataSource.getNamesOfAllah());
      verifyNoMoreInteractions(mockNamesOfAllahLocalDataSource);
    });

    test('should return failure when the call throws an Exception', () async {
      when(mockNamesOfAllahLocalDataSource.getNamesOfAllah())
          .thenThrow(Exception('test'));
      final result = await repository.getNamesOfAllah();
      expect(result.isLeft(), true);
      verify(mockNamesOfAllahLocalDataSource.getNamesOfAllah());
      verifyNoMoreInteractions(mockNamesOfAllahLocalDataSource);
    });
  });
}
