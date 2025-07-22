import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/widgets/mesbaha_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TasbehPage extends StatefulWidget {
  const TasbehPage({super.key});

  @override
  State<TasbehPage> createState() => _TasbehPageState();
}

class _TasbehPageState extends State<TasbehPage> {
  @override
  Widget build(BuildContext context) {
    final tasbehProvider = Provider.of<TasbehProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تسبيح',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MesbahaImage(),
            SizedBox(
              height: 20.h,
            ),
            Wrap(
              children: [
                Text(
                  'عدد التسبيحات:',
                  style:
                      TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 10.w,
                ),
                Text(
                  '${tasbehProvider.savedCount}',
                  style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.mainColor),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
