import 'package:azkar_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Component extends StatelessWidget {
  const Component(
      {super.key, required this.text, required this.img, required this.page});

  final String text;
  final String img;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => page));
      },
      child: CardWidget(
          height: MediaQuery.of(context).size.height * 0.08,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
              Image(image: AssetImage('assets/images/$img.png'), height: 30.h,)
            ],
          )),
    );
  }
}
