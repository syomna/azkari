import 'package:adhan/adhan.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  final PrayerTimeService prayerTimeService;
  final SharedPreferences sharedPreferences;

  AzkarProvider({
    required this.getAzkarUseCase,
    required this.prayerTimeService,
    required this.sharedPreferences,
  }) {
    loadPrayerTimes();
  }

  // Azkar state (unchanged)
  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;
  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;
  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  // Callback to trigger notification reschedule when overrides change
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
      // Recalculate if stored date isn't today
      final storedDate = sharedPreferences.getString('prayer_time_date');
      final today =
          DateTime.now().toIso8601String().substring(0, 10); // "2026-03-24"

      if (storedDate != today) {
        await prayerTimeService.calculateAndStore(lat, lng, sharedPreferences);
        await sharedPreferences.setString('prayer_time_date', today);
      }

      // Only used for nextPrayer() highlighting in the UI
      _prayerTimes = prayerTimeService.getTimes(lat, lng);
      notifyListeners();
    }
  }

  // --- Overrides (delegate everything to PrayerTimeService) ---

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

  // Azkar loading (unchanged)
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

  // Inside AzkarProvider class

  List<String> _favCategories = [];
  List<String> _favIndividualItems = []; // Stores unique IDs or Text hashes

  List<String> get favCategories => _favCategories;
  List<String> get favIndividualItems => _favIndividualItems;

// 1. Load everything on startup
  void loadFavorites() {
    _favCategories = sharedPreferences.getStringList('fav_categories') ?? [];
    _favIndividualItems = sharedPreferences.getStringList('fav_items') ?? [];
    notifyListeners();
  }

// 2. Category Level Logic (The "Folder")
  Future<void> toggleCategoryFavorite(String categoryName) async {
    if (_favCategories.contains(categoryName)) {
      _favCategories.remove(categoryName);
    } else {
      _favCategories.add(categoryName);
    }
    await sharedPreferences.setStringList('fav_categories', _favCategories);
    notifyListeners();
  }

// 3. Individual Item Logic (The "Zikr" or "Ayah")
// Tip: If your ZekrEntity has a unique ID, use that. If not, use the zikr text.
  Future<void> toggleItemFavorite(String itemIdentifier) async {
    if (_favIndividualItems.contains(itemIdentifier)) {
      _favIndividualItems.remove(itemIdentifier);
    } else {
      _favIndividualItems.add(itemIdentifier);
    }
    await sharedPreferences.setStringList('fav_items', _favIndividualItems);
    notifyListeners();
  }

// Helpers for the UI
  bool isCategoryFav(String name) => _favCategories.contains(name);
  bool isItemFav(String identifier) => _favIndividualItems.contains(identifier);
}
