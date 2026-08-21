import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/zekr_action_button.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:azkar_app/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class FavoriteItemsScreen extends StatelessWidget {
  const FavoriteItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<FavoritesProvider>(context);
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
                return AppCard(
                  padding: EdgeInsets.all(20.w),
                  borderColor: AppPalette.mainColor.withValues(alpha: 0.1),
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
    return const AppEmptyState(
      title: AppStrings.emptyFavorites,
      icon: Icons.star_border_rounded,
    );
  }
}
