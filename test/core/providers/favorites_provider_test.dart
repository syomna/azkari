import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FavoritesProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    provider = FavoritesProvider(sharedPreferences: prefs);
  });

  group('FavoritesProvider', () {
    test('initial state is empty', () {
      expect(provider.favCategories, isEmpty);
      expect(provider.favIndividualItems, isEmpty);
    });

    test('loadFavorites reads from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('fav_categories', ['أذكار الصباح', 'أذكار المساء']);
      await prefs.setStringList('fav_items', ['بسم الله']);

      await provider.loadFavorites();

      expect(provider.favCategories, ['أذكار الصباح', 'أذكار المساء']);
      expect(provider.favIndividualItems, ['بسم الله']);
    });

    test('loadFavorites handles empty SharedPreferences', () async {
      await provider.loadFavorites();
      expect(provider.favCategories, isEmpty);
      expect(provider.favIndividualItems, isEmpty);
    });

    test('toggleCategoryFavorite adds a category', () async {
      await provider.toggleCategoryFavorite('أذكار الصباح');
      expect(provider.isCategoryFav('أذكار الصباح'), isTrue);
      expect(provider.favCategories, contains('أذكار الصباح'));
    });

    test('toggleCategoryFavorite removes a category', () async {
      await provider.toggleCategoryFavorite('أذكار الصباح');
      expect(provider.isCategoryFav('أذكار الصباح'), isTrue);

      await provider.toggleCategoryFavorite('أذكار الصباح');
      expect(provider.isCategoryFav('أذكار الصباح'), isFalse);
    });

    test('toggleItemFavorite adds an item', () async {
      await provider.toggleItemFavorite('بسم الله الرحمن الرحيم');
      expect(provider.isItemFav('بسم الله الرحمن الرحيم'), isTrue);
    });

    test('toggleItemFavorite removes an item', () async {
      await provider.toggleItemFavorite('بسم الله');
      expect(provider.isItemFav('بسم الله'), isTrue);

      await provider.toggleItemFavorite('بسم الله');
      expect(provider.isItemFav('بسم الله'), isFalse);
    });

    test('isCategoryFav returns false for unknown category', () {
      expect(provider.isCategoryFav('unknown'), isFalse);
    });

    test('isItemFav returns false for unknown item', () {
      expect(provider.isItemFav('unknown'), isFalse);
    });

    test('notifies listeners on toggleCategoryFavorite', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleCategoryFavorite('test');
      expect(notifyCount, 1);

      await provider.toggleCategoryFavorite('test');
      expect(notifyCount, 2);
    });

    test('notifies listeners on toggleItemFavorite', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleItemFavorite('test');
      expect(notifyCount, 1);
    });

    test('notifies listeners on loadFavorites', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadFavorites();
      expect(notifyCount, 1);
    });

    test('toggles persist to SharedPreferences', () async {
      await provider.toggleCategoryFavorite('أذكار الصباح');
      await provider.toggleItemFavorite('بسم الله');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('fav_categories'), contains('أذكار الصباح'));
      expect(prefs.getStringList('fav_items'), contains('بسم الله'));
    });

    test('multiple categories can be favorited', () async {
      await provider.toggleCategoryFavorite('أذكار الصباح');
      await provider.toggleCategoryFavorite('أذكار المساء');
      await provider.toggleCategoryFavorite('أذكار النوم');

      expect(provider.favCategories.length, 3);
      expect(provider.isCategoryFav('أذكار الصباح'), isTrue);
      expect(provider.isCategoryFav('أذكار المساء'), isTrue);
      expect(provider.isCategoryFav('أذكار النوم'), isTrue);
    });

    test('renameCategory replaces old name with new name', () async {
      await provider.toggleCategoryFavorite('أذكار الصباح');
      await provider.renameCategory('أذكار الصباح', 'Morning Azkar');

      expect(provider.isCategoryFav('أذكار الصباح'), isFalse);
      expect(provider.isCategoryFav('Morning Azkar'), isTrue);
      expect(provider.favCategories.length, 1);
    });

    test('renameCategory is no-op if old name not favorited', () async {
      await provider.renameCategory('nonexistent', 'new');
      expect(provider.favCategories, isEmpty);
    });
  });
}
