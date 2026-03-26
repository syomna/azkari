import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class FavoriteItemsPage extends StatelessWidget {
  const FavoriteItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AzkarProvider>(context);
    final items = provider.favIndividualItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفوظات'),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: EdgeInsets.all(20.w),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppPalette.mainColor.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        items[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: AppPalette.amiriFontFamily,
                          height: 1.8,
                        ),
                      ),
                      SizedBox(
                        height: 12.h,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ZekrActionButton(
                              icon: Icons.copy_rounded,
                              isDark: isDark,
                              onTap: () => AppHelpers.copyText(items[index]),
                            ),
                            SizedBox(width: 6.w),

                            // Favorite button
                            ZekrActionButton(
                              isDark: isDark,
                              onTap: () =>
                                  provider.toggleItemFavorite(items[index]),
                              child: Icon(Icons.star_rounded,
                                  size: 22.sp, color: AppPalette.favoriteColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'قائمة المحفوظات فارغة',
        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
      ),
    );
  }
}
