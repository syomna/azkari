import 'package:azkar_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.child , this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          border: Border.all(color: mainColor),
          borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}
