import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_category_browser.dart';
import 'package:flutter/material.dart';

/// صفحة الأدعية: غلاف يمرّر النوع [AzkarLibrary.dua] إلى
/// [AzkarCategoryBrowser]. تسرد موضوعات الأدعية على هيئة شبكة من عمودين
/// بثلاثة تبويبات — الأدعية وأدعيتي والمفضلة — وتضيف دعاءً جديداً مثل ما
/// تفعل صفحة الأذكار بالأذكار.
class Ad3yaPage extends StatelessWidget {
  const Ad3yaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AzkarCategoryBrowser(
      key: ValueKey('dua_browser'),
      kind: AzkarLibrary.dua,
    );
  }
}
