import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAzkarRepository implements AzkarRepository {
  _FakeAzkarRepository(this.azkar);

  final List<ZekrEntity> azkar;

  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async => Right(azkar);

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async =>
      const Right([]);

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async =>
      const Right(unit);

  @override
  Future<Either<Failure, void>> deleteCustomCategory(String categoryName) async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> updateCustomAzkarCategory(
          String oldCategory, List<ZekrEntity> items) async =>
      const Right(unit);
}

void main() {
  const category = 'أذكار الصباح';
  const int total = 3;

  late List<ZekrEntity> azkar;
  late AzkarProvider azkarProvider;

  setUp(() {
    // Enough entries that the details list overflows the viewport and scrolls,
    // forcing `ListView` to recycle the first card out of view.
    azkar = List.generate(
      15,
      (i) => ZekrEntity(
        category: category,
        zekr: 'ذِكر ${i + 1}',
        description: '',
        count: '$total',
        reference: '',
      ),
    );

    final repo = _FakeAzkarRepository(azkar);
    azkarProvider = AzkarProvider(
      getAzkarUseCase: GetAzkarUseCase(azkarRepository: repo),
      getCustomAzkarUseCase: GetCustomAzkarUseCase(azkarRepository: repo),
      saveCustomAzkarUseCase: SaveCustomAzkarUseCase(azkarRepository: repo),
      deleteCustomAzkarUseCase: DeleteCustomAzkarUseCase(azkarRepository: repo),
      updateCustomAzkarUseCase:
          UpdateCustomAzkarUseCase(azkarRepository: repo),
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final favorites = FavoritesProvider(sharedPreferences: prefs);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        builder: (context, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: azkarProvider),
              ChangeNotifierProvider.value(value: favorites),
            ],
            child: const MaterialApp(
              home: AzkarDetailsPage(
                title: category,
                categoryName: category,
              ),
            ),
          );
        },
      ),
    );
    // Let ScreenUtil init and the async azkar load resolve (via microtasks),
    // then rebuild after the provider notifies.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('counting survives ListView recycling when scrolling', (
    tester,
  ) async {
    await pumpPage(tester);

    // Each card starts at its total.
    expect(
      azkarProvider.remainingFor(azkar.first.zekr, total, category: category),
      total,
    );

    // Decrement the first zekr twice (3 -> 1). Counting lives in the provider,
    // not in the recyclable widget state.
    await tester.tap(find.byType(DisplayAzkar).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(DisplayAzkar).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      azkarProvider.remainingFor(azkar.first.zekr, total, category: category),
      1,
    );
    // The first card's counter pill reflects the stored value (Arabic "١").
    expect(find.text('١'), findsOneWidget);

    // Scroll far down so the first card is recycled out of the viewport.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Provider memory survives the widget being disposed/recreated by the list.
    expect(
      azkarProvider.remainingFor(azkar.first.zekr, total, category: category),
      1,
    );

    // Scroll back to the top; the re-created first card still shows "١".
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      azkarProvider.remainingFor(azkar.first.zekr, total, category: category),
      1,
    );
    expect(find.text('١'), findsOneWidget);
  });
}
