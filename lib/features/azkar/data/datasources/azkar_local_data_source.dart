import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:dartz/dartz.dart';

abstract class AzkarLocalDataSource {
  Future<Either<Failure, List<AzkarModel>>> getAzkar();
  Future<Either<Failure, List<AzkarModel>>> getCustomAzkar();
  Future<Either<Failure, Unit>> saveCustomAzkar(List<AzkarModel> items);
  Future<void> deleteCustomCategory(String categoryName);
}
