import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_action_button.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_counter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayAzkar extends StatefulWidget {
  const DisplayAzkar({
    super.key,
    required this.zikrEntity,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onCounted,
  });

  final ZekrEntity zikrEntity;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  /// Called when the user finishes all repetitions of this zekr.
  /// Only passed for the currently active zekr in the list.
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
    _total = int.tryParse(widget.zikrEntity.count) ?? 1;
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
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _remaining--);
    if (_remaining == 0) {
      AppHelpers.showToast('أكملت الذكر!');
      widget.onCounted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasReference = widget.zikrEntity.reference.isNotEmpty;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: () => AppHelpers.copyText(widget.zikrEntity.zekr),
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
              // ── Arabic text ────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 14.h),
                child: Text(
                  widget.zikrEntity.zekr,
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

              // ── Source / reference ─────────────────────────
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
                    widget.zikrEntity.reference,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppPalette.mainColor
                          .withValues(alpha: _isDone ? 0.4 : 0.8),
                    ),
                  ),
                ),
              ],

              // ── Bottom actions row ─────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Copy button
                    ZekrActionButton(
                      icon: Icons.copy_rounded,
                      isDark: isDark,
                      onTap: () => AppHelpers.copyText(widget.zikrEntity.zekr),
                    ),
                    SizedBox(width: 6.w),

                    // Favorite button
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
                              ? const Color(0xFFF59E0B)
                              : (isDark ? Colors.white38 : Colors.black26),
                        ),
                      ),

                    const Spacer(),

                    // Counter pill
                    // if (hasCount)
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
        ),
      ),
    );
  }
}
