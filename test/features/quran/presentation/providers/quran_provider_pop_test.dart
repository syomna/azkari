import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_just_audio_platform.dart';
import '../../../../helpers/quran_test_doubles.dart';

class _DisposeResetScreen extends StatefulWidget {
  const _DisposeResetScreen(this.provider);

  final QuranProvider provider;

  @override
  State<_DisposeResetScreen> createState() => _DisposeResetScreenState();
}

class _DisposeResetScreenState extends State<_DisposeResetScreen> {
  @override
  void dispose() {
    widget.provider.resetAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('pop screen')));
  }
}

void main() {
  testWidgets('popping a screen that resets audio in dispose does not throw',
      (tester) async {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    final provider = buildTestQuranProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<QuranProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // مشترك يبقى حيّاً بعد الرجوع، فيتأثر بـ notifyListeners
                    Consumer<QuranProvider>(
                      builder: (context, p, child) =>
                          Text('surah ${p.bookmarkSurah}'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _DisposeResetScreen(provider),
                          ),
                        );
                      },
                      child: const Text('push'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('pop screen'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
