import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/utils/azkar_category_filter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  final PrayerTimeService prayerTimeService;
  final SharedPreferences sharedPreferences;
  AzkarProvider(
      {required this.getAzkarUseCase,
      required this.prayerTimeService,
      required this.sharedPreferences}) {
    loadPrayerTimes();
  }
  // Azkar
  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;
  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;

  List<ZekrEntity> get morningAzkar => _azkarList.getMorningAzkar();

  List<ZekrEntity> get eveningAzkar => _azkarList.getEveningAzkar();

  List<ZekrEntity> get wakingUpAzkar => _azkarList.getWakingUpAzkar();

  List<ZekrEntity> get exitHomeAzkar => _azkarList.getExitHomeAzkar();

  List<ZekrEntity> get sleepingAzkar => _azkarList.getSleepingAzkar();

  List<ZekrEntity> get prayerAzkar => _azkarList.getPrayerAzkar();

  List<ZekrEntity> get variousDuaa => _azkarList.getVariousDuaa();

  List<ZekrEntity> get mosqueAzkar => _azkarList.getMosqueAzkar();
  PrayerTimes? _prayerTimes;

  PrayerTimes? get prayerTimes => _prayerTimes;
  Future<void> loadPrayerTimes() async {
    double? lat = sharedPreferences.getDouble('lat');
    double? lng = sharedPreferences.getDouble('lng');
    if (lat == null && lng == null) {
      final position = await prayerTimeService.getCurrentLocation();
      lat = position?.latitude;
      lng = position?.longitude;
      if (lat != null && lng != null) {
        await sharedPreferences.setDouble('lat', lat);
        await sharedPreferences.setDouble('lng', lng);
      }
    }

    if (lat != null && lng != null) {
      _prayerTimes = prayerTimeService.getTimes(lat, lng);
      notifyListeners();
    }
  }

  Future<void> loadAzkar() async {
    if (_azkarStatus == AppLoadingStatus.loading) {
      // Prevent multiple concurrent calls if already loading
      return;
    }
    _azkarStatus = AppLoadingStatus.loading;
    _azkarErrorMessage = null;
    final result = await getAzkarUseCase();
    result.fold((failure) {
      _azkarStatus = AppLoadingStatus.error;
      _azkarErrorMessage = failure.message;
      _azkarList = [];
      notifyListeners();
    }, (azkarList) {
      _azkarStatus = AppLoadingStatus.loaded;
      _azkarList = azkarList;
      notifyListeners();
    });
  }
}
