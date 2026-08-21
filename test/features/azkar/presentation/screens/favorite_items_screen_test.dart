import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/screens/favorite_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> buildTestApp(Widget child, {List<String>? favItems}) async {
  SharedPreferences.setMockInitialValues({'fav_items': favItems ?? []});
  final prefs = await SharedPreferences.getInstance();
  final provider = FavoritesProvider(sharedPreferences: prefs);
  await provider.loadFavorites();

  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (ctx, _) => MaterialApp(
      locale: const Locale('ar'),
      home: ChangeNotifierProvider<FavoritesProvider>.value(
        value: provider,
        child: child,
      ),
    ),
  );
}

void main() {
  group('FavoriteItemsScreen', () {
    testWidgets('shows empty state when no favorites', (tester) async {
      final app = await buildTestApp(const FavoriteItemsScreen());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.emptyFavorites), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });

    testWidgets('displays favorited items', (tester) async {
      final app = await buildTestApp(
        const FavoriteItemsScreen(),
        favItems: ['بسم الله الرحمن الرحيم', 'الحمد لله'],
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('بسم الله الرحمن الرحيم'), findsOneWidget);
      expect(find.text('الحمد لله'), findsOneWidget);
      expect(find.text(AppStrings.emptyFavorites), findsNothing);
    });

    testWidgets('AppBar shows correct title', (tester) async {
      final app = await buildTestApp(const FavoriteItemsScreen());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('المحفوظات'), findsOneWidget);
    });
  });
}
