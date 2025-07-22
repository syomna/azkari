import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class GetAzkarUseCase {
  final AzkarRepository azkarRepository;

  GetAzkarUseCase({required this.azkarRepository});
  Future<Either<Failure, List<ZekrEntity>>> call() async {
    return await azkarRepository.getAzkar();
  }
}
