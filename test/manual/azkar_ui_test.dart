import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/favorite_items_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/add_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_item.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_picker_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/day_zekr_widget.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/edit_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_counter_pill.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/widget_guide/presentation/widget_guide_page.dart';
import 'package:azkar_app/pages/home_page.dart';
import 'package:azkar_app/pages/splash_page.dart';
import 'package:azkar_app/widgets/custom_text_field.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:dartz/dartz.dart' show Either, Left, Right, Unit, unit;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _morning = 'أذكار الصباح';
const _custom = 'مذكراتي';
const _longZekr =
    'ذكر طويل جدا لاختبار التخطيط على الشاشات الضيقة ومقاس النص الكبير، '
    'ويجب أن يبقى النص داخل البطاقة دون أي تجاوز بصري أو انهيار في التخطيط';

class _FakeAzkarRepository implements AzkarRepository {
  _FakeAzkarRepository({
    this.assetAzkar = const [],
    List<ZekrEntity> customAzkar = const [],
  }) : customAzkar = List.of(customAzkar);

  final List<ZekrEntity> assetAzkar;
  final List<ZekrEntity> customAzkar;
  bool failDelete = false;

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async =>
      Right(List.of(assetAzkar));

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async =>
      Right(List.of(customAzkar));

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async {
    customAzkar.addAll(items);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryName) async {
    if (failDelete) {
      return const Left(DatabaseFailure('delete failed'));
    }
    customAzkar.removeWhere((item) => item.category == categoryName);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Unit>> updateCustomAzkarCategory(
    String oldCategory,
    List<ZekrEntity> items,
  ) async {
    customAzkar.removeWhere((item) => item.category == oldCategory);
    customAzkar.addAll(items);
    return const Right(unit);
  }
}

class _FakeNamesRepository implements NamesOfAllahRepository {
  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah() async =>
      const Right([]);
}

class _FakeSurahRepository implements SurahRepository {
  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async =>
      const Right([]);
}

class _FakeNotificationProvider extends ChangeNotifier
    implements NotificationProvider {
  @override
  bool get areNotificationsEnabled => true;

  @override
  bool get isPrayerAdhanEnabled => true;

  @override
  bool get isMorningEveningAzkarEnabled => true;

  @override
  bool get isPeriodicAzkarEnabled => true;

  @override
  bool get isPreAdhanEnabled => true;

  @override
  bool get isQuranAfterSalahEnabled => true;

  @override
  bool get isProphetBlessingsEnabled => true;

  @override
  Future<String?> applyNotificationStates() async => null;

  @override
  Future<void> refreshNotifications() async {}

  @override
  TimeOfDay? azkarTime(String key) => null;

  @override
  Future<String?> setAzkarTime(String key, TimeOfDay? time) async => null;

  @override
  Future<String?> toggleAllNotifications(bool newValue) async => null;

  @override
  Future<void> toggleNotificationType(String key, bool value) async {}
}

class _AzkarHarness {
  _AzkarHarness({
    required this.repository,
    required this.azkar,
    required this.favorites,
    required this.prayer,
    required this.names,
    required this.surah,
    required this.theme,
    required this.preferences,
  });

