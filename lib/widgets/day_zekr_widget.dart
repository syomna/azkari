import 'dart:math';

import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/widgets/card_widget.dart';
import 'package:azkar_app/widgets/refresh_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DayZekrWidget extends StatefulWidget {
  const DayZekrWidget({super.key});

  @override
  State<DayZekrWidget> createState() => _DayZekrWidgetState();
}

class _DayZekrWidgetState extends State<DayZekrWidget> {
  int randomNumber = Random().nextInt(100);

  @override
  Widget build(BuildContext context) {
    List<AzkarModel> allAzkar = Provider.of<AzkarProvider>(context).allAzkar;

    var formatDay = DateFormat('EEEE', 'ar');

    var format = DateFormat.yMMMMd('ar');
    String dateString = format.format(DateTime.now());
    String dateDay = formatDay.format(DateTime.now());

    return CardWidget(
        height: MediaQuery.of(context).size.height * 0.18,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$dateDay ، $dateString',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          randomNumber = Random().nextInt(50);
                        });
                      },
                      icon: const RefreshIcon())
                ],
              ),
               SizedBox(
                height: 10.h,
              ),
              Text(
                allAzkar[randomNumber].zekr,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        ));
  }
}
