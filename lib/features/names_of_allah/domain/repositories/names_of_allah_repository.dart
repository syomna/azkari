import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:dartz/dartz.dart';

abstract class NamesOfAllahRepository {
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah();
}
