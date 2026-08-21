import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  @override
  Future<Either<Failure, double>> getQiblaDirection() async {
    try {
      await _handleLocationPermission();

      final position = await Geolocator.getCurrentPosition();

      final direction = AppHelpers.calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );
      return Right(direction);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
  }
}
