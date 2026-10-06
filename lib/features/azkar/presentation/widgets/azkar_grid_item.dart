import 'dart:math' as math;

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بطاقة موضوع داخل شبكة بعمودين: الأيقونة في الأعلى والعنوان تحتها والنجمة
/// في الزاوية، لأن عرض العمود في الشبكة أضيق من عرض البطاقة الكاملة.
class AzkarGridItem extends StatelessWidget {
  const AzkarGridItem({
    super.key,
    required this.title,
    this.count,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isDark,
    this.itemLabel,
    this.isDua = false,
  });

  final String title;
  final int? count;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isDark;
  final String? itemLabel;

  /// الموضوع دعاء لا ذكر، فيتغيّر تسمية العدد ("دعاء" بدل "ذكر").
  final bool isDua;

  @override
  Widget build(BuildContext context) {
    final resolved = azkarCategoryIcon(title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppPalette.darkElevatedSurface : Colors.white,
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
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // النجمة في الطرف المقابل للأيقونة (يسار في الواجهة العربية)
                // لا فوقها. وحين يضيق العمود عن عرض الأيقونة — نص كبير على
                // شاشة صغيرة — تصغر الأيقونة مع النجمة بدل أن تتداخلا، لأن
                // العرض هنا مقيس بـ.w من عرض الشاشة لا من عرض العمود.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double starSize = 18.w;
                    final double starSlot = starSize + 4.w;
                    final double available = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : double.infinity;
                    // الأيقونة تأخذ ما يتبقّى بعد النجمة، فلا يطفح الصف مهما
                    // ضاق. والعرضان مقيسان بـ.w من عرض الشاشة لا من عرض
                    // العمود، فالعمود الضيق جداً — نص كبير على شاشة صغيرة —
                    // كان يُداخل النجمة بالأيقونة.
                    final double iconBox = math.min(
                      36.w,
                      math.max(0.0, available - starSlot - 8.w),
                    );

                    return SizedBox(
                      height: 36.w,
                      child: Row(
                        children: [
                          Container(
                            width: iconBox,
                            height: iconBox,
                            decoration: BoxDecoration(
                              color: resolved.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              resolved.icon,
                              size: iconBox / 2,
                              color: resolved.color,
                            ),
                          ),
                          // النجمة في الطرف المقابل للأيقونة: الأيقونة في
                          // البداية (اليمين) والنجمة في النهاية (اليسار).
                          const Spacer(),
                          GestureDetector(
                            onTap: onFavoriteTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(2.w),
                              child: Icon(
                                isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: starSize,
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
                    );
                  },
                ),
                SizedBox(height: 6.h),
                // العنوان يأخذ ما تبقّى من الارتفاع والعدد أسفله، فينكمش
                // العنوان بدل أن يطفح العمود عند تكبير الخط.
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                if (count != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${AppHelpers.getArabicNumber(count!)} '
                    '${azkarCountLabel(count!, itemLabel, dua: isDua)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
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
        ),
      ),
    );
  }
}
