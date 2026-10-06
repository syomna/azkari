import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles user favorites (categories + individual azkar/surah items).
///
/// Kept separate from [AzkarProvider] so each change-notifier has a single
/// responsibility and the favorite lists can be consumed independently.
class FavoritesProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  FavoritesProvider({required this.sharedPreferences}) {
    loadFavorites();
  }

  List<String> _favCategories = [];
  List<String> _favIndividualItems = [];

  List<String> get favCategories => _favCategories;
  List<String> get favIndividualItems => _favIndividualItems;

  /// المفضلة مقسومة إلى قائمتين: موضوعات الأذكار وموضوعات الأدعية، كل واحدة
  /// تُعرض في تبويب المفضلة بصفحتها. القسمة بالاسم كما في قاعدة البيانات
  /// ([isDuaCategory]) لا بمفتاح تخزين ثانٍ، فتبقى المفضلة الحالية كما هي
  /// وينتقل موضوع الدعاء المفضّل تلقائياً إلى قائمة الأدعية.
  List<String> get favAzkarCategories =>
      _favCategories.where((c) => !isDuaCategory(c)).toList();

  List<String> get favDuaCategories =>
      _favCategories.where(isDuaCategory).toList();

  void loadFavorites() {
    _favCategories =
        sharedPreferences.getStringList(PrefsKeys.favoriteCategories) ?? [];
    _favIndividualItems =
        sharedPreferences.getStringList(PrefsKeys.favoriteItems) ?? [];
    notifyListeners();
  }

  Future<void> toggleCategoryFavorite(String categoryName) async {
    final updated = List<String>.from(_favCategories);
    if (updated.contains(categoryName)) {
      updated.remove(categoryName);
    } else {
      updated.add(categoryName);
    }
    final ok = await sharedPreferences.setStringList(
        PrefsKeys.favoriteCategories, updated);
    if (ok) {
      _favCategories = updated;
      notifyListeners();
    }
  }

  Future<void> toggleItemFavorite(String itemIdentifier) async {
    final updated = List<String>.from(_favIndividualItems);
    if (updated.contains(itemIdentifier)) {
      updated.remove(itemIdentifier);
    } else {
      updated.add(itemIdentifier);
    }
    final ok =
        await sharedPreferences.setStringList(PrefsKeys.favoriteItems, updated);
    if (ok) {
      _favIndividualItems = updated;
      notifyListeners();
    }
  }

  bool isCategoryFav(String categoryName) =>
      _favCategories.contains(categoryName);
  bool isItemFav(String itemIdentifier) =>
      _favIndividualItems.contains(itemIdentifier);

  /// Removes a category from favorites (e.g. when a custom category is
  /// deleted). No-op if it wasn't favourited.
  Future<void> removeCategoryFavorite(String categoryName) async {
    if (!_favCategories.contains(categoryName)) return;
    final updated = List<String>.from(_favCategories)..remove(categoryName);
    final ok = await sharedPreferences.setStringList(
        PrefsKeys.favoriteCategories, updated);
    if (ok) {
      _favCategories = updated;
      notifyListeners();
    }
  }

  /// Renames a favourites entry from [oldName] to [newName] (used when a
  /// custom azkar category is renamed). No-op if the old name wasn't saved.
  Future<void> renameCategoryFavorite(String oldName, String newName) async {
    final index = _favCategories.indexOf(oldName);
    if (index == -1) return;
    final updated = List<String>.from(_favCategories)..[index] = newName;
    final ok = await sharedPreferences.setStringList(
        PrefsKeys.favoriteCategories, updated);
    if (ok) {
      _favCategories = updated;
      notifyListeners();
    }
  }

  /// Re-keys a single favourited item when its zekr text is edited inside the
  /// same category (`"$category\u0000old"` -> `"$category\u0000new"`). No-op
  /// if the old key isn't favourited.
  Future<void> renameItemFavorite(
      String category, String oldZekr, String newZekr) async {
    final oldKey = '$category\u0000$oldZekr';
    if (!_favIndividualItems.contains(oldKey)) return;
    final newKey = '$category\u0000$newZekr';
    final updated =
        _favIndividualItems.map((id) => id == oldKey ? newKey : id).toList();
    final ok =
        await sharedPreferences.setStringList(PrefsKeys.favoriteItems, updated);
    if (ok) {
      _favIndividualItems = updated;
      notifyListeners();
    }
  }

  /// Renames the saved item favourites belonging to a renamed custom category.
  /// Item keys are `"$category\u0000$zekr"`, so every key prefixed with
  /// `"$oldName\u0000"` is re-keyed to `"$newName\u0000..."`. No-op if the
  /// category had no favourited items.
  Future<void> renameCategoryItemFavorites(
      String oldName, String newName) async {
    final prefix = '$oldName\u0000';
    if (!_favIndividualItems.any((id) => id.startsWith(prefix))) return;
    final updated = _favIndividualItems
        .map((id) => id.startsWith(prefix)
            ? '$newName${id.substring(oldName.length)}'
            : id)
        .toList();
    final ok =
        await sharedPreferences.setStringList(PrefsKeys.favoriteItems, updated);
    if (ok) {
      _favIndividualItems = updated;
      notifyListeners();
    }
  }

  /// Drops every favourited item belonging to [categoryName] (used when its
  /// custom category is deleted, so saved items are not orphaned). No-op if
  /// the category had no favourited items.
  Future<void> removeCategoryItemFavorites(String categoryName) async {
    final prefix = '$categoryName\u0000';
    if (!_favIndividualItems.any((id) => id.startsWith(prefix))) return;
    final updated =
        _favIndividualItems.where((id) => !id.startsWith(prefix)).toList();
    final ok =
        await sharedPreferences.setStringList(PrefsKeys.favoriteItems, updated);
    if (ok) {
      _favIndividualItems = updated;
      notifyListeners();
    }
  }
}
