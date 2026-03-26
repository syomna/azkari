import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AzkarDetailsPage extends StatefulWidget {
  const AzkarDetailsPage({
    super.key,
    required this.title,
    required this.categoryName,
  });

  final String title;
  final String categoryName;

  @override
  State<AzkarDetailsPage> createState() => _AzkarDetailsPageState();
}

class _AzkarDetailsPageState extends State<AzkarDetailsPage> {
  int _countedIndex = 0;

  double _progressValue(int length) {
    if (length == 0) return 0;
    return _countedIndex / length;
  }

  String _progressLabel(int length) {
    if (_countedIndex >= length) {
      return 'اكتمل ✓';
    }
    return '${AppHelpers.getArabicNumber(_countedIndex)} من ${AppHelpers.getArabicNumber(length)}';
  }

  String _progressPercent(int length) {
    return '${AppHelpers.getArabicNumber((_progressValue(length) * 100).round())}٪';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final azkarProvider = Provider.of<AzkarProvider>(context);
    List<ZekrEntity> currentDisplayedAzkar = context
        .read<AzkarProvider>()
        .azkarList
        .where((zekr) => zekr.category == widget.categoryName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Favorite the whole category
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: IconButton(
              onPressed: () {
                context
                    .read<AzkarProvider>()
                    .toggleCategoryFavorite(widget.categoryName);
              },
              icon: Icon(
                context
                        .watch<AzkarProvider>()
                        .isCategoryFav(widget.categoryName)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 28.sp,
                color: context
                        .watch<AzkarProvider>()
                        .isCategoryFav(widget.categoryName)
                    ? AppPalette.favoriteColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.18)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ────────────────────────────────────────
          if (currentDisplayedAzkar.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progressPercent(currentDisplayedAzkar.length),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        _progressLabel(currentDisplayedAzkar.length),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.mainColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: _progressValue(currentDisplayedAzkar.length),
                      minHeight: 3.h,
                      backgroundColor:
                          AppPalette.mainColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _countedIndex >= currentDisplayedAzkar.length
                            ? AppPalette.mainColor
                            : AppPalette.mainColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Tap hint ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    color: AppPalette.mainColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'اضغط للعد، ومطولاً للنسخ.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Azkar list ──────────────────────────────────────────
          Expanded(
            child: currentDisplayedAzkar.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    thickness: 4.w,
                    radius: Radius.circular(10.r),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      itemCount: currentDisplayedAzkar.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final zikr = currentDisplayedAzkar[index];

                        final isDone = index < _countedIndex;

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isDone ? 0.45 : 1.0,
                          child: DisplayAzkar(
                            zikrEntity: zikr,
                            isFavorite: context
                                .watch<AzkarProvider>()
                                .isItemFav(zikr.zekr),
                            onFavoriteTap: () => context
                                .read<AzkarProvider>()
                                .toggleItemFavorite(zikr.zekr),
                            // Called when the user finishes counting this zekr
                            onCounted: index == _countedIndex
                                ? () {
                                    setState(() {
                                      if (_countedIndex <
                                          currentDisplayedAzkar.length) {
                                        _countedIndex++;
                                      }
                                    });
                                  }
                                : null,
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
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
