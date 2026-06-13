import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
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
    final TextEditingController titleController = TextEditingController();

    // Kept synchronized to handle both the text content and the targeted execution count smoothly
    List<TextEditingController> zikrControllers = [TextEditingController()];
    List<TextEditingController> countControllers = [
      TextEditingController(text: '1')
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20.w,
              right: 20.w,
              top: 20.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'إضافة أذكار جديدة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: titleController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'عنوان الأذكار (مثال: أذكار السفر)',
                      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'النصوص والأدعية',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            zikrControllers.add(TextEditingController());
                            countControllers
                                .add(TextEditingController(text: '1'));
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('إضافة نص آخر'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppPalette.mainColor),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 220.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: zikrControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            // Changed to .start so both fields align smoothly from the top boundary
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (zikrControllers.length > 1)
                                Padding(
                                  // Added top padding to align the delete button perfectly with the inputs
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: IconButton(
                                    onPressed: () {
                                      setModalState(() {
                                        zikrControllers[index].dispose();
                                        countControllers[index].dispose();
                                        zikrControllers.removeAt(index);
                                        countControllers.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                  ),
                                ),
                              // Counter Input Field Container
                              SizedBox(
                                width: 60.w,
                                child: TextField(
                                  controller: countControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: '1',
                                    labelText: 'المرات',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelStyle: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppPalette.mainColor),
                                    // Added explicit content padding matching the main text field's structural height
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 14.h, horizontal: 4.w),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.black12
                                        : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // Zikr Text Input Field
                              Expanded(
                                child: TextField(
                                  controller: zikrControllers[index],
                                  maxLines: 2,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 13.sp),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'نص الذكر رقم ${index + 1}...',
                                    hintStyle: TextStyle(
                                        fontSize: 12.sp, color: Colors.grey),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 14.h, horizontal: 12.w),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.black12
                                        : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();

                      // Match pairs safely together
                      final List<Map<String, dynamic>> structuredAzkar = [];
                      for (int i = 0; i < zikrControllers.length; i++) {
                        final text = zikrControllers[i].text.trim();
                        final countVal =
                            int.tryParse(countControllers[i].text.trim()) ?? 1;
                        if (text.isNotEmpty) {
                          structuredAzkar.add({
                            'text': text,
                            'count': countVal,
                          });
                        }
                      }

                      if (title.isNotEmpty && structuredAzkar.isNotEmpty) {
                        // 👈 Pass structured data down to provider
                        await context
                            .read<AzkarProvider>()
                            .saveCustomAzkarCategory(
                              categoryTitle: title,
                              azkarItems: structuredAzkar,
                            );

                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {
                            _selectedFilter = 'أذكاري';
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'حفظ الكل',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
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

          // ── NEW: Dynamic Drag-To-Delete Hint Banner ────────────────────
          if (_selectedFilter == 'أذكاري' && filteredCategories.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0.h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.redAccent.withValues(alpha: 0.06)
                      : Colors.redAccent.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_left_alt_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'يمكنك سحب الذكر المخصص من اليسار إلى اليمين لحذفه.',
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
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await _showDeleteConfirmation(
                                context, category, isDark);
                          },
                          onDismissed: (direction) async {
                            await azkarProvider.deleteCustomCategory(category);
                            // remove from favorites if it was favorited
                            if (azkarProvider.isCategoryFav(category)) {
                              azkarProvider.toggleCategoryFavorite(category);
                            }
                            if (context.mounted) {
                              AppHelpers.showToast('تم حذف "$category" بنجاح',
                                  status: ToastStatus.success);
                            }
                          },
                          background: Container(
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
}
