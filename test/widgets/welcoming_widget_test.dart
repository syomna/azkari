import 'package:azkar_app/widgets/welcoming_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  /// The greeting is time-dependent, so the subtitle is the stable landmark.
  const String subtitle = 'ألا بذكر الله تطمئن القلوب 🌿';

  Future<void> pump(
    WidgetTester tester, {
    required TextDirection direction,
    Widget? action,
    double width = 390,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            // Directionality sits inside MaterialApp on purpose: MaterialApp
            // installs its own from the locale, which would override an outer
            // wrapper and silently test LTR in both directions.
            home: Directionality(
              textDirection: direction,
              // Mirrors HomePage, where the row scrolls inside a Column and so
              // gets unbounded height. A tight-height box would test a layout
              // the app never uses and overflow on the fallback test font.
              child: SingleChildScrollView(
                child: WelcomingWidget(action: action),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Widget actionButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.settings),
      );

  testWidgets('renders the action when one is supplied', (tester) async {
    await pump(tester, direction: TextDirection.rtl, action: actionButton());

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omits the action slot when none is supplied', (tester) async {
    await pump(tester, direction: TextDirection.rtl);

    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.text(subtitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('places the action at the left in RTL', (tester) async {
    await pump(tester, direction: TextDirection.rtl, action: actionButton());

    // RTL lays the row out right-to-left, so the trailing slot is the leftmost
    // element: the avatar leads on the right and the action ends up on the left.
    final double actionLeft = tester.getTopLeft(find.byIcon(Icons.settings)).dx;
    final double textLeft = tester.getTopLeft(find.text(subtitle)).dx;

    expect(actionLeft, lessThan(textLeft));
  });

  testWidgets('places the action at the right in LTR', (tester) async {
    await pump(
      tester,
      direction: TextDirection.ltr,
      action: actionButton(),
    );

    final double actionLeft = tester.getTopLeft(find.byIcon(Icons.settings)).dx;
    final double textLeft = tester.getTopLeft(find.text(subtitle)).dx;

    expect(actionLeft, greaterThan(textLeft));
  });

  testWidgets('survives a narrow screen at double text scale', (tester) async {
    await pump(
      tester,
      direction: TextDirection.rtl,
      action: actionButton(),
      width: 320,
      textScale: 2.0,
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
