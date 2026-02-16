import 'dart:async';

import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/qibla/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaProvider extends ChangeNotifier {
  final GetQiblaDirectionUseCase getQiblaDirectionUseCase;
  QiblaProvider({required this.getQiblaDirectionUseCase});

  double _qiblaDirection = 0;
  double get qiblaDirection => _qiblaDirection;

  double _currentHeading = 0;
  double get currentHeading => _currentHeading;

  double get difference => AppHelpers.normalize(_qiblaDirection - _currentHeading); 

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

      // Clean Arch: Provider doesn't know about Geolocator, only the Repo
      _qiblaDirection = await getQiblaDirectionUseCase.call();

      _compassSubscription = FlutterCompass.events!
          .distinct((prev, next) => (prev.heading! - next.heading!).abs() < 0.5)
          .listen((event) {
        _currentHeading = event.heading ?? 0;
        notifyListeners();
      });

      _isLoading = false;
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
