import 'dart:async';
import 'dart:developer';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/page_number_card.dart';
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
  int _surahNumber = 1;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<QuranProvider>(context, listen: false);

    _surahNumber = provider.savedLatestQuranSurahNumber ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePosition();
    });

    _itemPositionsListener.itemPositions.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    if (_debounce?.isActive ?? false) return;

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final positions = _itemPositionsListener.itemPositions.value;

      if (positions.isEmpty) return;

      final firstVisible = positions
          .where((pos) => pos.itemLeadingEdge >= 0)
          .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b)
          .index;

      Provider.of<QuranProvider>(context, listen: false).saveQuranPosition(
        _surahNumber,
        firstVisible + 1,
      );
    });
  }

  void _restorePosition() {
    final provider = Provider.of<QuranProvider>(context, listen: false);

    final saved = provider.getSavedPosition(_surahNumber);

    _itemScrollController.jumpTo(
      index: saved.ayahNumber - 1,
    );
  }

  void _changeSurah(int surah) {
    setState(() {
      _surahNumber = surah;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePosition();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('Surah: $_surahNumber');

    final verseCount = quran.getVerseCount(_surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(_surahNumber);

    final padding = EdgeInsets.only(
      top: 10.h,
      left: 20.w,
      right: 20.w,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          surahNameArabic,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<QuranProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: () {
                  provider.saveLatestQuranSurahNumber(_surahNumber);

                  final positions = _itemPositionsListener.itemPositions.value;

                  if (positions.isNotEmpty) {
                    final firstVisible = positions
                        .where((pos) => pos.itemLeadingEdge >= 0)
                        .reduce((a, b) =>
                            a.itemLeadingEdge < b.itemLeadingEdge ? a : b)
                        .index;

                    provider.saveQuranPosition(_surahNumber, firstVisible + 1);
                  }

                  AppHelpers.showToast('تم حفظ الصفحة');
                },
                icon: Icon(
                  provider.savedLatestQuranSurahNumber == _surahNumber
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  size: 22.h,
                  color: AppPalette.mainColor,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.list_bullet, size: 25.h),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: QuranList(
                    selectedSurahNumber: _surahNumber,
                    onSurahSelected: (surahNumber) {
                      Navigator.pop(context);
                      _changeSurah(surahNumber);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/duaa.png'),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemCount: verseCount,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemBuilder: (context, index) {
                    final currentPageNumber =
                        quran.getPageNumber(_surahNumber, index + 1);

                    final previousPageNumber = index > 0
                        ? quran.getPageNumber(_surahNumber, index)
                        : 0;

                    final isNewPage = currentPageNumber != previousPageNumber;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNewPage)
                          PageNumberCard(pageNumber: currentPageNumber),
                        QuranSurah(
                          surahNumber: _surahNumber,
                          index: index,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_surahNumber + 1 <= 114)
                InkWell(
                  onTap: () => _changeSurah(_surahNumber + 1),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.mainColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5.w,
                        children: [
                          Text(
                            quran.getSurahNameArabic(_surahNumber + 1),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16.h),
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
