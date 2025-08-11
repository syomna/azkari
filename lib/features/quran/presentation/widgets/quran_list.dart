import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';

class QuranList extends StatefulWidget {
  const QuranList(
      {super.key,
      required this.selectedSurahNumber,
      required this.onSurahSelected});

  final int selectedSurahNumber;
  final Function(int) onSurahSelected;

  @override
  State<QuranList> createState() => _QuranListState();
}

class _QuranListState extends State<QuranList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedSurah = widget.selectedSurahNumber;

      final selectedIndex = selectedSurah - 1;
      const double itemHeight = 60.0;
      final double offset = selectedIndex * itemHeight;

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close,
              size: 25.h,
              color: Colors.red,
            )),
        centerTitle: true,
      ),
      body: Scrollbar(
        controller: _scrollController,
        thickness: 6.w,
        radius: Radius.circular(8.r),
        trackVisibility: true,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          itemCount: 114,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final surahNumber = index + 1;
            return ListTile(
              selected: surahNumber == widget.selectedSurahNumber,
              selectedTileColor: AppPalette.mainColor,
              selectedColor: Colors.white,
              title: Text(
                quran.getSurahNameArabic(surahNumber),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18.sp),
              ),
              subtitle: Text(
                '${_getArabicPlaceOfRevelation(surahNumber)} - ${quran.getVerseCount(surahNumber)} آية',
                textAlign: TextAlign.right,
              ),
              trailing: Text(
                '$surahNumber',
                style: GoogleFonts.amiri(fontSize: 16.sp),
              ),
              onTap: () {
                widget.onSurahSelected(surahNumber);
              },
            );
          },
        ),
      ),
    );
  }

  String _getArabicPlaceOfRevelation(int surahNumber) {
    String place = quran.getPlaceOfRevelation(surahNumber);
    if (place == 'Makkah') {
      return 'مكية';
    } else if (place == 'Madinah') {
      return 'مدنية';
    }
    return '';
  }
}
