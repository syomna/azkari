import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_category_browser.dart';
import 'package:flutter/material.dart';

/// صفحة مكتبة الأذكار: غلاف يمرّر النوع [AzkarLibrary.azkar] إلى
/// [AzkarCategoryBrowser]، والمنطق كله هناك لتتقاسمه مع صفحة الأدعية.
class AllAzkarPage extends StatelessWidget {
  const AllAzkarPage({super.key, this.selectedFilter});

  /// يُستخدم عند فتح الصفحة من اختصار أو إشعار ليبدأ على التبويب المناسب
  /// ("أذكاري" أو "المفضلة") بدل تبويب الأذكار.
  final String? selectedFilter;

  @override
  Widget build(BuildContext context) {
    return AzkarCategoryBrowser(
      key: const ValueKey('azkar_browser'),
      kind: AzkarLibrary.azkar,
      initialFilter: selectedFilter,
    );
  }
}
