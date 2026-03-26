import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_action_button.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SurahItem extends StatelessWidget {
  const SurahItem({super.key, required this.surah});

  final SurahEntity surah;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green Badge (Surah Name)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppPalette.mainColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          child: Text(
            surah.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Main Content Card
        GestureDetector(
          onLongPress: () => AppHelpers.copyText(surah.surah),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18.r),
                bottomRight: Radius.circular(18.r),
                topLeft: Radius.circular(18.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.03),
              ),
            ),
            child: Column(
              children: [
                Text(
                  surah.surah,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppPalette.amiriFontFamily,
                    fontSize: 18.sp, // Traditional font size for Quranic text
                    fontWeight: FontWeight.w600,
                    height: 1.9,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    ZekrActionButton(
                      icon: Icons.copy_rounded,
                      isDark: isDark,
                      onTap: () => AppHelpers.copyText(surah.surah),
                    ),
                    SizedBox(width: 6.w),

                    // Favorite button
                    ZekrActionButton(
                      isDark: isDark,
                      onTap: () => context
                          .read<AzkarProvider>()
                          .toggleItemFavorite(surah.surah),
                      child: Icon(
                        context.watch<AzkarProvider>().isItemFav(surah.surah)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 22.sp,
                        color: context
                                .watch<AzkarProvider>()
                                .isItemFav(surah.surah)
                            ? const Color(0xFFF59E0B)
                            : (isDark ? Colors.white38 : Colors.black26),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
