import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:flutter/material.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  final GetCustomAzkarUseCase getCustomAzkarUseCase;
  final SaveCustomAzkarUseCase saveCustomAzkarUseCase;
  final DeleteCustomAzkarUseCase deleteCustomAzkarUseCase;

  AzkarProvider({
    required this.getAzkarUseCase,
    required this.getCustomAzkarUseCase,
    required this.saveCustomAzkarUseCase,
    required this.deleteCustomAzkarUseCase,
  });

  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;

  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;

  List<ZekrEntity> _customAzkarList = [];

  List<String> _customCategories = [];
  List<String> _allCategories = [];

  List<ZekrEntity> get customAzkarList => _customAzkarList;
  List<String> get customCategories => _customCategories;
  List<String> get allCategories => _allCategories;

  Map<String, int> _categoryCounts = {};

  Map<String, int> get categoryCounts => _categoryCounts;

  void _rebuildCategories() {
    _customCategories =
        _customAzkarList.map((item) => item.category).toSet().toList();

    _allCategories = {
      ..._azkarList.map((item) => item.category),
      ..._customCategories,
    }.toList();

    _categoryCounts = {};

    for (final item in _azkarList) {
      _categoryCounts[item.category] =
          (_categoryCounts[item.category] ?? 0) + 1;
    }

    for (final item in _customAzkarList) {
      if (!_categoryCounts.containsKey(item.category)) {
        _categoryCounts[item.category] =
            (_categoryCounts[item.category] ?? 0) + 1;
      }
    }
  }

  Future<void> loadAzkar() async {
    if (_azkarStatus == AppLoadingStatus.loading) return;
    _azkarStatus = AppLoadingStatus.loading;
    _azkarErrorMessage = null;
    final result = await getAzkarUseCase(const NoParams());
    result.fold(
      (failure) {
        _azkarStatus = AppLoadingStatus.error;
        _azkarErrorMessage = failure.message;
        _azkarList = [];
        notifyListeners();
      },
      (azkarList) {
        _azkarStatus = AppLoadingStatus.loaded;
        _azkarList = azkarList;
        _rebuildCategories();
        notifyListeners();
      },
    );
  }


  Future<void> loadCustomAzkar() async {
    final result = await getCustomAzkarUseCase(const NoParams());
    result.fold(
      (failure) =>
          null, 
      (customList) {
        _customAzkarList = customList;
        _rebuildCategories();
        notifyListeners();
      },
    );
  }

  Future<void> saveCustomAzkarCategory({
    required String categoryTitle,
    required List<Map<String, dynamic>> azkarItems,
  }) async {
    final List<ZekrEntity> modelsToInsert = azkarItems.map((item) {
      return ZekrEntity(
        category: categoryTitle,
        zekr: item['text'] as String,
        count: item['count'] as int,
        description: '',
        reference: '',
      );
    }).toList();

    if (modelsToInsert.isNotEmpty) {
      final result = await saveCustomAzkarUseCase(modelsToInsert);
      await result.fold(
        (failure) => null, 
        (_) async =>
            await loadCustomAzkar(), 
      );
    }
  }

  Future<void> deleteCustomCategory(String categoryName) async {
    final result = await deleteCustomAzkarUseCase(categoryName);

    result.fold(
      (_) {},
      (_) async => await loadCustomAzkar(),
    );
  }
}
