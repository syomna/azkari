import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
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
  bool _loadTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadTriggered) {
      _loadTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = Provider.of<SurahProvider>(context, listen: false);
        if (provider.surahStatus == AppLoadingStatus.initial) {
          provider.loadSurah();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurahEntity> _filterSurahs(String query, List<SurahEntity> baseList) {
    if (query.isEmpty) return baseList;
    return baseList
        .where(
            (surah) => surah.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
            child: SearchBarWidget(
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
              searchController: _searchController,
              hint: 'ابحث عن سورة...',
            ),
          ),
          Expanded(
            child: Consumer<SurahProvider>(
              builder: (context, surahProvider, child) {
                switch (surahProvider.surahStatus) {
                  case AppLoadingStatus.initial:
                  case AppLoadingStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  case AppLoadingStatus.error:
                    return _buildErrorState(surahProvider.surahErrorMessage);
                  case AppLoadingStatus.loaded:
                    final surahs = _filterSurahs(
                        _searchController.text, surahProvider.surahList);
                    if (surahs.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 30.h),
                      itemCount: surahs.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 25.h),
                      itemBuilder: (context, index) =>
                          SurahItem(surah: surahs[index]),
                    );
                }
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

  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 50.h, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Text(
            message ?? 'حدث خطأ في تحميل السور',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () =>
                Provider.of<SurahProvider>(context, listen: false).loadSurah(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
