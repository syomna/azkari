import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as quran;

class QuranList extends StatefulWidget {
  const QuranList({
    super.key,
    required this.selectedSurahNumber,
    required this.onSurahSelected,
  });

  final int selectedSurahNumber;
  final Function(int) onSurahSelected;

  @override
  State<QuranList> createState() => _QuranListState();
}

class _QuranListState extends State<QuranList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final double itemHeight = 73.h;
      final int index = widget.selectedSurahNumber - 1;
      double targetOffset = index * itemHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (targetOffset > maxScroll) targetOffset = maxScroll;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic, // Smoother curve
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter list based on search
    final List<int> filteredIndices = List.generate(114, (i) => i + 1)
        .where((n) => quran.getSurahNameArabic(n).contains(_searchQuery))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        children: [
          // 1. Elegant Header with Handle
          Container(
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
            child: Column(
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'فهرس السور',
                  style: TextStyle(
                    fontFamily: AppPalette.amiriFontFamily,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.mainColor,
                  ),
                ),
              ],
            ),
          ),

          // 2. Modern Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppPalette.mainColor),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 15.h),

          // 3. The List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              itemCount: filteredIndices.length,
              itemBuilder: (context, index) {
                final surahNumber = filteredIndices[index];
                final isSelected = surahNumber == widget.selectedSurahNumber;

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    onTap: () => widget.onSurahSelected(surahNumber),
                    borderRadius: BorderRadius.circular(15.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.mainColor.withValues(alpha: 0.1)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isSelected
                              ? AppPalette.mainColor
                              : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          // Left Side: Number Circle
                          Container(
                            width: 40.h,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppPalette.mainColor
                                  : AppPalette.mainColor
                                      .withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                AppHelpers.getArabicNumber(surahNumber),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppPalette.mainColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),

                          // Center: Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الجزء ${AppHelpers.getArabicNumber(quran.getJuzNumber(surahNumber, 1))}',
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                                Text(
                                  '${quran.getPlaceOfRevelation(surahNumber) == 'Makkah' ? 'مكية' : 'مدنية'} • ${AppHelpers.getArabicNumber(quran.getVerseCount(surahNumber))} آية',
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          // Right Side: Surah Name
                          Text(
                            quran.getSurahNameArabic(surahNumber),
                            style: TextStyle(
                              fontFamily: AppPalette.amiriFontFamily,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppPalette.mainColor : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
