import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

/// Atomically replaces the rows of an existing custom azkar category
/// (deletes the old category and inserts the new items in one transaction).
class UpdateCustomAzkarUseCase {
  final AzkarRepository azkarRepository;
  UpdateCustomAzkarUseCase({required this.azkarRepository});

  Future<Either<Failure, Unit>> call({
    required String oldCategory,
    required List<ZekrEntity> items,
  }) {
    return azkarRepository.updateCustomAzkarCategory(oldCategory, items);
  }
}