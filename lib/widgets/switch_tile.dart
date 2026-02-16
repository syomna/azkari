import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      activeThumbColor: AppPalette.mainColor,
      value: value,
      onChanged: onChanged,
    );
  }
}
