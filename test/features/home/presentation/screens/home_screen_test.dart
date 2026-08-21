import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/home/presentation/screens/home_screen.dart';
import 'package:azkar_app/features/home/presentation/widgets/welcoming_widget.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/widget_guide/presentation/screens/widget_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([
  AzkarProvider,
  PrayerTimesProvider,
  NamesOfAllahProvider,
  FavoritesProvider,
  ThemeProvider,
  NotificationProvider,
  TasbehProvider,
])
void main() {
  late MockAzkarProvider mockAzkarProvider;
  late MockPrayerTimesProvider mockPrayerTimesProvider;
  late MockNamesOfAllahProvider mockNamesOfAllahProvider;
  late MockFavoritesProvider mockFavoritesProvider;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockTasbehProvider mockTasbehProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      WidgetGuideScreen.seenPreferenceKey: true,
    });

    mockAzkarProvider = MockAzkarProvider();
    mockPrayerTimesProvider = MockPrayerTimesProvider();
    mockNamesOfAllahProvider = MockNamesOfAllahProvider();
    mockFavoritesProvider = MockFavoritesProvider();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockTasbehProvider = MockTasbehProvider();

    when(mockAzkarProvider.azkarStatus).thenReturn(AppLoadingStatus.loaded);
    when(mockAzkarProvider.azkarList).thenReturn([
      const ZekrEntity(
        category: AppStrings.morningAzkar,
        zekr: 'test zekr',
        count: 1,
        description: '',
        reference: '',
      ),
    ]);
    when(mockAzkarProvider.customCategories).thenReturn([]);
    when(mockAzkarProvider.azkarErrorMessage).thenReturn(null);
    when(mockAzkarProvider.customAzkarList).thenReturn([]);
    when(mockAzkarProvider.loadAzkar()).thenAnswer((_) async {});
    when(mockNamesOfAllahProvider.namesOfAllahList).thenReturn([
      const NamesOfAllahModel(id: 1, name: 'test', text: 'test text'),
    ]);
    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(mockThemeProvider.textScaleFactor).thenReturn(1.0);
    when(mockPrayerTimesProvider.prayerTimes).thenReturn(null);
    when(mockPrayerTimesProvider.errorMessage).thenReturn(null);
    when(mockPrayerTimesProvider.allDisplayTimes).thenReturn({});
    when(mockPrayerTimesProvider.selectedCityName).thenReturn(null);
    when(mockPrayerTimesProvider.isAutoLocation).thenReturn(true);
    when(mockPrayerTimesProvider.loadPrayerTimes()).thenAnswer((_) async {});
    when(mockFavoritesProvider.loadFavorites()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (ctx, _) => MaterialApp(
        locale: const Locale('ar'),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AzkarProvider>.value(value: mockAzkarProvider),
            ChangeNotifierProvider<PrayerTimesProvider>.value(value: mockPrayerTimesProvider),
            ChangeNotifierProvider<NamesOfAllahProvider>.value(value: mockNamesOfAllahProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: mockFavoritesProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
            ChangeNotifierProvider<TasbehProvider>.value(value: mockTasbehProvider),
          ],
          child: const HomeScreen(),
        ),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('shows loading state', (tester) async {
      when(mockAzkarProvider.azkarStatus).thenReturn(AppLoadingStatus.loading);
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      when(mockAzkarProvider.azkarStatus).thenReturn(AppLoadingStatus.error);
      when(mockAzkarProvider.azkarErrorMessage).thenReturn('Test error');

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('builds HomeContent when loaded', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(WelcomingWidget), findsOneWidget);
    });

    testWidgets('has Semantics on header buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Toggle theme'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Contact us'), findsOneWidget);
    });

    testWidgets('has GridView for azkar categories', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
