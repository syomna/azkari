import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/favorite_items_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_item.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AllAzkarPage extends StatefulWidget {
  const AllAzkarPage({super.key, this.selectedFilter});

  final String? selectedFilter;

  @override
  State<AllAzkarPage> createState() => _AllAzkarPageState();
}

class _AllAzkarPageState extends State<AllAzkarPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'الكل';

  final List<String> _filters = [
    'المفضلة',
    'الكل',
    'الصباح',
    'المساء',
    'النوم',
    'الآذان',
    'المسجد',
    'الصلاة',
    'الطعام',
    'المنزل',
    'الرُّقية الشرعية',
    'الحج',
  ];

  bool _matchesFilter(String category) {
    if (_selectedFilter == 'الكل') return true;
    if (_selectedFilter == 'المفضلة') {
      return true; // Handled by display list logic
    }
    return category.contains(_selectedFilter);
  }

  int _categoryCount(AzkarProvider provider, String category) {
    return provider.azkarList.where((e) => e.category == category).length;
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? 'الكل';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AzkarProvider>().loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azkarProvider = Provider.of<AzkarProvider>(context);

    // 1. Determine dynamic categories based on filter
    List<String> dynamicCategories;
    if (_selectedFilter == 'المفضلة') {
      dynamicCategories = azkarProvider.favCategories;
    } else {
      dynamicCategories =
          azkarProvider.azkarList.map((e) => e.category).toSet().toList();
    }

    // 2. Filter & Search
    final List<String> filteredCategories = dynamicCategories
        .where((cat) =>
            cat.contains(_searchQuery) &&
            _matchesFilter(cat) &&
            cat != AppConstants.shortSurahsTitle)
        .toList();

    // 3. Sort: Favorites bubble to top in "All" view
    if (_selectedFilter == 'الكل') {
      filteredCategories.sort((a, b) {
        // 1. Primary Sort: Favorites first
        final aFav = azkarProvider.isCategoryFav(a) ? 0 : 1;
        final bFav = azkarProvider.isCategoryFav(b) ? 0 : 1;

        if (aFav != bFav) {
          return aFav.compareTo(bFav);
        }

        // 2. Secondary Sort: Categories starting with "أذكار" first
        final aStartsWaitAzkar = a.trim().startsWith('أذكار') ? 0 : 1;
        final bStartsWaitAzkar = b.trim().startsWith('أذكار') ? 0 : 1;

        if (aStartsWaitAzkar != bStartsWaitAzkar) {
          return aStartsWaitAzkar.compareTo(bStartsWaitAzkar);
        }

        // 3. Tertiary Sort: Alphabetical (Optional, for a cleaner look)
        return a.compareTo(b);
      });
    }

    // 4. Surahs visibility logic
    final bool isSurahFav =
        azkarProvider.isCategoryFav(AppConstants.shortSurahsTitle);
    final bool showSurahs =
        AppConstants.shortSurahsTitle.contains(_searchQuery) &&
            (_selectedFilter == 'الكل' ||
                (_selectedFilter == 'المفضلة' && isSurahFav));

    // 5. Individual Saved Items (Expandable folder)
    final bool showSavedFolder =
        _selectedFilter == 'المفضلة' && _searchQuery.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.allAzkarPageTitle),
        centerTitle: true,
        elevation: 0,
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
              hint: 'ابحث عن ذكر أو دعاء...',
            ),
          ),
          SizedBox(
            height: 44.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = _selectedFilter == filter;
                return InkWell(
                  onTap: () => setState(() {
                    _selectedFilter = filter;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppPalette.mainColor
                          : AppPalette.mainColor
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : AppPalette.mainColor.withValues(alpha: 0.2),
                          width: 0.5),
                    ),
                    child: Center(
                      child: Text(filter,
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : AppPalette.mainColor)),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: (filteredCategories.isEmpty && !showSurahs)
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 120.h),
                    itemCount: filteredCategories.length +
                        (showSurahs ? 1 : 0) +
                        (showSavedFolder ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(
                      height: 0,
                      thickness: 0.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, index) {
                      int adjustedIndex = index;

                      // --- 1. Saved Individual Items Expansion Folder ---
                      if (showSavedFolder && index == 0) {
                        return _buildSavedItems(azkarProvider, isDark);
                      }
                      if (showSavedFolder) adjustedIndex--;

                      // --- 2. Short Surahs Card ---
                      if (adjustedIndex == 0 &&
                          showSurahs &&
                          _searchQuery.isEmpty) {
                        return AzkarItem(
                          title: AppConstants.shortSurahsTitle,
                          count: context.read<SurahProvider>().surahList.length,
                          itemLabel: 'سورة',
                          isFavorite: isSurahFav,
                          onFavoriteTap: () =>
                              azkarProvider.toggleCategoryFavorite(
                                  AppConstants.shortSurahsTitle),
                          onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) => const SurahListPage())),
                          isDark: isDark,
                        );
                      }
                      if (showSurahs && _searchQuery.isEmpty) adjustedIndex--;

                      // --- 3. Dynamic Categories ---
                      final category = filteredCategories[adjustedIndex];
                      return AzkarItem(
                        title: category,
                        count: _categoryCount(azkarProvider, category),
                        isFavorite: azkarProvider.isCategoryFav(category),
                        onFavoriteTap: () =>
                            azkarProvider.toggleCategoryFavorite(category),
                        onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => AzkarDetailsPage(
                                    title: category, categoryName: category))),
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedItems(AzkarProvider provider, bool isDark) {
    final items = provider.favIndividualItems;
    if (items.isEmpty) return const SizedBox.shrink();
    return AzkarItem(
      title: 'الأذكار والآيات المحفوظة',
      count: items.length,
      itemLabel: 'مادة',
      isFavorite: true,
      onFavoriteTap: () {
        for (final item in items) {
          provider.toggleItemFavorite(item);
        }
      }, // Folder container
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const FavoriteItemsPage(),
        ));
      },
      isDark: isDark,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('لم يتم العثور على نتائج',
          style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w500)),
    );
  }
}
