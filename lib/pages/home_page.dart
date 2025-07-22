import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/pages/tasbeh_page.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/pages/settings_page.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/day_zekr_widget.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_widget.dart';
import 'package:azkar_app/widgets/welcoming_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final azkarProvider = Provider.of<AzkarProvider>(context);

    if (azkarProvider.azkarStatus == AppLoadingStatus.initial ||
        azkarProvider.azkarStatus == AppLoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppPalette.mainColor,
        ),
      );
    } else if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
      return Center(
          child:
              Text('Error loading Azkar: ${azkarProvider.azkarErrorMessage}'));
    } else {
      return Scaffold(
          body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.settings,
                        size: 22.h,
                      )),
                ),
                const WelcomingWidget(),
                SizedBox(
                  height: 10.h,
                ),
                Text(
                  AppConstants.dayOfZikr,
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.h,
                ),
                const DayZekrWidget(),
                SizedBox(
                  height: 10.h,
                ),
                Row(
                  children: [
                    const Expanded(
                        child: Component(
                      text: AppConstants.morningAzkarCategory,
                      img: 'sun',
                      page: AzkarCategoryPage(
                        title: AppConstants.morningAzkarCategory,
                        categoryName: AppConstants.morningAzkarCategory,
                      ),
                    )),
                    SizedBox(
                      width: 10.w,
                    ),
                    const Expanded(
                        child: Component(
                      text: AppConstants.eveningAzkarCategory,
                      img: 'night',
                      page: AzkarCategoryPage(
                        title: AppConstants.eveningAzkarCategory,
                        categoryName: AppConstants.eveningAzkarCategory,
                      ),
                    ))
                  ],
                ),
                SizedBox(
                  height: 10.h,
                ),
                Row(
                  children: [
                    const Expanded(
                        child: Component(
                      text: AppConstants.variousDuaaCategory,
                      img: 'duaa',
                      page: AzkarCategoryPage(
                        title: AppConstants.variousDuaaCategory,
                        categoryName: AppConstants.variousDuaaCategory,
                      ),
                    )),
                    SizedBox(
                      width: 10.w,
                    ),
                    const Expanded(
                        child: Component(
                      text: AppConstants.tasbeh,
                      img: 'tasbih',
                      page: TasbehPage(),
                    ))
                  ],
                ),
                SizedBox(
                  height: 20.h,
                ),
                Text(
                  AppConstants.namesOfAllah,
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.h,
                ),
                const NamesOfAllahWidget(),
                SizedBox(
                  height: 40.h,
                ),
              ],
            ),
          ),
        ),
      ));
    }
  }
}
