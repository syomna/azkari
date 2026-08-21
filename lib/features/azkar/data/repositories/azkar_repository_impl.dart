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
    try {
      final List<AzkarModel> azkarModels = await azkarLocalDataSource.getAzkar();
      return Right(azkarModels);
    } catch (e) {
      return Left(JsonParsingFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async {
    try {
      final List<AzkarModel> azkarModels =
          await azkarLocalDataSource.getCustomAzkar();
      return Right(azkarModels);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async {
    try {
      final List<AzkarModel> modelsToSave = items.map((entity) {
        return AzkarModel(
          category: entity.category,
          count: entity.count,
          description: entity.description,
          reference: entity.reference,
          zekr: entity.zekr,
        );
      }).toList();

      await azkarLocalDataSource.saveCustomAzkar(modelsToSave);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryName) async {
    try {
      await azkarLocalDataSource.deleteCustomCategory(categoryName);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
