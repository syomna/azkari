import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AzkarFilterChips extends StatelessWidget {
  const AzkarFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = selectedFilter == filter;
          return Semantics(
            label: filter,
            selected: isActive,
            button: true,
            child: InkWell(
            onTap: () => onFilterSelected(filter),
            borderRadius: BorderRadius.circular(20.r),
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
            )
          );
        },
      ),
    );
  }
}
