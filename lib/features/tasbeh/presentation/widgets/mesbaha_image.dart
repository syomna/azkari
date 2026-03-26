import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MesbahaWidget extends StatefulWidget {
  const MesbahaWidget({super.key});

  @override
  State<MesbahaWidget> createState() => _MesbahaWidgetState();
}

class _MesbahaWidgetState extends State<MesbahaWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _blur;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60), // Fast snap
    );

    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _blur = Tween<double>(begin: 20.0, end: 4.0).animate(_controller);
    _offset = Tween<double>(begin: 10.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // This handles the "Tap" logic: Shrink -> Wait -> Grow -> Count
  void _handleTap(TasbehProvider provider) async {
    // 1. Shrink down immediately
    await _controller.forward();

    // 2. Pop back up
    await _controller.reverse();

    // 3. Trigger haptics and count only AFTER the animation/release
    HapticFeedback.lightImpact();
    provider.addCount();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasbehProvider>(context);

    return Column(
      children: [
        // LCD Screen
        Container(
          width: 220.w,
          height: 110.h,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3436),
            borderRadius: BorderRadius.circular(15.r),
            border:
                Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Center(
            child: Text(
              AppHelpers.getArabicNumber(provider.count),
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: 50.sp,
                color: const Color(0xFFBDC3C7).withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        SizedBox(height: 60.h),

        // Animated Button
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return GestureDetector(
              // Using onTap to ensure the logic runs on finger release
              onTap: () => _handleTap(provider),
              // We still use TapDown/Cancel just to manage visual state if finger stays held
              onTapDown: (_) => _controller.forward(),
              onTapCancel: () => _controller.reverse(),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 190.h,
                  height: 190.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPalette.mainColor,
                        AppPalette.mainColor.withValues(alpha: 0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.mainColor.withValues(alpha: 0.3),
                        blurRadius: _blur.value,
                        spreadRadius: 1,
                        offset: Offset(0, _offset.value),
                      ),
                      const BoxShadow(
                        color: Colors.white24,
                        blurRadius: 2,
                        offset: Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fingerprint,
                      size: 85.sp,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
