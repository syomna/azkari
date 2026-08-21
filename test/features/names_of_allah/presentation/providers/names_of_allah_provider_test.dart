import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'names_of_allah_provider_test.mocks.dart';

@GenerateMocks([GetNamesOfAllahUseCase])
void main() {
  late NamesOfAllahProvider provider;
  late MockGetNamesOfAllahUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetNamesOfAllahUseCase();
    provider = NamesOfAllahProvider(getNamesOfAllahUseCase: mockUseCase);
  });

  final tNamesOfAllah = [
    const NamesOfAllahEntity(id: 1, name: 'Ar-Rahman', text: 'The Beneficent'),
    const NamesOfAllahEntity(id: 2, name: 'Ar-Raheem', text: 'The Merciful'),
  ];

  group('NamesOfAllahProvider', () {
    test('initial state is initial with empty list', () {
      expect(provider.namesOfAllahStatus, AppLoadingStatus.initial);
      expect(provider.namesOfAllahList, isEmpty);
      expect(provider.namesOfAllahErrorMessage, isNull);
    });

    test('loadNamesOfAllah success sets loaded and populates list', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tNamesOfAllah));

      await provider.loadNamesOfAllah();

      expect(provider.namesOfAllahStatus, AppLoadingStatus.loaded);
      expect(provider.namesOfAllahList, tNamesOfAllah);
      expect(provider.namesOfAllahErrorMessage, isNull);
    });

    test('loadNamesOfAllah failure sets error state', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => const Left(CacheFailure('Load failed')));

      await provider.loadNamesOfAllah();

      expect(provider.namesOfAllahStatus, AppLoadingStatus.error);
      expect(provider.namesOfAllahErrorMessage, 'Load failed');
      expect(provider.namesOfAllahList, isEmpty);
    });

    test('loadNamesOfAllah guard returns early if already loading', () async {
      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tNamesOfAllah));

      // Start first load (will be loading state)
      final future1 = provider.loadNamesOfAllah();
      // Start second load while first is still in progress
      final future2 = provider.loadNamesOfAllah();

      await Future.wait([future1, future2]);

      // Use case should only be called once
      verify(mockUseCase(const NoParams())).called(1);
    });

    test('loadNamesOfAllah notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      when(mockUseCase(const NoParams()))
          .thenAnswer((_) async => Right(tNamesOfAllah));

      await provider.loadNamesOfAllah();

      expect(notifyCount, 2); // loading + loaded
    });
  });
}
