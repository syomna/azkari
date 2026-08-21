import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_completion_dialog.dart';
import 'package:azkar_app/widgets/app_empty_state.dart';
import 'package:azkar_app/widgets/app_error_widget.dart';
import 'package:azkar_app/widgets/app_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AzkarDetailsScreen extends StatefulWidget {
  const AzkarDetailsScreen({
    super.key,
    required this.title,
    required this.categoryName,
    this.isCustomCategory = false,
  });

  final String title;
  final String categoryName;
  final bool isCustomCategory;

  @override
  State<AzkarDetailsScreen> createState() => _AzkarDetailsScreenState();
}

class _AzkarDetailsScreenState extends State<AzkarDetailsScreen> {
  int _countedIndex = 0;

  double _progressValue(int length) {
    if (length == 0) return 0;
    return _countedIndex / length;
  }

  String _progressLabel(int length) {
    if (_countedIndex >= length) {
      return AppStrings.completeLabel;
    }
    return '${AppHelpers.getArabicNumber(_countedIndex)} من ${AppHelpers.getArabicNumber(length)}';
  }

  String _progressPercent(int length) {
    return '${AppHelpers.getArabicNumber((_progressValue(length) * 100).round())}${AppStrings.percentSign}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azkarProvider = context.watch<AzkarProvider>();

    if (azkarProvider.azkarStatus == AppLoadingStatus.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const AppLoadingWidget(),
      );
    }

    if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: AppErrorWidget(
          errorMessage: azkarProvider.azkarErrorMessage ?? AppStrings.loadError,
          onRetry: () => azkarProvider.loadAzkar(),
        ),
      );
    }

    List<ZekrEntity> currentDisplayedAzkar = widget.isCustomCategory
        ? azkarProvider.customAzkarList
            .where((zekr) => zekr.category == widget.categoryName)
            .toList()
        : azkarProvider.azkarList
            .where((zekr) => zekr.category == widget.categoryName)
            .toList();

    if (_countedIndex > currentDisplayedAzkar.length) {
      _countedIndex = currentDisplayedAzkar.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: IconButton(
              onPressed: () {
                context
                    .read<FavoritesProvider>()
                    .toggleCategoryFavorite(widget.categoryName);
              },
              icon: Selector<FavoritesProvider, bool>(
                selector: (_, p) => p.isCategoryFav(widget.categoryName),
                builder: (context, isFav, _) => Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 28.sp,
                  color: isFav
                      ? AppPalette.favoriteColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppPalette.mainColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    AppStrings.tapToCount,
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
                          opacity: isDone ? AppConstants.doneOpacity : 1.0,
                          child: DisplayAzkar(
                            zekrEntity: zikr,
                            isFavorite: context
                                .watch<FavoritesProvider>()
                                .isItemFav(zikr.zekr),
                            onFavoriteTap: () => context
                                .read<FavoritesProvider>()
                                .toggleItemFavorite(zikr.zekr),
                            onCounted: index == _countedIndex
                                ? () {
                                    setState(() {
                                      if (_countedIndex <
                                          currentDisplayedAzkar.length) {
                                        _countedIndex++;
                                      }
                                      if (currentDisplayedAzkar.isNotEmpty &&
                                          _countedIndex ==
                                              currentDisplayedAzkar.length) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            ZekrCompletionDialog.show(context);
                                          }
                                        });
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
    return const AppEmptyState(
      title: AppStrings.notFound,
      icon: Icons.search_off_rounded,
    );
  }
}
