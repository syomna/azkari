import 'package:azkar_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Component extends StatelessWidget {
  const Component(
      {super.key,
      required this.text,
      required this.img,
      required this.page,
      this.isColumn = false});

  final String text;
  final String img;
  final Widget page;
  final bool isColumn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => page));
      },
      child: isColumn
          ? CardWidget(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 30.w,
                    child: Image(
                      image: AssetImage('assets/images/$img.png'),
                      height: 30.h,
                    )),
                SizedBox(
                  height: 8.h,
                ),
                Flexible(
                  child: Text(
                    text,
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ))
          : CardWidget(
              height: MediaQuery.of(context).size.height * 0.08,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                      width: 30.w,
                      child: Image(
                        image: AssetImage('assets/images/$img.png'),
                        height: 30.h,
                      ))
                ],
              )),
    );
  }
}
