import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MesbahaImage extends StatefulWidget {
  const MesbahaImage({super.key});

  @override
  State<MesbahaImage> createState() => _MesbahaImageState();
}

class _MesbahaImageState extends State<MesbahaImage> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    final tasbehProvider = Provider.of<TasbehProvider>(context);
    return GestureDetector(
      onTapDown: (details) {
        final imageSize = context.size;
        final tapPosition = details.localPosition;
        final bottomAreaHeight = imageSize!.height * 0.4;

        if (tapPosition.dy > imageSize.height - bottomAreaHeight) {
          tasbehProvider.addCount();
        }
      },
      onTapUp: (details) {
        final imageSize = context.size;
        final tapPosition = details.localPosition;
        final bottomAreaHeight = imageSize!.height * 0.4;

        if (tapPosition.dy < imageSize.height - bottomAreaHeight) {
          tasbehProvider.reset();
        }
      },
      child: Stack(
        children: [
          Image.asset('assets/images/masbha.png'),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.14,
            right: MediaQuery.of(context).size.width * 0.18,
            child: Text(
              '${tasbehProvider.count}',
              style: TextStyle(
                  fontSize: 35.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
