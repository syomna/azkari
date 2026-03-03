import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class QuranFontSheet extends StatelessWidget {
  const QuranFontSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Sheet only takes needed space
        children: [
          // Drag Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),

          Text(
            'تخصيص القراءة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 25.h),

          // Preview Area (Very important for Quranic script)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppPalette.mainColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                  color: AppPalette.mainColor.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontSize: 18.sp * theme.textScaleFactor, // Real-time preview
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(height: 25.h),

          // Stepper-style Font Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (theme.textScaleFactor > 0.8) {
                    theme.setTextScaleFactor(theme.textScaleFactor - 0.1);
                  }
                },
              ),

              // Visual progress dots
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Slider(
                    value: theme.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    activeColor: AppPalette.mainColor,
                    onChanged: (v) => theme.setTextScaleFactor(v),
                  ),
                ),
              ),

              _buildStepButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (theme.textScaleFactor < 2.0) {
                    theme.setTextScaleFactor(theme.textScaleFactor + 0.1);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'حجم الخط: ${(theme.textScaleFactor * 100).toInt()}%',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildStepButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border:
              Border.all(color: AppPalette.mainColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: AppPalette.mainColor, size: 24.sp),
      ),
    );
  }
}
