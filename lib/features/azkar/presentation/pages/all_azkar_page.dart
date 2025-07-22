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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.allAzkarPageTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.morningAzkarCategory,
                img: 'sun',
                page: AzkarCategoryPage(
                  title: AppConstants.morningAzkarCategory,
                  categoryName: AppConstants.morningAzkarCategory,
                )),
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.eveningAzkarCategory,
                img: 'night',
                page: AzkarCategoryPage(
                  title: AppConstants.eveningAzkarCategory,
                  categoryName: AppConstants.eveningAzkarCategory,
                )),
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.wakingUpAzkarCategory,
                img: 'get-up',
                page: AzkarCategoryPage(
                  title: AppConstants.wakingUpAzkarCategory,
                  categoryName: AppConstants.wakingUpAzkarCategory,
                )),
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.prayerAzkarCategory,
                img: 'temple',
                page: AzkarCategoryPage(
                  title: AppConstants.prayerAzkarCategory,
                  categoryName: AppConstants.prayerAzkarCategory,
                )),
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.shortSurahsTitle,
                img: 'mat',
                page: SurahListPage()),
            SizedBox(
              height: 20.h,
            ),
            const Component(
                text: AppConstants.variousDuaaTitle,
                img: 'duaa',
                page: AzkarCategoryPage(
                  title: AppConstants.variousDuaaTitle,
                  categoryName: AppConstants.variousDuaaCategory,
                )),
          ],
        ),
      ),
    );
  }
}
