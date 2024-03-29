import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/utils/theme.dart';
import 'package:azkar_app/widgets/clickable_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class Tasbeh extends StatefulWidget {
  const Tasbeh({super.key});

  @override
  State<Tasbeh> createState() => _TasbehState();
}

class _TasbehState extends State<Tasbeh> {
  @override
  void initState() {
    Provider.of<AzkarProvider>(context, listen: false).loadCount();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسبيح', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ClickableImage(),
             SizedBox(
              height: 20.h,
            ),
            Wrap(
              children: [
               Text(
                  'عدد التسبيحات:',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                 SizedBox(
                  width: 10.w,
                ),
                Text(
                  '${Provider.of<AzkarProvider>(context).savedCount}',
                  style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: mainColor),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
