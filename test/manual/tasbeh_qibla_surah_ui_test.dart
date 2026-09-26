import 'dart:async';
import 'dart:math' as math;

import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/di/injection_container.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source_impl.dart';
import 'package:azkar_app/features/names_of_allah/data/repositories/names_of_allah_repository_impl.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/pages/names_of_allah_page.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:azkar_app/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:azkar_app/features/qibla/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:azkar_app/features/qibla/presentation/pages/qibla_screen.dart';
import 'package:azkar_app/features/qibla/presentation/providers/qibla_provider.dart';
import 'package:azkar_app/features/qibla/presentation/widgets/qibla_body.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/surah/presentation/widgets/surah_item.dart';
import 'package:azkar_app/features/tasbeh/presentation/pages/tasbeh_page.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/widget_guide/presentation/widget_guide_page.dart';
import 'package:azkar_app/features/widget_guide/widgets/fullscreen_screenshot.dart';
import 'package:azkar_app/features/widget_guide/widgets/screenshot_container.dart';
import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testNames = <NamesOfAllahEntity>[
  NamesOfAllahEntity(id: 1, name: 'الرحمن', text: 'كثير الرحمة'),
  NamesOfAllahEntity(id: 2, name: 'الرحيم', text: 'المنعم أبدا'),
];

const _testSurahs = <SurahEntity>[
  SurahEntity(
    name: 'سورة الإخلاص',
    surah: 'قل هو الله أحد، الله الصمد، لم يلد ولم يولد.',
  ),
  SurahEntity(
    name: 'سورة الكوثر',
    surah: 'إنا أعطيناك الكوثر، فصل لربك وانحر.',
  ),
  SurahEntity(
    name: 'سورة الفلق',
    surah: 'قل أعوذ برب الفلق، من شر ما خلق.',
  ),
];

class _FakeNamesRepository implements NamesOfAllahRepository {
  _FakeNamesRepository(this.responses);

  final List<Either<Failure, List<NamesOfAllahEntity>>> responses;
  int calls = 0;

  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}

class _DeferredNamesRepository implements NamesOfAllahRepository {
  _DeferredNamesRepository(this.response);

  final Future<Either<Failure, List<NamesOfAllahEntity>>> response;

  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah() =>
      response;
}

class _FakeSurahRepository implements SurahRepository {
  _FakeSurahRepository(this.responses);

  final List<Either<Failure, List<SurahEntity>>> responses;
  int calls = 0;

  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}

class _DeferredSurahRepository implements SurahRepository {
  _DeferredSurahRepository(this.response);

  final Future<Either<Failure, List<SurahEntity>>> response;

  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() => response;
}

class _FakeQiblaRepository implements QiblaRepository {
  @override
  Future<double> getQiblaDirection() async => 0;
}

class _FakeQiblaProvider extends QiblaProvider {
  _FakeQiblaProvider({
    required this.loading,
    required this.heading,
    required this.qiblaDelta,
    required this.aligned,
    this.message,
    this.compassIsUnavailable = false,
  }) : super(
          getQiblaDirectionUseCase:
              GetQiblaDirectionUseCase(_FakeQiblaRepository()),
        );

  final bool loading;
  final double heading;
  final double qiblaDelta;
  final bool aligned;
  final String? message;
  final bool compassIsUnavailable;

  @override
  bool get isLoading => loading;

  @override
  double get currentHeading => heading;

  @override
  double get difference => qiblaDelta;

  @override
  bool get isAligned => aligned;

  @override
  String? get errorMessage => message;

  @override
  bool get compassUnavailable => compassIsUnavailable;

  @override
  Future<void> init() => Future<void>.value();
}

class _GuideHost extends StatelessWidget {
  const _GuideHost({this.openedFromSettings = false});

  final bool openedFromSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await WidgetGuidePage.open(
              context,
              openedFromSettings: openedFromSettings,
            );
          },
          child: const Text('فتح الدليل'),
        ),
      ),
    );
  }
}

class _QiblaCase {
  const _QiblaCase({
    required this.heading,
    required this.difference,
    required this.aligned,
    required this.status,
  });

  final double heading;
  final double difference;
  final bool aligned;
  final String status;
}

final _testTheme = ThemeData(useMaterial3: true, fontFamily: 'Tajawal');

Widget _testApp({
  required Widget home,
  List<SingleChildWidget> providers = const [],
  TextScaler textScaler = const TextScaler.linear(1),
}) {
  final materialApp = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _testTheme,
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
  final app = providers.isEmpty
      ? materialApp
      : MultiProvider(providers: providers, child: materialApp);

  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    builder: (context, _) => app,
  );
}

