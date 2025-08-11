import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int verseNumber = 1;
  bool showBasmala = false;

  @override
  void initState() {
    verseNumber = widget.index + 1;
    showBasmala = (widget.surahNumber != 1 &&
        widget.surahNumber != 9 &&
        verseNumber == 1);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBasmala)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                quran.basmala,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Text(
          quran.getVerse(widget.surahNumber, verseNumber, verseEndSymbol: true),
          style: GoogleFonts.amiriQuran(fontSize: 20.sp),
        )
      ],
    );
  }
}
