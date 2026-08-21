import 'package:azkar_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class QiblaRepository {
  Future<Either<Failure, double>> getQiblaDirection();
}
