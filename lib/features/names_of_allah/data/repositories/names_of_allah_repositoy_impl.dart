import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:dartz/dartz.dart';

class NamesOfAllahRepositoyImpl extends NamesOfAllahRepository {
  NamesOfAllahLocalDataSource namesOfAllahLocalDataSource;
  NamesOfAllahRepositoyImpl({required this.namesOfAllahLocalDataSource});
  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah() async {
    Either<Failure, List<NamesOfAllahModel>> result =
        await namesOfAllahLocalDataSource.getNamesOfAllah();
    return result.fold((failure) => Left(failure),
        (namesOfAllahModels) => Right(namesOfAllahModels));
  }
}
