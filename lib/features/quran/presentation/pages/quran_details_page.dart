import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_player_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_font_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _generateVirtualPages();

    _provider = Provider.of<QuranProvider>(context, listen: false);
    int savedPage = _provider.savedLatestQuranPageNumber ?? 1;
    if (savedPage < 1) savedPage = 1;
    if (savedPage > 604) savedPage = 604;

    _currentIndex = savedPage - 1;
    _pageController = PageController(initialPage: _currentIndex);
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
    // Stop any playing surah audio before leaving the reader
    _provider.resetAudio();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final int currentSurahNumber = _currentSurah;
    final int currentPageNumber = _currentIndex + 1;

    return Scaffold(
      appBar: _buildAppBar(theme, currentSurahNumber, currentPageNumber),
      bottomNavigationBar: _buildBottomBar(theme),
      body: Stack(
        children: [
          Padding(
            // إفساح مساحة كافية كي لا يغطي كارت الصوت آخر سطر في الصفحة
            padding: EdgeInsets.only(bottom: _isAudioVisible ? 190.h : 0),
            child: quran.QuranPageView(
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              onLongPressStart: (surah, verse, details) {
                HapticFeedback.mediumImpact();
                _showTafseer(surah, verse);
              },
              ayahStyle: TextStyle(
                fontSize: 23.55 * themeProvider.textScaleFactor,
              ),
              pageBackgroundColor: theme.scaffoldBackgroundColor,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _isAudioVisible
                ? AudioPlayerCard(surahNumber: currentSurahNumber)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    int currentSurahNumber,
    int currentPageNumber,
  ) {
    final int firstStart =
        _virtualPages[_currentIndex].surahSegments.first['start'] as int;
    final int juz = quran.getJuzNumber(currentSurahNumber, firstStart);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: const BackButton(),
      title: Text(
        AppConstants.holyQuran,
        style: TextStyle(
          fontFamily: AppPalette.amiriFontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'قائمة السور',
          icon: const Icon(CupertinoIcons.list_bullet),
          onPressed: _showSurahPicker,
        ),
        IconButton(
          tooltip: 'حجم الخط',
          icon: const Icon(Icons.format_size_rounded),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QuranFontSheet(),
            );
          },
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
        preferredSize: Size.fromHeight(34.h),
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
                'سورة ${quran.getSurahNameArabic(currentSurahNumber)} • الجزء ${AppHelpers.getArabicNumber(juz)} • صفحة ${AppHelpers.getArabicNumber(currentPageNumber)}',
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
    final int currentSurahNumber = _currentSurah;
    final int currentPageNumber = _currentIndex + 1;
    final bool isBookmarked = _provider.bookmarkSurah == currentSurahNumber &&
        _provider.bookmarkPage == currentPageNumber;

    return IconButton(
      tooltip: isBookmarked ? 'إزالة الإشارة المرجعية' : 'إضافة إشارة مرجعية',
      icon: Icon(
        isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        color: isBookmarked ? Colors.amber : null,
      ),
      onPressed: () {
        if (isBookmarked) {
          _provider.clearBookmark();
        } else {
          _provider.saveBookmark(
            surahNumber: currentSurahNumber,
            pageNumber: currentPageNumber,
          );
        }
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
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
          height: 54.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBarButton(
                theme: theme,
                icon: CupertinoIcons.forward_end_alt,
                tooltip: 'السورة السابقة',
                enabled: _currentSurah > 1,
                onTap: _goToPreviousSurah,
              ),
              _buildBarButton(
                theme: theme,
                icon: CupertinoIcons.forward_end,
                tooltip: 'الصفحة السابقة',
                enabled: _currentIndex > 0,
                onTap: _goToPreviousPage,
              ),
              _buildPagePill(theme),
              _buildBarButton(
                theme: theme,
                icon: CupertinoIcons.backward_end,
                tooltip: 'الصفحة التالية',
                enabled: _currentIndex < _virtualPages.length - 1,
                onTap: _goToNextPage,
              ),
              _buildBarButton(
                theme: theme,
                icon: CupertinoIcons.backward_end_alt,
                tooltip: 'السورة التالية',
                enabled: _currentSurah < 114,
                onTap: _goToNextSurah,
              ),
            ],
          ),
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

  Widget _buildBarButton({
    required ThemeData theme,
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final Color enabledColor = theme.colorScheme.onSurface;
    final Color disabledColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.25,
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18.r),
          child: SizedBox(
            width: 38.w,
            height: 38.h,
            child: Icon(
              icon,
              size: 20.sp,
              color: enabled ? enabledColor : disabledColor,
            ),
          ),
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

    setState(() => _currentIndex = pageNumber - 1);

    _provider.saveQuranPageNumber(pageNumber);
    _provider.saveLatestQuranSurahNumber(savedSurah);
  }

  void _goToNextPage() {
    if (_currentIndex == _virtualPages.length - 1) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goToPreviousPage() {
    if (_currentIndex == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goToNextSurah() {
    if (_currentSurah >= 114) return;

    _jumpToSurah(_currentSurah + 1, animate: true);
  }

  void _goToPreviousSurah() {
    if (_currentSurah <= 1) return;

    _jumpToSurah(_currentSurah - 1, animate: true);
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
