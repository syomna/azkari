import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as quran;

class QuranSurah extends StatefulWidget {
  const QuranSurah({
    super.key,
    required this.surahNumber,
    required this.index,
  });

  final int surahNumber;
  final int index;

  @override
  State<QuranSurah> createState() => _QuranSurahState();
}

class _QuranSurahState extends State<QuranSurah> {
  @override
  Widget build(BuildContext context) {
    final int verseNumber = widget.index + 1;

    // 1. Get the raw verse text
    String ayah =
        quran.getVerse(widget.surahNumber, verseNumber, verseEndSymbol: true);

    // 2. Logic to check if we should show a custom Basmala header
    // (Not for Al-Fatiha [1] or At-Tawbah [9])
    bool isFirstVerse = verseNumber == 1;
    bool shouldShowHeaderBasmala = isFirstVerse && widget.surahNumber != 1;
    if (isFirstVerse && widget.surahNumber != 1) {
      final basmalaRegex = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

      if (ayah.contains(basmalaRegex)) {
        ayah = ayah.replaceFirst(basmalaRegex, '').trim();
      } else {
        ayah = ayah.replaceFirst(quran.basmala, '').trim();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shouldShowHeaderBasmala) ...[
          _buildBasmalaHeader(),
          SizedBox(height: 15.h),
        ],

        // Use Text.rich or just Text with a nice height for readability
        Text(
          ayah,
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppPalette.amiriFontFamily,
            fontSize: 22.sp,
            height: 2.2, // Increased height for better "Othmani" feel
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );
  }

  Widget _buildBasmalaHeader() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Text(
          quran.basmala,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppPalette.amiriFontFamily,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
