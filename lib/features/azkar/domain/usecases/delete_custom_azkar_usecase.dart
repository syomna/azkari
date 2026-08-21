import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:azkar_app/core/error/failures.dart';

class DeleteCustomAzkarUseCase extends UseCase<void, String> {
  final AzkarRepository azkarRepository;

  DeleteCustomAzkarUseCase({required this.azkarRepository});

  @override
  Future<Either<Failure, void>> call(String params) {
    return azkarRepository.deleteCustomCategory(params);
  }
}
