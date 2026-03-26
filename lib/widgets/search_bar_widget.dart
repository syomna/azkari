import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.searchController,
    required this.hint,
  });

  final TextEditingController searchController;
  final String hint;
  final Function(String) onChanged;
  final Function() onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 45.h, // Slightly taller for better touch targets
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius:
            BorderRadius.circular(15.r), // Softer, more modern corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppPalette.mainColor.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: TextFormField(
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
          controller: searchController,
          onChanged: onChanged,
          cursorColor: AppPalette.mainColor,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            isDense: true,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppPalette.mainColor,
              size: 20.h,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.cancel_rounded, // Softer circle icon
                      color: Colors.grey.withValues(alpha: 0.5),
                      size: 20.h,
                    ),
                    onPressed: () {
                      searchController.clear();
                      onClear();
                    },
                  )
                : null,
            border: InputBorder.none, // Hide the default underline/border
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}
