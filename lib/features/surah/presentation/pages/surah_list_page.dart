import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/surah/presentation/widgets/surah_item.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.surahs,
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
            child: SearchBarWidget(
              onChanged: _filterSurahs,
              onClear: () {
                _searchController.clear();
                _filterSurahs('');
              },
              searchController: _searchController,
              hint: 'ابحث عن سورة...',
            ),
          ),

          Expanded(
            child: _currentDisplayedSurahs.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 30.h),
                    itemCount: _currentDisplayedSurahs.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 25.h),
                    itemBuilder: (context, index) {
                      final surah = _currentDisplayedSurahs[index];
                      return SurahItem(surah: surah);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 50.h, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Text(
            'لم يتم العثور على السورة',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
