import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AllAzkarPage extends StatelessWidget {
  const AllAzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          AppConstants.allAzkarPageTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // 2. Use ListView.separated for better performance
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        itemCount: categories.length,
        separatorBuilder: (context, index) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = categories[index];
          return Component(
            text: item.title,
            img: item.image,
            page: item.page,
          );
        },
      ),
    );
  }
}

class AzkarCategoryModel {
  final String title;
  final String image;
  final Widget page;

  AzkarCategoryModel(
      {required this.title, required this.image, required this.page});
}
