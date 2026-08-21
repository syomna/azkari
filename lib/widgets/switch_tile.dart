import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Semantics(
        label: title,
        toggled: value,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(!value);
            },
            splashColor: AppPalette.mainColor.withValues(alpha: 0.08),
            highlightColor: AppPalette.mainColor.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  IgnorePointer(
                    child: Switch(
                      value: value,
                      activeThumbColor: AppPalette.mainColor,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        onChanged(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