  final _FakeAzkarRepository repository;
  final AzkarProvider azkar;
  final FavoritesProvider favorites;
  final PrayerTimesProvider prayer;
  final NamesOfAllahProvider names;
  final SurahProvider surah;
  final ThemeProvider theme;
  final SharedPreferences preferences;
}

Future<_AzkarHarness> _createHarness({
  List<ZekrEntity> assetAzkar = const [],
  List<ZekrEntity> customAzkar = const [],
  Map<String, Object> extraPreferences = const {},
}) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  SharedPreferences.setMockInitialValues({
    WidgetGuidePage.seenPreferenceKey: true,
    PrefsKeys.latitude: 30.0444,
    PrefsKeys.longitude: 31.2357,
    PrefsKeys.cityTimezone: 'UTC',
    PrefsKeys.prayerTimeDate: today,
    ...extraPreferences,
  });
  final preferences = await SharedPreferences.getInstance();
  final repository = _FakeAzkarRepository(
    assetAzkar: assetAzkar,
    customAzkar: customAzkar,
  );
  final azkar = AzkarProvider(
    getAzkarUseCase: GetAzkarUseCase(azkarRepository: repository),
    getCustomAzkarUseCase: GetCustomAzkarUseCase(azkarRepository: repository),
    saveCustomAzkarUseCase: SaveCustomAzkarUseCase(azkarRepository: repository),
    deleteCustomAzkarUseCase:
        DeleteCustomAzkarUseCase(azkarRepository: repository),
    updateCustomAzkarUseCase:
        UpdateCustomAzkarUseCase(azkarRepository: repository),
  );
  final favorites = FavoritesProvider(sharedPreferences: preferences);
  final prayer = PrayerTimesProvider(
    prayerTimeService: PrayerTimeService(),
    sharedPreferences: preferences,
  );
  final names = NamesOfAllahProvider(
    getNamesOfAllahUseCase: GetNamesOfAllahUseCase(
      namesOfAllahRepository: _FakeNamesRepository(),
    ),
  );
  final surah = SurahProvider(
    getSurahUseCase: GetSurahUseCase(
      surahRepository: _FakeSurahRepository(),
    ),
  );
  final theme = ThemeProvider(prefs: preferences);
  return _AzkarHarness(
    repository: repository,
    azkar: azkar,
    favorites: favorites,
    prayer: prayer,
    names: names,
    surah: surah,
    theme: theme,
    preferences: preferences,
  );
}

List<SingleChildWidget> _harnessProviders(_AzkarHarness harness) => [
      ChangeNotifierProvider.value(value: harness.azkar),
      ChangeNotifierProvider.value(value: harness.favorites),
      ChangeNotifierProvider.value(value: harness.prayer),
      ChangeNotifierProvider.value(value: harness.names),
      ChangeNotifierProvider.value(value: harness.surah),
      ChangeNotifierProvider.value(value: harness.theme),
    ];

Widget _testApp({
  required Widget home,
  required List<SingleChildWidget> providers,
  TextScaler textScaler = const TextScaler.linear(1),
}) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    builder: (context, _) {
      final child = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppPalette.lightTheme,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: home,
      );
      return providers.isEmpty
          ? child
          : MultiProvider(providers: providers, child: child);
    },
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _setNarrowSurface(WidgetTester tester) =>
    _setSurface(tester, const Size(320, 600));

Future<void> _setTallSurface(WidgetTester tester) =>
    _setSurface(tester, const Size(430, 1200));

Future<void> _setWideSurface(WidgetTester tester) =>
    _setSurface(tester, const Size(1000, 1200));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectNoException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

class _AddSheetHost extends StatelessWidget {
  const _AddSheetHost({
    required this.provider,
    required this.onSaved,
  });

  final AzkarProvider provider;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddAzkarBottomSheet(onChangeFilter: onSaved),
              );
            },
            child: const Text('open add'),
          ),
        ),
      ),
    );
  }
}

class _EditSheetHost extends StatelessWidget {
  const _EditSheetHost({
    required this.provider,
    required this.category,
    required this.currentAzkar,
  });

  final AzkarProvider provider;
  final String category;
  final List<ZekrEntity> currentAzkar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditAzkarBottomSheet(
                  category: category,
                  currentAzkar: currentAzkar,
                ),
              );
            },
            child: const Text('open edit'),
          ),
        ),
      ),
    );
  }
}

class _SearchHost extends StatefulWidget {
  const _SearchHost();

  @override
  State<_SearchHost> createState() => _SearchHostState();
}

class _SearchHostState extends State<_SearchHost> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SearchBarWidget(
          searchController: _controller,
          onChanged: (value) => setState(() => _query = value),
          onClear: () => setState(() {
            _controller.clear();
            _query = '';
          }),
          hint: 'ابحث عن ذكر أو دعاء طويل جدا',
        ),
      ),
    );
  }

  String get query => _query;
}

class _PickerHost extends StatefulWidget {
  const _PickerHost();

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  CitySelection? selection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              selection = await showCityPicker(context, currentCity: 'الرياض');
            },
            child: const Text('open picker'),
          ),
        ),
      ),
    );
  }
}

class _FavoriteItemHost extends StatelessWidget {
  const _FavoriteItemHost({
    required this.favorites,
    required this.category,
  });

