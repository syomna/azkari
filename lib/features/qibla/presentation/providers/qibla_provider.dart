import 'dart:async';
import 'dart:developer';

import 'package:azkar_app/core/utils/app_helpers.dart';
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

      log('serviceEnabled: $serviceEnabled');
      if (!serviceEnabled) {
        _isLoading = false;
        _errorMessage =
            'خدمات الموقع معطلة. يرجى تفعيل نظام تحديد المواقع (GPS).';
        notifyListeners();
        return;
      }

      // 2. Check Permissions (The App Dialog)
      LocationPermission permission = await Geolocator.checkPermission();

      log('permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLoading = false;
          _errorMessage = 'تم رفض الوصول إلى الموقع.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoading = false;
        _errorMessage =
            'صلاحيات الموقع مرفوضة نهائياً\n. يرجى تفعيلها من إعدادات التطبيق.';
        notifyListeners();
        return;
      }

      // Clean Arch: Provider doesn't know about Geolocator, only the Repo
      _qiblaDirection = await getQiblaDirectionUseCase.call();

      _compassSubscription = FlutterCompass.events!
          .distinct((prev, next) => (prev.heading! - next.heading!).abs() < 0.5)
          .listen((event) {
        _currentHeading = event.heading ?? 0;
        notifyListeners();
      });

      _isLoading = false;
      _errorMessage = null;
      // notifyListeners();
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
