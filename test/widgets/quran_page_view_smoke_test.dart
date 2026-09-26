import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart' as quran;

void main() {
  testWidgets('QuranPageView renders a mushaf page with ayah text',
      (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: quran.QuranPageView(pageController: controller),
        ),
      ),
    );

    // initState loads the 604-page data synchronously (decode package assets).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(quran.QuranPageView), findsOneWidget);
    // Mushaf lines render as RichText (ayat text sits inside WidgetSpans).
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('QuranPageView reports physical page numbers via onPageChanged',
      (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    int? reportedPage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: quran.QuranPageView(
            pageController: controller,
            onPageChanged: (p) => reportedPage = p,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    controller.jumpToPage(100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(reportedPage, 101);
  });
}