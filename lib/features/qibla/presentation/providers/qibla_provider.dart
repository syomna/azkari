import 'dart:async';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/qibla/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaProvider extends ChangeNotifier {
  final GetQiblaDirectionUseCase getQiblaDirectionUseCase;
  QiblaProvider({required this.getQiblaDirectionUseCase});

  double _qiblaDirection = 0;
  double get qiblaDirection => _qiblaDirection;

  double _currentHeading = 0;
  double get currentHeading => _currentHeading;

  double get difference =>
      AppHelpers.normalize(_qiblaDirection - _currentHeading);

  bool get isAligned => difference <= 5 || difference >= 355;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<CompassEvent>? _compassSubscription;

  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _isLoading = false;
        _errorMessage = AppStrings.locationDisabled;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLoading = false;
          _errorMessage = AppStrings.locationDenied;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoading = false;
        _errorMessage = AppStrings.locationPermanentlyDenied;
        notifyListeners();
        return;
      }

      final result = await getQiblaDirectionUseCase(const NoParams());
      final success = result.fold(
        (failure) {
          _isLoading = false;
          _errorMessage = failure.message;
          return false;
        },
        (direction) {
          _qiblaDirection = direction;
          return true;
        },
      );

      if (success) {
        _compassSubscription?.cancel();
        if (FlutterCompass.events != null) {
          _compassSubscription = FlutterCompass.events!
              .distinct((prev, next) {
                final prevHeading = prev.heading;
                final nextHeading = next.heading;
                if (prevHeading == null || nextHeading == null) return false;
                return (prevHeading - nextHeading).abs() < 0.5;
              })
              .listen((event) {
            _currentHeading = event.heading ?? 0;
            notifyListeners();
          });
        }

        _isLoading = false;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
