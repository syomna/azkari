import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/models/city.dart';
import 'package:azkar_app/core/services/city_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CitySelectionResult {
  const CitySelectionResult.city(this.city) : isAuto = false;
  const CitySelectionResult.auto()
      : city = null,
        isAuto = true;

  final City? city;
  final bool isAuto;
}

class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key, required this.selectedCityId});

  final String? selectedCityId;

  static Future<CitySelectionResult?> show(
    BuildContext context, {
    required String? selectedCityId,
  }) {
    return showModalBottomSheet<CitySelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet(selectedCityId: selectedCityId),
    );
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<City>? _cities;
  int _arabCount = 0;
  Map<String, String> _countryNames = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cities = await CityService.loadCities();
      Map<String, String> countryNames = const {};
      try {
        countryNames = await CityService.loadCountryNames();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _arabCount = CityService.arabCitiesCount(cities);
        _countryNames = countryNames;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cities = []);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  String _countryName(City city) =>
      CityService.arabCountryNames[city.countryCode] ??
      _countryNames[city.countryCode] ??
      city.countryCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.selectCity,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppStrings.searchCityHint,
                prefixIcon:
                    Icon(Icons.search_rounded, size: 22.sp, color: Colors.grey),
                filled: true,
                fillColor:
                    isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_cities == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.mainColor),
      );
    }

    if (_isSearching) {
      final results = CityService.search(_cities!, _searchController.text);
      if (results.isEmpty) {
        return _buildEmpty(isDark);
      }
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        itemCount: results.length + 1,
        itemBuilder: (context, index) => index == 0
            ? _buildAutoTile(isDark)
            : _buildCityTile(results[index - 1], isDark),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      itemCount: _cities!.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) return _buildAutoTile(isDark);
        if (index == 1) return _buildSectionHeader(AppStrings.arabCitiesSection);
        final listIndex = index - 2;
        if (listIndex == _arabCount) {
          return _buildSectionHeader(AppStrings.worldCitiesSection);
        }
        if (listIndex > _arabCount) {
          return _buildCityTile(_cities![listIndex - 1], isDark);
        }
        return _buildCityTile(_cities![listIndex], isDark);
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: 44.sp, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 10.h),
          Text(
            AppStrings.noResults,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 6.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: AppPalette.mainColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoTile(bool isDark) {
    final isSelected = widget.selectedCityId == null;
    return _CityTile(
      icon: Icons.my_location_rounded,
      title: AppStrings.autoLocationOption,
      subtitle: null,
      isSelected: isSelected,
      highlightColor: AppPalette.mainColor,
      isDark: isDark,
      onTap: () => Navigator.pop(context, const CitySelectionResult.auto()),
    );
  }

  Widget _buildCityTile(City city, bool isDark) {
    final isSelected = '${city.id}' == widget.selectedCityId;
    return _CityTile(
      icon: Icons.location_city_rounded,
      title: city.displayName,
      subtitle: _countryName(city),
      isSelected: isSelected,
      highlightColor: AppPalette.mainColor,
      isDark: isDark,
      onTap: () => Navigator.pop(context, CitySelectionResult.city(city)),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.highlightColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppPalette.darkText : AppPalette.lightText;
    final mutedColor =
        isDark ? AppPalette.darkMutedText : AppPalette.lightMutedText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? highlightColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: isSelected ? highlightColor : mutedColor,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? highlightColor : textColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.sp, color: mutedColor),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    size: 20.sp, color: highlightColor),
            ],
          ),
        ),
      ),
    );
  }
}
