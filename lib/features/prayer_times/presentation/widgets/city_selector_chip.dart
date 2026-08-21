import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/prayer_times/presentation/widgets/city_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class CitySelectorChip extends StatelessWidget {
  const CitySelectorChip({super.key});

  Future<void> _openPicker(BuildContext context) async {
    final provider = context.read<PrayerTimesProvider>();
    final currentCityId = provider.selectedCityId;

    final result = await CityPickerSheet.show(
      context,
      selectedCityId: currentCityId,
    );

    if (result == null || !context.mounted) return;

    final isSameCity = !result.isAuto && '${result.city!.id}' == currentCityId;
    if (isSameCity && result.city != null) return;

    if (provider.hasAnyOverrides && context.mounted) {
      final keep = await _confirmOverrides(context);
      if (!context.mounted) return;
      if (!keep) provider.clearAllOverrides();
    }

    final success = await provider.selectCity(result.city);
    if (!context.mounted) return;

    if (!success) {
      AppHelpers.showToast(
        AppStrings.locationUpdateFailed,
        status: ToastStatus.error,
      );
      return;
    }

    await context.read<NotificationProvider>().applyNotificationStates();
    AppHelpers.showToast(AppStrings.prayerTimesUpdated);
  }

  Future<bool> _confirmOverrides(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          AppStrings.manualAdjustmentsTitle,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
        ),
        content: Text(
          AppStrings.manualAdjustmentsBody,
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              AppStrings.keepAdjustments,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              AppStrings.discardAdjustments,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppPalette.mainColor,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, _) {
        final label =
            provider.selectedCityName ?? AppStrings.autoChipLabel;
        final isAuto = provider.isAutoLocation;

        return Semantics(
          button: true,
          label: AppStrings.selectCity,
          child: InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: AppPalette.mainColor.withValues(alpha: 0.2),
                ),
              ),
              constraints: BoxConstraints(maxWidth: 130.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAuto
                        ? Icons.my_location_rounded
                        : Icons.location_on_rounded,
                    size: 16.sp,
                    color: AppPalette.mainColor,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppPalette.darkText
                            : AppPalette.lightText,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18.sp,
                    color: AppPalette.mainColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
