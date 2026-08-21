import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  FavoritesProvider({required this.sharedPreferences});

  List<String> _favCategories = [];
  List<String> _favIndividualItems = [];

  List<String> get favCategories => List<String>.unmodifiable(_favCategories);
  List<String> get favIndividualItems => List<String>.unmodifiable(_favIndividualItems);

  Future<void> loadFavorites() async {
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

  Future<void> renameCategory(String oldName, String newName) async {
    if (!_favCategories.contains(oldName)) return;
    final index = _favCategories.indexOf(oldName);
    _favCategories[index] = newName;
    await sharedPreferences.setStringList('fav_categories', _favCategories);
    notifyListeners();
  }
}
