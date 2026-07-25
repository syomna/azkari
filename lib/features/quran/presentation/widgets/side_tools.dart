import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_font_sheet.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SideTools extends StatelessWidget {
  const SideTools(
      {super.key,
      required this.currentSurahNumber,
      required this.isAudioVisible,
      required this.onAudioToggle,
      required this.selectedSurahNumber,
      required this.onSurahSelected,
      required this.targetPage});
  final int currentSurahNumber;
  final bool isAudioVisible;
  final VoidCallback onAudioToggle;

  final int selectedSurahNumber;
  final void Function(int) onSurahSelected;

  final QuranPageItem targetPage;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuranProvider>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 54.w,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(
          alpha: 0.97,
        ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: AppPalette.mainColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.28 : 0.1,
            ),
            blurRadius: 20,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSideToolButton(
            context: context,
            icon: CupertinoIcons.list_bullet,
            tooltip: 'قائمة السور',
            onTap: () => _showSurahPicker(context),
          ),
          _buildSideDivider(context),
          _bookmark(context, provider, currentSurahNumber),
          _buildSideDivider(context),
          _buildSideToolButton(
            context: context,
            icon: Icons.format_size_rounded,
            tooltip: 'حجم الخط',
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QuranFontSheet(),
              );
            },
          ),
          _buildSideDivider(context),
          _buildSideToolButton(
            context: context,
            icon: CupertinoIcons.headphones,
            tooltip: 'الاستماع',
            color: isAudioVisible ? AppPalette.mainColor : null,
            onTap: onAudioToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildSideDivider(BuildContext context) {
    return Container(
      width: 24.w,
      height: 1.h,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
    );
  }

  Widget _buildSideToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22.r),
          child: SizedBox(
            width: 46.w,
            height: 46.h,
            child: Icon(
              icon,
              size: 22.sp,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  void _showSurahPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return QuranList(
            selectedSurahNumber: selectedSurahNumber,
            onSurahSelected: (int surahNum) {
              onSurahSelected(surahNum);
            },
          );
        },
      ),
    );
  }

  Widget _bookmark(
      BuildContext context, QuranProvider provider, int surahNumber) {
    // int index = _virtualPages.indexWhere((page) =>
    //     page.globalPageNumber ==
    //         _virtualPages[_currentIndex].globalPageNumber &&
    //     page.surahSegments.first['surah'] == surahNumber);
    // final targetPage = _virtualPages[_currentIndex];
    int targetSurah = targetPage.surahSegments.first['surah'];

    bool isBookmarked = provider.savedLatestQuranSurahNumber == targetSurah &&
        provider.savedLatestQuranPageNumber == targetPage.globalPageNumber;
    return _buildSideToolButton(
      context: context,
      icon:
          isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
      tooltip: isBookmarked ? 'إزالة من المفضلة' : 'أضف إلى المفضلة',
      color: Colors.amber,
      onTap: () {
        if (isBookmarked) {
          provider.clearSavedPosition();
        } else {
          provider.saveQuranPageNumber(targetPage.globalPageNumber);
          provider.saveLatestQuranSurahNumber(targetSurah);
        }
      },
    );
  }
}
