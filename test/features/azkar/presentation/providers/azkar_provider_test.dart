import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'azkar_provider_test.mocks.dart';

@GenerateMocks([
  GetAzkarUseCase,
  GetCustomAzkarUseCase,
  SaveCustomAzkarUseCase,
  DeleteCustomAzkarUseCase,
  UpdateCustomAzkarUseCase,
])
void main() {
  late AzkarProvider provider;
  late MockGetAzkarUseCase mockGetAzkar;
  late MockGetCustomAzkarUseCase mockGetCustomAzkar;
  late MockSaveCustomAzkarUseCase mockSaveCustomAzkar;
  late MockDeleteCustomAzkarUseCase mockDeleteCustomAzkar;
  late MockUpdateCustomAzkarUseCase mockUpdateCustomAzkar;

  setUp(() {
    mockGetAzkar = MockGetAzkarUseCase();
    mockGetCustomAzkar = MockGetCustomAzkarUseCase();
    mockSaveCustomAzkar = MockSaveCustomAzkarUseCase();
    mockDeleteCustomAzkar = MockDeleteCustomAzkarUseCase();
    mockUpdateCustomAzkar = MockUpdateCustomAzkarUseCase();
    provider = AzkarProvider(
      getAzkarUseCase: mockGetAzkar,
      getCustomAzkarUseCase: mockGetCustomAzkar,
      saveCustomAzkarUseCase: mockSaveCustomAzkar,
      deleteCustomAzkarUseCase: mockDeleteCustomAzkar,
      updateCustomAzkarUseCase: mockUpdateCustomAzkar,
    );
  });

  final tAzkarList = [
    const ZekrEntity(
        category: 'Morning', zekr: 'Zekr 1', count: 1,
        description: '', reference: ''),
    const ZekrEntity(
        category: 'Morning', zekr: 'Zekr 2', count: 3,
        description: '', reference: ''),
    const ZekrEntity(
        category: 'Evening', zekr: 'Zekr 3', count: 1,
        description: '', reference: ''),
  ];

  final tCustomAzkarList = [
    const ZekrEntity(
        category: 'My Duas', zekr: 'Dua 1', count: 1,
        description: '', reference: ''),
  ];

  group('loadAzkar', () {
    test('success sets loaded and populates list', () async {
      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tAzkarList));

      await provider.loadAzkar();

      expect(provider.azkarStatus, AppLoadingStatus.loaded);
      expect(provider.azkarList, tAzkarList);
      expect(provider.azkarErrorMessage, isNull);
    });

    test('failure sets error state with message', () async {
      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => const Left(CacheFailure('JSON parse error')));

      await provider.loadAzkar();

      expect(provider.azkarStatus, AppLoadingStatus.error);
      expect(provider.azkarErrorMessage, 'JSON parse error');
      expect(provider.azkarList, isEmpty);
    });

    test('guard returns early if already loading', () async {
      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tAzkarList));

      final f1 = provider.loadAzkar();
      final f2 = provider.loadAzkar();
      await Future.wait([f1, f2]);

      verify(mockGetAzkar(const NoParams())).called(1);
    });

    test('rebuilds categories after success', () async {
      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tAzkarList));
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => const Right([]));

      await provider.loadAzkar();

      expect(provider.allCategories, containsAll(['Morning', 'Evening']));
      expect(provider.categoryCounts['Morning'], 2);
      expect(provider.categoryCounts['Evening'], 1);
    });
  });

  group('loadCustomAzkar', () {
    test('success populates custom list and rebuilds categories', () async {
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tCustomAzkarList));

      await provider.loadCustomAzkar();

      expect(provider.customAzkarList, tCustomAzkarList);
      expect(provider.customCategories, contains('My Duas'));
    });

    test('failure is a silent no-op', () async {
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      await provider.loadCustomAzkar();

      expect(provider.customAzkarList, isEmpty);
    });
  });

  group('saveCustomAzkarCategory', () {
    test('saves items and reloads custom azkar', () async {
      when(mockSaveCustomAzkar(any))
          .thenAnswer((_) async => const Right(null));
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tCustomAzkarList));

      await provider.saveCustomAzkarCategory(
        categoryTitle: 'My Duas',
        azkarItems: [
          {'text': 'Dua 1', 'count': 1},
        ],
      );

      verify(mockSaveCustomAzkar(any)).called(1);
      expect(provider.customAzkarList, tCustomAzkarList);
    });

    test('does not save if list is empty', () async {
      await provider.saveCustomAzkarCategory(
        categoryTitle: 'Empty',
        azkarItems: [],
      );

      verifyNever(mockSaveCustomAzkar(any));
    });
  });

  group('deleteCustomCategory', () {
    test('deletes and reloads custom azkar', () async {
      when(mockDeleteCustomAzkar('My Duas'))
          .thenAnswer((_) async => const Right(null));
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => const Right([]));

      await provider.deleteCustomCategory('My Duas');

      verify(mockDeleteCustomAzkar('My Duas')).called(1);
      verify(mockGetCustomAzkar(const NoParams())).called(1);
    });
  });

  group('updateCustomAzkarCategory', () {
    test('updates category and reloads custom azkar', () async {
      when(mockUpdateCustomAzkar(any))
          .thenAnswer((_) async => const Right(null));
      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tCustomAzkarList));

      await provider.updateCustomAzkarCategory(
        originalCategory: 'My Duas',
        categoryTitle: 'My Renamed Duas',
        azkarItems: [
          {'text': 'Dua 1', 'count': 2},
        ],
      );

      final captured = verify(mockUpdateCustomAzkar(captureAny)).captured.single
          as UpdateCustomAzkarParams;
      expect(captured.originalCategory, 'My Duas');
      expect(captured.newCategory, 'My Renamed Duas');
      expect(captured.items.single.zekr, 'Dua 1');
      expect(captured.items.single.count, 2);
      expect(provider.customAzkarList, tCustomAzkarList);
    });

    test('does not call usecase if list is empty', () async {
      await provider.updateCustomAzkarCategory(
        originalCategory: 'My Duas',
        categoryTitle: 'My Duas',
        azkarItems: [],
      );

      verifyNever(mockUpdateCustomAzkar(any));
    });

    test('failure does not reload custom azkar', () async {
      when(mockUpdateCustomAzkar(any))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      await provider.updateCustomAzkarCategory(
        originalCategory: 'My Duas',
        categoryTitle: 'My Duas',
        azkarItems: [
          {'text': 'Dua 1', 'count': 1},
        ],
      );

      verifyNever(mockGetCustomAzkar(const NoParams()));
    });
  });

  group('categoryCounts', () {
    test('counts every custom zekr per category', () async {
      when(mockGetCustomAzkar(const NoParams())).thenAnswer((_) async =>
          const Right([
            ZekrEntity(
                category: 'My Duas',
                zekr: 'Dua 1',
                count: 1,
                description: '',
                reference: ''),
            ZekrEntity(
                category: 'My Duas',
                zekr: 'Dua 2',
                count: 3,
                description: '',
                reference: ''),
            ZekrEntity(
                category: 'Other',
                zekr: 'Zekr 1',
                count: 1,
                description: '',
                reference: ''),
          ]));

      await provider.loadCustomAzkar();

      expect(provider.categoryCounts['My Duas'], 2);
      expect(provider.categoryCounts['Other'], 1);
    });

    test('merges counts when custom category shares an asset name', () async {
      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tAzkarList));
      when(mockGetCustomAzkar(const NoParams())).thenAnswer((_) async =>
          const Right([
            ZekrEntity(
                category: 'Morning',
                zekr: 'Extra zekr',
                count: 1,
                description: '',
                reference: ''),
          ]));

      await provider.loadAzkar();
      await provider.loadCustomAzkar();

      expect(provider.categoryCounts['Morning'], 3);
    });
  });

  group('notifies listeners', () {
    test('on loadAzkar success', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tAzkarList));

      await provider.loadAzkar();

      expect(notifyCount, 1);
    });

    test('on loadAzkar failure', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      when(mockGetAzkar(const NoParams()))
          .thenAnswer((_) async => const Left(CacheFailure('error')));

      await provider.loadAzkar();

      expect(notifyCount, 1);
    });

    test('on loadCustomAzkar success', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      when(mockGetCustomAzkar(const NoParams()))
          .thenAnswer((_) async => Right(tCustomAzkarList));

      await provider.loadCustomAzkar();

      expect(notifyCount, 1);
    });
  });
}
