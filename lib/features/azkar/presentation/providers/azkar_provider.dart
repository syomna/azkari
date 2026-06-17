import 'dart:developer';

import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
// IMPORT YOUR NEW USE CASES HERE
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  // Added new custom use case dependencies
  final GetCustomAzkarUseCase getCustomAzkarUseCase;
  final SaveCustomAzkarUseCase saveCustomAzkarUseCase;
  final DeleteCustomAzkarUseCase deleteCustomAzkarUseCase;

  final PrayerTimeService prayerTimeService;
  final SharedPreferences sharedPreferences;

  AzkarProvider({
    required this.getAzkarUseCase,
    required this.getCustomAzkarUseCase,
    required this.saveCustomAzkarUseCase,
    required this.deleteCustomAzkarUseCase,
    required this.prayerTimeService,
    required this.sharedPreferences,
  }) {
    _initData();
  }

  // Orchestrate app initialization steps safely
  Future<void> _initData() async {
    await loadAzkar();
    loadFavorites();
    await loadCustomAzkar(); // Load sqflite cache data right away
    await loadPrayerTimes();
  }

  // --- Core Azkar Asset State ---
  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;
  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;

  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  // --- 📍 NEW: Custom User-Generated Azkar State ---
  List<ZekrEntity> _customAzkarList = [];
  List<ZekrEntity> get customAzkarList => _customAzkarList;

  // Extends your navigation menus by getting all unique custom titles
  List<String> get customCategories {
    return _customAzkarList.map((item) => item.category).toSet().toList();
  }

  VoidCallback? onOverrideChanged;

  Future<void> loadPrayerTimes() async {
    double? lat = sharedPreferences.getDouble('lat');
    double? lng = sharedPreferences.getDouble('lng');

    if (lat == null || lng == null) {
      final position = await prayerTimeService.getCurrentLocation();
      lat = position?.latitude;
      lng = position?.longitude;
      if (lat != null && lng != null) {
        await sharedPreferences.setDouble('lat', lat);
        await sharedPreferences.setDouble('lng', lng);
      }
    }

    if (lat != null && lng != null) {
      final storedDate = sharedPreferences.getString('prayer_time_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (storedDate != today) {
        await prayerTimeService.calculateAndStore(lat, lng, sharedPreferences);
        await sharedPreferences.setString('prayer_time_date', today);
      }

      _prayerTimes = prayerTimeService.getTimes(lat, lng);
      notifyListeners();
    }
  }

  // --- Overrides ---
  Map<String, TimeOfDay> get allDisplayTimes =>
      prayerTimeService.getEffectiveTimes(sharedPreferences);

  TimeOfDay? getDisplayTime(String key) => allDisplayTimes[key];

  bool isOverridden(String key) =>
      prayerTimeService.hasOverride(key, sharedPreferences);

  void setOverride(String key, TimeOfDay time) {
    prayerTimeService.saveOverride(key, time, sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
  }

  void clearOverride(String key) {
    prayerTimeService.clearOverride(key, sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
  }

  void clearAllOverrides() {
    prayerTimeService.clearAllOverrides(sharedPreferences);
    notifyListeners();
    onOverrideChanged?.call();
  }

  // Standard Azkar loading from JSON
  Future<void> loadAzkar() async {
    if (_azkarStatus == AppLoadingStatus.loading) return;
    _azkarStatus = AppLoadingStatus.loading;
    _azkarErrorMessage = null;
    final result = await getAzkarUseCase();
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
        notifyListeners();
      },
    );
  }

  // --- 📍 NEW: Custom SQLite Interaction Handlers via Use Cases ---

  /// Fetches your user-defined entries natively from the database helper layer
  Future<void> loadCustomAzkar() async {
    final result = await getCustomAzkarUseCase();
    result.fold(
      (failure) =>
          null, // Fail silently or assign to a dedicated error state if needed
      (customList) {
        _customAzkarList = customList;
        notifyListeners();
      },
    );
  }

  /// Packages multi-field dynamic inputs into pure entities and writes them to sqflite
  Future<void> saveCustomAzkarCategory({
    required String categoryTitle,
    required List<Map<String, dynamic>> azkarItems,
  }) async {
    final List<ZekrEntity> modelsToInsert = azkarItems.map((item) {
      return ZekrEntity(
        category: categoryTitle,
        zekr: item['text'] as String,
        count: (item['count'] as int)
            .toString(), // 👈 Here is your custom counter parsed properly!
        description: '',
        reference: '',
      );
    }).toList();

    if (modelsToInsert.isNotEmpty) {
      final result = await saveCustomAzkarUseCase(modelsToInsert);
      await result.fold(
        (failure) => null, // Handle local disk write constraint exceptions here
        (_) async =>
            await loadCustomAzkar(), // Reload immediately to populate UI maps
      );
    }
  }

  Future<void> deleteCustomCategory(String categoryName,
      {bool keepInFavorites = false}) async {
    final result = await deleteCustomAzkarUseCase(categoryName);

    result.fold(
      (failure) => log('Failed to delete category: ${failure.message}'),
      (_) async {
        log('Successfully deleted category: $categoryName');
        await loadCustomAzkar();

        if (!keepInFavorites) {
          if (_favCategories.contains(categoryName)) {
            _favCategories.remove(categoryName);
            await sharedPreferences.setStringList(
                'fav_categories', _favCategories);
          }
        }
        loadFavorites();
      },
    );
  }

  // --- Favorites Management ---
  List<String> _favCategories = [];
  List<String> _favIndividualItems = [];

  List<String> get favCategories => _favCategories;
  List<String> get favIndividualItems => _favIndividualItems;

  void loadFavorites() {
    _favCategories = sharedPreferences.getStringList('fav_categories') ?? [];
    _favIndividualItems = sharedPreferences.getStringList('fav_items') ?? [];
    notifyListeners();
  }

  Future<void> toggleCategoryFavorite(String categoryName) async {
    if (_favCategories.contains(categoryName)) {
      _favCategories.remove(categoryName);
    } else {
      _favCategories.add(categoryName);
    }
    await sharedPreferences.setStringList('fav_categories', _favCategories);
    notifyListeners();
  }

  Future<void> toggleItemFavorite(String itemIdentifier) async {
    if (_favIndividualItems.contains(itemIdentifier)) {
      _favIndividualItems.remove(itemIdentifier);
    } else {
      _favIndividualItems.add(itemIdentifier);
    }
    await sharedPreferences.setStringList('fav_items', _favIndividualItems);
    notifyListeners();
  }

  bool isCategoryFav(String name) => _favCategories.contains(name);
  bool isItemFav(String identifier) => _favIndividualItems.contains(identifier);
}
