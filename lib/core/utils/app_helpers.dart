import 'dart:math';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastStatus { success, warning, error }

class AppHelpers {
  static String getArabicNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)'),
      (match) {
        // Map English digits (keys) to Arabic digits (values)
        const map = {
          '0': '٠',
          '1': '١',
          '2': '٢',
          '3': '٣',
          '4': '٤',
          '5': '٥',
          '6': '٦',
          '7': '٧',
          '8': '٨',
          '9': '٩',
        };

        // Use ! because we know the regex (\d) only matches 0-9
        return map[match.group(0)!]!;
      },
    );
  }

  static void copyText(String text) {
    FlutterClipboard.copy(text).then((value) {
      showToast(
        'تم النسخ',
      );
    });
  }

  static void showToast(String msg,
      {ToastStatus status = ToastStatus.success}) {
    Color backgroundColor;

    // Use your AppPalette for a cohesive look
    switch (status) {
      case ToastStatus.success:
        backgroundColor = AppPalette.mainColor;
        break;
      case ToastStatus.warning:
        backgroundColor = Colors.amber.shade700;
        break;
      case ToastStatus.error:
        backgroundColor = const Color(0xFFD32F2F); // A softer, premium red
        break;
    }

    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity
            .SNACKBAR, // Slightly higher than BOTTOM to avoid the home indicator
        timeInSecForIosWeb: 2,
        backgroundColor: backgroundColor.withValues(
            alpha: 0.9), // Subtle transparency feels more modern
        textColor: Colors.white,
        fontSize: 14.sp); // Slightly smaller font is often more elegant
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
