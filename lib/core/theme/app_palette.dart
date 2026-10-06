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

  /// لون الخطأ الموحد في التنبيهات.
  static const Color errorColor = Color(0xFFD32F2F);

  /// تدرّج بطاقة ذكر اليوم، وهو الأخضر المرجعي في الشاشة الرئيسية. كل مساحات
  /// خضراء أخرى في التطبيق تأخذ من هذا التدرج بدل أن تختار أخضر مستقلاً.
  static const Color greenGradientStart = mainColor;
  static const Color greenGradientEnd = Color(0xFF3ABB7A);

  /// طرفا تدرج الوضع الداكن لبطاقة ذكر اليوم.
  static const Color darkCardSurface = Color(0xFF1E1E1E);
  static const Color darkCardSurfaceAlt = Color(0xFF121E1E);

  /// خلفية قسم المواقيت. لون فاتح مشتق من الأخضر المرجعي ليبقى القسم من
  /// العائلة نفسها، والبطاقات البيضاء فوقه تعطي التباين.
  static const Color prayerPanelLight = Color(0xFFDDF1E4);
  static const Color prayerPanelDark = Color(0xFF14281B);

  /// أخضر داكن للنصوص والأيقونات. الأخضر الأساسي وحده يعطي نسبة تباين تقارب
  /// 3.3 مع الأبيض، وهي لا تكفي لاسم صلاة بحجم عشرة، فتأخذ النصوص هذه الدرجة
  /// ويبقى الأخضر الأساسي للتعبئة والحدود.
  static const Color deepGreenLight = Color(0xFF146B3C);
  static const Color deepGreenDark = Color(0xFF7FD8A0);

  /// أسطح مرتفعة تتكرر في عدة شاشات: الأوراق المنبثقة والحوارات وبطاقات
  /// القوائم في الوضع الداكن.
  static const Color darkElevatedSurface = Color(0xFF1E293B);

  /// تدرجات الشاشات.
  static const Color homeGradientLightFrom = Color(0xFFFDFDFD);
  static const Color homeGradientLightTo = Color(0xFFF5F5F5);
  static const Color homeGradientDarkFrom = Color(0xFF1A1A1A);
  static const Color homeGradientDarkTo = Color(0xFF121212);

  static const Color splashGradientLightFrom = Colors.white;
  static const Color splashGradientLightTo = Color(0xFFF2F7F5);
  static const Color splashGradientDarkFrom = Color(0xFF1A1A1A);
  static const Color splashGradientDarkTo = Color(0xFF0F0F0F);

  /// ألوان صفحات القرآن والأذان والرسوم.
  static const Color quranPageLight = Color(0xFFEFF3F9);
  static const Color quranPageDark = Color(0xFF232B36);

  static const Color adhanGreenDark = Color(0xFF0D3B1E);
  static const Color adhanGreenMid = Color(0xFF145A32);
  static const Color adhanGreenLight = Color(0xFF1A6B3C);

  static const Color mesbahInk = Color(0xFF2D3436);
  static const Color mesbahHighlight = Color(0xFFBDC3C7);

  static const Color guideCanvasLight = Color(0xFFF0F8F3);
  static const Color guideAccent = Color(0xFF0E5E38);

  static const String tajawalFontFamily = 'Tajawal';
  static const String amiriFontFamily = 'Amiri';
  static const String emojiFontFamily = 'NotoColorEmoji';

  static const List<String> emojiFallback = [emojiFontFamily];

  /// الظل الموحّد لبطاقات الشاشة الرئيسية. كان كل بطاقة تختار لونه بنفسه
  /// (أخضر 25% تحت بطاقة ذكر اليوم) فيظهر هالة ملونة أسفلها؛ الظل هنا محايد
  /// ومتناسب مع الوضعين.
  static List<BoxShadow> cardShadow(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  /// حبر النص المحفور داخل بطاقة. الشفافية منخفضة عمداً، فلا يظهر العنوان
  /// واضحاً تماماً: حضوره محسوس أكثر مما هو مقروء.
  static Color engravedInk(Brightness brightness) =>
      mainColor.withValues(alpha: brightness == Brightness.dark ? 0.85 : 0.5);

  /// ظلال النص المحفور. الحافة العليا من الحرف داخل البئر لا يصلها الضوء،
  /// والحافة السفلية تلتقطه. ظل فوق الحرف وظل تحته يجعلان النص يبدو منحوتاً
  /// في البطاقة لا مطبوعاً فوقها.
  static List<Shadow> engravedTextShadows(Brightness brightness) => [
        Shadow(
          color: Colors.black
              .withValues(alpha: brightness == Brightness.dark ? 0.45 : 0.18),
          offset: const Offset(0, -1),
        ),
        Shadow(
          color: Colors.white
              .withValues(alpha: brightness == Brightness.dark ? 0.14 : 0.85),
          offset: const Offset(0, 1),
        ),
      ];

  /// ظل أخف لعناصر GridView الصغيرة.
  static List<BoxShadow> tileShadow(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];

  static TextTheme _withEmojiFallback(TextTheme theme) {
    TextStyle? fb(TextStyle? style) =>
        style?.copyWith(fontFamilyFallback: emojiFallback);
    return TextTheme(
      displayLarge: fb(theme.displayLarge),
      displayMedium: fb(theme.displayMedium),
      displaySmall: fb(theme.displaySmall),
      headlineLarge: fb(theme.headlineLarge),
      headlineMedium: fb(theme.headlineMedium),
      headlineSmall: fb(theme.headlineSmall),
      titleLarge: fb(theme.titleLarge),
      titleMedium: fb(theme.titleMedium),
      titleSmall: fb(theme.titleSmall),
      bodyLarge: fb(theme.bodyLarge),
      bodyMedium: fb(theme.bodyMedium),
      bodySmall: fb(theme.bodySmall),
      labelLarge: fb(theme.labelLarge),
      labelMedium: fb(theme.labelMedium),
      labelSmall: fb(theme.labelSmall),
    );
  }

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
        fontFamilyFallback: emojiFallback,
        fontWeight: FontWeight.w900,
        fontSize: 18.sp,
        color: mainColor,
      ),
    ),
    textTheme: _withEmojiFallback(
      Typography.englishLike2018.apply(
        fontSizeFactor: 1,
        fontFamily: tajawalFontFamily,
        bodyColor: lightText,
        displayColor: lightText,
      ),
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
        fontFamilyFallback: emojiFallback,
        fontWeight: FontWeight.w900,
        fontSize: 18.sp,
        color: Colors.white,
      ),
    ),
    textTheme: _withEmojiFallback(
      Typography.englishLike2018.apply(
        fontSizeFactor: 1,
        fontFamily: tajawalFontFamily,
        bodyColor: darkText,
        displayColor: darkText,
      ),
    ),
  );
}
