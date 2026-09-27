import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AzkarDetailsPage extends StatefulWidget {
  const AzkarDetailsPage({
    super.key,
    required this.title,
    required this.categoryName,
    this.isCustomCategory = false,
  });

  final String title;
  final String categoryName;
  final bool isCustomCategory; // Flag to indicate if this is a custom category

  @override
  State<AzkarDetailsPage> createState() => _AzkarDetailsPageState();
}

class _AzkarDetailsPageState extends State<AzkarDetailsPage> {
  /// "`<category>` + `\u0000` + `<zekr>`" — stable identity so the same
  /// zekr text in different custom categories (or morning/evening)
  /// keeps independent favorites.
  String _favoriteKey(String categoryName, String zekr) =>
      '$categoryName\u0000$zekr';

  late final AzkarProvider _azkarProvider;
  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    _azkarProvider = context.read<AzkarProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wasComplete = _isComplete();
      _azkarProvider.addListener(_handleProgressChange);
    });
  }

  @override
  void dispose() {
    _azkarProvider.removeListener(_handleProgressChange);
    super.dispose();
  }

  int _currentCount() {
    final azkar = widget.isCustomCategory
        ? _azkarProvider.customAzkarList
        : _azkarProvider.azkarList;
    return azkar.where((z) => z.category == widget.categoryName).length;
  }

  bool _isComplete() {
    final total = _currentCount();
    if (total == 0) return false;
    return _azkarProvider.completedIndexOf(widget.categoryName) >= total;
  }

  void _handleProgressChange() {
    if (!mounted) return;
    final nowComplete = _isComplete();
    // Celebrate only on the transition from not-complete to complete.
    if (!_wasComplete && nowComplete) {
      _wasComplete = true;
      _showCelebrationDialog();
    } else {
      _wasComplete = nowComplete;
    }
  }

  double _progressValue(int length, int countedIndex) {
    if (length == 0) return 0;
    return countedIndex / length;
  }

  String _progressLabel(int length, int countedIndex) {
    if (countedIndex >= length) {
      return 'اكتمل ✓';
    }
    return '${AppHelpers.getArabicNumber(countedIndex)} من ${AppHelpers.getArabicNumber(length)}';
  }

  String _progressPercent(int length, int countedIndex) {
    return '${AppHelpers.getArabicNumber((_progressValue(length, countedIndex) * 100).round())}٪';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = context.watch<FavoritesProvider>();
    final currentDisplayedAzkar = context
        .select<AzkarProvider, List<ZekrEntity>>(
            (p) => widget.isCustomCategory ? p.customAzkarList : p.azkarList)
        .where((zekr) => zekr.category == widget.categoryName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          // Reset counting for this category
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: IconButton(
              tooltip: 'إعادة تعيين العد',
              onPressed: () => _confirmReset(context),
              icon: Icon(
                Icons.refresh_rounded,
                size: 24.sp,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Favorite the whole category
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: IconButton(
              onPressed: () =>
                  favorites.toggleCategoryFavorite(widget.categoryName),
              icon: Icon(
                favorites.isCategoryFav(widget.categoryName)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 28.sp,
                color: favorites.isCategoryFav(widget.categoryName)
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
            Consumer<AzkarProvider>(
              builder: (context, azkarProvider, _) {
                final countedIndex = azkarProvider
                    .completedIndexOf(widget.categoryName)
                    .clamp(0, currentDisplayedAzkar.length);
                return Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _progressPercent(
                                  currentDisplayedAzkar.length, countedIndex),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _progressLabel(
                                  currentDisplayedAzkar.length, countedIndex),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.mainColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: _progressValue(
                              currentDisplayedAzkar.length, countedIndex),
                          minHeight: 3.h,
                          backgroundColor:
                              AppPalette.mainColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            countedIndex >= currentDisplayedAzkar.length
                                ? AppPalette.favoriteColor
                                : AppPalette.mainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  Expanded(
                    child: Text(
                      'اضغط للعد، ومطولاً للنسخ.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppPalette.mainColor,
                      ),
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
                        final total = int.tryParse(zikr.count) ?? 1;

                        return Selector<AzkarProvider, int>(
                          selector: (_, p) => p.remainingFor(
                            zikr.zekr,
                            total,
                            category: widget.categoryName,
                            index: index,
                          ),
                          builder: (context, remaining, _) {
                            final isDone = remaining == 0;
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isDone ? 0.45 : 1.0,
                              child: DisplayAzkar(
                                key: ValueKey('$index\u0000${zikr.zekr}'),
                                zikrEntity: zikr,
                                remaining: remaining,
                                isFavorite: favorites.isItemFav(_favoriteKey(
                                    widget.categoryName, zikr.zekr)),
                                onFavoriteTap: () =>
                                    favorites.toggleItemFavorite(_favoriteKey(
                                        widget.categoryName, zikr.zekr)),
                                onDecrement: () =>
                                    context.read<AzkarProvider>().decrement(
                                          zikr.zekr,
                                          total,
                                          category: widget.categoryName,
                                          index: index,
                                        ),
                                onCounted: () {},
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCelebrationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        contentPadding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.h,
              height: 84.h,
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppPalette.mainColor,
                size: 56.h,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'أحسنت! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF162019),
                fontFamilyFallback: AppPalette.emojiFallback,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'أتممت جميع الأذكار في هذه المجموعة.\nتقبل الله منك، وجعل ذلك في ميزان حسناتك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.7,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.mainColor,
                textStyle: TextStyle(
                  fontFamily: AppPalette.tajawalFontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('ما شاء الله'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'إعادة تعيين العد؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp),
        ),
        content: Text(
          'سيتم مسح تقدم العد في هذه المجموعة.',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.mainColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('إعادة التعيين',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    if (!context.mounted) return;
    context.read<AzkarProvider>().resetCategoryCounts(widget.categoryName);
    AppHelpers.showToast('تمت إعادة تعيين العد');
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
