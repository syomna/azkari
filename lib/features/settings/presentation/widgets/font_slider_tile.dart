import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class FontSliderTile extends StatelessWidget {
  const FontSliderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields_rounded,
                  color: AppPalette.mainColor, size: 22.h),
              SizedBox(width: 15.w),
              Text(
                AppStrings.fontSize,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Slider(
            value: theme.textScaleFactor,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            activeColor: AppPalette.mainColor,
            onChanged: (v) => theme.setTextScaleFactor(v),
          ),
        ],
      ),
    );
  }
}
