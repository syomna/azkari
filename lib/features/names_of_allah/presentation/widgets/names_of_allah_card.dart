import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NamesOfAllahCard extends StatelessWidget {
  const NamesOfAllahCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final NamesOfAllahEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25.r),
          child: Ink(
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: AppPalette.mainColor.withValues(alpha: 0.15),
              ),
              boxShadow: AppPalette.cardShadow(Theme.of(context).brightness),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Stack(
                children: [
                  // Stylized Background Number
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      AppHelpers.getArabicNumber(item.id),
                      style: TextStyle(
                        fontSize: 35.sp,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.mainColor.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // عنوان البطاقة محفور في سطحها قبل الاسم، وغير ظاهر
                        // تماماً حتى لا ينافس الاسم الذي هو موضوع البطاقة.
                        Text(
                          AppConstants.namesOfAllah,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.engravedInk(
                              Theme.of(context).brightness,
                            ),
                            shadows: AppPalette.engravedTextShadows(
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontFamily: AppPalette.amiriFontFamily,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.mainColor,
                            shadows: [
                              Shadow(
                                color:
                                    AppPalette.mainColor.withValues(alpha: 0.1),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          item.text,
                          textAlign: TextAlign.center,
                          // maxLines: 2,
                          // overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.4, // Improved line spacing for Arabic
                            color: isDark
                                ? AppPalette.darkMutedText
                                : AppPalette.lightMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
