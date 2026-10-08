import 'dart:async';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_player_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:azkar_app/features/quran/presentation/widgets/tafseer_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart' as quran;

// وصف صفحة المصحف الواحدة: رقمها (1-604) مع شرائح السور التي تبدأ عليها
class QuranPageItem {
  final int globalPageNumber; // رقم الصفحة الأصلي بالمصحف (1-604)
  final List<Map<String, dynamic>>
      surahSegments; // السور والآيات الموجودة على هذه الصفحة

  QuranPageItem({
    required this.globalPageNumber,
    required this.surahSegments,
  });
}

class QuranDetailPage extends StatefulWidget {
  const QuranDetailPage({super.key});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  late PageController _pageController;
  final List<QuranPageItem> _virtualPages = [];
  int _currentIndex = 0;
  bool _isAudioVisible = false;
  late QuranProvider _provider;

  // الآية المختارة: تُمتلئ بالضغط المطوّل عليها، ويُظلَّل معناها في المصحف
  // طوال فترة فتح تفسيرها حتى يتضح أي آية يشير إليه النص المعروض.
  int? _selectedAyahSurah;
  int? _selectedAyahVerse;

  // التفسير يُفتح بالضغط المطوّل على الآية (وليس بالنقر) حتى لا تعترض
  // القراءة نقرة عارضة. نعرض تلميحاً صغيراً مرة واحدة فقط (محفوظ في
  // الإعدادات) ثم نخفيه بنقرة عليه أو بعد ثوانٍ معدودة حتى لا يعيق القراءة.
  static const String _tafseerHintSeenKey = 'quran_tafseer_hint_seen';
  bool _showTafseerHint = false;
  Timer? _tafseerHintTimer;

  @override
  void initState() {
    super.initState();
    _generateVirtualPages();
    _provider = Provider.of<QuranProvider>(context, listen: false);

    // الإشارة المرجعية (أيقونة الـ bookmark) لها الأولوية عند الفتح: إن وُجدت
    // نبدأ من صفحتها، وإلا نرجع لآخر صفحة قُرئت تلقائياً. قيمة خارج حدود
    // المصحف (1..604) تُعتبر تالفة وتُتجاهل.
    final int? bookmarkPage = _provider.bookmarkPage;
    final bool bookmarkIsValid =
        bookmarkPage != null && bookmarkPage >= 1 && bookmarkPage <= 604;
    int savedPage = (bookmarkIsValid ? bookmarkPage : null) ??
        _provider.savedLatestQuranPageNumber ??
        1;
    if (savedPage < 1) savedPage = 1;
    if (savedPage > 604) savedPage = 604;

    _currentIndex = savedPage - 1;
    _pageController = PageController(initialPage: _currentIndex);
    _maybeShowTafseerHint();
  }

