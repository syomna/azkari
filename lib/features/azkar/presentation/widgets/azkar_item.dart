import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AzkarItem extends StatelessWidget {
  const AzkarItem({
    super.key,
    required this.title,
    this.count,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isDark,
    this.itemLabel,
    this.isCustom = false, // 👈 NEW: Flag to detect custom user azkar
  });

  final String title;
  final int? count;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isDark;
  final String? itemLabel;
  final bool isCustom; // 👈 Explicit declaration

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.06),
            blurRadius: 10.w,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                // Right Side: Context Icon + Title Info
                _buildCategoryIcon(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.black.withValues(alpha: 0.85),
                        ),
                      ),
                      if (count != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '${AppHelpers.getArabicNumber(count!)} ${itemLabel ?? _itemLabel(count!)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Left Side: Interactive Components (Favorite + Optional Drag Handle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onFavoriteTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppPalette.favoriteColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 22.sp,
                          color: isFavorite
                              ? AppPalette.favoriteColor
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dynamic context-based decorative icons matching dashboard layout language
  Widget _buildCategoryIcon() {
    IconData iconData = Icons.layers_outlined;
    Color iconColor = AppPalette.mainColor;

    if (title.contains('الصباح')) {
      iconData = Icons.wb_sunny_rounded;
      iconColor = Colors.orange;
    } else if (title.contains('المساء') || title.contains('النوم')) {
      iconData = Icons.nightlight_round;
      iconColor = Colors.indigo;
    } else if (title.contains('صلاة') ||
        title.contains('الآذان') ||
        title.contains('المسجد')) {
      iconData = Icons.mosque_rounded;
    } else if (title.contains('المحفوظة') || title.contains('المفضلة')) {
      iconData = Icons.folder_special_rounded;
      iconColor = AppPalette.favoriteColor;
    } else if (title.contains('سورة')) {
      iconData = Icons.menu_book_rounded;
      iconColor = Colors.teal;
    }

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        iconData,
        size: 20.sp,
        color: iconColor,
      ),
    );
  }

  String _itemLabel(int count) {
    if (count == 1) return 'ذكر';
    if (count == 2) return 'ذكران';
    if (count >= 3 && count <= 10) return 'أذكار';
    return 'ذكراً';
  }
}
