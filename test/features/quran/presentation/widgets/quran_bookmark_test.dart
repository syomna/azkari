import 'package:azkar_app/features/quran/domain/usecases/clear_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_page_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/get_quran_bookmark_surah_usecase.dart';
import 'package:azkar_app/features/quran/domain/usecases/save_quran_bookmark_usecase.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_just_audio_platform.dart';
import '../../../../helpers/quran_test_doubles.dart';

class _MemoryBookmark {
  int? surah;
  int? page;
}

class _SaveBookmarkFake extends SaveQuranBookmarkUseCase {
  _SaveBookmarkFake(this.mem) : super(quranRepository: ThrowingRepo());

  final _MemoryBookmark mem;

  @override
  Future<void> call({
    required int surahNumber,
    required int pageNumber,
  }) async {
    mem.surah = surahNumber;
    mem.page = pageNumber;
  }
}

class _ClearBookmarkFake extends ClearQuranBookmarkUseCase {
  _ClearBookmarkFake(this.mem) : super(quranRepository: ThrowingRepo());

  final _MemoryBookmark mem;

  @override
  Future<void> call() async {
    mem.surah = null;
    mem.page = null;
  }
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

/// نفس ربط زر الإشارة الموجود في `_buildBookmarkButton` بصفحة القارئ:
/// `Consumer<QuranProvider>` هو السبب في تحديث الأيقونة فور النقر.
Widget _harness(QuranProvider provider, {int surah = 7, int page = 12}) {
  return ChangeNotifierProvider<QuranProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            Consumer<QuranProvider>(
              builder: (context, p, child) {
                final isBookmarked =
                    p.bookmarkSurah == surah && p.bookmarkPage == page;
                return IconButton(
                  tooltip: isBookmarked ? 'remove' : 'add',
                  icon: Icon(
                    isBookmarked
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    color: isBookmarked ? Colors.amber : null,
                  ),
                  onPressed: () {
                    if (isBookmarked) {
                      p.clearBookmark();
                    } else {
                      p.saveBookmark(
                        surahNumber: surah,
                        pageNumber: page,
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranProvider provider;
  late _MemoryBookmark mem;

  setUp(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    mem = _MemoryBookmark();
    provider = buildTestQuranProvider(
      saveQuranBookmarkUseCase: _SaveBookmarkFake(mem),
      getQuranBookmarkSurahUseCase: _GetBookmarkSurahFake(mem),
      getQuranBookmarkPageUseCase: _GetBookmarkPageFake(mem),
      clearQuranBookmarkUseCase: _ClearBookmarkFake(mem),
    );
  });

  tearDown(() {
    provider.dispose();
  });

  testWidgets('bookmark icon toggles immediately when tapped', (tester) async {
    await tester.pumpWidget(_harness(provider));

    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.bookmark_fill), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.bookmark));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.bookmark_fill), findsOneWidget);
    expect(provider.bookmarkSurah, 7);
    expect(provider.bookmarkPage, 12);

    await tester.tap(find.byIcon(CupertinoIcons.bookmark_fill));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    expect(provider.bookmarkSurah, isNull);
    expect(provider.bookmarkPage, isNull);
  });
}
