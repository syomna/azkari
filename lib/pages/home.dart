import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/pages/azkar_page.dart';
import 'package:azkar_app/pages/Tasbeh.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/utils/theme.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:azkar_app/widgets/day_zekr_widget.dart';
import 'package:azkar_app/widgets/names_of_allah_widget.dart';
import 'package:azkar_app/widgets/welcoming_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    Provider.of<AzkarProvider>(context, listen: false).loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    List<AzkarModel> allAzkar = Provider.of<AzkarProvider>(context).allAzkar;

    if (allAzkar.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: mainColor,
        ),
      );
    } else {
      return Scaffold(
          body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomingWidget(),
                SizedBox(
                  height: 20.h,
                ),
                 Text(
                  'ذكر اليوم',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.bold),
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
                    Expanded(
                        child: Component(
                      text: "أذكار الصباح",
                      img: "sun",
                      page: AzkarPage(
                          title: "أذكار الصباح",
                          listOfAzkar: allAzkar
                              .where((e) => e.category == "أذكار الصباح")
                              .toList()),
                    )),
                     SizedBox(
                      width: 10.w,
                    ),
                    Expanded(
                        child: Component(
                      text: "أذكار المساء",
                      img: "night",
                      page: AzkarPage(
                          title: "أذكار المساء",
                          listOfAzkar: allAzkar
                              .where((e) => e.category == "أذكار المساء")
                              .toList()),
                    ))
                  ],
                ),
                 SizedBox(
                  height: 10.h,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Component(
                      text: "أدعية",
                      img: "duaa",
                      page: AzkarPage(
                          title: "أدعية",
                          isVarious: true,
                          listOfAzkar: allAzkar
                              .where((e) =>
                                  e.category != "أذكار الصباح" &&
                                  e.category != "أذكار المساء" &&
                                  e.category != "أذكار الاستيقاظ من النوم" &&
                                  e.category != "أذكار الآذان")
                              .toList()),
                    )),
                     SizedBox(
                      width: 10.w,
                    ),
                    const Expanded(
                        child: Component(
                      text: "تسبيح",
                      img: "tasbih",
                      page: Tasbeh(),
                    ))
                  ],
                ),
                 SizedBox(
                  height: 20.h,
                ),
                 Text(
                  'أسماء الله الحسنى',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.bold),
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
