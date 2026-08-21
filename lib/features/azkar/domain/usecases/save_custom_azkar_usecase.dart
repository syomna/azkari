import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:azkar_app/core/error/failures.dart';

class SaveCustomAzkarUseCase extends UseCase<void, List<ZekrEntity>> {
  final AzkarRepository azkarRepository;

  SaveCustomAzkarUseCase({required this.azkarRepository});

  @override
  Future<Either<Failure, void>> call(List<ZekrEntity> params) async {
    return await azkarRepository.saveCustomAzkar(params);
  }
}
