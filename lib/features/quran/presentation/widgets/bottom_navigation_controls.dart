import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavigationControls extends StatelessWidget {
  const BottomNavigationControls({super.key, required this.currentIndex, required this.virtualPages, required this.onPreviousPage, required this.onNextPage, required this.onPreviousSurah, required this.onNextSurah});

  final int currentIndex;
  final List<QuranPageItem> virtualPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousSurah;
  final VoidCallback onNextSurah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentSurah =
        virtualPages[currentIndex].surahSegments.first['surah'];

    final canGoPreviousPage = currentIndex > 0;
    final canGoNextPage = currentIndex < virtualPages.length - 1;

    final canGoPreviousSurah = currentSurah > 1;
    final canGoNextSurah = currentSurah < 114;

    return Container(
      height: 62.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(
          alpha: 0.97,
        ),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: AppPalette.mainColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.28 : 0.1,
            ),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavigationButton(
            context: context,
            icon: CupertinoIcons.forward_end_alt,
            tooltip: 'السورة السابقة',
            enabled: canGoPreviousSurah,
            onTap: onPreviousSurah,
          ),
          _buildNavigationButton(
            context: context,
            icon: CupertinoIcons.forward_end,
            tooltip: 'الصفحة السابقة',
            enabled: canGoPreviousPage,
            onTap: onPreviousPage,
          ),
          Container(
            width: 1.w,
            height: 26.h,
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
          _buildNavigationButton(
            context: context,
            icon: CupertinoIcons.backward_end,
            tooltip: 'الصفحة التالية',
            enabled: canGoNextPage,
            onTap: onNextPage,
          ),
          _buildNavigationButton(
            context: context,
            icon: CupertinoIcons.backward_end_alt,
            tooltip: 'السورة التالية',
            enabled: canGoNextSurah,
            onTap: onNextSurah,
          ),
        ],
      ),
    );
  }

    Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    final enabledColor = theme.colorScheme.onSurface;
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24.r),
          child: SizedBox(
            width: 40.w,
            height: 40.h,
            child: Icon(
              icon,
              size: 20.sp,
              color: enabled ? enabledColor : disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
