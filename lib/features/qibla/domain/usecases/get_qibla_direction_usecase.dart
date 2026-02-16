import '../repositories/qibla_repository.dart';

class GetQiblaDirectionUseCase {
  final QiblaRepository repository;

  GetQiblaDirectionUseCase(this.repository);

  Future<double> call() async {
    return await repository.getQiblaDirection();
  }
}