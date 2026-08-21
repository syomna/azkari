import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateCustomAzkarParams extends Equatable {
  const UpdateCustomAzkarParams({
    required this.originalCategory,
    required this.newCategory,
    required this.items,
  });

  final String originalCategory;
  final String newCategory;
  final List<ZekrEntity> items;

  @override
  List<Object?> get props => [originalCategory, newCategory, items];
}

class UpdateCustomAzkarUseCase
    extends UseCase<void, UpdateCustomAzkarParams> {
  final AzkarRepository azkarRepository;

  UpdateCustomAzkarUseCase({required this.azkarRepository});

  @override
  Future<Either<Failure, void>> call(UpdateCustomAzkarParams params) async {
    return await azkarRepository.updateCustomCategory(
      originalCategory: params.originalCategory,
      newCategory: params.newCategory,
      items: params.items,
    );
  }
}
