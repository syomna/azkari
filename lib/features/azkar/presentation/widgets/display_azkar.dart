import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayAzkar extends StatefulWidget {
  const DisplayAzkar({
    super.key,
    required this.zikrEntity,
    this.showCategoryHeader = false,
  });

  final ZekrEntity zikrEntity;
  final bool showCategoryHeader;

  @override
  State<DisplayAzkar> createState() => _DisplayAzkarState();
}

class _DisplayAzkarState extends State<DisplayAzkar>
    with SingleTickerProviderStateMixin {
  late int zekrCount;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    zekrCount = int.tryParse(widget.zikrEntity.count) ?? 0;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (zekrCount > 0) {
      _pulseController.forward().then((_) => _pulseController.reverse());
      setState(() {
        zekrCount--;
      });
      if (zekrCount == 0) {
        AppHelpers.showToast('أكملت الذكر!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCategoryHeader)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
            child: Text(
              widget.zikrEntity.category,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppPalette.mainColor,
              ),
            ),
          ),
        GestureDetector(
          onTap: _handleTap,
          onLongPress: () => AppHelpers.copyText(widget.zikrEntity.zekr),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: zekrCount == 0
                      ? Colors.grey.withValues(alpha: 0.2)
                      : AppPalette.mainColor.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
                    child: Text(
                      widget.zikrEntity.zekr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppPalette.amiriFontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        color:
                            zekrCount == 0 && widget.zikrEntity.count.isNotEmpty
                                ? (isDark ? Colors.white38 : Colors.grey)
                                : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                  if (widget.zikrEntity.count.isNotEmpty)
                    Positioned(
                      left: 12.w,
                      bottom: 12.h,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: zekrCount == 0
                              ? Colors.grey.withValues(alpha: 0.2)
                              : AppPalette.mainColor,
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Text(
                          AppHelpers.getArabicNumber(zekrCount),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
