import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget(
      {super.key,
      required this.onChanged,
      required this.onClear,
      required this.searchController,
      required this.hint});

  final TextEditingController searchController;
  final String hint;
  final Function(String) onChanged;
  final Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 45.h,
        child: TextFormField(
          style: TextStyle(fontSize: 14.sp),
          controller: searchController,
          onChanged: onChanged,
          cursorColor: AppPalette.mainColor,
          decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search,
                color: AppPalette.mainColor,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppPalette.mainColor,
                      ),
                      onPressed: onClear,
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                  borderSide: BorderSide(
                    color: AppPalette.mainColor.withValues(alpha: 0.5),
                  )),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                  borderSide: BorderSide(
                    color: AppPalette.mainColor.withValues(alpha: 0.2),
                  )),
              hintText: hint),
        ),
      ),
    );
  }
}
