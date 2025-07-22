import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppPalette {
  static const Color mainColor = Color(0xFF22a351);
  static const String fontFamily = 'Tajawal';

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: mainColor,
    textTheme: Typography.englishLike2018
        .apply(fontSizeFactor: 1.sp)
        .apply(fontFamily: fontFamily, bodyColor: Colors.white),
  );

  static final ThemeData lightTheme = ThemeData.light()
      .copyWith(
        primaryColor: mainColor,
        textTheme: Typography.englishLike2018
            .apply(fontSizeFactor: 1.sp)
            .apply(fontFamily: fontFamily, bodyColor: Colors.black),
      )
      .copyWith(primaryColorDark: Colors.white);
}
