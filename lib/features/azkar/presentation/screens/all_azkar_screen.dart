import 'dart:async';

import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/favorites_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/screens/azkar_details_screen.dart';
import 'package:azkar_app/features/azkar/presentation/screens/favorite_items_screen.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/add_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/azkar_item.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/edit_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/surah/presentation/screens/surah_list_screen.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/widgets/app_bottom_sheet_wrapper.dart';
import 'package:azkar_app/widgets/app_empty_state.dart';
import 'package:azkar_app/widgets/azkar_filter_chips.dart';
import 'package:azkar_app/widgets/fade_slide_page_route.dart';
import 'package:azkar_app/widgets/search_bar_widget.dart';
import 'package:azkar_app/widgets/swipe_instruction_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AllAzkarScreen extends StatefulWidget {
  const AllAzkarScreen({super.key, this.selectedFilter});

  final String? selectedFilter;

  @override
  State<AllAzkarScreen> createState() => _AllAzkarScreenState();
}

class _AllAzkarScreenState extends State<AllAzkarScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = AppStrings.allCategories;
  Timer? _debounceTimer;

  final List<String> _filters = [
    AppStrings.favorites,
    AppStrings.myAzkar,
    AppStrings.allCategories,
    AppStrings.filterMorning,
    AppStrings.filterEvening,
    AppStrings.filterSleep,
    AppStrings.filterAdhan,
    AppStrings.filterMosque,
    AppStrings.filterPrayer,
    AppStrings.filterFood,
    AppStrings.filterHome,
    AppStrings.filterRuqyah,
    AppStrings.filterHajj,
  ];

  bool _matchesFilter(String category, AzkarProvider provider, FavoritesProvider favoritesProvider) {
    if (_selectedFilter == AppStrings.allCategories) return true;
    if (_selectedFilter == AppStrings.favorites) return favoritesProvider.isCategoryFav(category);

    final isCustom = provider.customCategories.contains(category);
    if (_selectedFilter == AppStrings.myAzkar) return isCustom;

    return category.contains(_selectedFilter);
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? AppStrings.allCategories;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesProvider>().loadFavorites();
        context.read<AzkarProvider>().loadCustomAzkar();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, String category, bool isDark) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text(
              '${AppStrings.deleteCategory} "$category"',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              '${AppStrings.deleteConfirm} "$category" ${AppStrings.deleteConfirmSuffix}',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.cancel,
                    style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(AppStrings.deleteCategory,
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
    AppBottomSheetWrapper.show(
      context: context,
      builder: (context) => AddAzkarBottomSheet(
        onChangeFilter: () {
          setState(() {
            _selectedFilter = AppStrings.myAzkar;
          });
        },
      ),
    );
  }

  /// Build a unified, flat list of items so we no longer need adjustedIndex math.
  /// Each entry is a tagged union: 'surah', 'saved', or 'category'.
  List<_ListItem> _buildUnifiedList(
    AzkarProvider azkarProvider,
    FavoritesProvider favoritesProvider,
    bool showSurahs,
    bool showSavedFolder,
    bool isSurahFav,
  ) {
    final items = <_ListItem>[];

    if (showSavedFolder) {
      items.add(_SavedFolderItem());
    }

    if (showSurahs) {
      items.add(_SurahItem(isFavorite: isSurahFav));
    }

    final customCategories = azkarProvider.customCategories;
    final allUniqueCategories = azkarProvider.allCategories;

    List<String> dynamicCategories;
    if (_selectedFilter == AppStrings.favorites) {
      dynamicCategories = List.from(favoritesProvider.favCategories);
      for (var cat in customCategories) {
        if (favoritesProvider.isCategoryFav(cat) &&
            !dynamicCategories.contains(cat)) {
          dynamicCategories.add(cat);
        }
      }
    } else if (_selectedFilter == AppStrings.myAzkar) {
      dynamicCategories = List.from(customCategories);
    } else {
      dynamicCategories = List.from(allUniqueCategories);
    }

    final filteredCategories = dynamicCategories.where((cat) {
      final matchesSearch =
          cat.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _matchesFilter(cat, azkarProvider, favoritesProvider);
      final isNotShortSurah = cat != AppStrings.shortSurahsTitle;
      return matchesSearch && matchesTab && isNotShortSurah;
    }).toList();

    if (_selectedFilter == AppStrings.allCategories) {
      filteredCategories.sort((a, b) {
        final aFav = favoritesProvider.isCategoryFav(a) ? 0 : 1;
        final bFav = favoritesProvider.isCategoryFav(b) ? 0 : 1;
        if (aFav != bFav) return aFav.compareTo(bFav);

        final aStartsAzkar = a.trim().startsWith('\u0623\u0630\u0643\u0627\u0631') ? 0 : 1;
        final bStartsAzkar = b.trim().startsWith('\u0623\u0630\u0643\u0627\u0631') ? 0 : 1;
        if (aStartsAzkar != bStartsAzkar) {
          return aStartsAzkar.compareTo(bStartsAzkar);
        }

        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    }

    for (final cat in filteredCategories) {
      items.add(_CategoryItem(category: cat));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azkarProvider = Provider.of<AzkarProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final bool isSurahFav =
        favoritesProvider.isCategoryFav(AppStrings.shortSurahsTitle);
    final bool showSurahs =
        AppStrings.shortSurahsTitle.contains(_searchQuery) &&
            (_selectedFilter == AppStrings.allCategories ||
                (_selectedFilter == AppStrings.favorites && isSurahFav));

    final bool showSavedFolder =
        _selectedFilter == AppStrings.favorites && _searchQuery.isEmpty;

    final unifiedList = _buildUnifiedList(
        azkarProvider, favoritesProvider, showSurahs, showSavedFolder, isSurahFav);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.allAzkarTitle),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: AppStrings.addZikr,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddAzkarBottomSheet(context, isDark),
          backgroundColor: AppPalette.mainColor,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            AppStrings.addZikr,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
            child: SearchBarWidget(
              onChanged: _onSearchChanged,
              onClear: () => setState(() {
                _debounceTimer?.cancel();
                _searchController.clear();
                _searchQuery = '';
              }),
              searchController: _searchController,
              hint: AppStrings.searchHint,
            ),
          ),
          AzkarFilterChips(
            filters: _filters,
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) => setState(() {
              _selectedFilter = filter;
            }),
          ),

          if (_selectedFilter == AppStrings.myAzkar && unifiedList.isNotEmpty)
            const SwipeInstructionBanner(),

          SizedBox(height: 8.h),
          Expanded(
            child: unifiedList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppPalette.mainColor,
                    onRefresh: () async {
                      final favProvider = context.read<FavoritesProvider>();
                      final azkarProv = context.read<AzkarProvider>();
                      await favProvider.loadFavorites();
                      await azkarProv.loadCustomAzkar();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: unifiedList.length,
                      itemBuilder: (context, index) {
                        final item = unifiedList[index];
                        return item.build(
                          context: context,
                          azkarProvider: azkarProvider,
                          favoritesProvider: favoritesProvider,
                          isDark: isDark,
                          onDeleteConfirmation: (category) =>
                              _showDeleteConfirmation(context, category, isDark),
                          onEdit: (category) => _showEditAzkarBottomSheet(
                              context, category, azkarProvider, isDark),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      title: _selectedFilter == AppStrings.myAzkar
          ? AppStrings.noCustomAzkar
          : AppStrings.noResults,
      icon: Icons.search_off_rounded,
    );
  }

  void _showEditAzkarBottomSheet(BuildContext context, String category,
      AzkarProvider provider, bool isDark) {
    AppBottomSheetWrapper.show(
        context: context,
        builder: (context) => EditAzkarBottomSheet(
              category: category,
              currentAzkar: provider.customAzkarList
                  .where((e) => e.category == category)
                  .toList(),
            ));
  }
}

// ---------------------------------------------------------------------------
// Unified list item hierarchy
// ---------------------------------------------------------------------------

sealed class _ListItem {
  Widget build({
    required BuildContext context,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favoritesProvider,
    required bool isDark,
    required Future<bool> Function(String category) onDeleteConfirmation,
    required void Function(String category) onEdit,
  });
}

class _SavedFolderItem extends _ListItem {
  _SavedFolderItem();

  @override
  Widget build({
    required BuildContext context,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favoritesProvider,
    required bool isDark,
    required Future<bool> Function(String category) onDeleteConfirmation,
    required void Function(String category) onEdit,
  }) {
    final items = favoritesProvider.favIndividualItems;
    if (items.isEmpty) return const SizedBox.shrink();
    return AzkarItem(
      title: AppStrings.savedItems,
      count: items.length,
      itemLabel: AppStrings.material,
      isFavorite: true,
      onFavoriteTap: () {
        for (final item in items) {
          favoritesProvider.toggleItemFavorite(item);
        }
      },
      onTap: () {
        Navigator.of(context).push(FadeSlidePageRoute(
          page: const FavoriteItemsScreen(),
        ));
      },
      isDark: isDark,
    );
  }
}

class _SurahItem extends _ListItem {
  _SurahItem({required this.isFavorite});

  final bool isFavorite;

  @override
  Widget build({
    required BuildContext context,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favoritesProvider,
    required bool isDark,
    required Future<bool> Function(String category) onDeleteConfirmation,
    required void Function(String category) onEdit,
  }) {
    return AzkarItem(
      title: AppStrings.shortSurahsTitle,
      count: context.read<SurahProvider>().surahList.length,
      itemLabel: AppStrings.categorySurah,
      isFavorite: isFavorite,
      onFavoriteTap: () =>
          favoritesProvider.toggleCategoryFavorite(AppStrings.shortSurahsTitle),
      onTap: () => Navigator.push(
          context, FadeSlidePageRoute(page: const SurahListScreen())),
      isDark: isDark,
    );
  }
}

class _CategoryItem extends _ListItem {
  _CategoryItem({required this.category});

  final String category;

  @override
  Widget build({
    required BuildContext context,
    required AzkarProvider azkarProvider,
    required FavoritesProvider favoritesProvider,
    required bool isDark,
    required Future<bool> Function(String category) onDeleteConfirmation,
    required void Function(String category) onEdit,
  }) {
    final isCustom = azkarProvider.customCategories.contains(category);

    final azkarItem = AzkarItem(
      title: category,
      count: azkarProvider.categoryCounts[category] ?? 0,
      isCustom: isCustom,
      isFavorite: favoritesProvider.isCategoryFav(category),
      onFavoriteTap: () =>
          favoritesProvider.toggleCategoryFavorite(category),
      onTap: () => Navigator.push(
          context,
          FadeSlidePageRoute(
              page: AzkarDetailsScreen(
                  title: category,
                  categoryName: category,
                  isCustomCategory: isCustom))),
      isDark: isDark,
    );

    if (!isCustom) return azkarItem;

    return Semantics(
      label: '$category, swipe to edit or delete',
      child: Dismissible(
        key: Key('custom_cat_$category'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await onDeleteConfirmation(category);
          } else if (direction == DismissDirection.startToEnd) {
            onEdit(category);
            return false;
          }
          return false;
        },
        onDismissed: (direction) async {
          if (direction == DismissDirection.endToStart) {
            if (favoritesProvider.isCategoryFav(category)) {
              favoritesProvider.toggleCategoryFavorite(category);
            }
            await azkarProvider.deleteCustomCategory(category);
            if (context.mounted) {
              AppHelpers.showToast(
                  '${AppStrings.deleteSuccess} "$category" ${AppStrings.deleteSuccessSuffix}',
                  status: ToastStatus.success);
            }
          }
        },
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
        secondaryBackground: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 20.w),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: azkarItem,
      ),
    );
  }
}
