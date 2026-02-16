import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppHelpers {
  static void copyText(String text) {
    FlutterClipboard.copy(text).then((value) {
      showToast(
        'تم النسخ',
      );
    });
  }

  static void showToast(String msg, {bool isError = false, Color? color}) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: isError ? Colors.red : color ?? Colors.green,
        textColor: Colors.white,
        fontSize: 16.sp);
  }

  static double calculateQiblaDirection(
    double userLat,
    double userLng,
  ) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;

    final lat1 = userLat * pi / 180;
    final lat2 = kaabaLat * pi / 180;
    final deltaLng = (kaabaLng - userLng) * pi / 180;

    final y = sin(deltaLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);

    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }

  static double normalize(double angle) {
    return (angle + 360) % 360;
  }
}
