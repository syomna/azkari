import 'package:azkar_app/core/constants/app_cities.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The result of the city picker: either the user chose Automatic (GPS) or a
/// specific [AppCity] was picked.
class CitySelection {
  final AppCity? city;

  /// `true` when the "Automatic location" (GPS) option was chosen.
  bool get isAutomatic => city == null;

  const CitySelection.auto() : city = null;

  const CitySelection.city(AppCity this.city);
}

/// Shows a bottom sheet listing an "Automatic (GPS)" option followed by
/// cities from across the world (Arabic countries first), each grouped under a
/// region header, with a live search field matching city name and country.
///
/// Returns the chosen [CitySelection], or `null` if the user dismisses it.
Future<CitySelection?> showCityPicker(
  BuildContext context, {
  String? currentCity,
}) {
  return showModalBottomSheet<CitySelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      minHeight: 0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) => _CityPickerSheet(currentCity: currentCity),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({this.currentCity});

  final String? currentCity;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  /// Automatic option (always shown) followed by cities in list order.
  List<Object> _buildItems() {
    final q = _query.trim();
    final cities = _query.isEmpty
        ? appCities
        : appCities
            .where((c) =>
                c.name.contains(q) ||
                c.country.contains(q) ||
                _normalize(q).isNotEmpty &&
                    (_normalize(c.name).contains(_normalize(q)) ||
                        _normalize(c.country).contains(_normalize(q))))
            .toList();

    final items = <Object>[const _AutoOption()];
    String? lastRegion;
    for (final city in cities) {
      if (city.region != lastRegion) {
        items.add(city.region);
        lastRegion = city.region;
      }
      items.add(city);
    }
    return items;
  }

  String _normalize(String s) => s.replaceAll(RegExp('\\s+'), '');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildItems();
    final isAuto = widget.currentCity == null;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.darkElevatedSurface : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      // Transparent Material below the decorated container gives the ListTiles
      // a Material ancestor so ink ripples render over the sheet background
      // (the framework otherwise asserts the tiles' ink is hidden).
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 20.h),
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
                'اختر المدينة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.mainColor,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                textAlign: TextAlign.right,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مدينة أو دولة...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppPalette.mainColor),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _AutoOption) {
                      return _buildTile(
                        icon: Icons.my_location_rounded,
                        title: 'الموقع الحالي (تلقائي)',
                        subtitle: 'استخدام موقع جهازك لحساب المواقيت',
                        checked: isAuto,
                        onTap: () => Navigator.of(context)
                            .pop(const CitySelection.auto()),
                      );
                    }
                    if (item is String) {
                      return _SectionHeader(region: item);
                    }
                    final city = item as AppCity;
                    final selected = city.name == widget.currentCity;
                    return _buildTile(
                      icon: Icons.location_city_rounded,
                      title: city.name,
                      subtitle: city.country,
                      checked: selected,
                      onTap: () =>
                          Navigator.of(context).pop(CitySelection.city(city)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppPalette.mainColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: checked
          ? const Icon(Icons.check_circle_rounded, color: AppPalette.mainColor)
          : null,
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.region});

  final String region;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 2.h),
      child: Text(
        regionHeaders[region] ?? region,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: AppPalette.mainColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _AutoOption {
  const _AutoOption();
}
