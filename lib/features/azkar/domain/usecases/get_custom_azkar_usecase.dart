import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class GetCustomAzkarUseCase {
  final AzkarRepository azkarRepository;

  GetCustomAzkarUseCase({required this.azkarRepository});

  Future<Either<Failure, List<ZekrEntity>>> call() async {
    return await azkarRepository.getCustomAzkar();
  }
}