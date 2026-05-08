import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_player_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_font_sheet.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;

class QuranDetailPage extends StatefulWidget {
  const QuranDetailPage({super.key});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  late PageController _pageController;
  int _currentPageNumber = 1;
  bool _isAudioVisible = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<QuranProvider>(context, listen: false);
    _currentPageNumber = provider.savedLatestQuranPageNumber ?? 1;
    _pageController = PageController(initialPage: _currentPageNumber - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuranProvider>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    int surahNumber = quran.getPageData(_currentPageNumber).first['surah'];

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
                if (_showControls)
                  SizedBox(
                    height: 70.h,
                  ),
                LinearProgressIndicator(
                  value: _currentPageNumber / 604,
                  backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
                  color: AppPalette.mainColor,
                  minHeight: 2.h,
                ),
                SizedBox(height: 10.h),
                _buildInfoRow(isDark),
                SizedBox(height: 10.h),
                _buildSurahNameCard(context, surahNumber),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 604,
                    onPageChanged: (index) {
                      provider.resetAudio();
                      int newPage = index + 1;
                      setState(() => _currentPageNumber = newPage);
                      provider.saveQuranPageNumber(newPage);
                      int currentSurah =
                          quran.getPageData(newPage).first['surah'];
                      provider.saveLatestQuranSurahNumber(currentSurah);
                    },
                    itemBuilder: (context, index) =>
                        _buildPageContent(index + 1),
                  ),
                ),
              ],
            ),

            // 2. الرأس العائم (Top Floating Header)
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
              child: _buildBottomControls(context, provider, surahNumber),
            ),

            // 4. كرت المشغل الصوتي
            Align(
              alignment: Alignment.bottomCenter,
              child: _isAudioVisible
                  ? AudioPlayerCard(surahNumber: surahNumber)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
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
          Text(
            AppConstants.holyQuran,
            style: TextStyle(
              fontFamily: AppPalette.amiriFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, QuranProvider provider, int surahNumber) {
    return Container(
      height: 65.h,
      decoration: BoxDecoration(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(35.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -2))
        ],
        border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlIcon(
              icon: Icons.format_size_rounded,
              onTap: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) => const QuranFontSheet(),
                );
              }),
          _buildControlIcon(
            icon: provider.savedLatestQuranSurahNumber == surahNumber
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            color: Colors.amber,
            onTap: () {
              if (provider.savedLatestQuranSurahNumber == surahNumber) {
                provider.saveLatestQuranSurahNumber(1);
                provider.saveQuranPageNumber(1);
              } else {
                provider.saveLatestQuranSurahNumber(surahNumber);
                provider.saveQuranPageNumber(_currentPageNumber);
              }
            },
          ),
          _buildControlIcon(
            icon: CupertinoIcons.headphones,
            color: _isAudioVisible ? AppPalette.mainColor : null,
            onTap: () => setState(() {
              _isAudioVisible = !_isAudioVisible;
              _showControls = false;
            }),
          ),
          _buildControlIcon(
            icon: CupertinoIcons.list_bullet,
            onTap: () => _showSurahPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon(
      {required IconData icon, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Icon(icon, size: 22.h, color: color),
      ),
    );
  }

  Widget _buildSurahNameCard(BuildContext context, int surahNumber) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color contentColor = isDark ? Colors.white : AppPalette.mainColor;

    int totalAyahs = quran.getVerseCount(surahNumber);
    String surahOrder = AppHelpers.getArabicNumber(surahNumber);
    String ayahsCount = AppHelpers.getArabicNumber(totalAyahs);

    return SizedBox(
      height: 40.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/surah_border.svg',
            width: MediaQuery.of(context).size.width * 0.95,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
          ),
          Positioned(
            left: 74.w,
            child: Text(
              'ترتيبها\n$surahOrder',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppPalette.amiriFontFamily,
                fontSize: 7.sp,
                fontWeight: FontWeight.bold,
                color: contentColor,
                height: 1.1,
              ),
            ),
          ),
          Text(
            quran.getSurahNameArabic(surahNumber),
            style: TextStyle(
              fontFamily: AppPalette.amiriFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: contentColor,
            ),
          ),
          Positioned(
            right: 74.w,
            child: Text(
              'آياتها\n$ayahsCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppPalette.amiriFontFamily,
                fontSize: 7.sp,
                fontWeight: FontWeight.bold,
                color: contentColor,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark) {
    List<Map<String, dynamic>> pageData =
        quran.getPageData(_currentPageNumber).cast<Map<String, dynamic>>();
    int juz =
        quran.getJuzNumber(pageData.first['surah'], pageData.first['start']);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الجزء ${AppHelpers.getArabicNumber(juz)}',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppPalette.mainColor,
                  fontWeight: FontWeight.w600)),
          Text('صفحة ${AppHelpers.getArabicNumber(_currentPageNumber)}',
              style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPageContent(int pageNum) {
    List<Map<String, dynamic>> pageData =
        quran.getPageData(pageNum).cast<Map<String, dynamic>>();
    bool hasNewSurah =
        pageData.any((data) => data['start'] == 1 && data['surah'] != 9);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          if (hasNewSurah) ...[
            SizedBox(height: 10.h),
            _buildBasmalaHeader(),
          ],
          SizedBox(height: 10.h),
          Text.rich(
            TextSpan(children: _buildVersesList(pageData)),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
          if (_isAudioVisible) SizedBox(height: 200.h),
          if (_showControls) SizedBox(height: 100.h),
        ],
      ),
    );
  }

  List<InlineSpan> _buildVersesList(List<Map<String, dynamic>> pageData) {
    List<InlineSpan> spans = [];
    for (var surahData in pageData) {
      int surahNum = surahData['surah'];
      int start = surahData['start'];
      int end = surahData['end'];
      for (int vNum = start; vNum <= end; vNum++) {
        spans.add(buildVerseSpan(surahNumber: surahNum, index: vNum - 1));
      }
    }
    return spans;
  }

  TextSpan buildVerseSpan({required int surahNumber, required int index}) {
    final int verseNumber = index + 1;
    String ayah =
        quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true);

    if (verseNumber == 1 && surahNumber != 9) {
      const basmalaRegex = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
      if (ayah.contains(basmalaRegex)) {
        ayah = ayah.replaceFirst(basmalaRegex, '').trim();
      } else {
        ayah = ayah.replaceFirst(quran.basmala, '').trim();
      }
    }

    return TextSpan(
      text: '$ayah ',
      style: TextStyle(
        fontFamily: AppPalette.amiriFontFamily,
        fontSize: 22.sp,
        height: 2.2,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  Widget _buildBasmalaHeader() {
    return Text(
      quran.basmala,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontFamily: AppPalette.amiriFontFamily,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold),
    );
  }

  void _showSurahPicker(BuildContext context) {
    showModalBottomSheet(
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
            selectedSurahNumber:
                quran.getPageData(_currentPageNumber).first['surah'],
            onSurahSelected: (int surahNum) {
              Navigator.pop(context);
              int firstPageOfSurah = quran.getPageNumber(surahNum, 1);
              _pageController.jumpToPage(firstPageOfSurah - 1);
            },
          );
        },
      ),
    );
  }
}
