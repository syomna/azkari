import 'dart:math';

import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DayZekrWidget extends StatefulWidget {
  const DayZekrWidget({super.key});
  @override
  State<DayZekrWidget> createState() => _DayZekrWidgetState();
}

class _DayZekrWidgetState extends State<DayZekrWidget> {
  int _currentZekrIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    if (azkarProvider.azkarStatus == AppLoadingStatus.loaded &&
        _currentZekrIndex == 0 &&
        azkarProvider.azkarList.isNotEmpty) {
      _currentZekrIndex = Random().nextInt(azkarProvider.azkarList.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final azkarProvider = Provider.of<AzkarProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (azkarProvider.azkarList.isEmpty) return const SizedBox();

    ZekrEntity currentZekr = azkarProvider
        .azkarList[_currentZekrIndex % azkarProvider.azkarList.length];
    String dateString = DateFormat.yMMMMd('ar').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1E1E), // Deep Charcoal
                  const Color(0xFF121212)
                      .withBlue(30)
                      .withGreen(30), // Hints of midnight green
                ]
              : [
                  AppPalette.mainColor,
                  AppPalette.mainColor.withBlue(100).withGreen(180),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: isDark
            ? Border.all(
                color: AppPalette.mainColor.withValues(alpha: 0.15),
                width: 1) // Subtle border for definition
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppPalette.mainColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.format_quote,
                size: 100.sp,
                color: isDark
                    ? AppPalette.mainColor
                        .withValues(alpha: 0.03) // Even subtler in dark mode
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.calendar,
                              color: isDark ? Colors.grey : Colors.white,
                              size: 14.sp),
                          SizedBox(width: 5.w),
                          Text(dateString,
                              style: TextStyle(
                                color: isDark ? Colors.grey : Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                      _buildHeaderIcon(
                        isDark: isDark,
                        icon: CupertinoIcons.refresh,
                        onTap: () => setState(() => _currentZekrIndex =
                            Random().nextInt(azkarProvider.azkarList.length)),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    currentZekr.zekr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppPalette.amiriFontFamily,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildHeaderIcon(
                        isDark: isDark,
                        icon: CupertinoIcons.doc_on_doc,
                        onTap: () {
                          AppHelpers.copyText(currentZekr.zekr);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Update the icon builder to handle dark mode colors
  Widget _buildHeaderIcon(
      {required bool isDark,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isDark
              ? AppPalette.mainColor.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon,
            color: isDark ? AppPalette.mainColor : Colors.white, size: 18.sp),
      ),
    );
  }
}
