import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AllAzkarPage extends StatefulWidget {
  const AllAzkarPage({super.key});

  @override
  State<AllAzkarPage> createState() => _AllAzkarPageState();
}

class _AllAzkarPageState extends State<AllAzkarPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // دالة ذكية لاختيار أيقونة النظام بناءً على اسم القسم
  IconData _getIconData(String title) {
    if (title.contains('الصباح')) return Icons.wb_sunny_rounded;
    if (title.contains('المساء')) return Icons.dark_mode_rounded;
    if (title.contains('النوم')) return Icons.bedtime_rounded;
    if (title.contains('الاستيقاظ')) return Icons.alarm_on_rounded;
    if (title.contains('المنزل')) return Icons.home_rounded;
    if (title.contains('الصلاة')) return Icons.mosque_rounded;
    if (title.contains('المسجد')) return Icons.account_balance_rounded;
    if (title.contains('تسابيح')) return Icons.all_inclusive_rounded;
    if (title.contains('وضوء')) return Icons.waves_rounded;
    if (title.contains('ثوب')) return Icons.checkroom_rounded;
    if (title.contains('خلاء')) return Icons.clean_hands_rounded;
    if (title.contains('السور')) return Icons.menu_book_rounded;
    if (title.contains('دعاء') || title.contains('أدعية')) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.article_rounded; // أيقونة افتراضية للأقسام الأخرى
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azkarProvider = Provider.of<AzkarProvider>(context);

    // استخراج التصنيفات الفريدة وتصفيتها
    List<String> dynamicCategories =
        azkarProvider.azkarList.map((e) => e.category).toSet().toList();

    List<String> filteredCategories =
        dynamicCategories.where((cat) => cat.contains(_searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.allAzkarPageTitle,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22.sp)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: SearchBarWidget(
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
              searchController: _searchController,
              hint: 'ابحث عن ذكر أو دعاء...',
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 120.h),
              // دمج "السور القصيرة" مع القائمة الديناميكية لسهولة الإدارة
              itemCount: filteredCategories.length +
                  (AppConstants.shortSurahsTitle.contains(_searchQuery)
                      ? 1
                      : 0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                // منطق عرض السور القصيرة
                if (index == 0 && _searchQuery.isEmpty) {
                  return _buildCategoryCard(
                      context,
                      AppConstants.shortSurahsTitle,
                      _getIconData(AppConstants.shortSurahsTitle),
                      const SurahListPage(),
                      isDark);
                }

                final category = filteredCategories[
                    _searchQuery.isEmpty ? index - 1 : index];
                return _buildCategoryCard(
                  context,
                  category,
                  _getIconData(category),
                  AzkarCategoryPage(title: category, categoryName: category),
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon,
      Widget page, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(
          context, CupertinoPageRoute(builder: (context) => page)),
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppPalette.mainColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppPalette.mainColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: AppPalette.mainColor,
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
