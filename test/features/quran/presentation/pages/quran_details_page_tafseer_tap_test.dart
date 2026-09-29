import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/tafseer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_just_audio_platform.dart';
import '../../../../helpers/quran_test_doubles.dart';

Widget _harness(QuranProvider provider) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      ScreenUtil.init(context, designSize: const Size(430, 932));
      return ChangeNotifierProvider<QuranProvider>.value(
        value: provider,
        child: const MaterialApp(home: QuranDetailPage()),
      );
    },
  );
}

/// الحزمة تغلّف كل آية مظلَّلة بـ BoxDefinition بلون التظليل بشفافية 0.4،
/// فنبحث عن ذلك الصندوق بالذات لا عن أي BoxDefinition آخر في الصفحة.
Finder get highlightedAyah {
  final Color expected = AppPalette.mainColor.withValues(alpha: 0.4);
  return find.byWidgetPredicate((Widget widget) {
    if (widget is! Container) return false;
    final Decoration? decoration = widget.decoration;
    return decoration is BoxDecoration && decoration.color == expected;
  });
}

/// المصحف يعرض كل سطر في FittedBox، وداخله آية واحدة على الأقل داخل
/// GestureDetector خاص بها (WidgetSpan)، فنقر أول آية في أول سطر كما يفعل
/// المستخدم. لا نبحث عن أول RichText في الشجرة لأن أول واحد منها نص شريط
/// الأدوات لا نص المصحف.
Finder get firstAyah => find
    .descendant(
      of: find.byType(FittedBox).first,
      matching: find.byType(GestureDetector),
    )
    .first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
  });

  testWidgets('tapping an ayah opens its tafseer and highlights that ayah',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final provider = buildTestQuranProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(_harness(provider));
    await tester.pumpAndSettle();

    expect(highlightedAyah, findsNothing);

    await tester.tap(firstAyah, warnIfMissed: false);
    // لا نستخدم pumpAndSettle هنا: الورقة تعرض CircularProgressIndicator
    // أثناء جلب التفسير، وهي حركة لا تهدأ أبداً فلا يستقر الإطار.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // النقر يفتح ورقة التفسير مبيّنةً رقم السورة والآية المضغوطة.
    expect(find.byType(TafseerSheet), findsOneWidget);
    expect(find.textContaining('تفسير الآية'), findsOneWidget);

    // والآية نفسها مظلَّلة في المصحف خلف الورقة.
    expect(highlightedAyah, findsOneWidget);

    // إغلاق الورقة يرفع التظليل حتى لا يبقى أثر آية بلا سبب على الشاشة.
    final NavigatorState navigator = tester.state(find.byType(Navigator).first);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TafseerSheet), findsNothing);
    expect(highlightedAyah, findsNothing);
  });
}
