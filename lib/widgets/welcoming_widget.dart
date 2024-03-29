import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomingWidget extends StatelessWidget {
  const WelcomingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.15,
          width: MediaQuery.of(context).size.width * 0.25,
          decoration: const BoxDecoration(
              image:
                  DecorationImage(image: AssetImage('assets/images/pray.png'))),
        ),
         SizedBox(
          width: 10.w,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'مرحبا بك',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text('لا تنسى قراءة وردك اليومي  🌟',
                style: TextStyle(
                    fontSize: 14.sp))
          ],
        ),
      ],
    );
  }
}
