import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_action_button.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_counter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayAzkar extends StatefulWidget {
  const DisplayAzkar({
    super.key,
    required this.zekrEntity,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onCounted,
  });

  final ZekrEntity zekrEntity;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  final VoidCallback? onCounted;

  @override
  State<DisplayAzkar> createState() => _DisplayAzkarState();
}

class _DisplayAzkarState extends State<DisplayAzkar>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late int _total;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _total = widget.zekrEntity.count == 0 ? 1 : widget.zekrEntity.count;
    _remaining = _total;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isDone => _total > 0 && _remaining == 0;

  void _handleTap() {
    if (_remaining <= 0) return;
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _remaining--);
    if (_remaining == 0) {
      AppHelpers.showToast(AppStrings.zikrCompleted);
      widget.onCounted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasReference = widget.zekrEntity.reference.isNotEmpty;

    return Semantics(
      label:
          'zekr: ${widget.zekrEntity.zekr}, $_remaining of $_total remaining',
      button: true,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: () => AppHelpers.copyText(widget.zekrEntity.zekr),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: _isDone ? 0.03 : 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: _isDone
                    ? Colors.grey.withValues(alpha: 0.15)
                    : AppPalette.mainColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 14.h),
                  child: Text(
                    widget.zekrEntity.zekr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppPalette.amiriFontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.85,
                      color: _isDone
                          ? (isDark ? Colors.white30 : Colors.grey)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                if (hasReference) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Divider(
                      height: 0,
                      thickness: 0.5,
                      color: AppPalette.mainColor.withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                    child: Text(
                      widget.zekrEntity.reference,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppPalette.mainColor
                            .withValues(alpha: _isDone ? 0.4 : 0.8),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      ZekrActionButton(
                        icon: Icons.copy_rounded,
                        isDark: isDark,
                        onTap: () =>
                            AppHelpers.copyText(widget.zekrEntity.zekr),
                      ),
                      SizedBox(width: 6.w),
                      if (widget.onFavoriteTap != null)
                        ZekrActionButton(
                          isDark: isDark,
                          onTap: widget.onFavoriteTap!,
                          child: Icon(
                            widget.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22.sp,
                            color: widget.isFavorite
                                ? AppPalette.favoriteColor
                                : (isDark ? Colors.white38 : Colors.black26),
                          ),
                        ),
                      const Spacer(),
                      ZekrCounterPill(
                        remaining: _remaining,
                        total: _total,
                        isDone: _isDone,
                        isDark: isDark,
                        onTap: _handleTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ), // AnimatedContainer
        ), // ScaleTransition
      ), // GestureDetector
    ); // Semantics + return
  }
}
