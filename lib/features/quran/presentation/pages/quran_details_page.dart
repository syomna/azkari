import 'dart:developer';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:azkar_app/features/quran/presentation/widgets/page_number_card.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_surah.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;

class QuranDetailPage extends StatefulWidget {
  const QuranDetailPage({super.key});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  int _surahNumber = 1;
  double _savedScrollOffset = 0.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    _surahNumber = quranProvider.savedLatestQuranSurahNumber ?? 1;
    if (_surahNumber == 0) {
      _surahNumber = 1;
    }
    _savedScrollOffset =
        quranProvider.getSavedPosition(_surahNumber).scrollOffset;
    _scrollController =
        ScrollController(initialScrollOffset: _savedScrollOffset);
    _scrollController.addListener(() {
      final currentOffset = _scrollController.offset;
      Provider.of<QuranProvider>(context, listen: false)
          .saveQuranPosition(_surahNumber, currentOffset);
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('$_savedScrollOffset || $_surahNumber');
    final verseCount = quran.getVerseCount(_surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(_surahNumber);
    final padding = EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          surahNameArabic,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<QuranProvider>(
            builder: (context, quranProvider, child) {
              return IconButton(
                  onPressed: () {
                    if (quranProvider.savedLatestQuranSurahNumber ==
                        _surahNumber) {
                      quranProvider.saveLatestQuranSurahNumber(1);
                      quranProvider.saveQuranPosition(1, 0.0);
                      AppHelpers.showToast('تم حذف الصفحة',
                          color: Colors.red.shade800);
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      quranProvider.saveLatestQuranSurahNumber(_surahNumber);
                      quranProvider.saveQuranPosition(
                          _surahNumber, _scrollController.offset);

                      AppHelpers.showToast('تم حفظ الصفحة');
                    }
                  },
                  icon: Icon(
                    quranProvider.savedLatestQuranSurahNumber == _surahNumber
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    size: 22.h,
                    color: AppPalette.mainColor,
                  ));
            },
          ),
          Consumer<QuranProvider>(builder: (context, quranProvider, child) {
            return IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => Dialog(
                            child: QuranList(
                                selectedSurahNumber: _surahNumber,
                                onSurahSelected: (surahNumber) {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _surahNumber = surahNumber;
                                    _savedScrollOffset = quranProvider
                                        .getSavedPosition(_surahNumber)
                                        .scrollOffset;
                                  });
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollController.animateTo(
                                      _savedScrollOffset,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }),
                          ));
                },
                icon: Icon(
                  Icons.list,
                  size: 25.h,
                ));
          })
        ],
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/duaa.png'), opacity: 0.08)),
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thickness: 6.w,
                radius: Radius.circular(8.r),
                trackVisibility: true,
                thumbVisibility: true,
                child: Padding(
                  padding: padding,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: verseCount,
                    itemBuilder: (context, index) {
                      final currentPageNumber =
                          quran.getPageNumber(_surahNumber, index + 1);
                      final previousPageNumber = index > 0
                          ? quran.getPageNumber(_surahNumber, index)
                          : 0;
                      final bool isNewPage =
                          currentPageNumber != previousPageNumber;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isNewPage)
                            PageNumberCard(
                                pageNumber: quran.getPageNumber(
                                    _surahNumber, index + 1)),
                          QuranSurah(
                            surahNumber: _surahNumber,
                            index: index,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_surahNumber < 114)
              Consumer<QuranProvider>(builder: (context, quranProvider, child) {
                return Padding(
                  padding: padding,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_surahNumber < 114) {
                          _surahNumber++;
                          _savedScrollOffset = quranProvider
                              .getSavedPosition(_surahNumber)
                              .scrollOffset;
                        }
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController.animateTo(
                          _savedScrollOffset,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                    splashColor: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(quran.getSurahNameArabic(_surahNumber + 1),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_forward_ios)
                        ],
                      ),
                    ),
                  ),
                );
              })
          ],
        ),
      ),
    );
  }
}
