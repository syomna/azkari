import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryAzkarRepository implements AzkarRepository {
  _MemoryAzkarRepository(this.assetAzkar);

  List<ZekrEntity> assetAzkar;
  final List<ZekrEntity> customAzkar = [];
  bool failSave = false;
  bool failDelete = false;
  bool failUpdate = false;

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async => Right(assetAzkar);

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async =>
      Right(customAzkar);

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async {
    if (failSave) return const Left(DatabaseFailure('disk write failed'));
    customAzkar.addAll(items);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryName) async {
    if (failDelete) {
      return const Left(DatabaseFailure('disk write failed'));
    }
    customAzkar.removeWhere((e) => e.category == categoryName);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Unit>> updateCustomAzkarCategory(
      String oldCategory, List<ZekrEntity> items) async {
    if (failUpdate) {
      return const Left(DatabaseFailure('disk write failed'));
    }
    customAzkar.removeWhere((e) => e.category == oldCategory);
    customAzkar.addAll(items);
    return const Right(unit);
  }
}

AzkarProvider _buildProvider(_MemoryAzkarRepository repo) {
  return AzkarProvider(
    getAzkarUseCase: GetAzkarUseCase(azkarRepository: repo),
    getCustomAzkarUseCase: GetCustomAzkarUseCase(azkarRepository: repo),
    saveCustomAzkarUseCase: SaveCustomAzkarUseCase(azkarRepository: repo),
    deleteCustomAzkarUseCase: DeleteCustomAzkarUseCase(azkarRepository: repo),
    updateCustomAzkarUseCase:
        UpdateCustomAzkarUseCase(azkarRepository: repo),
  );
}

void main() {
  group('duplicate zekr texts', () {
    test('count independently within one custom category', () async {
      final repo = _MemoryAzkarRepository([])
        ..customAzkar.addAll([
          const ZekrEntity(
              category: 'دعاء', zekr: 'اللهم اغفر لي', count: '3',
              description: '', reference: ''),
          const ZekrEntity(
              category: 'دعاء', zekr: 'اللهم اغفر لي', count: '3',
              description: '', reference: ''),
          const ZekrEntity(
              category: 'دعاء', zekr: 'يا حي يا قيوم', count: '2',
              description: '', reference: ''),
        ]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();

      expect(
          provider.remainingFor('اللهم اغفر لي', 3,
              category: 'دعاء', index: 0),
          3);
      expect(
          provider.remainingFor('اللهم اغفر لي', 3,
              category: 'دعاء', index: 1),
          3);

      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 0);
      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 0);
      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 0);

      expect(
          provider.remainingFor('اللهم اغفر لي', 3,
              category: 'دعاء', index: 0),
          0);
      expect(
          provider.remainingFor('اللهم اغفر لي', 3,
              category: 'دعاء', index: 1),
          3);

      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 1);
      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 1);
      provider.decrement('اللهم اغفر لي', 3, category: 'دعاء', index: 1);

      expect(provider.completedIndexOf('دعاء'), 2);

      provider.resetCategoryCounts('دعاء');
      expect(
          provider.remainingFor('اللهم اغفر لي', 3,
              category: 'دعاء', index: 0),
          3);
      expect(provider.completedIndexOf('دعاء'), 0);
    });
  });

  group('updateCustomAzkarCategory', () {
    test('resets stale counting state so an edited category can complete',
        () async {
      final repo = _MemoryAzkarRepository([])
        ..customAzkar.addAll([
          const ZekrEntity(
              category: 'مذكراتي', zekr: 'استغفر الله', count: '1',
              description: '', reference: ''),
          const ZekrEntity(
              category: 'مذكراتي', zekr: 'الحمد لله', count: '1',
              description: '', reference: ''),
        ]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();

      provider.decrement('استغفر الله', 1, category: 'مذكراتي', index: 0);
      provider.decrement('الحمد لله', 1, category: 'مذكراتي', index: 1);
      expect(provider.completedIndexOf('مذكراتي'), 2);

      final ok = await provider.updateCustomAzkarCategory(
        oldCategoryTitle: 'مذكراتي',
        newCategoryTitle: 'أذكار المساء الجديدة',
        azkarItems: [
          {'text': 'استغفر الله', 'count': 1},
          {'text': 'الحمد لله', 'count': 1},
        ],
      );

      expect(ok, isTrue);
      expect(provider.completedIndexOf('مذكراتي'), 0);
      expect(provider.completedIndexOf('أذكار المساء الجديدة'), 0);
      expect(
          provider.remainingFor('استغفر الله', 1,
              category: 'أذكار المساء الجديدة', index: 0),
          1);
      expect(
          provider.customAzkarList
              .where((e) => e.category == 'أذكار المساء الجديدة')
              .length,
          2);
    });

    test('returns false and keeps data when the write fails', () async {
      final repo = _MemoryAzkarRepository([])
        ..customAzkar.addAll([
          const ZekrEntity(
              category: 'مذكراتي', zekr: 'استغفر الله', count: '1',
              description: '', reference: ''),
        ]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();
      repo.failUpdate = true;

      final ok = await provider.updateCustomAzkarCategory(
        oldCategoryTitle: 'مذكراتي',
        newCategoryTitle: 'اسم جديد',
        azkarItems: [
          {'text': 'استغفر الله', 'count': 1},
        ],
      );

      expect(ok, isFalse);
      expect(provider.customAzkarList.single.category, 'مذكراتي');
    });
  });

  group('saveCustomAzkarCategory', () {
    test('returns false and writes nothing when the save fails', () async {
      final repo = _MemoryAzkarRepository([]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();
      repo.failSave = true;

      final ok = await provider.saveCustomAzkarCategory(
        categoryTitle: 'جديدة',
        azkarItems: [
          {'text': 'ذكر', 'count': 1},
        ],
      );

      expect(ok, isFalse);
      expect(provider.customAzkarList, isEmpty);
    });

    test('returns true and reloads the list when the save succeeds',
        () async {
      final repo = _MemoryAzkarRepository([]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();

      final ok = await provider.saveCustomAzkarCategory(
        categoryTitle: 'جديدة',
        azkarItems: [
          {'text': 'ذكر', 'count': 1},
        ],
      );

      expect(ok, isTrue);
      expect(provider.customAzkarList.single.zekr, 'ذكر');
    });
  });

  group('deleteCustomCategory', () {
    test('returns false and keeps the category when the delete fails',
        () async {
      final repo = _MemoryAzkarRepository([])
        ..customAzkar.addAll([
          const ZekrEntity(
              category: 'مذكراتي', zekr: 'استغفر الله', count: '1',
              description: '', reference: ''),
        ]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();
      repo.failDelete = true;

      final ok = await provider.deleteCustomCategory('مذكراتي');

      expect(ok, isFalse);
      expect(provider.customCategories, contains('مذكراتي'));
    });

    test('returns true and removes the category on success', () async {
      final repo = _MemoryAzkarRepository([])
        ..customAzkar.addAll([
          const ZekrEntity(
              category: 'مذكراتي', zekr: 'استغفر الله', count: '1',
              description: '', reference: ''),
        ]);
      final provider = _buildProvider(repo);
      await provider.loadCustomAzkar();

      final ok = await provider.deleteCustomCategory('مذكراتي');

      expect(ok, isTrue);
      expect(provider.customCategories, isEmpty);
    });
  });
}