import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:dartz/dartz.dart';

abstract class AzkarLocalDataSource {
  Future<Either<Failure, List<AzkarModel>>> getAzkar();
}
