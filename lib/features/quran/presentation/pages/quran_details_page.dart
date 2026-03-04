import 'dart:async';
import 'dart:ui';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/infinate_download_icon.dart';
import 'package:azkar_app/features/quran/presentation/widgets/page_number_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_font_sheet.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_surah.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranDetailPage extends StatefulWidget {
  const QuranDetailPage({super.key});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  late PageController _pageController;
  int _surahNumber = 1;
  bool _isAudioVisible = false;

  final Map<int, ItemScrollController> _scrollControllers = {};
  final Map<int, ItemPositionsListener> _positionsListeners = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<QuranProvider>(context, listen: false);
    _surahNumber = provider.savedLatestQuranSurahNumber ?? 1;
    _pageController = PageController(initialPage: _surahNumber - 1);
  }

  void _onScrollChanged(int surahNum) {
    if (surahNum != _surahNumber) return;
    if (_debounce?.isActive ?? false) return;

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final listener = _positionsListeners[surahNum];
      if (listener == null) return;

      final positions = listener.itemPositions.value;
      if (positions.isEmpty) return;

      final firstVisible = positions
          .where((pos) => pos.itemLeadingEdge >= 0)
          .fold(positions.first,
              (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b)
          .index;

      final provider = Provider.of<QuranProvider>(context, listen: false);
      provider.saveLatestQuranSurahNumber(surahNum);
      provider.saveQuranPosition(surahNum, firstVisible + 1);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuranProvider>(context);

    if (provider.errorMessage != null) {
      Future.microtask(() {
        AppHelpers.showToast(provider.errorMessage!, status: ToastStatus.error);
        provider
            .clearError(); // Clear it so it doesn't show again on next rebuild
      });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          quran.getSurahNameArabic(_surahNumber),
          style: TextStyle(
              fontFamily: AppPalette.amiriFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 26.sp),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded,
                color: AppPalette.mainColor),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) =>
                    const QuranFontSheet(), // A simple slider to update your font provider
              );
            },
          ),
          IconButton(
            onPressed: () => setState(() => _isAudioVisible = !_isAudioVisible),
            icon: Icon(
              CupertinoIcons.headphones,
              size: 22.h,
              color: _isAudioVisible ? AppPalette.mainColor : null,
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.list_bullet, size: 22.h),
            onPressed: () => _showSurahPicker(context),
          ),
        ],
      ),
      body: InkWell(
        onTap: () => setState(() => _isAudioVisible = !_isAudioVisible),
        splashColor: Colors.transparent,
        child: Stack(
          children: [
            Column(
              children: [
                LinearProgressIndicator(
                  value: _surahNumber / 114,
                  backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
                  color: AppPalette.mainColor,
                  minHeight: 2.h,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 114,
                    onPageChanged: (index) {
                      provider.resetAudio();

                      setState(() => _surahNumber = index + 1);
                      context
                          .read<QuranProvider>()
                          .saveLatestQuranSurahNumber(_surahNumber);
                      context
                          .read<QuranProvider>()
                          .saveQuranPosition(_surahNumber, 1);
                    },
                    itemBuilder: (context, index) =>
                        _buildSurahPage(index + 1, provider),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 1.2), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastLinearToSlowEaseIn)),
                  child: child,
                ),
                child: _isAudioVisible
                    ? _buildAudioPlayer(context, provider)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahPage(int surahNum, QuranProvider provider) {
    final verseCount = quran.getVerseCount(surahNum);
    final initialAyah = provider.getSavedPosition(surahNum).ayahNumber;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollChanged(surahNum);
          return false;
        },
        child: ScrollablePositionedList.builder(
          key: PageStorageKey('surah_$surahNum'),
          itemCount: verseCount,
          itemScrollController: _scrollControllers[surahNum] ??=
              ItemScrollController(),
          itemPositionsListener: _positionsListeners[surahNum] ??=
              ItemPositionsListener.create(),
          initialScrollIndex: initialAyah - 1,
          itemBuilder: (context, index) {
            final currentPageNum = quran.getPageNumber(surahNum, index + 1);
            final previousPageNum =
                index > 0 ? quran.getPageNumber(surahNum, index) : 0;

            return Column(
              children: [
                if (currentPageNum != previousPageNum)
                  PageNumberCard(
                      pageNumber: currentPageNum,
                      juz: quran.getJuzNumber(surahNum, index + 1)),
                QuranSurah(surahNumber: surahNum, index: index),
                // Padding at the end so the player doesn't cover the last verse
                if (index == verseCount - 1)
                  SizedBox(height: _isAudioVisible ? 180.h : 40.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context, QuranProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String url = quran.getAudioURLBySurah(_surahNumber);

    return Container(
      key: const ValueKey('floating_audio_player'),
      height: 155.h,
      margin: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.all(15.h),
            child: Column(
              children: [
                _buildAudioSlider(provider),
                _buildAudioControls(provider, url, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioSlider(QuranProvider provider) {
    return StreamBuilder<Duration?>(
      stream: provider.positionStream,
      builder: (context, snapshot) {
        final bool isSameSurah = provider.currentPlayingSurah == _surahNumber;
        final position =
            isSameSurah ? (snapshot.data ?? Duration.zero) : Duration.zero;
        final duration = isSameSurah
            ? (provider.player.duration ?? Duration.zero)
            : Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                activeTrackColor: AppPalette.mainColor,
                inactiveTrackColor: AppPalette.mainColor.withValues(alpha: 0.2),
                thumbColor: AppPalette.mainColor,
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble() > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: isSameSurah
                    ? (v) => provider.seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  Text(_formatDuration(duration),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioControls(QuranProvider provider, String url, bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => provider.toggleAudio(_surahNumber, url),
          child: Container(
            width: 50.h,
            height: 50.h,
            decoration: const BoxDecoration(
                color: AppPalette.mainColor, shape: BoxShape.circle),
            child: (provider.isDownloading &&
                    provider.currentPlayingSurah == _surahNumber)
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(
                    (provider.isActuallyPlaying &&
                            provider.currentPlayingSurah == _surahNumber)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30.h),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سورة ${quran.getSurahNameArabic(_surahNumber)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppPalette.mainColor)),
              Text(
                provider.isDownloading
                    ? 'جاري التحميل...'
                    : 'اضغط للاستماع للقارئ',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        FutureBuilder<bool>(
          future: provider.checkSurahDownloadedUseCase(_surahNumber),
          builder: (context, snapshot) {
            if (provider.isDownloading) {
              return const InfiniteDownloadIcon();
            }
            return Icon(
              (snapshot.data ?? false)
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.cloud_download,
              color: (snapshot.data ?? false)
                  ? AppPalette.mainColor
                  : Colors.grey.withValues(alpha: 0.5),
            );
          },
        ),
      ],
    );
  }

  void _showSurahPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more screen space
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Opens at 90% height
        minChildSize: 0.5, // Can be dragged down to 50%
        maxChildSize: 0.95, // Can be dragged up to 95%
        builder: (context, scrollController) {
          // Pass the scrollController to your QuranList to sync scrolling
          return QuranList(
            selectedSurahNumber: _surahNumber,
            onSurahSelected: (int surahNum) {
              Navigator.pop(context);
              context
                  .read<QuranProvider>()
                  .saveLatestQuranSurahNumber(surahNum);
              context.read<QuranProvider>().saveQuranPosition(surahNum, 1);
              _pageController.jumpToPage(surahNum - 1);
            },
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
