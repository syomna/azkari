import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AzkarItem extends StatelessWidget {
  const AzkarItem(
      {super.key,
      required this.title,
      this.count,
      required this.isFavorite,
      required this.onTap,
      required this.onFavoriteTap,
      required this.isDark,
      this.itemLabel});
  final String title;
  final int? count;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isDark;
  final String? itemLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: onFavoriteTap,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 20.sp,
                          color: isFavorite
                              ? AppPalette.favoriteColor
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.18)),
                        ),
                      ),
                    ],
                  ),
                  if (count != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${AppHelpers.getArabicNumber(count!)} ${itemLabel ?? _itemLabel(count!)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 7.w,
              height: 7.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.mainColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
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
