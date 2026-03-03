import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/widgets/mesbaha_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TasbehPage extends StatelessWidget {
  const TasbehPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tasbehProvider = Provider.of<TasbehProvider>(context);
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.mesbaha,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => tasbehProvider.reset(),
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const MesbahaWidget(), // Our new interactive widget
          const Spacer(),

          // Total Sessions Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppPalette.mainColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'إجمالي التسبيحات:',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 15.w),
                Text(
                  AppHelpers.getArabicNumber(tasbehProvider.savedCount),
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.mainColor),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
