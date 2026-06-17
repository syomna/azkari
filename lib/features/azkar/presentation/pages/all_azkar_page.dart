import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/favorite_items_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/add_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_item.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/edit_azkar_bottom_sheet.dart';
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
    'أذكاري',
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

  bool _matchesFilter(String category, AzkarProvider provider) {
    if (_selectedFilter == 'الكل') return true;
    if (_selectedFilter == 'المفضلة') return provider.isCategoryFav(category);

    final isCustom = provider.customCategories.contains(category);
    if (_selectedFilter == 'أذكاري') return isCustom;

    return category.contains(_selectedFilter);
  }

  int _categoryCount(AzkarProvider provider, String category) {
    final assetCount =
        provider.azkarList.where((e) => e.category == category).length;
    if (assetCount > 0) return assetCount;
    return provider.customAzkarList.where((e) => e.category == category).length;
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? 'الكل';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AzkarProvider>().loadFavorites();
        context.read<AzkarProvider>().loadCustomAzkar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dialog to double check before wiping out user inputs
  Future<bool> _showDeleteConfirmation(
      BuildContext context, String category, bool isDark) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text(
              'حذف "$category"',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              'هل أنت متأكد من حذف "$category" وكل الأذكار المضافة بداخله؟',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء',
                    style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('حذف',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAddAzkarBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => AddAzkarBottomSheet(
        onChangeFilter: () {
          setState(() {
            _selectedFilter = 'أذكاري';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azkarProvider = Provider.of<AzkarProvider>(context);

    final List<String> assetCategories =
        azkarProvider.azkarList.map((e) => e.category).toSet().toList();
    final List<String> customCategories = azkarProvider.customCategories;

    final Set<String> allUniqueCategories = {
      ...assetCategories,
      ...customCategories
    };

    List<String> dynamicCategories = [];
    if (_selectedFilter == 'المفضلة') {
      dynamicCategories = List.from(azkarProvider.favCategories);
      for (var cat in customCategories) {
        if (azkarProvider.isCategoryFav(cat) &&
            !dynamicCategories.contains(cat)) {
          dynamicCategories.add(cat);
        }
      }
    } else if (_selectedFilter == 'أذكاري') {
      dynamicCategories = List.from(customCategories);
    } else {
      dynamicCategories = allUniqueCategories.toList();
    }

    final List<String> filteredCategories = dynamicCategories.where((cat) {
      final matchesSearch =
          cat.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _matchesFilter(cat, azkarProvider);
      final isNotShortSurah = cat != AppConstants.shortSurahsTitle;

      return matchesSearch && matchesTab && isNotShortSurah;
    }).toList();

    if (_selectedFilter == 'الكل') {
      filteredCategories.sort((a, b) {
        final aFav = azkarProvider.isCategoryFav(a) ? 0 : 1;
        final bFav = azkarProvider.isCategoryFav(b) ? 0 : 1;
        if (aFav != bFav) return aFav.compareTo(bFav);

        final aStartsAzkar = a.trim().startsWith('أذكار') ? 0 : 1;
        final bStartsAzkar = b.trim().startsWith('أذكار') ? 0 : 1;
        if (aStartsAzkar != bStartsAzkar) {
          return aStartsAzkar.compareTo(bStartsAzkar);
        }

        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    }

    final bool isSurahFav =
        azkarProvider.isCategoryFav(AppConstants.shortSurahsTitle);
    final bool showSurahs =
        AppConstants.shortSurahsTitle.contains(_searchQuery) &&
            (_selectedFilter == 'الكل' ||
                (_selectedFilter == 'المفضلة' && isSurahFav));

    final bool showSavedFolder =
        _selectedFilter == 'المفضلة' && _searchQuery.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.allAzkarPageTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAzkarBottomSheet(context, isDark),
        backgroundColor: AppPalette.mainColor,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة ذكر',
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
              hint: 'ابحث عن ذكر أو دعاء...',
            ),
          ),
          SizedBox(
            height: 44.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
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
                              : AppPalette.mainColor.withValues(alpha: 0.15),
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

          // ── UPDATED: Dynamic Drag Hint Banner ────────────────────
          if (_selectedFilter == 'أذكاري' && filteredCategories.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0.h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppPalette.mainColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppPalette.mainColor.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horizontal_circle_outlined,
                      color: AppPalette.mainColor.withValues(alpha: 0.8),
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'اسحب الذكر لليسار ◀ للحذف، أو لليمين ▶ للتعديل.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 8.h),
          Expanded(
            child: (filteredCategories.isEmpty && !showSurahs)
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                    itemCount: filteredCategories.length +
                        (showSurahs ? 1 : 0) +
                        (showSavedFolder ? 1 : 0),
                    itemBuilder: (context, index) {
                      int adjustedIndex = index;

                      if (showSavedFolder && index == 0) {
                        return _buildSavedItems(azkarProvider, isDark);
                      }
                      if (showSavedFolder) adjustedIndex--;

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

                      final category = filteredCategories[adjustedIndex];
                      final isCustom =
                          azkarProvider.customCategories.contains(category);

                      final azkarItemWidget = AzkarItem(
                        title: category,
                        count: _categoryCount(azkarProvider, category),
                        isCustom: isCustom,
                        isFavorite: azkarProvider.isCategoryFav(category),
                        onFavoriteTap: () =>
                            azkarProvider.toggleCategoryFavorite(category),
                        onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => AzkarDetailsPage(
                                    title: category,
                                    categoryName: category,
                                    isCustomCategory: isCustom))),
                        isDark: isDark,
                      );

                      if (isCustom) {
                        return Dismissible(
                          key: Key('custom_cat_$category'),
                          direction: DismissDirection
                              .horizontal, // التغيير هنا لدعم الاتجاهين
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              // سحب لليسار -> تأكيد الحذف
                              return await _showDeleteConfirmation(
                                  context, category, isDark);
                            } else if (direction ==
                                DismissDirection.startToEnd) {
                              // سحب لليمن -> فتح واجهة التعديل
                              _showEditAzkarBottomSheet(
                                  context, category, azkarProvider, isDark);
                              return false; // يمنع حذف الكارت من القائمة بصرياً بعد انتهاء السحب
                            }
                            return false;
                          },
                          onDismissed: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              await azkarProvider
                                  .deleteCustomCategory(category);
                              if (azkarProvider.isCategoryFav(category)) {
                                azkarProvider.toggleCategoryFavorite(category);
                              }
                              if (context.mounted) {
                                AppHelpers.showToast('تم حذف "$category" بنجاح',
                                    status: ToastStatus.success);
                              }
                            }
                          },
                          // خلفية السحب لليمين (التعديل)
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(Icons.edit, color: Colors.white),
                              ],
                            ),
                          ),
                          // خلفية السحب لليسار (الحذف)
                          secondaryBackground: Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 20.w),
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: azkarItemWidget,
                        );
                      }

                      return azkarItemWidget;
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
      },
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
      child: Text(
        _selectedFilter == 'أذكاري'
            ? 'لا توجد أذكار مخصصة مضافة'
            : 'لم يتم العثور على نتائج',
        style: TextStyle(
            fontSize: 15.sp, color: Colors.grey, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showEditAzkarBottomSheet(BuildContext context, String category,
      AzkarProvider provider, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (context) => EditAzkarBottomSheet(
              category: category,
              currentAzkar: provider.customAzkarList
                  .where((e) => e.category == category)
                  .toList(),
            ));
  }
}
