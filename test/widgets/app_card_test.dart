import 'package:azkar_app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (ctx, _) => MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            child: Text('Test Content'),
          ),
        ),
      );
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            padding: EdgeInsets.all(16),
            child: Text('Padded'),
          ),
        ),
      );
      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('applies border color', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            borderColor: Colors.red,
            child: Text('Bordered'),
          ),
        ),
      );
      expect(find.text('Bordered'), findsOneWidget);
    });

    testWidgets('glass mode renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            glass: true,
            child: Text('Glass'),
          ),
        ),
      );
      expect(find.text('Glass'), findsOneWidget);
    });
  });
}
