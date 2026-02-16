import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:geolocator/geolocator.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  @override
  Future<double> getQiblaDirection() async {
    // 1. Check/Request Permissions
    await _handleLocationPermission();

    // 2. Get Position
    final position = await Geolocator.getCurrentPosition();

    // 3. Return the calculated angle
    return AppHelpers.calculateQiblaDirection(
      position.latitude,
      position.longitude,
    );
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
