import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_player_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/bottom_navigation_controls.dart';
import 'package:azkar_app/features/quran/presentation/widgets/side_tools.dart';
import 'package:azkar_app/features/quran/presentation/widgets/tafseer_sheet.dart';
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
  bool _showControls = true;
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final currentSurahNumber = _currentSurah;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
            _isAudioVisible = false;
          });
        },
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                if (_showControls) SizedBox(height: 70.h),
                LinearProgressIndicator(
                  value: _virtualPages.length > 1
                      ? _currentIndex / (_virtualPages.length - 1)
                      : 0,
                  backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
                  color: AppPalette.mainColor,
                  minHeight: 2.h,
                ),
                SizedBox(height: 10.h),
                _buildInfoRow(isDark, _virtualPages[_currentIndex]),
                SizedBox(height: 10.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          _showControls ? 110.h : (_isAudioVisible ? 210.h : 0),
                    ),
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
                      pageBackgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showControls ? 0 : -120.h,
              left: 0,
              right: 0,
              child: _buildFloatingHeader(context),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showControls ? 25.h : -100.h,
              left: 20.w,
              right: 20.w,
              child: BottomNavigationControls(
                currentIndex: _currentIndex,
                virtualPages: _virtualPages,
                onPreviousPage: _goToPreviousPage,
                onNextPage: _goToNextPage,
                onPreviousSurah: _goToPreviousSurah,
                onNextSurah: _goToNextSurah,
              ),
            ),
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              start: _showControls ? 14.w : -90.w,
              top: MediaQuery.sizeOf(context).height * 0.34,
              child: SideTools(
                isAudioVisible: _isAudioVisible,
                onAudioToggle: () {
                  setState(() {
                    _isAudioVisible = !_isAudioVisible;

                    if (_isAudioVisible) {
                      _showControls = false;
                    }
                  });
                },
                selectedSurahNumber: _currentSurah,
                onSurahSelected: (int surahNum) {
                  Navigator.pop(context);
                  int firstPageOfSurah = quran.getPageNumber(surahNum, 1);

                  _pageController.jumpToPage(firstPageOfSurah - 1);
                },
                targetPage: _virtualPages[_currentIndex],
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

  Widget _buildFloatingHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        bottom: 15.h,
        left: 15.w,
        right: 15.w,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BackButton(),
          Expanded(
            child: Center(
              child: Text(
                AppConstants.holyQuran,
                style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40.w,
          )
        ],
      ),
    );
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

    final int targetPage = quran.getPageNumber(_currentSurah + 1, 1);

    _pageController.animateToPage(
      targetPage - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _goToPreviousSurah() {
    if (_currentSurah <= 1) return;

    final int previousSurah = _currentSurah - 1;
    final int targetPage = quran.getPageNumber(previousSurah, 1);

    _pageController.animateToPage(
      targetPage - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
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

  Widget _buildInfoRow(bool isDark, QuranPageItem pageItem) {
    int firstSurahInPage = pageItem.surahSegments.first['surah'];
    int firstStart = pageItem.surahSegments.first['start'];
    int juz = quran.getJuzNumber(firstSurahInPage, firstStart);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'سورة ${quran.getSurahNameArabic(firstSurahInPage)}',
            style: TextStyle(
                fontSize: 13.sp,
                color: AppPalette.mainColor,
                fontFamily: AppPalette.amiriFontFamily,
                fontWeight: FontWeight.bold),
          ),
          Text(
            'الجزء ${AppHelpers.getArabicNumber(juz)} • صفحة ${AppHelpers.getArabicNumber(pageItem.globalPageNumber)}',
            style: TextStyle(
                fontFamily: AppPalette.amiriFontFamily,
                fontSize: 12.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
