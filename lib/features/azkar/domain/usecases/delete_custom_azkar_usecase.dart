import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteCustomAzkarUseCase {
  final AzkarRepository azkarRepository;
  DeleteCustomAzkarUseCase({required this.azkarRepository});

  Future<Either<Failure, void>> call(String categoryName) {
    return azkarRepository.deleteCustomCategory(categoryName);
  }
}
