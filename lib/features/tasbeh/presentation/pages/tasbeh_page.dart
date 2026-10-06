import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/confirm_dialog.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/widgets/mesbaha_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TasbehPage extends StatelessWidget {
  const TasbehPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild only when the total changes — a session tap (via MesbahaWidget)
    // notifies the provider and must not rebuild this whole page.
    final savedCount = context.select<TasbehProvider, int>((p) => p.savedCount);
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.mesbaha,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () =>
                _confirmReset(context, context.read<TasbehProvider>()),
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
                Flexible(
                  child: Text(
                    'إجمالي التسبيحات:',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 15.w),
                Text(
                  AppHelpers.getArabicNumber(savedCount),
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

  Future<void> _confirmReset(
      BuildContext context, TasbehProvider provider) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'تصفير جلسة التسبيح؟',
      message: 'سيتم تصفير عداد هذه الجلسة فقط، مع بقاء الإجمالي كما هو.',
      confirmLabel: 'تصفير',
      confirmColor: AppPalette.mainColor,
    );
    if (!confirmed || !context.mounted) return;
    await provider.reset();
  }
}
