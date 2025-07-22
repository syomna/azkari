import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:dartz/dartz.dart';

class GetNamesOfAllahUseCase {
  NamesOfAllahRepository namesOfAllahRepository;
  GetNamesOfAllahUseCase({required this.namesOfAllahRepository});

  Future<Either<Failure, List<NamesOfAllahEntity>>> call() async {
    return await namesOfAllahRepository.getNamesOfAllah();
  }
}
