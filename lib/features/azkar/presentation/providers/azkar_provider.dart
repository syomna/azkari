import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:flutter/material.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  AzkarProvider({required this.getAzkarUseCase});
  // Azkar
  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;
  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;

  List<ZekrEntity> get morningAzkar =>
      _azkarList.where((e) => e.category == 'أذكار الصباح').toList();

  List<ZekrEntity> get eveningAzkar =>
      _azkarList.where((e) => e.category == 'أذكار المساء').toList();

  List<ZekrEntity> get wakingUpAzkar => _azkarList
      .where((e) => e.category == 'أذكار الاستيقاظ من النوم')
      .toList();

  List<ZekrEntity> get prayerAzkar =>
      _azkarList.where((e) => e.category == 'أذكار الآذان').toList();

  List<ZekrEntity> get variousDuaa => _azkarList
      .where((e) =>
          e.category != 'أذكار الصباح' &&
          e.category != 'أذكار المساء' &&
          e.category != 'أذكار الاستيقاظ من النوم' &&
          e.category != 'أذكار الآذان')
      .toList();

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
