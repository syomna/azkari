import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/screens/all_azkar_screen.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'all_azkar_screen_test.mocks.dart';

@GenerateMocks([
  AzkarProvider,
  FavoritesProvider,
  SurahProvider,
])
void main() {
  late MockAzkarProvider mockAzkarProvider;
  late MockFavoritesProvider mockFavoritesProvider;
  late MockSurahProvider mockSurahProvider;

  setUp(() {
    mockAzkarProvider = MockAzkarProvider();
    mockFavoritesProvider = MockFavoritesProvider();
    mockSurahProvider = MockSurahProvider();

    when(mockAzkarProvider.allCategories).thenReturn([
      AppStrings.morningAzkar,
      AppStrings.eveningAzkar,
    ]);
    when(mockAzkarProvider.customCategories).thenReturn([]);
    when(mockAzkarProvider.categoryCounts).thenReturn({
      AppStrings.morningAzkar: 5,
      AppStrings.eveningAzkar: 5,
    });
    when(mockFavoritesProvider.isCategoryFav(any)).thenReturn(false);
    when(mockFavoritesProvider.favCategories).thenReturn([]);
    when(mockAzkarProvider.loadCustomAzkar()).thenAnswer((_) async {});
    when(mockFavoritesProvider.loadFavorites()).thenAnswer((_) async {});
    when(mockSurahProvider.surahList).thenReturn([]);
  });

  Widget buildTestWidget({String? selectedFilter}) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (ctx, _) => MaterialApp(
        locale: const Locale('ar'),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AzkarProvider>.value(value: mockAzkarProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: mockFavoritesProvider),
            ChangeNotifierProvider<SurahProvider>.value(value: mockSurahProvider),
          ],
          child: AllAzkarScreen(selectedFilter: selectedFilter),
        ),
      ),
    );
  }

  group('AllAzkarScreen', () {
    testWidgets('shows empty state when no categories and searching', (tester) async {
      when(mockAzkarProvider.allCategories).thenReturn([]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter a search that won't match the short surah title
      await tester.enterText(find.byType(TextField), 'xyznotexist');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noResults), findsOneWidget);
    });

    testWidgets('displays categories when available', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.morningAzkar), findsWidgets);
      expect(find.text(AppStrings.eveningAzkar), findsWidgets);
    });

    testWidgets('has search bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('has filter chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.favorites), findsWidgets);
      expect(find.text(AppStrings.myAzkar), findsWidgets);
      expect(find.text(AppStrings.allCategories), findsWidgets);
    });

    testWidgets('has add button for custom azkar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays correct AppBar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.allAzkarTitle), findsOneWidget);
    });
  });
}
