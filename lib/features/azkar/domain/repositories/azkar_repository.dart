import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AzkarRepository {
  Future<Either<Failure, List<ZekrEntity>>> getAzkar();
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar();
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items);
  Future<Either<Failure, void>> deleteCustomCategory(String categoryName);
}
