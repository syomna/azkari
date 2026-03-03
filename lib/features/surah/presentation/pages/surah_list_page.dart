import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SurahEntity> _currentDisplayedSurahs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterSurahs(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);
    List<SurahEntity> baseList = surahProvider.surahList;

    setState(() {
      if (query.isEmpty) {
        _currentDisplayedSurahs = baseList;
      } else {
        _currentDisplayedSurahs = baseList
            .where((surah) =>
                surah.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          AppConstants.surahs,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SearchBarWidget(
                onChanged: _filterSurahs,
                onClear: () {
                  _searchController.clear();
                  _filterSurahs('');
                },
                searchController: _searchController,
                hint: 'ابحث عن سورة'),
          ),

          // 2. Modern Instruction Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                    color: AppPalette.mainColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.copy_rounded,
                      color: AppPalette.mainColor, size: 20.h),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'لنسخ أي سورة، قم بالضغط المطول عليها.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Surah List
          Expanded(
            child: _currentDisplayedSurahs.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    thickness: 4.w,
                    radius: Radius.circular(10.r),
                    child: ListView.separated(
                        padding: EdgeInsets.only(bottom: 24.h, top: 10.h),
                        itemCount: _currentDisplayedSurahs.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final surah = _currentDisplayedSurahs[index];
                          return _buildSurahCard(surah, isDark);
                        }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(SurahEntity surah, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Category Header (Surah Name)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppPalette.mainColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15.r),
                topLeft: Radius.circular(15.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(15.r),
              ),
            ),
            child: Text(
              surah.name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Surah Text Card
          GestureDetector(
            onLongPress: () => AppHelpers.copyText(surah.surah),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                surah.surah,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 60.h, color: Colors.grey),
          SizedBox(height: 10.h),
          Text(
            'غير موجود',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
