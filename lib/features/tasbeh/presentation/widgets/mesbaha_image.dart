import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasbehProvider>(context);
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // The LCD Screen
        Container(
          width: 200.w,
          height: 100.h,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3436), // Classic LCD dark grey
            borderRadius: BorderRadius.circular(15.r),
            border:
                Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Center(
            child: Text(
              AppHelpers.getArabicNumber(provider.count),
              style: TextStyle(
                fontFamily:
                    'Digital', // If you have a digital font, otherwise Amiri looks great too
                fontSize: 45.sp,
                color: const Color(0xFFBDC3C7),
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        SizedBox(height: 50.h),

        // The Main Button
        GestureDetector(
          onTapDown: (_) {
            _controller.forward();
            provider.addCount();
          },
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 180.h,
              height: 180.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.mainColor,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.mainColor.withValues(alpha: 0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(-2, -2),
                  )
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppPalette.mainColor,
                    AppPalette.mainColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.fingerprint, size: 80, color: Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
