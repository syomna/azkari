import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<FavoritesProvider> buildProvider(
      Map<String, Object> initialValues) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    return FavoritesProvider(sharedPreferences: prefs);
  }

  group('azkar and dua favorites are separate lists', () {
    test('each library sees only its own topics', () async {
      final provider = await buildProvider({
        PrefsKeys.favoriteCategories: [
          'أذكار الصباح',
          'دعاء الكرب',
          'أدعية طلب العلم',
          'دعاء السفر',
        ],
      });

      expect(provider.favAzkarCategories, ['أذكار الصباح']);
      expect(provider.favDuaCategories,
          ['دعاء الكرب', 'أدعية طلب العلم', 'دعاء السفر']);
      // القائمتان معاً كل المفضلة المخزّنة، فلا يضيع موضوع.
      expect(
          provider.favAzkarCategories.length + provider.favDuaCategories.length,
          provider.favCategories.length);
    });

    test('a topic added later lands in the list of its own library', () async {
      final provider = await buildProvider(const {});

      await provider.toggleCategoryFavorite('دعاء الاستخارة');
      await provider.toggleCategoryFavorite('أذكار السفر');

      expect(provider.favDuaCategories, ['دعاء الاستخارة']);
      expect(provider.favAzkarCategories, ['أذكار السفر']);
      expect(provider.isCategoryFav('دعاء الاستخارة'), isTrue);
    });

    test('removing a dua favorite leaves the azkar list untouched', () async {
      final provider = await buildProvider({
        PrefsKeys.favoriteCategories: ['أذكار الصباح', 'دعاء الكرب'],
      });

      await provider.removeCategoryFavorite('دعاء الكرب');

      expect(provider.favDuaCategories, isEmpty);
      expect(provider.favAzkarCategories, ['أذكار الصباح']);
    });
  });

  group('renameCategoryItemFavorites', () {
    test('re-keys favourited items of the renamed category', () async {
      final provider = await buildProvider({
        PrefsKeys.favoriteCategories: ['صباح'],
        PrefsKeys.favoriteItems: [
          'صباح\u0000ذكر أول',
          'مساء\u0000ذكر ثان',
          'استغفرالله',
        ],
      });

      await provider.renameCategoryItemFavorites('صباح', 'صباح جديد');

      expect(provider.favIndividualItems, contains('صباح جديد\u0000ذكر أول'));
      expect(provider.favIndividualItems, contains('مساء\u0000ذكر ثان'));
      expect(provider.favIndividualItems, contains('استغفرالله'));
      expect(provider.favIndividualItems, isNot(contains('صباح\u0000ذكر أول')));
    });
  });

  group('removeCategoryItemFavorites', () {
    test('drops every favourited item of the deleted category', () async {
      final provider = await buildProvider({
        PrefsKeys.favoriteCategories: ['مساء'],
        PrefsKeys.favoriteItems: [
          'صباح\u0000ذكر أول',
          'مساء\u0000ذكر ثان',
          'مساء\u0000ذكر ثالث',
        ],
      });

      await provider.removeCategoryItemFavorites('مساء');

      expect(provider.favIndividualItems, contains('صباح\u0000ذكر أول'));
      expect(provider.favIndividualItems, isNot(contains('مساء\u0000ذكر ثان')));
      expect(
          provider.favIndividualItems, isNot(contains('مساء\u0000ذكر ثالث')));
      expect(provider.favCategories, contains('مساء'));
    });
  });
}
