import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppPalette {
  static const Color mainColor = Color(0xFF22A351);

  static const Color lightBackground = Color(0xFFF8FBF9);
  static const Color darkBackground = Color(0xFF121714);

  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF1B211E);

  static const Color lightText = Color(0xFF162019);
  static const Color darkText = Color(0xFFF3F7F4);

  static const Color lightMutedText = Color(0xFF66736B);
  static const Color darkMutedText = Color(0xFFAAB5AE);

  static const Color lightInactiveIndicator = Color(0xFFD3E1D8);
  static const Color darkInactiveIndicator = Color(0xFF3D4841);

  static const Color favoriteColor = Color(0xFFF59E0B);

  static const String tajawalFontFamily = 'Tajawal';
  static const String amiriFontFamily = 'Amiri';

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: tajawalFontFamily,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: mainColor,
      onPrimary: Colors.white,
      surface: lightSurface,
      onSurface: lightText,
      surfaceContainerHighest: Color(0xFFEAF3ED),
      outline: Color(0xFFD6E2DA),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: lightText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: tajawalFontFamily,
        fontWeight: FontWeight.w900,
        fontSize: 18.sp,
        color: mainColor,
      ),
    ),
    textTheme: Typography.englishLike2018.apply(
      fontSizeFactor: 1,
      fontFamily: tajawalFontFamily,
      bodyColor: lightText,
      displayColor: lightText,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: tajawalFontFamily,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: mainColor,
      onPrimary: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: Color(0xFF253029),
      outline: Color(0xFF39443D),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: tajawalFontFamily,
        fontWeight: FontWeight.w900,
        fontSize: 18.sp,
        color: Colors.white,
      ),
    ),
    textTheme: Typography.englishLike2018.apply(
      fontSizeFactor: 1,
      fontFamily: tajawalFontFamily,
      bodyColor: darkText,
      displayColor: darkText,
    ),
  );
}
