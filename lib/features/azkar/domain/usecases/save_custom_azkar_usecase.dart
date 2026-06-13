import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class SaveCustomAzkarUseCase {
  final AzkarRepository azkarRepository;

  SaveCustomAzkarUseCase({required this.azkarRepository});

  Future<Either<Failure, Unit>> call(List<ZekrEntity> items) async {
    return await azkarRepository.saveCustomAzkar(items);
  }
}