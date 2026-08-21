import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:dartz/dartz.dart';

class GetQiblaDirectionUseCase extends UseCase<double, NoParams> {
  final QiblaRepository repository;

  GetQiblaDirectionUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) async {
    return await repository.getQiblaDirection();
  }
}
