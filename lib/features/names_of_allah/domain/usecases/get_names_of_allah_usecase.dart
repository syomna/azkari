import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:azkar_app/core/error/failures.dart';

class GetNamesOfAllahUseCase
    extends UseCase<List<NamesOfAllahEntity>, NoParams> {
  final NamesOfAllahRepository namesOfAllahRepository;

  GetNamesOfAllahUseCase({required this.namesOfAllahRepository});

  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> call(
      NoParams params) async {
    return await namesOfAllahRepository.getNamesOfAllah();
  }
}
