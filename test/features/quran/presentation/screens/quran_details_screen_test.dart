import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/screens/quran_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'quran_details_screen_test.mocks.dart';

@GenerateMocks([QuranProvider])
void main() {
  late MockQuranProvider mockQuranProvider;

  setUp(() {
    mockQuranProvider = MockQuranProvider();
    when(mockQuranProvider.savedLatestQuranPageNumber).thenReturn(1);
    when(mockQuranProvider.savedLatestQuranSurahNumber).thenReturn(1);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      locale: const Locale('ar'),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(430, 932)),
        child: ChangeNotifierProvider<QuranProvider>.value(
          value: mockQuranProvider,
          child: const QuranDetailsScreen(),
        ),
      ),
    );
  }

  group('QuranDetailsScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(QuranDetailsScreen), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
