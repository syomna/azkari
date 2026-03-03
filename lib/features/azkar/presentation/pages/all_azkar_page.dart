import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AllAzkarPage extends StatelessWidget {
  const AllAzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<AzkarCategoryModel> categories = [
      AzkarCategoryModel(
        title: AppConstants.morningAzkarCategory,
        image: 'sun',
        page: const AzkarCategoryPage(
          title: AppConstants.morningAzkarCategory,
          categoryName: AppConstants.morningAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.eveningAzkarCategory,
        image: 'night',
        page: const AzkarCategoryPage(
          title: AppConstants.eveningAzkarCategory,
          categoryName: AppConstants.eveningAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.sleepingAzkarCategory,
        image: 'sleep',
        page: const AzkarCategoryPage(
          title: AppConstants.sleepingAzkarCategory,
          categoryName: AppConstants.sleepingAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.wakingUpAzkarCategory,
        image: 'get-up',
        page: const AzkarCategoryPage(
          title: AppConstants.wakingUpAzkarCategory,
          categoryName: AppConstants.wakingUpAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.exitHomeCategory,
        image: 'door',
        page: const AzkarCategoryPage(
          title: AppConstants.exitHomeCategory,
          categoryName: AppConstants.exitHomeCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.prayerAzkarCategory,
        image: 'azan',
        page: const AzkarCategoryPage(
          title: AppConstants.prayerAzkarCategory,
          categoryName: AppConstants.prayerAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.mosqueAzkarCategory,
        image: 'temple',
        page: const AzkarCategoryPage(
          title: AppConstants.mosqueAzkarCategory,
          categoryName: AppConstants.mosqueAzkarCategory,
        ),
      ),
      AzkarCategoryModel(
        title: AppConstants.shortSurahsTitle,
        image: 'mat',
        page: const SurahListPage(),
      ),
      AzkarCategoryModel(
        title: AppConstants.variousDuaaTitle,
        image: 'duaa',
        page: const AzkarCategoryPage(
          title: AppConstants.variousDuaaTitle,
          categoryName: AppConstants.variousDuaaCategory,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppConstants.allAzkarPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        // Updated padding: increased bottom padding to 120.w
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 10.h,
          bottom: 120.h, // This provides space for the floating nav bar
        ),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15.w,
          mainAxisSpacing: 15.h,
          // childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final item = categories[index];
          return _buildCategoryItem(context, item, isDark);
        },
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context, AzkarCategoryModel item, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => item.page),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Background
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/${item.image}.png',
                height: 25.h,
                width: 25.h,
                // color: AppPalette.mainColor,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.category,
                    color: AppPalette.mainColor,
                    size: 25.h),
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AzkarCategoryModel {
  final String title;
  final String image;
  final Widget page;

  AzkarCategoryModel({
    required this.title,
    required this.image,
    required this.page,
  });
}
