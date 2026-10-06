import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/confirm_dialog.dart';
import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/favorite_items_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_form_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_grid_item.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// مكتبة موضوعات على هيئة شبكة من عمودين بثلاثة تبويبات: المواضيع المدمجة،
/// والمواضيع التي أضافها المستخدم، والمفضلة. تستخدمه صفحتا الأذكار والأدعية
/// لأنهما تفترقان في الموضوعات فقط: كل موضوع إما ذكر وإما دعاء باسمه.
///
/// ليست صفحة بذاتها لأن صفحتَي الأذكار والأدعية غلافان يمرّران [kind]، فلا
/// يتكرّر منطق التبويبات والشبكة والسحب والإضافة في ملفّين.
class AzkarCategoryBrowser extends StatefulWidget {
  const AzkarCategoryBrowser({
    super.key,
    required this.kind,
    this.initialFilter,
  });

  /// أي مكتبة يعرضها: الأذكار أم الأدعية. الفرق كله في الموضوعات المضمّنة
  /// وتسميات التبويبات وزر الإضافة، والتنسيق واحد.
  final AzkarLibrary kind;

  /// يُستخدم عند فتح الصفحة من اختصار أو إشعار ليبدأ على التبويب المناسب
  /// ("أذكاري"/"أدعيتي" أو "المفضلة") بدل تبويب العرض.
  final String? initialFilter;

  @override
  State<AzkarCategoryBrowser> createState() => _AzkarCategoryBrowserState();
}

