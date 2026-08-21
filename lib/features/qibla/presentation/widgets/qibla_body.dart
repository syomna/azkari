import 'dart:math';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QiblaBody extends StatelessWidget {
  final double heading;
  final double difference;
  final bool isAligned;

  const QiblaBody({
    super.key,
    required this.heading,
    required this.difference,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isAligned
          ? 'Qibla aligned, compass heading ${heading.toInt()} degrees'
          : 'Compass heading ${heading.toInt()} degrees, rotate to face Qibla',
      child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text('${AppHelpers.getArabicNumber(heading.toInt())}°',
                style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold)),
            Text(AppStrings.currentDegree,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
          ],
        ),

        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isAligned
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 15,
                      )
                    ]
                  : [],
            ),
            child: Transform.rotate(
              angle: (difference * pi / 180),
              child: Image.asset(
                'assets/images/qibla.png',
                width: 0.7.sw, 
              ),
            ),
          ),
        ),

        Text(
          isAligned ? AppStrings.facingQibla : AppStrings.rotateToQibla,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: isAligned ? Colors.green : null,
          ),
        ),
      ],        // Column children
      ),        // Column
    );          // Semantics + return
  }
}
