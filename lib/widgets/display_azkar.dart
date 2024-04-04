import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/utils/helpers.dart';
import 'package:azkar_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayAzkar extends StatelessWidget {
  const DisplayAzkar(
      {super.key,
      required this.listOfAzkar,
      required this.index,
      required this.isVarious});

  final List<AzkarModel>? listOfAzkar;
  final int index;
  final bool isVarious;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isVarious)
          if (index == 0 ||
              listOfAzkar?[index].category != listOfAzkar?[index - 1].category)
            Container(
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r), color: mainColor),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${listOfAzkar?[index].category}',
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
        Stack(
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    border: Border.all(color: mainColor),
                    borderRadius: BorderRadius.circular(8.r)),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: GestureDetector(
                    onLongPress: () {
                      Helpers.copyText('${listOfAzkar?[index].zekr}');
                    },
                    child: Text(
                      '${listOfAzkar?[index].zekr}',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
            if (listOfAzkar![index].count.isNotEmpty)
              Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    height: 30.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: mainColor),
                    child: Center(
                        child: Text(
                      '${listOfAzkar?[index].count}',
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    )),
                  )),
          ],
        ),
      ],
    );
  }
}