  // التلميح لا يُعرض إلا مرة واحدة أبداً، ثم يُحفظ في الإعدادات.
  Future<void> _maybeShowTafseerHint() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool seen = preferences.getBool(_tafseerHintSeenKey) ?? false;
    if (seen) return;
    setState(() => _showTafseerHint = true);
    _tafseerHintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showTafseerHint = false);
    });
  }

  Future<void> _dismissTafseerHint() async {
    if (_showTafseerHint) {
      (await SharedPreferences.getInstance())
          .setBool(_tafseerHintSeenKey, true);
    }
    _tafseerHintTimer?.cancel();
    if (mounted) setState(() => _showTafseerHint = false);
  }

  // صفحة مصحف واحدة لكل entry (1..604)، بدون تقسيم صفحات افتراضية لأن
  // QuranPageView يعرض الصفحة كاملة كما في المصحف المطبوع.
  void _generateVirtualPages() {
    _virtualPages.clear();
    for (int p = 1; p <= 604; p++) {
      _virtualPages.add(QuranPageItem(
        globalPageNumber: p,
        surahSegments: quran.getPageData(p).cast<Map<String, dynamic>>(),
      ));
    }
  }

  @override
  void dispose() {
    _tafseerHintTimer?.cancel();
    // Stop any playing surah audio before leaving the reader
    _provider.resetAudio();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int currentSurahNumber = _currentSurah;
    final int currentPageNumber = _currentIndex + 1;

    return Scaffold(
      appBar: _buildAppBar(theme, currentSurahNumber, currentPageNumber),
      bottomNavigationBar: _buildBottomBar(theme),
      body: Stack(
        children: [
          // مشغل الصوت يطفو فوق الصفحة كـ overlay ولا يزاحم نص المصحف:
          // لا يتم حجز مساحة أسفل الصفحة عند ظهوره.
          quran.QuranPageView(
            pageController: _pageController,
            onPageChanged: _onPageChanged,
            highlights: _highlightedVerses,
            highlightBorderRadius: BorderRadius.circular(6.r),
            onLongPressStart: (surah, verse, details) {
              HapticFeedback.mediumImpact();
              _openTafseer(surah, verse);
            },
            ayahStyle: const TextStyle(fontSize: 23.55),
            pageBackgroundColor: theme.scaffoldBackgroundColor,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showTafseerHint
                ? _buildTafseerHint(theme)
                : const SizedBox.shrink(),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isAudioVisible
                ? Align(
                    key: const ValueKey('audio_overlay'),
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: AudioPlayerCard(
                        surahNumber: currentSurahNumber,
                        onClose: () => setState(() => _isAudioVisible = false),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTafseerHint(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: _dismissTafseerHint,
              child: Container(
                padding: EdgeInsets.fromLTRB(10.w, 2.h, 2.w, 2.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppPalette.quranPageDark
                      : AppPalette.quranPageLight,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppPalette.mainColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.lightbulb_fill,
                      size: 13,
                      color: AppPalette.mainColor,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'اضغط مطولاً على أي آية لعرض تفسيرها، من التفسير الميسّر',
                        style: TextStyle(
                          fontFamily: AppPalette.amiriFontFamily,
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      onPressed: _dismissTafseerHint,
                      tooltip: 'إغلاق',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        CupertinoIcons.xmark,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    int currentSurahNumber,
    int currentPageNumber,
  ) {
    final List<Map<String, dynamic>> segments =
        _virtualPages[_currentIndex].surahSegments;
    final int firstStart =
        segments.isEmpty ? 1 : segments.first['start'] as int;
    final int juz = quran.getJuzNumber(currentSurahNumber, firstStart);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: const BackButton(),
      title: Text(
        'سورة ${quran.getSurahNameArabic(currentSurahNumber)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppPalette.amiriFontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'قائمة السور',
          icon: const Icon(CupertinoIcons.list_bullet),
          onPressed: _showSurahPicker,
        ),
        _buildBookmarkButton(),
        IconButton(
          tooltip: 'الاستماع',
          icon: Icon(
            CupertinoIcons.headphones,
            color: _isAudioVisible ? AppPalette.mainColor : null,
          ),
          onPressed: () {
            setState(() => _isAudioVisible = !_isAudioVisible);
          },
        ),
        SizedBox(width: 4.w),
      ],
      bottom: PreferredSize(
        // PreferredSize height ثابت، لكن سطر «الجزء • صفحة» يرسم بخط .sp
        // فينمو مع تكبير الخط أكثر مما ينمو الارتفاع المحجوز، فتجاوزه سطر
        // واحد (١٤px على اللوحي عند ×٢). نضرب الارتفاع في معامل تكبير الخط
        // فيكبر معه؛ ومعامل ١ يبقى الارتفاع كما هو تماماً.
        preferredSize: Size.fromHeight(
          34.h * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _virtualPages.length > 1
                  ? _currentIndex / (_virtualPages.length - 1)
                  : 0,
              backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
              color: AppPalette.mainColor,
              minHeight: 2.h,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
              child: Text(
                'الجزء ${AppHelpers.getArabicNumber(juz)} • صفحة ${AppHelpers.getArabicNumber(currentPageNumber)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontSize: 12.sp,
                  color: AppPalette.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final int currentSurahNumber = _currentSurah;
        final int currentPageNumber = _currentIndex + 1;
        final bool isBookmarked =
            provider.bookmarkSurah == currentSurahNumber &&
                provider.bookmarkPage == currentPageNumber;

        return IconButton(
          tooltip:
              isBookmarked ? 'إزالة الإشارة المرجعية' : 'إضافة إشارة مرجعية',
          icon: Icon(
            isBookmarked
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            color: isBookmarked ? Colors.amber : null,
          ),
          onPressed: () {
            if (isBookmarked) {
              provider.clearBookmark();
            } else {
              provider.saveBookmark(
                surahNumber: currentSurahNumber,
                pageNumber: currentPageNumber,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    // شريط سفلي ضئيل: مؤشر الصفحة فقط. التقليب يتم بالتمرير الأفقي والتسور
    // من قائمة السور في الـ AppBar.
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 44.h,
          width: double.infinity,
          child: Center(child: _buildPagePill(theme)),
        ),
      ),
    );
  }

  Widget _buildPagePill(ThemeData theme) {
    final int currentPage = _currentIndex + 1;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppPalette.mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppPalette.mainColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '${AppHelpers.getArabicNumber(currentPage)} / ٦٠٤',
        style: TextStyle(
          fontFamily: AppPalette.amiriFontFamily,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: AppPalette.mainColor,
        ),
      ),
    );
  }

  // السورة المقصودة في الصفحة الحالية (أول سورة تظهر أعلى الصفحة)
  int get _currentSurah {
    final segments = _virtualPages[_currentIndex].surahSegments;
    if (segments.isEmpty) return 1;
    return segments.first['surah'];
  }

  void _onPageChanged(int pageNumber) {
    final segments = quran.getPageData(pageNumber).cast<Map<String, dynamic>>();
    final int savedSurah =
        segments.isEmpty ? 1 : segments.first['surah'] as int;
    final int prevSurah = _currentSurah;

    if (savedSurah != prevSurah) {
      _provider.resetAudio();
    }

    setState(() {
      _currentIndex = pageNumber - 1;
      // التظليل يخص صفحة واحدة: نتخلّص منه عند الانتقال حتى لا يبقى أثر آية
      // مختارة على صفحة لم تعد معروضة.
      _selectedAyahSurah = null;
      _selectedAyahVerse = null;
    });

    _provider.saveQuranPageNumber(pageNumber);
    _provider.saveLatestQuranSurahNumber(savedSurah);
  }

  void _jumpToSurah(int surahNumber, {bool animate = false}) {
    final int firstPageOfSurah = quran.getPageNumber(surahNumber, 1);
    if (animate) {
      _pageController.animateToPage(
        firstPageOfSurah - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(firstPageOfSurah - 1);
    }
  }

  void _showSurahPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return QuranList(
            selectedSurahNumber: _currentSurah,
            onSurahSelected: (int surahNum) {
              Navigator.pop(context);
              _jumpToSurah(surahNum);
            },
          );
        },
      ),
    );
  }

  /// الآية المظلَّلة حالياً، إن وُجدت. الحزمة تطابق التظليل بالسورة ورقم
  /// الآية فقط، فرقم الصفحة في [quran.HighlightVerse] بيانات وصفية.
  List<quran.HighlightVerse> get _highlightedVerses {
    final int? surah = _selectedAyahSurah;
    final int? verse = _selectedAyahVerse;
    if (surah == null || verse == null) return const [];
    return <quran.HighlightVerse>[
      quran.HighlightVerse(
        surah: surah,
        verseNumber: verse,
        page: _currentIndex + 1,
        color: AppPalette.mainColor,
      ),
    ];
  }

  /// ضغط مطوّل على آية: نظلّلها ثم نفتح تفسيرها، ونزيل التظليل بانتظار الورقة.
  /// إذا فتح المستخدم تفسيراً آخر قبل إغلاق الأول، نحتفظ بتظليل الجديد:
  /// المقارنة تمنع إغلاق الورقة الأولى من مسح تظليل الثانية.
  Future<void> _openTafseer(int surahNumber, int verseNumber) async {
    setState(() {
      _selectedAyahSurah = surahNumber;
      _selectedAyahVerse = verseNumber;
    });

    await _showTafseer(surahNumber, verseNumber);

    if (!mounted) return;
    if (_selectedAyahSurah == surahNumber &&
        _selectedAyahVerse == verseNumber) {
      setState(() {
        _selectedAyahSurah = null;
        _selectedAyahVerse = null;
      });
    }
  }

  Future<void> _showTafseer(int surahNumber, int verseNumber) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TafseerSheet(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      ),
    );
  }
}
