import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class AzkarRepositoryImpl extends AzkarRepository {
  final AzkarLocalDataSource azkarLocalDataSource;

  AzkarRepositoryImpl({required this.azkarLocalDataSource});

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async {
    final Either<Failure, List<AzkarModel>> result =
        await azkarLocalDataSource.getAzkar();
    return result.fold(
        (failure) => Left(failure), (azkarModels) => Right(azkarModels));
  }

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async {
    final Either<Failure, List<AzkarModel>> result =
        await azkarLocalDataSource.getCustomAzkar();

    return result.fold(
      (failure) => Left(failure),
      // Automatically upcasts List<AzkarModel> into List<ZekrEntity> cleanly
      (azkarModels) => Right(azkarModels),
    );
  }

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async {
    // Convert List<ZekrEntity> to explicit List<AzkarModel> objects for our database engine
    final List<AzkarModel> modelsToSave = items.map((entity) {
      return AzkarModel(
        category: entity.category,
        count: entity.count,
        description: entity.description,
        reference: entity.reference,
        zekr: entity.zekr,
      );
    }).toList();

    return await azkarLocalDataSource.saveCustomAzkar(modelsToSave);
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(String categoryName) async {
    try {
      await azkarLocalDataSource.deleteCustomCategory(categoryName);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete custom category: $e'));
    }
  }
}
