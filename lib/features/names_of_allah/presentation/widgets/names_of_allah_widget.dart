import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NamesOfAllahWidget extends StatefulWidget {
  const NamesOfAllahWidget({super.key});

  @override
  State<NamesOfAllahWidget> createState() => _NamesOfAllahWidgetState();
}

class _NamesOfAllahWidgetState extends State<NamesOfAllahWidget> {
  // Use a PageController with viewportFraction to see edges of side cards
  final PageController _controller = PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NamesOfAllahProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.namesOfAllahStatus == AppLoadingStatus.loading) {
      return SizedBox(
        height: 150.h,
        child: const Center(
          child: CircularProgressIndicator(color: AppPalette.mainColor),
        ),
      );
    }

    return SizedBox(
      height: 160.h, // Increased height to accommodate scaling and shadows
      child: PageView.builder(
        controller: _controller,
        itemCount: provider.namesOfAllahList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = provider.namesOfAllahList[index];

          // AnimatedBuilder creates the premium "Focus" scaling effect
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = 1.0;
              if (_controller.position.haveDimensions) {
                value = _controller.page! - index;
                // Clamp scaling between 0.9 and 1.0 for a subtle effect
                value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
              } else {
                // Default scale for the first item before interaction
                value = index == 0 ? 1.0 : 0.9;
              }

              return Center(
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: AppPalette.mainColor.withValues(alpha: 0.15),
                ),
                // Glow shadow using mainColor instead of grey for a spiritual look
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.mainColor.withValues(alpha: 0.1),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Stylized Background Number
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '${index + 1}',
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.4, // Improved line spacing for Arabic
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