Future<SharedPreferences> _mockPreferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _setNarrowSurface(WidgetTester tester) {
  return _setSurface(tester, const Size(320, 600));
}

Future<void> _setPortraitSurface(WidgetTester tester) {
  return _setSurface(tester, const Size(430, 932));
}

Future<void> _settle(WidgetTester tester,
    {Duration delay = const Duration(milliseconds: 100)}) async {
  await tester.pump();
  await tester.pump(delay);
}

void _expectNoException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

NamesOfAllahProvider _namesProvider(NamesOfAllahRepository repository) {
  return NamesOfAllahProvider(
    getNamesOfAllahUseCase: GetNamesOfAllahUseCase(
      namesOfAllahRepository: repository,
    ),
  );
}

SurahProvider _surahProvider(SurahRepository repository) {
  return SurahProvider(
    getSurahUseCase: GetSurahUseCase(surahRepository: repository),
  );
}

Future<void> _registerQiblaProvider(QiblaProvider provider) async {
  if (sl.isRegistered<QiblaProvider>()) {
    await sl.unregister<QiblaProvider>();
  }
  sl.registerFactory<QiblaProvider>(() => provider);
}

Future<void> _unregisterQiblaProvider() async {
  if (sl.isRegistered<QiblaProvider>()) {
    await sl.unregister<QiblaProvider>();
  }
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/tajawal.ttf'));
    await loader.load();
  });

  tearDown(_unregisterQiblaProvider);

  group('tasbeh', () {
    testWidgets('restores, counts, and resets only the current session',
        (tester) async {
      final preferences = await _mockPreferences({
        'total_tasbeh_count': 7,
        'current_session_tasbeh_count': 3,
      });
      final provider = TasbehProvider(sharedPreferences: preferences);
      await provider.loadCount();

      await tester.pumpWidget(
        _testApp(
          home: const TasbehPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('٣'), findsOneWidget);
      expect(find.text('٧'), findsOneWidget);
      expect(find.text('إجمالي التسبيحات:'), findsOneWidget);
      _expectNoException(tester);

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();

      expect(provider.count, 4);
      expect(provider.savedCount, 8);
      expect(find.text('٤'), findsOneWidget);
      _expectNoException(tester);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await _settle(tester);
      expect(find.text('تصفير جلسة التسبيح؟'), findsOneWidget);

      await tester.tap(find.text('تصفير'));
      await _settle(tester);

      expect(provider.count, 0);
      expect(provider.savedCount, 8);
      expect(preferences.getInt('current_session_tasbeh_count'), 0);
      expect(preferences.getInt('total_tasbeh_count'), 8);
      expect(find.text('٠'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('counts rapid completed taps', (tester) async {
      final preferences = await _mockPreferences();
      final provider = TasbehProvider(sharedPreferences: preferences);
      await provider.loadCount();

      await tester.pumpWidget(
        _testApp(
          home: const TasbehPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();

      expect(provider.count, 2);
      expect(provider.savedCount, 2);
      _expectNoException(tester);
    });

    testWidgets('survives a narrow surface with enlarged text', (tester) async {
      await _setNarrowSurface(tester);
      final preferences = await _mockPreferences();
      final provider = TasbehProvider(sharedPreferences: preferences);
      await provider.loadCount();

      await tester.pumpWidget(
        _testApp(
          home: const TasbehPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          textScaler: const TextScaler.linear(2),
        ),
      );
      await _settle(tester);

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      _expectNoException(tester);
    });
  });

  group('names of Allah', () {
    testWidgets('shows the loading state until the asset request completes',
        (tester) async {
      final completer = Completer<Either<Failure, List<NamesOfAllahEntity>>>();
      final repository = _DeferredNamesRepository(completer.future);
      final provider = _namesProvider(repository);
      final load = provider.loadNamesOfAllah();

      await tester.pumpWidget(
        _testApp(
          home: const NamesOfAllahPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await tester.pump();

      expect(provider.namesOfAllahStatus, AppLoadingStatus.loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(
        const Right<Failure, List<NamesOfAllahEntity>>(_testNames),
      );
      await load;
      await _settle(tester);

      expect(provider.namesOfAllahStatus, AppLoadingStatus.loaded);
      expect(find.byType(NamesOfAllahCard), findsWidgets);
      expect(find.text('الرحمن'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('loads the real asset and renders a name with its text',
        (tester) async {
      final repository = NamesOfAllahRepositoryImpl(
        namesOfAllahLocalDataSource: NamesOfAllahLocalDataSourceImpl(),
      );
      final provider = _namesProvider(repository);
      await provider.loadNamesOfAllah();

      await tester.pumpWidget(
        _testApp(
          home: const NamesOfAllahPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await _settle(tester);

      expect(provider.namesOfAllahStatus, AppLoadingStatus.loaded);
      expect(provider.namesOfAllahList, isNotEmpty);
      expect(find.byType(NamesOfAllahCard), findsWidgets);
      expect(find.text(provider.namesOfAllahList.first.name), findsOneWidget);
      expect(
        find.text(provider.namesOfAllahList.first.text),
        findsOneWidget,
      );
      _expectNoException(tester);
    });

    testWidgets('shows an error and retries successfully', (tester) async {
      final repository = _FakeNamesRepository([
        const Left<Failure, List<NamesOfAllahEntity>>(
          JsonParsingFailure('تعذر تحميل الأسماء'),
        ),
        const Right<Failure, List<NamesOfAllahEntity>>(_testNames),
      ]);
      final provider = _namesProvider(repository);
      await provider.loadNamesOfAllah();

      await tester.pumpWidget(
        _testApp(
          home: const NamesOfAllahPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('تعذر تحميل الأسماء'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);

      expect(repository.calls, 2);
      expect(find.text('الرحمن'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('handles an empty loaded list without throwing',
        (tester) async {
      final repository = _FakeNamesRepository([
        const Right<Failure, List<NamesOfAllahEntity>>(<NamesOfAllahEntity>[]),
      ]);
      final provider = _namesProvider(repository);
      await provider.loadNamesOfAllah();

      await tester.pumpWidget(
        _testApp(
          home: const NamesOfAllahPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
        ),
      );
      await _settle(tester);

      expect(find.byType(NamesOfAllahCard), findsNothing);
      _expectNoException(tester);
    });

    testWidgets('survives a narrow surface with enlarged text', (tester) async {
      await _setNarrowSurface(tester);
      final repository = _FakeNamesRepository([
        const Right<Failure, List<NamesOfAllahEntity>>([
          NamesOfAllahEntity(
            id: 1,
            name: 'اسم طويل جدا لاختبار إعادة التفاف النص',
            text:
                'نص طويل جدا يحتوي على كلمات كثيرة لاختبار البطاقة على شاشة ضيقة.',
          ),
        ]),
      ]);
      final provider = _namesProvider(repository);
      await provider.loadNamesOfAllah();

      await tester.pumpWidget(
        _testApp(
          home: const NamesOfAllahPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          textScaler: const TextScaler.linear(2),
        ),
      );
      await _settle(tester);

      expect(find.byType(NamesOfAllahCard), findsOneWidget);
      _expectNoException(tester);
    });
  });

  group('surah list', () {
    testWidgets('loads, searches, clears, and favorites a surah',
        (tester) async {
      final preferences = await _mockPreferences();
      final repository = _FakeSurahRepository([
        const Right<Failure, List<SurahEntity>>(_testSurahs),
      ]);
      final provider = _surahProvider(repository);
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
        ),
      );
      await _settle(tester);

      expect(repository.calls, 1);
      expect(find.text('سورة الإخلاص'), findsOneWidget);
      expect(find.text('سورة الكوثر'), findsOneWidget);
      expect(find.byType(SurahItem), findsWidgets);

      await tester.enterText(find.byType(TextFormField), 'الإخلاص');
      await _settle(tester);

      expect(find.text('سورة الإخلاص'), findsOneWidget);
      expect(find.text('سورة الكوثر'), findsNothing);
      expect(find.text('لم يتم العثور على السورة'), findsNothing);

      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await _settle(tester);
      expect(find.text('سورة الكوثر'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await _settle(tester);

      expect(favorites.isItemFav(_testSurahs.first.surah), isTrue);
      _expectNoException(tester);
    });

    testWidgets('shows the loading state and handles a deferred result',
        (tester) async {
      final completer = Completer<Either<Failure, List<SurahEntity>>>();
      final repository = _DeferredSurahRepository(completer.future);
      final provider = _surahProvider(repository);
      final preferences = await _mockPreferences();
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
        ),
      );
      await tester.pump();

      expect(provider.surahStatus, AppLoadingStatus.loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const Right<Failure, List<SurahEntity>>(_testSurahs));
      await _settle(tester);

      expect(provider.surahStatus, AppLoadingStatus.loaded);
      expect(find.text('سورة الإخلاص'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('shows an error and retries successfully', (tester) async {
      final repository = _FakeSurahRepository([
        const Left<Failure, List<SurahEntity>>(
          JsonParsingFailure('تعذر تحميل السور'),
        ),
        const Right<Failure, List<SurahEntity>>(_testSurahs),
      ]);
      final provider = _surahProvider(repository);
      final preferences = await _mockPreferences();
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
        ),
      );
      await _settle(tester);

      expect(find.text('تعذر تحميل السور'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);

      expect(repository.calls, 2);
      expect(find.text('سورة الإخلاص'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('shows the no-results state and clears it', (tester) async {
      final repository = _FakeSurahRepository([
        const Right<Failure, List<SurahEntity>>(_testSurahs),
      ]);
      final provider = _surahProvider(repository);
      final preferences = await _mockPreferences();
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
        ),
      );
      await _settle(tester);

      await tester.enterText(find.byType(TextFormField), 'سورة غير موجودة');
      await _settle(tester);

      expect(find.text('لم يتم العثور على السورة'), findsOneWidget);
      expect(find.byType(SurahItem), findsNothing);

      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await _settle(tester);
      expect(find.text('سورة الإخلاص'), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('handles an empty loaded list', (tester) async {
      final repository = _FakeSurahRepository([
        const Right<Failure, List<SurahEntity>>(<SurahEntity>[]),
      ]);
      final provider = _surahProvider(repository);
      await provider.loadSurah();
      final preferences = await _mockPreferences();
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
        ),
      );
      await _settle(tester);

      expect(find.byType(SurahItem), findsNothing);
      _expectNoException(tester);
    });

    testWidgets('survives a narrow surface with enlarged text', (tester) async {
      await _setNarrowSurface(tester);
      final repository = _FakeSurahRepository([
        const Right<Failure, List<SurahEntity>>(_testSurahs),
      ]);
      final provider = _surahProvider(repository);
      final preferences = await _mockPreferences();
      final favorites = FavoritesProvider(sharedPreferences: preferences);

      await tester.pumpWidget(
        _testApp(
          home: const SurahListPage(),
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: favorites),
          ],
          textScaler: const TextScaler.linear(2),
        ),
      );
      await _settle(tester);

      expect(find.byType(SurahItem), findsWidgets);
      _expectNoException(tester);
    });
  });

  group('qibla', () {
    testWidgets('renders fixed heading differences and alignment states',
        (tester) async {
      const cases = [
        _QiblaCase(
          heading: 0,
          difference: 0,
          aligned: true,
          status: 'أنت باتجاه القبلة الآن',
        ),
        _QiblaCase(
          heading: 180,
          difference: 180,
          aligned: false,
          status: 'قم بتدوير الهاتف نحو القبلة',
        ),
        _QiblaCase(
          heading: 360,
          difference: 360,
          aligned: true,
          status: 'أنت باتجاه القبلة الآن',
        ),
      ];

      for (final item in cases) {
        await tester.pumpWidget(
          _testApp(
            home: QiblaBody(
              heading: item.heading,
              difference: item.difference,
              isAligned: item.aligned,
            ),
          ),
        );
        await _settle(tester);

        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(QiblaBody),
            matching: find.byType(Transform),
          ),
        );
        expect(
          transform.transform.storage[0],
          closeTo(math.cos(item.difference * math.pi / 180), 0.000001),
        );
        expect(
          find.text('${AppHelpers.getArabicNumber(item.heading.toInt())}°'),
          findsOneWidget,
        );
        expect(find.text(item.status), findsOneWidget);
        _expectNoException(tester);
      }
    });

    testWidgets('renders the loading state', (tester) async {
      final provider = _FakeQiblaProvider(
        loading: true,
        heading: 0,
        qiblaDelta: 0,
        aligned: true,
      );
      await _registerQiblaProvider(provider);

      await tester.pumpWidget(
        _testApp(home: const QiblaScreen()),
      );
      await _settle(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('renders location and compass error states', (tester) async {
      final locationProvider = _FakeQiblaProvider(
        loading: false,
        heading: 0,
        qiblaDelta: 0,
        aligned: false,
        message: 'تعذر تحديد الموقع',
      );
      await _registerQiblaProvider(locationProvider);
      await tester.pumpWidget(
        _testApp(home: const QiblaScreen(key: ValueKey('location-error'))),
      );
      await _settle(tester);

      expect(find.text('تعذر تحديد الموقع'), findsOneWidget);
      expect(find.text('فتح الاعدادات'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);
      _expectNoException(tester);

      final compassProvider = _FakeQiblaProvider(
        loading: false,
        heading: 0,
        qiblaDelta: 0,
        aligned: false,
        compassIsUnavailable: true,
      );
      await _registerQiblaProvider(compassProvider);
      await tester.pumpWidget(
        _testApp(home: const QiblaScreen(key: ValueKey('compass-error'))),
      );
      await _settle(tester);

      expect(find.text('البوصلة غير متوفرة على هذا الجهاز'), findsOneWidget);
      expect(find.text('لا يمكن تحديد اتجاه القبلة دون مستشعر البوصلة.'),
          findsOneWidget);
      _expectNoException(tester);
    });

    testWidgets('passes provider state into the qibla body', (tester) async {
      await _setPortraitSurface(tester);
      final provider = _FakeQiblaProvider(
        loading: false,
        heading: 120,
        qiblaDelta: 30,
        aligned: false,
      );
      await _registerQiblaProvider(provider);

      await tester.pumpWidget(
        _testApp(home: const QiblaScreen(key: ValueKey('body-state'))),
      );
      await _settle(tester);

      expect(find.byType(QiblaBody), findsOneWidget);
      expect(find.text('١٢٠°'), findsOneWidget);
      expect(find.text('قم بتدوير الهاتف نحو القبلة'), findsOneWidget);
      _expectNoException(tester);
    });
  });

  group('widget guide', () {
    testWidgets('navigates all steps and marks the guide as seen',
        (tester) async {
      final preferences = await _mockPreferences();

      await tester.pumpWidget(
        _testApp(
          home: const _GuideHost(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('فتح الدليل'));
      await _settle(tester);

      expect(find.byType(WidgetGuidePage), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('مواقيت الصلاة على شاشتك'), findsOneWidget);
      expect(find.text('ميزة جديدة'), findsOneWidget);
      expect(find.text('عرض طريقة الإضافة'), findsOneWidget);

      await tester.tap(find.text('عرض طريقة الإضافة'));
      await _settle(tester, delay: const Duration(milliseconds: 500));
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('افتح قائمة الويدجت'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await _settle(tester, delay: const Duration(milliseconds: 500));
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('ابحث عن أذكاري'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await _settle(tester, delay: const Duration(milliseconds: 500));
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('أضف الويدجت'), findsOneWidget);
      expect(find.text('تم، فهمت'), findsOneWidget);

      await tester.tap(find.text('تم، فهمت'));
      await tester.pumpAndSettle();

      expect(find.byType(WidgetGuidePage), findsNothing);
      expect(preferences.getBool(WidgetGuidePage.seenPreferenceKey), isTrue);
      _expectNoException(tester);
    });

    testWidgets('opens and closes the fullscreen screenshot', (tester) async {
      await tester.pumpWidget(
        _testApp(
          home: const _GuideHost(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('فتح الدليل'));
      await _settle(tester);

      await tester.tap(find.byType(ScreenshotContainer));
      await _settle(tester, delay: const Duration(milliseconds: 300));

      expect(find.byType(FullScreenScreenshot), findsOneWidget);
      final closeButton = find.descendant(
        of: find.byType(FullScreenScreenshot),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenScreenshot), findsNothing);
      _expectNoException(tester);
    });

    testWidgets('does not mark a settings-opened guide as seen when deferred',
        (tester) async {
      final preferences = await _mockPreferences();

      await tester.pumpWidget(
        _testApp(
          home: const _GuideHost(openedFromSettings: true),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('فتح الدليل'));
      await _settle(tester);

      expect(find.text('لاحقًا'), findsOneWidget);
      await tester.tap(find.text('لاحقًا'));
      await _settle(tester, delay: const Duration(milliseconds: 300));

      expect(find.byType(WidgetGuidePage), findsNothing);
      expect(preferences.getBool(WidgetGuidePage.seenPreferenceKey), isNull);
      _expectNoException(tester);
    });

    testWidgets('survives a narrow surface with enlarged text', (tester) async {
      await _setNarrowSurface(tester);

      await tester.pumpWidget(
        _testApp(
          home: const _GuideHost(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('فتح الدليل'));
      await _settle(tester);

      expect(find.byType(WidgetGuidePage), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      _expectNoException(tester);
    });
  });
}
