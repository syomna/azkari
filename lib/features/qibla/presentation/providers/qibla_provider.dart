import 'dart:async';
import 'dart:developer';

import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/qibla/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaProvider extends ChangeNotifier with WidgetsBindingObserver {
  final GetQiblaDirectionUseCase getQiblaDirectionUseCase;
  QiblaProvider({required this.getQiblaDirectionUseCase}) {
    WidgetsBinding.instance.addObserver(this);
  }

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

  bool _compassUnavailable = false;
  bool get compassUnavailable => _compassUnavailable;

  StreamSubscription<CompassEvent>? _compassSubscription;
  Future<void>? _initFuture;
  bool _disposed = false;

  Future<void> init() async {
    if (_disposed) return;
    _initFuture ??= _init();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  /// (Re)subscribes to compass events. Cancels any previous subscription
  /// first so a paused-then-resumed (or re-entered) lifecycle never leaks a
  /// second `StreamSubscription`.
  void _subscribeToCompass() {
    if (_disposed) return;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    if (FlutterCompass.events == null) {
      // No compass/magnetometer on this device — surface that instead of
      // silently degrading to a frozen heading of 0°.
      _compassUnavailable = true;
      _notify();
      return;
    }
    _compassUnavailable = false;
    _compassSubscription = FlutterCompass.events!.distinct((prev, next) {
      final prevHeading = prev.heading;
      final nextHeading = next.heading;
      if (prevHeading == null || nextHeading == null) return false;
      return (prevHeading - nextHeading).abs() < 0.5;
    }).listen(
      (event) {
        if (_disposed) return;
        _currentHeading = event.heading ?? 0;
        _notify();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        _compassUnavailable = true;
        _notify();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Stop receiving sensor updates while the screen is away; forwarding
      // notifications to a paved-over route wastes cycles and battery.
      _compassSubscription?.cancel();
      _compassSubscription = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_qiblaDirection != 0) {
        _subscribeToCompass();
      } else {
        // Never finished initializing before pausing — resume the flow.
        // `_initFuture` dedupes against any in-flight init.
        init();
      }
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      _isLoading = true;
      _notify();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      log('serviceEnabled: $serviceEnabled');
      if (!serviceEnabled) {
        _isLoading = false;
        _errorMessage =
            'خدمات الموقع معطلة. يرجى تفعيل نظام تحديد المواقع (GPS).';
        _notify();
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
          _notify();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoading = false;
        _errorMessage =
            'صلاحيات الموقع مرفوضة نهائياً.\nيرجى تفعيلها من إعدادات التطبيق.';
        _notify();
        return;
      }

      // Clean Arch: Provider doesn't know about Geolocator, only the Repo
      _qiblaDirection = await getQiblaDirectionUseCase.call();

      if (_disposed) return;

      _subscribeToCompass();

      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[QiblaProvider] init failed: $e');
      _errorMessage = 'حدث خطأ أثناء تحديد اتجاه القبلة. أعد المحاولة.';
      _isLoading = false;
    }
    _notify();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    super.dispose();
  }
}
