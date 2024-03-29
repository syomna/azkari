import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ClickableImage extends StatefulWidget {
  const ClickableImage({
    super.key,
  });

  @override
  _ClickableImageState createState() => _ClickableImageState();
}

class _ClickableImageState extends State<ClickableImage> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    final allData = Provider.of<AzkarProvider>(context);
    return GestureDetector(
      onTapDown: (details) {
        final imageSize = context.size;
        final tapPosition = details.localPosition;
        final bottomAreaHeight = imageSize!.height * 0.4;

        if (tapPosition.dy > imageSize.height - bottomAreaHeight) {
          allData.addCount();
        }
      },
      onTapUp: (details) {
        final imageSize = context.size;
        final tapPosition = details.localPosition;
        final bottomAreaHeight = imageSize!.height * 0.4;

        if (tapPosition.dy < imageSize.height - bottomAreaHeight) {
          allData.reset();
        }
      },
      child: Stack(
        children: [
          Image.asset('assets/images/masbha.png'),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.14,
            right: MediaQuery.of(context).size.width * 0.18,
            child: Text(
              '${allData.count}',
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
