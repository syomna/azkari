import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_player_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_just_audio_platform.dart';
import '../../../../helpers/quran_test_doubles.dart';

Widget _wrap(QuranProvider provider, int surahNumber) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      ScreenUtil.init(context);
      return ChangeNotifierProvider<QuranProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: AudioPlayerCard(surahNumber: surahNumber),
          ),
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranProvider provider;

  setUp(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
  });

  tearDown(() {
    provider.dispose();
  });

  testWidgets('play button does not crash and download check is reflected',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    provider = buildTestQuranProvider(
      checkSurahDownloadedUseCase: FakeDownloadedCheck({2}),
    );

    await tester.pumpWidget(_wrap(provider, 2));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('slider clamps a stale position when the duration is unknown',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controllable = ControllableQuranProvider(downloaded: {2});
    provider = controllable;
    controllable.playingSurah = 2;

    await tester.pumpWidget(_wrap(provider, 2));
    await tester.pump();

    // موضع تشغيل متقدم بينما المدة غير معروفة (أثناء الإيقاف أو التحميل):
    // كان ذلك يُفعّل Slider assertion لأن value أكبر من max.
    controllable.emitPosition(const Duration(seconds: 12));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);

    // الحالة الطبيعية: المدة معروفة ويبقى الموضع داخل المدى.
    controllable.emitPosition(const Duration(seconds: 4));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('play time shows the duration even before a position arrives',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // سورة غير منزّلة: لا مدة معروفة قبل التشغيل، فتظل "0:00 / 0:00".
    final controllable = ControllableQuranProvider(downloaded: {});
    provider = controllable;
    controllable.playingSurah = 2;

    await tester.pumpWidget(_wrap(provider, 2));
    await tester.pump();

    // قبل التحميل: لا مدة ولا موضع
    expect(find.text('0:00 / 0:00'), findsOneWidget);

    // المدة تصل وحدها: لا يوجد أي حدث موضع بعد، ومع ذلك يجب أن تتحدّث
    // خانة الوقت (كانت تبقى "0:00 / 0:00" في الكود القديم).
    controllable.emitDuration(const Duration(minutes: 3, seconds: 4));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('0:00 / 3:04'), findsOneWidget);

    // ثم يصل الموضع ويتقدّم العدّاد
    controllable.emitPosition(const Duration(seconds: 12));
    await tester.pump();
    await tester.pump();
    expect(find.text('0:12 / 3:04'), findsOneWidget);
  });

  testWidgets(
      'downloaded surah shows its full duration before any playback',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    provider = ControllableQuranProvider(
      downloaded: {2},
      knownDuration: const Duration(minutes: 3),
    );

    await tester.pumpWidget(_wrap(provider, 2));
    await tester.pumpAndSettle();

    // لم يُلمس زر التشغيل إطلاقاً: المدة معروفة من ملف السورة المنزّلة
    // فتظهر "0:00 / 3:00" بدل "0:00 / 0:00".
    expect(tester.takeException(), isNull);
    expect(find.text('0:00 / 3:00'), findsOneWidget);
  });

  testWidgets('download status updates when the surah changes', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    provider = buildTestQuranProvider(
      checkSurahDownloadedUseCase: FakeDownloadedCheck({2}),
    );

    await tester.pumpWidget(_wrap(provider, 1));
    await tester.pump();
    await tester.pump();

    // Surah 1 not downloaded -> cloud icon
    expect(
      find.byIcon(CupertinoIcons.cloud_download),
      findsOneWidget,
    );

    // Swap to a downloaded surah while the same widget stays alive
    await tester.pumpWidget(_wrap(provider, 2));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );
  });
}
