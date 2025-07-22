import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AzkarRepository {
  Future<Either<Failure, List<ZekrEntity>>> getAzkar();
}
