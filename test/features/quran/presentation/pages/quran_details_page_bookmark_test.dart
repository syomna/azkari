import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_page_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_surah_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_saved_quran_page_number_usecase.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_just_audio_platform.dart';
import '../../../../helpers/quran_test_doubles.dart';

class _MemoryBookmark {
  int? surah;
  int? page;
}

class _GetBookmarkSurahFake extends GetQuranBookmarkSurahUseCase {
  _GetBookmarkSurahFake(this.mem) : super(quranRepository: ThrowingRepo());

  final _MemoryBookmark mem;

  @override
  int? call() => mem.surah;
}

class _GetBookmarkPageFake extends GetQuranBookmarkPageUseCase {
  _GetBookmarkPageFake(this.mem) : super(quranRepository: ThrowingRepo());

  final _MemoryBookmark mem;

  @override
  int? call() => mem.page;
}

class _SavedPageFake extends GetSavedQuranPageNumberUsecase {
  _SavedPageFake(this.page) : super(quranRepository: ThrowingRepo());

  final int? page;

  @override
  int? call() => page;
}

Widget _harness(QuranProvider provider) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      ScreenUtil.init(context);
      return ChangeNotifierProvider<QuranProvider>.value(
        value: provider,
        child: const MaterialApp(home: QuranDetailPage()),
      );
    },
  );
}

String _pillFor(int page) => '${AppHelpers.getArabicNumber(page)} / ٦٠٤';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryBookmark mem;

  setUp(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    mem = _MemoryBookmark();
  });

  testWidgets('reader opens at the bookmarked page', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // الإشارة المرجعية على صفحة 50، وآخر صفحة قُرئت تلقائياً 12:
    // العلامة المرجعية لها الأولوية عند الفتح.
    mem.surah = 18;
    mem.page = 50;
    final provider = buildTestQuranProvider(
      getQuranBookmarkSurahUseCase: _GetBookmarkSurahFake(mem),
      getQuranBookmarkPageUseCase: _GetBookmarkPageFake(mem),
      getQuranPageNumberUseCase: _SavedPageFake(12),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_harness(provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(_pillFor(50)), findsOneWidget);
    expect(find.text(_pillFor(12)), findsNothing);
  });

  testWidgets('reader falls back to the last read page without a bookmark',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final provider = buildTestQuranProvider(
      getQuranBookmarkSurahUseCase: _GetBookmarkSurahFake(mem),
      getQuranBookmarkPageUseCase: _GetBookmarkPageFake(mem),
      getQuranPageNumberUseCase: _SavedPageFake(23),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_harness(provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // بلا إشارة مرجعية نبدأ من آخر صفحة قُرئت تلقائياً
    expect(find.text(_pillFor(23)), findsOneWidget);
  });

  testWidgets('bookmark is ignored when it is out of range', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    mem.surah = 1;
    mem.page = 900; // خارج حدود المصحف (1..604)
    final provider = buildTestQuranProvider(
      getQuranBookmarkSurahUseCase: _GetBookmarkSurahFake(mem),
      getQuranBookmarkPageUseCase: _GetBookmarkPageFake(mem),
      getQuranPageNumberUseCase: _SavedPageFake(23),
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(_harness(provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // صفحة خارج النطاق تُتجاهل ويبدأ من آخر صفحة مقروءة
    expect(find.text(_pillFor(604)), findsNothing);
    expect(find.text(_pillFor(23)), findsOneWidget);
  });
}