  final FavoritesProvider favorites;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) => AzkarItem(
          title: category,
          count: 3,
          isFavorite: provider.isCategoryFav(category),
          onTap: () {},
          onFavoriteTap: () {
            provider.toggleCategoryFavorite(category);
          },
          isDark: false,
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    final loader = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/tajawal.ttf'));
    await loader.load();
  });

  testWidgets('home dashboard survives 320x600 and 2x text', (tester) async {
    await _setNarrowSurface(tester);
    final harness = await _createHarness(
      assetAzkar: List.generate(
        12,
        (index) => ZekrEntity(
          category: index.isEven ? _morning : 'أذكار المساء',
          zekr: index == 0 ? _longZekr : 'ذكر $index',
          count: '${index + 1}',
          description: '',
          reference: 'المصدر $index',
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        home: const HomePage(),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('ذكر اليوم'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('splash navigation runs onReady after replacing splash',
      (tester) async {
    await _setWideSurface(tester);
    final harness = await _createHarness(
      assetAzkar: const [
        ZekrEntity(
          category: _morning,
          zekr: 'ذكر الصباح',
          count: '1',
          description: '',
          reference: '',
        ),
      ],
    );
    final tasbeh = TasbehProvider(sharedPreferences: harness.preferences);
    final notifications = _FakeNotificationProvider();
    var ready = false;

    await tester.pumpWidget(
      _testApp(
        home: SplashPage(onReady: () => ready = true),
        providers: [
          ..._harnessProviders(harness),
          ChangeNotifierProvider.value(value: tasbeh),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: notifications,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
    _expectNoException(tester);
    expect(ready, isTrue);
  });

  testWidgets('details counts, favorites, and completes', (tester) async {
    await _setTallSurface(tester);
    final entity = const ZekrEntity(
      category: _morning,
      zekr: 'ذكر الصباح',
      count: '2',
      description: '',
      reference: '',
    );
    final harness = await _createHarness(assetAzkar: [entity]);

    await tester.pumpWidget(
      _testApp(
        home: const AzkarDetailsPage(
          title: _morning,
          categoryName: _morning,
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    expect(find.text('غير موجود'), findsNothing);

    final counter = find.byType(ZekrCounterPill);
    await tester.ensureVisible(counter);
    await tester.tap(counter);
    await _settle(tester);
    expect(
      harness.azkar.remainingFor(entity.zekr, 2, category: _morning, index: 0),
      1,
    );

    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await _settle(tester);
    expect(
      harness.favorites.isItemFav('$_morning\u0000${entity.zekr}'),
      isTrue,
    );
    expect(
      harness.azkar.remainingFor(entity.zekr, 2, category: _morning, index: 0),
      1,
    );

    await tester.tap(counter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(harness.azkar.completedIndexOf(_morning), 1);
    expect(find.text('أحسنت! 🎉'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('details layout survives 320x600 at 2x text', (tester) async {
    await _setNarrowSurface(tester);
    final entity = const ZekrEntity(
      category: _morning,
      zekr: _longZekr,
      count: '2',
      description: '',
      reference: 'مرجع طويل جدا لاختبار إعادة التغليف',
    );
    final harness = await _createHarness(assetAzkar: [entity]);

    await tester.pumpWidget(
      _testApp(
        home: const AzkarDetailsPage(
          title: _morning,
          categoryName: _morning,
        ),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);

    expect(find.byType(AzkarDetailsPage), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('all azkar search and favorite work', (tester) async {
    await _setTallSurface(tester);
    final harness = await _createHarness(
      assetAzkar: const [
        ZekrEntity(
          category: _morning,
          zekr: 'ذكر الصباح',
          count: '1',
          description: '',
          reference: '',
        ),
      ],
      customAzkar: const [
        ZekrEntity(
          category: _custom,
          zekr: 'ذكر مخصص',
          count: '2',
          description: '',
          reference: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        home: const AllAzkarPage(selectedFilter: 'أذكاري'),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    final customCard = find.byKey(const Key('custom_cat_$_custom'));
    expect(find.text(_custom), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'مذكراتي');
    await _settle(tester);
    expect(find.text('١ ذكر'), findsOneWidget);

    final favoriteButton = find.descendant(
      of: customCard,
      matching: find.byIcon(Icons.star_border_rounded),
    );
    expect(favoriteButton, findsOneWidget);
    await tester.tap(favoriteButton);
    await _settle(tester);
    expect(harness.favorites.isCategoryFav(_custom), isTrue);
    _expectNoException(tester);
  });

  testWidgets('all azkar layout survives 320x600 at 2x text', (tester) async {
    await _setNarrowSurface(tester);
    final harness = await _createHarness(
      customAzkar: const [
        ZekrEntity(
          category: _custom,
          zekr: 'ذكر مخصص',
          count: '2',
          description: '',
          reference: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        home: const AllAzkarPage(selectedFilter: 'أذكاري'),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);

    expect(find.byType(AllAzkarPage), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('favorite items page removes an item on narrow large text',
      (tester) async {
    await _setNarrowSurface(tester);
    final harness = await _createHarness(
      extraPreferences: {
        PrefsKeys.favoriteItems: ['$_morning\u0000$_longZekr'],
      },
    );

    await tester.pumpWidget(
      _testApp(
        home: const FavoriteItemsPage(),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    expect(find.text(_longZekr), findsOneWidget);
    _expectNoException(tester);

    final favoriteButton = find.byIcon(Icons.star_rounded);
    await tester.ensureVisible(favoriteButton);
    await _settle(tester);
    await tester.tap(favoriteButton);
    await _settle(tester);
    expect(find.text('قائمة المحفوظات فارغة'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('day zekr refreshes and uses Arabic digits', (tester) async {
    await _setWideSurface(tester);
    final harness = await _createHarness(
      assetAzkar: const [
        ZekrEntity(
          category: _morning,
          zekr: _longZekr,
          count: '1',
          description: '',
          reference: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        home: const Scaffold(
          body: SingleChildScrollView(child: DayZekrWidget()),
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    final dateFinder = find.descendant(
      of: find.byType(DayZekrWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('،') ?? false) &&
            (widget.data?.length ?? 0) < 60,
      ),
    );
    expect(dateFinder, findsOneWidget);
    expect(tester.widget<Text>(dateFinder).data, isNot(matches(RegExp(r'\d'))));

    await tester.tap(find.byIcon(CupertinoIcons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_longZekr), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('day zekr layout survives 320x600 at 2x text', (tester) async {
    await _setNarrowSurface(tester);
    final harness = await _createHarness(
      assetAzkar: const [
        ZekrEntity(
          category: _morning,
          zekr: _longZekr,
          count: '1',
          description: '',
          reference: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        home: const Scaffold(
          body: SingleChildScrollView(child: DayZekrWidget()),
        ),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);

    expect(find.byType(DayZekrWidget), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('long AzkarItem and custom field survive 320x600 at 2x text',
      (tester) async {
    await _setNarrowSurface(tester);
    final controller = TextEditingController(text: _longZekr);

    await tester.pumpWidget(
      _testApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AzkarItem(
                  title: 'فئة ذات اسم طويل جدا يتجاوز عرض البطاقة',
                  count: 1000000,
                  isFavorite: false,
                  onTap: () {},
                  onFavoriteTap: () {},
                  isDark: false,
                ),
                CustomTextField(
                  controller: controller,
                  label: 'نص أطول للتأكد من التفاف الحقل',
                  hint: _longZekr,
                  icon: Icons.notes,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        providers: const [],
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    expect(find.byType(AzkarItem), findsOneWidget);
    expect(find.byType(CustomTextField), findsOneWidget);
    _expectNoException(tester);

    controller.dispose();
  });

  testWidgets('search bar typing and clearing work on narrow large text',
      (tester) async {
    await _setNarrowSurface(tester);

    await tester.pumpWidget(
      _testApp(
        home: const _SearchHost(),
        providers: const [],
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    expect(find.byType(SearchBarWidget), findsOneWidget);
    _expectNoException(tester);

    await tester.enterText(find.byType(TextFormField), 'دعاء');
    await _settle(tester);
    expect(
        tester.state<_SearchHostState>(find.byType(_SearchHost)).query, 'دعاء');
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await _settle(tester);
    expect(tester.state<_SearchHostState>(find.byType(_SearchHost)).query, '');
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('city picker searches and returns a city', (tester) async {
    await _setTallSurface(tester);

    await tester.pumpWidget(
      _testApp(
        home: const _PickerHost(),
        providers: const [],
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open picker'));
    await _settle(tester);
    _expectNoException(tester);
    expect(find.text('اختر المدينة'), findsOneWidget);
    _expectNoException(tester);

    await tester.enterText(find.byType(TextField), 'القاهرة');
    await _settle(tester);
    final cityTile = find.widgetWithText(ListTile, 'القاهرة');
    expect(cityTile, findsOneWidget);
    _expectNoException(tester);

    await tester.tap(cityTile);
    await _settle(tester);
    final host = tester.state<_PickerHostState>(find.byType(_PickerHost));
    expect(host.selection?.city?.name, 'القاهرة');
    _expectNoException(tester);
  });

  testWidgets('city picker layout survives 320x600 at 2x text', (tester) async {
    await _setNarrowSurface(tester);

    await tester.pumpWidget(
      _testApp(
        home: const _PickerHost(),
        providers: const [],
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open picker'));
    await _settle(tester);

    expect(find.text('اختر المدينة'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('add bottom sheet has no layout errors on narrow large text',
      (tester) async {
    await _setNarrowSurface(tester);
    final harness = await _createHarness();

    await tester.pumpWidget(
      _testApp(
        home: _AddSheetHost(
          provider: harness.azkar,
          onSaved: () {},
        ),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open add'));
    await _settle(tester);
    expect(find.byType(AddAzkarBottomSheet), findsOneWidget);
    expect(find.text('إضافة أذكار جديدة'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('add bottom sheet saves Arabic-Indic repetition count',
      (tester) async {
    await _setWideSurface(tester);
    final harness = await _createHarness();
    var filterChanged = false;

    await tester.pumpWidget(
      _testApp(
        home: _AddSheetHost(
          provider: harness.azkar,
          onSaved: () => filterChanged = true,
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open add'));
    await _settle(tester);
    _expectNoException(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'أذكار السفر');
    await tester.enterText(fields.at(1), '٣');
    await tester.enterText(fields.at(2), 'ذكر الرحلة');
    final saveButton = find.widgetWithText(ElevatedButton, 'حفظ الكل');
    tester.widget<ElevatedButton>(saveButton).onPressed!();
    await _settle(tester);

    expect(harness.repository.customAzkar, hasLength(1));
    expect(harness.repository.customAzkar.single.category, 'أذكار السفر');
    expect(harness.repository.customAzkar.single.zekr, 'ذكر الرحلة');
    expect(harness.repository.customAzkar.single.count, '3');
    expect(filterChanged, isTrue);
    _expectNoException(tester);
  });

  testWidgets('add bottom sheet rejects a zero repetition count',
      (tester) async {
    await _setWideSurface(tester);
    final harness = await _createHarness();
    var filterChanged = false;

    await tester.pumpWidget(
      _testApp(
        home: _AddSheetHost(
          provider: harness.azkar,
          onSaved: () => filterChanged = true,
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open add'));
    await _settle(tester);
    _expectNoException(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'أذكار صفرية');
    await tester.enterText(fields.at(1), '٠');
    await tester.enterText(fields.at(2), 'ذكر لا يمكن عدّه');
    final saveButton = find.widgetWithText(ElevatedButton, 'حفظ الكل');
    tester.widget<ElevatedButton>(saveButton).onPressed!();
    await _settle(tester);

    _expectNoException(tester);
    expect(harness.repository.customAzkar, isEmpty);
    expect(filterChanged, isFalse);
  });

  testWidgets('edit bottom sheet has no layout errors on narrow large text',
      (tester) async {
    await _setNarrowSurface(tester);
    const entity = ZekrEntity(
      category: _custom,
      zekr: _longZekr,
      count: '1000',
      description: '',
      reference: '',
    );
    final harness = await _createHarness(customAzkar: const [entity]);

    await tester.pumpWidget(
      _testApp(
        home: _EditSheetHost(
          provider: harness.azkar,
          category: _custom,
          currentAzkar: const [entity],
        ),
        providers: _harnessProviders(harness),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open edit'));
    await _settle(tester);
    expect(find.byType(EditAzkarBottomSheet), findsOneWidget);
    expect(find.text('تعديل الأذكار المخصصة'), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('edit bottom sheet updates category and category favorite',
      (tester) async {
    await _setWideSurface(tester);
    const entity = ZekrEntity(
      category: _custom,
      zekr: 'ذكر قديم',
      count: '1',
      description: '',
      reference: '',
    );
    final harness = await _createHarness(
      customAzkar: const [entity],
      extraPreferences: {
        PrefsKeys.favoriteCategories: [_custom],
        PrefsKeys.favoriteItems: ['$_custom\u0000ذكر قديم'],
      },
    );

    await tester.pumpWidget(
      _testApp(
        home: _EditSheetHost(
          provider: harness.azkar,
          category: _custom,
          currentAzkar: const [entity],
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open edit'));
    await _settle(tester);
    _expectNoException(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'أذكار جديدة');
    await tester.enterText(fields.at(1), '٤');
    await tester.enterText(fields.at(2), 'ذكر معدل');
    final saveButton = find.widgetWithText(ElevatedButton, 'تعديل وحفظ');
    tester.widget<ElevatedButton>(saveButton).onPressed!();
    await _settle(tester);

    expect(harness.repository.customAzkar, hasLength(1));
    expect(harness.repository.customAzkar.single.category, 'أذكار جديدة');
    expect(harness.repository.customAzkar.single.zekr, 'ذكر معدل');
    expect(harness.repository.customAzkar.single.count, '4');
    expect(harness.favorites.isCategoryFav('أذكار جديدة'), isTrue);
    _expectNoException(tester);
  });

  testWidgets('edit bottom sheet migrates item favorite when zekr text changes',
      (tester) async {
    await _setWideSurface(tester);
    const entity = ZekrEntity(
      category: _custom,
      zekr: 'ذكر قديم',
      count: '1',
      description: '',
      reference: '',
    );
    final harness = await _createHarness(
      customAzkar: const [entity],
      extraPreferences: {
        PrefsKeys.favoriteItems: ['$_custom\u0000ذكر قديم'],
      },
    );

    await tester.pumpWidget(
      _testApp(
        home: _EditSheetHost(
          provider: harness.azkar,
          category: _custom,
          currentAzkar: const [entity],
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('open edit'));
    await _settle(tester);
    _expectNoException(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '٤');
    await tester.enterText(fields.at(2), 'ذكر معدل');
    final saveButton = find.widgetWithText(ElevatedButton, 'تعديل وحفظ');
    tester.widget<ElevatedButton>(saveButton).onPressed!();
    await _settle(tester);

    expect(harness.repository.customAzkar.single.zekr, 'ذكر معدل');
    expect(harness.favorites.isItemFav('$_custom\u0000ذكر معدل'), isTrue);
    _expectNoException(tester);
  });

  testWidgets('confirmed custom category delete persists through provider',
      (tester) async {
    final harness = await _createHarness(
      customAzkar: const [
        ZekrEntity(
          category: _custom,
          zekr: 'حذفني',
          count: '1',
          description: '',
          reference: '',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        home: const AllAzkarPage(selectedFilter: 'أذكاري'),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const Key('custom_cat_$_custom')), findsOneWidget);
    _expectNoException(tester);

    await tester.drag(
      find.byKey(const Key('custom_cat_$_custom')),
      const Offset(-500, 0),
    );
    await _settle(tester);
    expect(find.widgetWithText(ElevatedButton, 'حذف'), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await tester.pumpAndSettle();
    expect(harness.repository.customAzkar, isEmpty);
    expect(harness.azkar.customCategories, isEmpty);
    _expectNoException(tester);
  });

  testWidgets('failed custom category delete rebuilds Dismissible safely',
      (tester) async {
    final harness = await _createHarness(
      customAzkar: const [
        ZekrEntity(
          category: _custom,
          zekr: 'يبقى',
          count: '1',
          description: '',
          reference: '',
        ),
      ],
    )
      ..repository.failDelete = true;

    await tester.pumpWidget(
      _testApp(
        home: const AllAzkarPage(selectedFilter: 'أذكاري'),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);

    await tester.drag(
      find.byKey(const Key('custom_cat_$_custom')),
      const Offset(-500, 0),
    );
    await _settle(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 500));

    _expectNoException(tester);
    expect(harness.repository.customAzkar, hasLength(1));
    expect(harness.azkar.customCategories, contains(_custom));
  });

  testWidgets('two rapid favorite taps apply add then remove', (tester) async {
    final harness = await _createHarness();

    await tester.pumpWidget(
      _testApp(
        home: _FavoriteItemHost(
          favorites: harness.favorites,
          category: 'قسم سريع',
        ),
        providers: _harnessProviders(harness),
      ),
    );
    await _settle(tester);
    expect(harness.favorites.isCategoryFav('قسم سريع'), isFalse);
    _expectNoException(tester);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await _settle(tester);

    _expectNoException(tester);
    expect(harness.favorites.isCategoryFav('قسم سريع'), isFalse);
  });
}
