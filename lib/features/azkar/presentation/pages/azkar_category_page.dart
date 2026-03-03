import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AzkarCategoryPage extends StatefulWidget {
  const AzkarCategoryPage({
    super.key,
    required this.title,
    required this.categoryName,
  });

  final String title;
  final String categoryName;

  @override
  State<AzkarCategoryPage> createState() => _AzkarCategoryPageState();
}

class _AzkarCategoryPageState extends State<AzkarCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ZekrEntity> _currentDisplayedAzkar = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterAzkar(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAzkar(String query) {
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    List<ZekrEntity> baseList;

    if (widget.categoryName == AppConstants.morningAzkarCategory) {
      baseList = azkarProvider.morningAzkar;
    } else if (widget.categoryName == AppConstants.eveningAzkarCategory) {
      baseList = azkarProvider.eveningAzkar;
    } else if (widget.categoryName == AppConstants.wakingUpAzkarCategory) {
      baseList = azkarProvider.wakingUpAzkar;
    } else if (widget.categoryName == AppConstants.sleepingAzkarCategory) {
      baseList = azkarProvider.sleepingAzkar;
    } else if (widget.categoryName == AppConstants.exitHomeCategory) {
      baseList = azkarProvider.exitHomeAzkar;
    } else if (widget.categoryName == AppConstants.prayerAzkarCategory) {
      baseList = azkarProvider.prayerAzkar;
    } else if (widget.categoryName == AppConstants.mosqueAzkarCategory) {
      baseList = azkarProvider.mosqueAzkar;
    } else if (widget.categoryName == AppConstants.variousDuaaCategory) {
      baseList = azkarProvider.variousDuaa;
    } else {
      baseList = azkarProvider.azkarList;
    }

    setState(() {
      if (query.isEmpty) {
        _currentDisplayedAzkar = baseList;
      } else {
        _currentDisplayedAzkar = baseList
            .where((zekr) =>
                zekr.category.toLowerCase().contains(query.toLowerCase()) ||
                zekr.zekr.toLowerCase().contains(query.toLowerCase()))
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
        title: Text(
          widget.title,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (widget.categoryName == AppConstants.variousDuaaCategory)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: SearchBarWidget(
                onChanged: _filterAzkar,
                onClear: () {
                  _searchController.clear();
                  _filterAzkar('');
                },
                searchController: _searchController,
                hint: 'ابحث عن ذكر أو دعاء',
              ),
            ),

          // Enhanced Instruction Box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                  Icon(Icons.touch_app_outlined,
                      color: AppPalette.mainColor, size: 20.h),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.categoryName == AppConstants.variousDuaaCategory
                          ? 'اضغط مطولاً للنسخ.'
                          : 'اضغط للعد، ومطولاً للنسخ.',
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

          Expanded(
            child: _currentDisplayedAzkar.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    thickness: 4.w,
                    radius: Radius.circular(10.r),
                    child: ListView.separated(
                      padding: EdgeInsets.only(bottom: 24.h),
                      itemCount: _currentDisplayedAzkar.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final zikr = _currentDisplayedAzkar[index];
                        bool showHeader = false;
                        if (widget.categoryName ==
                                    AppConstants.variousDuaaCategory &&
                                (index == 0 ||
                                    zikr.category !=
                                        _currentDisplayedAzkar[index - 1]
                                            .category) ||
                            widget.categoryName ==
                                AppConstants.mosqueAzkarCategory) {
                          showHeader = true;
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: DisplayAzkar(
                            zikrEntity: zikr,
                            showCategoryHeader: showHeader,
                          ),
                        );
                      },
                    ),
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
          Icon(Icons.search_off_rounded, size: 60.h, color: Colors.grey),
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
