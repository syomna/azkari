import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared confirmation dialog used before destructive or resetting actions.
///
/// Returns `true` only when the user confirms; `false` when cancelled or
/// dismissed. A single home for the app's confirm-chrome (rounded surface,
/// right-aligned Arabic copy, pill confirm button) so call sites stop
/// re-implementing the same ~25 lines. Destructive actions keep the default
/// [confirmColor]; non-destructive resets pass `AppPalette.mainColor`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'إلغاء',
  Color confirmColor = AppPalette.errorColor,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppPalette.darkElevatedSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
