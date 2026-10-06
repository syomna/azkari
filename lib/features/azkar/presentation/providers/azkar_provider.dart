import 'dart:developer';

import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:flutter/material.dart';

class AzkarProvider extends ChangeNotifier {
  final GetAzkarUseCase getAzkarUseCase;
  final GetCustomAzkarUseCase getCustomAzkarUseCase;
  final SaveCustomAzkarUseCase saveCustomAzkarUseCase;
  final DeleteCustomAzkarUseCase deleteCustomAzkarUseCase;
  final UpdateCustomAzkarUseCase updateCustomAzkarUseCase;

  AzkarProvider({
    required this.getAzkarUseCase,
    required this.getCustomAzkarUseCase,
    required this.saveCustomAzkarUseCase,
    required this.deleteCustomAzkarUseCase,
    required this.updateCustomAzkarUseCase,
  }) {
    _initData();
  }

  // Orchestrate app initialization steps safely
  Future<void> _initData() async {
    await loadAzkar();
    await loadCustomAzkar(); // Load sqflite cache data right away
  }

  // --- Core Azkar Asset State ---
  List<ZekrEntity> _azkarList = [];
  AppLoadingStatus _azkarStatus = AppLoadingStatus.initial;
  String? _azkarErrorMessage;
  List<ZekrEntity> get azkarList => _azkarList;
  AppLoadingStatus get azkarStatus => _azkarStatus;
  String? get azkarErrorMessage => _azkarErrorMessage;

  // --- 📍 NEW: Custom User-Generated Azkar State ---
  List<ZekrEntity> _customAzkarList = [];
  List<ZekrEntity> get customAzkarList => _customAzkarList;

  // Extends your navigation menus by getting all unique custom titles
  List<String> get customCategories {
    return _customAzkarList.map((item) => item.category).toSet().toList();
  }

  /// موضوعات الأدعية في البيانات الأصلية، لصفحة الأدعية.
  List<String> get duaCategories => duaCategoriesFrom(_azkarList);

  /// عدد أدعية موضوع معيّن.
  int duaCountIn(String category) =>
      _azkarList.where((item) => item.category == category).length;

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

  /// Packages multi-field dynamic inputs into pure entities and writes them to
  /// sqflite. Returns whether the write actually succeeded so callers only
  /// report success / navigate when the data really persisted.
  Future<bool> saveCustomAzkarCategory({
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

    if (modelsToInsert.isEmpty) return false;

    final result = await saveCustomAzkarUseCase(modelsToInsert);
    return result.fold(
      (failure) async {
        log('Failed to save category: ${failure.message}');
        return false;
      },
      (_) async {
        await loadCustomAzkar(); // Reload immediately to populate UI maps
        return true;
      },
    );
  }

  /// Deletes a custom category. Returns whether the delete actually happened.
  Future<bool> deleteCustomCategory(String categoryName) async {
    final result = await deleteCustomAzkarUseCase(categoryName);
    return result.fold(
      (failure) async {
        log('Failed to delete category: ${failure.message}');
        return false;
      },
      (_) async {
        log('Successfully deleted category: $categoryName');
        await loadCustomAzkar();
        return true;
      },
    );
  }

  /// Atomically replaces the items of [oldCategoryTitle] (optionally renaming
  /// it to [newCategoryTitle]). Unlike delete-then-save, a disk failure cannot
  /// leave the old category deleted. Returns whether the write succeeded.
  Future<bool> updateCustomAzkarCategory({
    required String oldCategoryTitle,
    required String newCategoryTitle,
    required List<Map<String, dynamic>> azkarItems,
  }) async {
    final List<ZekrEntity> modelsToInsert = azkarItems.map((item) {
      return ZekrEntity(
        category: newCategoryTitle,
        zekr: item['text'] as String,
        count: (item['count'] as int).toString(),
        description: '',
        reference: '',
      );
    }).toList();

    if (modelsToInsert.isEmpty) return false;

    final result = await updateCustomAzkarUseCase.call(
      oldCategory: oldCategoryTitle,
      items: modelsToInsert,
    );
    return result.fold(
      (failure) async {
        log('Failed to update category: ${failure.message}');
        return false;
      },
      (_) async {
        // Editing a category invalidates its in-memory counting: completed
        // state and any stale per-item remainders for BOTH the old and the new
        // name must be dropped, otherwise a shrunken item list keeps an
        // impossible remainder ("٢٠ / ٥") and the category can never
        // complete again.
        _completedIndex.remove(oldCategoryTitle);
        _completedIndex.remove(newCategoryTitle);
        _clearCategoryCountKeys(oldCategoryTitle);
        _clearCategoryCountKeys(newCategoryTitle);
        await loadCustomAzkar();
        return true;
      },
    );
  }

  // --- Counting State (in-memory only so it resets each app session) ---
  // Azkar are meant to be re-read daily, so counts intentionally reset every
  // time the app launches. This state lives in the (app-scoped) provider so it
  // survives `ListView` recycling (scrolling) within a single session.
  final Map<String, int> _remainingCounts = {};
  final Map<String, int> _completedIndex = {};

  // A zekr's text can appear in multiple categories; key by category + text so
  // completing it in one category does not mark it done in another. The index
  // part disambiguates duplicate zekr texts *within* a single custom category
  // (two identical rows previously shared one counter, so they always finished
  // together and the category could never complete).
  String _countKey(String category, int index, String zekr) =>
      '$category\u0000$index\u0000$zekr';

  int remainingFor(String zekr, int total,
          {required String category, int index = 0}) =>
      _remainingCounts[_countKey(category, index, zekr)] ?? total;

  int completedIndexOf(String category) => _completedIndex[category] ?? 0;

  /// Decrements the remaining count for a zekr and advances the category
  /// progress when the zekr is finished. The count lives in the provider so
  /// that `ListView` recycling (scrolling) does not reset it.
  void decrement(String zekr, int total,
      {required String category, int index = 0}) {
    final key = _countKey(category, index, zekr);
    final current = _remainingCounts[key] ?? total;
    if (current <= 0) return;
    _remainingCounts[key] = current - 1;
    if (current - 1 == 0) {
      _completedIndex[category] = (_completedIndex[category] ?? 0) + 1;
    }
    notifyListeners();
  }

  /// Drops every counting row that belongs to [category].
  void _clearCategoryCountKeys(String category) {
    final prefix = '$category\u0000';
    _remainingCounts.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Resets all counting progress for a single category (e.g. from a
  /// user-tapped reset button on the details page).
  void resetCategoryCounts(String categoryName) {
    _clearCategoryCountKeys(categoryName);
    _completedIndex.remove(categoryName);
    notifyListeners();
  }
}