class _AzkarCategoryBrowserState extends State<AzkarCategoryBrowser>
    with SingleTickerProviderStateMixin {
  static const String _favoritesTab = 'المفضلة';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final TabController _tabController;

  bool get _isDua => widget.kind == AzkarLibrary.dua;

  /// الموضوعات المضافة من المستخدم تنتمي لمكتبة واحدة: الموضوع الذي عنوانه
  /// موضوع دعاء لا يظهر في مكتبة الأذكار، والعكس. فالتصنيف بالاسم نفسه الذي
  /// تستعمله [isDuaCategory] في صفحة الأدعية.
  bool _belongsToLibrary(String category) => libraryOf(category) == widget.kind;

  String get _allTab => _isDua ? 'الأدعية' : 'الأذكار';
  String get _mineTab => _isDua ? 'أدعيتي' : 'أذكاري';
  String get _pageTitle =>
      _isDua ? AppConstants.ad3yaPageTitle : AppConstants.allAzkarPageTitle;
  String get _searchHint => _isDua ? 'ابحث عن دعاء...' : 'ابحث عن ذكر...';
  String get _addLabel => _isDua ? 'إضافة دعاء' : 'إضافة ذكر';
  String get _emptyAll => _isDua ? 'لا توجد أدعية' : 'لا توجد أذكار';
  String get _emptyMine =>
      _isDua ? 'لا توجد أدعية مضافة' : 'لا توجد أذكار مخصصة مضافة';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (widget.initialFilter) {
        final String tab when tab == _mineTab => 1,
        final String tab when tab == _favoritesTab => 2,
        _ => 0,
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesProvider>().loadFavorites();
        context.read<AzkarProvider>().loadCustomAzkar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Dialog to double check before wiping out user inputs
  Future<bool> _showDeleteConfirmation(BuildContext context, String category) {
    final String noun = _isDua ? 'الأدعية' : 'الأذكار';
    return showConfirmDialog(
      context,
      title: 'حذف "$category"',
      message: 'هل أنت متأكد من حذف "$category" وكل $noun المضافة بداخله؟',
      confirmLabel: 'حذف',
    );
  }

  void _showAddBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppPalette.darkElevatedSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => AzkarFormSheet(
        kind: widget.kind,
        // الإضافة تُنشئ موضوعاً مخصصاً، فتبقى في تبويب "أذكاري".
        onChangeFilter: () => _tabController.animateTo(1),
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, String category,
      AzkarProvider provider, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? AppPalette.darkElevatedSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (context) => AzkarFormSheet(
              initialCategory: category,
              currentAzkar: provider.customAzkarList
                  .where((e) => e.category == category)
                  .toList(),
            ));
  }

  /// ارتفاع بطاقة الموضوع. مركّب من نفس وحدات البطاقة نفسها (حشو + أيقونة +
  /// فاصل + سطرا عنوان + سطر العدد) بدل رقم ثابت: الرقم الثابت كان يطفح على
  /// الشاشات الطويلة لأن الحشو والفواصل تنمو بـ.h بينما سطرا العنوان ينموان
  /// بمقياس النصّ وحده.
  double _cardExtent(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return 20.w + // حشو البطاقة
        36.w + // دائرة الأيقونة
        10.h + // الفاصلان بين الأيقونة والعنوان والعدد
        (2 * 12 * 1.3 + 10 * 1.2) * textScale + // سطرا العنوان وسطر العدد
        8; // هامش تنفّس
  }

  int _categoryCount(AzkarProvider provider, String category) {
    // Match the source the details page actually displays: a category with any
    // custom entries (even one sharing an asset category's name) is shown as
    // custom, so report the custom count for it.
    final customCount =
        provider.customAzkarList.where((e) => e.category == category).length;
    if (customCount > 0) return customCount;
    return provider.azkarList.where((e) => e.category == category).length;
  }

  /// أبجدياً مع تفضيل المواضيع المفضّلة أولاً في تبويب العرض، فهو الترتيب
  /// الذي اعتاده المستخدم في المكتبة.
  List<String> _sortedByFavoriteFirst(
      List<String> categories, FavoritesProvider favorites) {
    final sorted = List<String>.from(categories);
    sorted.sort((a, b) {
      final aFav = favorites.isCategoryFav(a) ? 0 : 1;
      final bFav = favorites.isCategoryFav(b) ? 0 : 1;
      if (aFav != bFav) return aFav.compareTo(bFav);
      return a.compareTo(b);
    });
    return sorted;
  }

  /// يبني شبكة من عمودين لموضوعات [categories].
  Widget _buildGrid(
    BuildContext context,
    List<String> categories, {
    required bool isDark,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favorites,
  }) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        // الطول لا النسبة: النسبة تقصّ العنوان عند تكبير الخط. ويُمدّ الطول
        // مع معامل النصّ حتى تبقى البطاقة تسع سطرين منه عند 2x.
        mainAxisExtent: _cardExtent(context),
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isCustom = azkarProvider.customCategories.contains(category);

        return _wrapSwipeIfCustom(
          category: category,
          isCustom: isCustom,
          isDark: isDark,
          azkarProvider: azkarProvider,
          favorites: favorites,
          child: AzkarGridItem(
            title: category,
            count: _categoryCount(azkarProvider, category),
            isDua: _isDua,
            isFavorite: favorites.isCategoryFav(category),
            onFavoriteTap: () => favorites.toggleCategoryFavorite(category),
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => AzkarDetailsPage(
                  title: category,
                  categoryName: category,
                  isCustomCategory: isCustom,
                ),
              ),
            ),
            isDark: isDark,
          ),
        );
      },
    );
  }

  /// الموضوعات المخصصة وحدها تُسحب للتعديل والحذف؛ ما عداها تفتح الصفحة.
  Widget _wrapSwipeIfCustom({
    required String category,
    required bool isCustom,
    required bool isDark,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favorites,
    required Widget child,
  }) {
    if (!isCustom) return child;

    return Dismissible(
      key: Key('custom_cat_$category'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // RTL: start = اليمين، end = اليسار.
        // endToStart = سحب لليمين -> تعديل. startToEnd = لليسار -> حذف.
        if (direction == DismissDirection.startToEnd) {
          // startToEnd = سحب لليسار -> تأكيد الحذف
          final confirmed = await _showDeleteConfirmation(context, category);
          if (!confirmed) return false;
          // Delete BEFORE the card leaves the tree. If the delete fails, keep
          // the card (return false); otherwise the card must not show a
          // dismissed state or the swap can't be rolled back.
          final ok = await azkarProvider.deleteCustomCategory(category);
          if (!ok) {
            if (context.mounted) {
              AppHelpers.showToast('فشل حذف "$category"، حاول مرة أخرى',
                  status: ToastStatus.error);
            }
            return false;
          }
          // Drop favourite references so saved items and the category aren't
          // left orphaned after delete.
          await favorites.removeCategoryItemFavorites(category);
          await favorites.removeCategoryFavorite(category);
          if (context.mounted) {
            AppHelpers.showToast('تم حذف "$category" بنجاح',
                status: ToastStatus.success);
          }
          return true;
        } else if (direction == DismissDirection.endToStart) {
          // endToStart = سحب لليمين -> فتح واجهة التعديل
          _showEditBottomSheet(context, category, azkarProvider, isDark);
          return false; // يمنع حذف الكارت من القائمة بصرياً بعد انتهاء السحب
        }
        return false;
      },
      onDismissed: (_) {},
      // خلفية السحب لليسار (الحذف)
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppPalette.errorColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // خلفية السحب لليمين (التعديل)
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: Colors.amber[700],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(String emptyMessage, bool isDark) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          isSearching ? 'لم يتم العثور على نتائج' : emptyMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.sp,
            color: isDark ? Colors.white60 : Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// تبويب المفضلة: قائمة موضوعات هذه المكتبة فقط. بطاقة "المحفوظات" والسور
  /// القصيرة من مدخلات صفحة الأذكار، فتبقيان في تبويبها هي.
  Widget _buildFavoritesTab(
    BuildContext context,
    List<String> favoriteCategories, {
    required SurahProvider surahProvider,
    required bool isDark,
    required AzkarProvider azkarProvider,
  }) {
    final FavoritesProvider favorites = context.read<FavoritesProvider>();

    /// بطاقة "المحفوظات" تفتح صفحة الأذكار والآيات المحفوظة، وهي مدخل
    /// مستقل عن الموضوعات لأنه يفتح قائمة لا موضوعاً.
    final bool showSavedFolder = !_isDua && _searchQuery.trim().isEmpty;
    final int savedCount = favorites.favIndividualItems.length;

    final bool showSurahs = !_isDua &&
        favorites.isCategoryFav(AppConstants.shortSurahsTitle) &&
        AppConstants.shortSurahsTitle.contains(_searchQuery.trim());

    final int total = favoriteCategories.length +
        (showSurahs ? 1 : 0) +
        (showSavedFolder ? 1 : 0);

    if (total == 0) {
      return _buildEmptyState('لا توجد مفضلات بعد', isDark);
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        mainAxisExtent: _cardExtent(context),
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        int listIndex = index;

        if (showSavedFolder) {
          if (listIndex == 0) {
            return AzkarGridItem(
              title: 'الأذكار والآيات المحفوظة',
              count: savedCount,
              itemLabel: 'مادة',
              isFavorite: true,
              onFavoriteTap: () => _confirmClearSavedItems(context, favorites),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoriteItemsPage(),
                ),
              ),
              isDark: isDark,
            );
          }
          listIndex--;
        }

        if (showSurahs) {
          if (listIndex == 0) {
            return AzkarGridItem(
              title: AppConstants.shortSurahsTitle,
              count: surahProvider.surahList.length,
              itemLabel: 'سورة',
              isFavorite: true,
              onFavoriteTap: () => favorites
                  .toggleCategoryFavorite(AppConstants.shortSurahsTitle),
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const SurahListPage()),
              ),
              isDark: isDark,
            );
          }
          listIndex--;
        }

        final category = favoriteCategories[listIndex];
        final isCustom = azkarProvider.customCategories.contains(category);

        return AzkarGridItem(
          title: category,
          count: _categoryCount(azkarProvider, category),
          isDua: _isDua,
          isFavorite: true,
          onFavoriteTap: () => favorites.toggleCategoryFavorite(category),
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => AzkarDetailsPage(
                title: category,
                categoryName: category,
                isCustomCategory: isCustom,
              ),
            ),
          ),
          isDark: isDark,
        );
      },
    );
  }

  Future<void> _confirmClearSavedItems(
      BuildContext context, FavoritesProvider provider) async {
    final items = List.of(provider.favIndividualItems);
    if (items.isEmpty) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'إزالة كل المحفوظات؟',
      message:
          'سيتم إزالة جميع الأذكار والآيات المحفوظة (${items.length} مادة) من المفضلة.',
      confirmLabel: 'إزالة الكل',
    );
    if (!confirmed) return;
    for (final item in items) {
      await provider.toggleItemFavorite(item);
    }
    AppHelpers.showToast('تمت إزالة جميع المحفوظات');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AzkarProvider azkarProvider = context.watch<AzkarProvider>();
    final FavoritesProvider favorites = context.watch<FavoritesProvider>();
    final SurahProvider surahProvider = context.watch<SurahProvider>();

    final String query = _searchQuery.trim().toLowerCase();

    /// موضوعات هذه المكتبة: المدمجة والمخصصة معاً، بترتيب أبجدي. مكتبة
    /// الأذكار لا تعرض موضوعات الأدعية والعكس، وكل موضوع إما في هذه أو تلك.
    final List<String> allCategories = () {
      final Set<String> unique = {
        ...azkarProvider.azkarList.map((e) => e.category),
        ...azkarProvider.customCategories,
      };
      final list = unique
          .where((cat) =>
              cat != AppConstants.shortSurahsTitle && _belongsToLibrary(cat))
          .toList()
        ..sort((a, b) => a.compareTo(b));
      return list;
    }();

    final List<String> visibleCategories = allCategories
        .where((cat) => cat.toLowerCase().contains(query))
        .toList();

    final List<String> mineCategories = azkarProvider.customCategories
        .where((cat) =>
            _belongsToLibrary(cat) && cat.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    /// المفضلة مقسومة إلى قائمتين، وكل صفحة ترى قائمتها: موضوعات الأذكار في
    /// تبويب الأذكار، وموضوعات الأدعية في تبويب الأدعية.
    final List<String> favoriteCategories = (_isDua
            ? favorites.favDuaCategories
            : favorites.favAzkarCategories)
        .where((cat) =>
            allCategories.contains(cat) && cat.toLowerCase().contains(query))
        .toList();

    /// عدد ما يعرضه التبويب المفتوح، للشريط في الأعلى.
    final int visibleCount = switch (_tabController.index) {
      1 => mineCategories.length,
      2 => favoriteCategories.length +
          (_isDua
              ? 0
              : (_searchQuery.trim().isEmpty ? 1 : 0) +
                  (favorites.isCategoryFav(AppConstants.shortSurahsTitle) &&
                          AppConstants.shortSurahsTitle.contains(query)
                      ? 1
                      : 0)),
      _ => visibleCategories.length,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          // AnimatedBuilder لتتغيّر كلمة العدد مع تبديل التبويب.
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Center(
                child: Text(
                  '${AppHelpers.getArabicNumber(visibleCount)} موضوع',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBottomSheet(context, isDark),
        backgroundColor: AppPalette.mainColor,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _addLabel,
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
            child: SearchBarWidget(
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
              searchController: _searchController,
              hint: _searchHint,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppPalette.mainColor,
            unselectedLabelColor:
                isDark ? Colors.white54 : AppPalette.lightMutedText,
            indicatorColor: AppPalette.mainColor,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: [
              _buildTab(Icons.menu_book_rounded, _allTab),
              _buildTab(Icons.edit_note_rounded, _mineTab),
              _buildTab(Icons.star_rounded, _favoritesTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                visibleCategories.isEmpty
                    ? _buildEmptyState(_emptyAll, isDark)
                    : _buildGrid(
                        context,
                        _sortedByFavoriteFirst(visibleCategories, favorites),
                        isDark: isDark,
                        azkarProvider: azkarProvider,
                        favorites: favorites,
                      ),
                mineCategories.isEmpty
                    ? _buildEmptyState(_emptyMine, isDark)
                    : _buildGrid(
                        context,
                        mineCategories,
                        isDark: isDark,
                        azkarProvider: azkarProvider,
                        favorites: favorites,
                      ),
                _buildFavoritesTab(
                  context,
                  favoriteCategories,
                  surahProvider: surahProvider,
                  isDark: isDark,
                  azkarProvider: azkarProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 6.w),
          // التبويب بعرض الثلث على كل الأحجام: النص يتقلّص بدل أن يطفح
          // عندما يطوّر المستخدم الخط.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
