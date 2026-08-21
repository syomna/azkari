import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:azkar_app/core/error/failures.dart';

class GetCustomAzkarUseCase extends UseCase<List<ZekrEntity>, NoParams> {
  final AzkarRepository azkarRepository;

  GetCustomAzkarUseCase({required this.azkarRepository});

  @override
  Future<Either<Failure, List<ZekrEntity>>> call(NoParams params) async {
    return await azkarRepository.getCustomAzkar();
  }
}
