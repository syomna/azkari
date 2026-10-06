import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/pages/ad3ya_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_form_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_grid_item.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAzkarRepository implements AzkarRepository {
  _FakeAzkarRepository(this.azkar, {List<ZekrEntity> custom = const []})
      : custom = List.of(custom);

  final List<ZekrEntity> azkar;
  final List<ZekrEntity> custom;

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async => Right(azkar);

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async =>
      Right(List.of(custom));

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async {
    custom.addAll(items);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
    String categoryName,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> updateCustomAzkarCategory(
    String oldCategory,
    List<ZekrEntity> items,
  ) async {
    custom.removeWhere((item) => item.category == oldCategory);
    custom.addAll(items);
    return const Right(unit);
  }
}

class _FakeSurahRepository implements SurahRepository {
  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async =>
      const Right([]);
}

ZekrEntity _zekr(String category) => ZekrEntity(
      category: category,
      zekr: 'نص $category',
      description: '',
      count: '1',
      reference: '',
    );

void main() {
  late AzkarProvider azkarProvider;
  late FavoritesProvider favoritesProvider;
  late _FakeAzkarRepository repository;

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(430, 932),
    TextScaler textScaler = const TextScaler.linear(1),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        builder: (context, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: azkarProvider),
              ChangeNotifierProvider.value(value: favoritesProvider),
              ChangeNotifierProvider(
                create: (_) => SurahProvider(
                  getSurahUseCase: GetSurahUseCase(
                    surahRepository: _FakeSurahRepository(),
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
              home: const Ad3yaPage(),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  void seed(List<String> categories, {List<ZekrEntity> custom = const []}) {
    repository = _FakeAzkarRepository(
      categories.map(_zekr).toList(),
      custom: custom,
    );
    azkarProvider = AzkarProvider(
      getAzkarUseCase: GetAzkarUseCase(azkarRepository: repository),
      getCustomAzkarUseCase: GetCustomAzkarUseCase(azkarRepository: repository),
      saveCustomAzkarUseCase:
          SaveCustomAzkarUseCase(azkarRepository: repository),
      deleteCustomAzkarUseCase:
          DeleteCustomAzkarUseCase(azkarRepository: repository),
      updateCustomAzkarUseCase:
          UpdateCustomAzkarUseCase(azkarRepository: repository),
    );
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    favoritesProvider = FavoritesProvider(sharedPreferences: prefs);
    seed([
      'أذكار الصباح',
      'دعاء الكرب',
      'أذكار النوم',
      'دعاء السفر',
      'أدعية طلب العلم',
    ]);
  });

  testWidgets('تسرد الأدعية وحدها في شبكة ولا تسرد الأذكار', (tester) async {
    await pumpPage(tester);

    expect(find.byType(AzkarGridItem), findsNWidgets(3));
    expect(find.text('دعاء الكرب'), findsOneWidget);
    expect(find.text('دعاء السفر'), findsOneWidget);
    expect(find.text('أدعية طلب العلم'), findsOneWidget);

    // أذكار الصباح والنوم موضوعان في البيانات لكنهما ليسا أدعية.
    expect(find.text('أذكار الصباح'), findsNothing);
    expect(find.text('أذكار النوم'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('التبويبات الثلاثة: الأدعية وأدعيتي والمفضلة', (tester) async {
    await pumpPage(tester);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text(AppConstants.ad3yaPageTitle), findsOneWidget);
    expect(find.widgetWithText(Tab, 'الأدعية'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'أدعيتي'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'المفضلة'), findsOneWidget);

    // زر الإضافة يضيف دعاءً لا ذكراً.
    expect(find.text('إضافة دعاء'), findsOneWidget);
  });

  testWidgets('كل الموضوعات تأخذ أيقونة الصلاة', (tester) async {
    // "دعاء السفر" فيه كلمة "السفر" و"دعاء النوم" فيه "النوم"، وكلاهما له
    // أيقونة في مسار الأذكار، فيجب أن يأخذ أيقونة الصلاة لأن فحص الأدعية
    // يسبق غيره.
    seed(['دعاء السفر', 'دعاء النوم', 'دعاء بعد الصلاة', 'أذكار الصباح']);
    await pumpPage(tester);

    final duaCards = find.ancestor(
      of: find.byIcon(FlutterIslamicIcons.prayer),
      matching: find.byType(AzkarGridItem),
    );
    expect(duaCards, findsNWidgets(3));
    expect(find.byIcon(Icons.layers_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('تبويب أدعيتي يعرض الموضوعات المضافة فقط', (tester) async {
    seed(
      ['أذكار الصباح', 'دعاء الكرب'],
      custom: [_zekr('دعاء النوم'), _zekr('مذكراتي')],
    );
    await pumpPage(tester);
    await openTab(tester, 'أدعيتي');

    expect(find.byType(AzkarGridItem), findsOneWidget);
    expect(find.text('دعاء النوم'), findsOneWidget);
    // موضوع مضاف بلا كلمة "دعاء" في عنوانه يبقى في مكتبة الأذكار.
    expect(find.text('مذكراتي'), findsNothing);
  });

  testWidgets('المفضلة هنا لا تعرض موضوعات الأذكار', (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.favoriteCategories: ['دعاء الكرب', 'أذكار الصباح'],
    });
    final prefs = await SharedPreferences.getInstance();
    favoritesProvider = FavoritesProvider(sharedPreferences: prefs);
    await pumpPage(tester);
    await openTab(tester, 'المفضلة');

    expect(find.text('دعاء الكرب'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsNothing);
  });

  testWidgets('البحث يضيّق النتائج وينوي فتح صفحة التفاصيل', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'السفر');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AzkarGridItem), findsOneWidget);
    expect(find.text('دعاء السفر'), findsOneWidget);

    await tester.tap(find.text('دعاء السفر'));
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(AzkarDetailsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('بحث بلا نتائج يعرض رسالة واضحة', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'لاشيء هنا');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AzkarGridItem), findsNothing);
    expect(find.text('لم يتم العثور على نتائج'), findsOneWidget);
  });

  testWidgets('بيانات بلا أدعية تعرض حالة فارغة', (tester) async {
    seed(['أذكار الصباح', 'أذكار المساء']);
    await pumpPage(tester);

    expect(find.byType(AzkarGridItem), findsNothing);
    expect(find.text('لا توجد أدعية'), findsOneWidget);
  });

  testWidgets('العنوان يعرض عدد الموضوعات', (tester) async {
    await pumpPage(tester);

    expect(find.text('٣ موضوع'), findsOneWidget);
  });

  testWidgets('الشبكة تتحمّل 320x600 بمقياس نص 2x', (tester) async {
    await pumpPage(
      tester,
      size: const Size(320, 600),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byType(AzkarGridItem), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('إضافة دعاء', () {
    Future<void> openAddSheet(WidgetTester tester) async {
      await tester.tap(find.text('إضافة دعاء'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('تحفظ العنوان الذي فيه كلمة دعاء', (tester) async {
      await pumpPage(tester);
      await openAddSheet(tester);

      expect(find.byType(AzkarFormSheet), findsOneWidget);
      expect(find.text('إضافة أدعية جديدة'), findsOneWidget);

      // حقول الورقة وحدها: حقل البحث في الصفحة ما زال في الشجرة خلف النافذة.
      final fields = find.descendant(
        of: find.byType(AzkarFormSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'دعاء الاستخارة');
      await tester.enterText(fields.at(2), 'نص الدعاء');
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'حفظ الكل'),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        repository.custom.any((item) => item.category == 'دعاء الاستخارة'),
        isTrue,
      );
    });

    testWidgets('ترفض العنوان الذي لا يميّزه كدعاء', (tester) async {
      await pumpPage(tester);
      await openAddSheet(tester);

      final fields = find.descendant(
        of: find.byType(AzkarFormSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'كلمات');
      await tester.enterText(fields.at(2), 'نص');
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'حفظ الكل'),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // لم يُحفظ شيء وبقيت الورقة مفتوحة.
      expect(repository.custom, isEmpty);
      expect(find.byType(AzkarFormSheet), findsOneWidget);
    });
  });
}
