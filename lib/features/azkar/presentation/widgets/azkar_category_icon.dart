import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

/// أيقونة الموضوع ولونها، مشتقّان من اسم الموضوع حتى يبدو كل موضوع بلون
/// يميّزه داخل الشبكة، وتشترك فيها بطاقات الموضوع المختلفة حتى لا يختلف
/// الشكل بينها.
({IconData icon, Color color}) azkarCategoryIcon(String title) {
  // الأدعية أولاً: كل موضوعات الأدعية في مكتبة واحدة فتأخذ أيقونة واحدة.
  // وفحصها قبل غيره لأن بعض عناوين الأدعية تحتوي كلمات الأذكار التي لها
  // أيقونات ("دعاء النوم"، "الدعاء بعد الصلاة") فلا يصل بينها.
  if (isDuaCategory(title)) {
    return (icon: FlutterIslamicIcons.prayer, color: AppPalette.mainColor);
  }
  if (title.contains('الصباح')) {
    return (icon: Icons.wb_sunny_rounded, color: Colors.orange);
  }
  if (title.contains('المساء') || title.contains('النوم')) {
    return (icon: Icons.nightlight_round, color: Colors.indigo);
  }
  if (title.contains('صلاة') ||
      title.contains('الآذان') ||
      title.contains('المسجد')) {
    return (icon: Icons.mosque_rounded, color: AppPalette.mainColor);
  }
  if (title.contains('المحفوظة') ||
      title.contains(AppConstants.favoriteCategory)) {
    return (
      icon: Icons.folder_special_rounded,
      color: AppPalette.favoriteColor
    );
  }
  if (title.contains('سورة')) {
    return (icon: Icons.menu_book_rounded, color: Colors.teal);
  }
  // ما بقي بلا كلمة مميّزة: أيقونة الصلاة، وهي أعمّ ما في المجموعة. كان
  // الطبقات الفارغة بلا معنى ورسماً يُوهم بشيء آخر.
  return (icon: FlutterIslamicIcons.prayingPerson, color: AppPalette.mainColor);
}

/// صياغة العدد مع تعديده الذي يتّفق معه، مثل "٣ أذكار" أو "١٠ ذكراً"، أو
/// بصيغة الدعاء مثل "٣ أدعية" عندما يكون [count] عدد أدعية.
String azkarCountLabel(int count, String? override, {bool dua = false}) {
  if (override != null) return override;
  if (dua) {
    if (count == 1) return 'دعاء';
    if (count == 2) return 'دعاءان';
    if (count <= 10) return 'أدعية';
    return 'دعاءً';
  }
  if (count == 1) return 'ذكر';
  if (count == 2) return 'ذكران';
  if (count <= 10) return 'أذكار';
  return 'ذكراً';
}
