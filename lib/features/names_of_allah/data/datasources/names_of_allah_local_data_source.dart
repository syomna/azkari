import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:dartz/dartz.dart';

abstract class NamesOfAllahLocalDataSource {
  Future<Either<Failure, List<NamesOfAllahModel>>> getNamesOfAllah();
}