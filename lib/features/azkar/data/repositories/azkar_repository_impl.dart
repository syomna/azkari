import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:dartz/dartz.dart';

class AzkarRepositoryImpl extends AzkarRepository {
  final AzkarLocalDataSource azkarLocalDataSource;

  AzkarRepositoryImpl({required this.azkarLocalDataSource});

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async {
    final Either<Failure, List<AzkarModel>> result =
        await azkarLocalDataSource.getAzkar();
    return result.fold(
        (failure) => Left(failure), (azkarModels) => Right(azkarModels));
  }
}
