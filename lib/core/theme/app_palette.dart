import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppPalette {
  static const Color mainColor = Color(0xFF22a351);
  static const Color lightBackground = Color(0xFFF8FBF9);
  static const Color darkBackground = Color(0xFF121212);
  static const Color favoriteColor = Color(0xFFF59E0B);
  static const String tajawalFontFamily = 'Tajawal';
  static const String amiriFontFamily = 'Amiri';

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBackground,
    primaryColor: mainColor,
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: tajawalFontFamily,
        fontWeight: FontWeight.w900,
        fontSize: 18.sp,
        color: Colors.white,
      ),
    ),
    textTheme: Typography.englishLike2018
        .apply(fontSizeFactor: 1.sp)
        .apply(fontFamily: tajawalFontFamily, bodyColor: Colors.white),
  );

  static final ThemeData lightTheme = ThemeData.light()
      .copyWith(
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: lightBackground,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: tajawalFontFamily,
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
            color: AppPalette.mainColor,
          ),
        ),
        primaryColor: mainColor,
        textTheme: Typography.englishLike2018
            .apply(fontSizeFactor: 1.sp)
            .apply(fontFamily: tajawalFontFamily, bodyColor: Colors.black),
      )
      .copyWith(primaryColorDark: Colors.white);
}
