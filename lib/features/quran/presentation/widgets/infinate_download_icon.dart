import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfiniteDownloadIcon extends StatefulWidget {
  const InfiniteDownloadIcon({super.key});

  @override
  State<InfiniteDownloadIcon> createState() => _InfiniteDownloadIconState();
}

class _InfiniteDownloadIconState extends State<InfiniteDownloadIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // This is the magic line for infinite looping

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Ring
            Container(
              width: 25.h,
              height: 25.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppPalette.mainColor.withAlpha(50),
                  width: 2,
                ),
              ),
            ),
            // Moving Arrow
            Transform.translate(
              offset: Offset(0, -6 + (_animation.value * 12)),
              child: Opacity(
                opacity: 1 - _animation.value,
                child: Icon(
                  CupertinoIcons.arrow_down,
                  color: AppPalette.mainColor,
                  size: 15.h,
                ),
              ),
            ),
            // Static Base Line
            Positioned(
              bottom: 8.h,
              child: Container(
                width: 10.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: AppPalette.mainColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
