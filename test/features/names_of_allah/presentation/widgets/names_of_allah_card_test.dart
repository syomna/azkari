import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const NamesOfAllahEntity _name = NamesOfAllahEntity(
  id: 1,
  name: 'الرَّحْمَنُ',
  text: 'رحيم',
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: brightness == Brightness.dark
              ? AppPalette.darkTheme
              : AppPalette.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: const NamesOfAllahCard(item: _name),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  TextStyle captionStyle(WidgetTester tester) =>
      tester.widget<Text>(find.text(AppConstants.namesOfAllah)).style!;

  testWidgets('العنوان محفور فوق الاسم لا تحته', (tester) async {
    await pumpCard(tester);

    final Finder caption = find.text(AppConstants.namesOfAllah);
    final Finder name = find.text(_name.name);
    expect(caption, findsOneWidget);
    expect(name, findsOneWidget);
    expect(tester.getTopLeft(caption).dy, lessThan(tester.getTopLeft(name).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('العنوان غير ظاهر تماماً: شفافية أقل من الواحد', (tester) async {
    await pumpCard(tester);

    final Color color = captionStyle(tester).color!;
    expect(color.a, lessThan(1.0));
    expect(color.a, greaterThan(0.0));
  });

  testWidgets('النحت ظل فوق الحرف وظل تحته', (tester) async {
    await pumpCard(tester);

    final List<Shadow>? shadows = captionStyle(tester).shadows;
    expect(shadows, isNotNull);
    expect(shadows, hasLength(2));

    // ظل الحافة العليا في بئر لا يصله الضوء.
    expect(shadows!.first.offset, const Offset(0, -1));
    // ظل الحافة السفلية التي تلتقط الضوء.
    expect(shadows.last.offset, const Offset(0, 1));

    // والظل فوق الحرف أغمق من الظل تحته. هذا الترتيب هو ما يقرأه العين
    // كأن الحرف غائر في البطاقة لا ناتئ منها، وعكسه (فاتح فوق، غامق تحت)
    // يعطي مظهراً بارزاً على البطاقة.
    expect(
      shadows.first.color.computeLuminance(),
      lessThan(shadows.last.color.computeLuminance()),
    );
  });

  testWidgets('الوضع الداكن يبقى محفوراً لا مقلوباً', (tester) async {
    await pumpCard(tester, brightness: Brightness.dark);

    final List<Shadow>? shadows = captionStyle(tester).shadows;
    expect(shadows, hasLength(2));
    expect(shadows!.first.offset, const Offset(0, -1));
    expect(shadows.last.offset, const Offset(0, 1));
    // في الداكن يحتاج الحبر حضوراً أكبر من النمط الفاتح.
    expect(captionStyle(tester).color!.a, greaterThan(0.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('العنوان لا يتقطع مع نص كبير', (tester) async {
    await pumpCard(tester, textScale: 2);

    expect(
      tester
          .renderObject<RenderParagraph>(find.text(AppConstants.namesOfAllah))
          .didExceedMaxLines,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
