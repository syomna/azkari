import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// A dropdown-styled control in the top bar that shows the currently selected
/// city (or a placeholder) and opens the [showCityPicker] sheet on tap.
class CityDropdownButton extends StatelessWidget {
  const CityDropdownButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, _) {
        final isAuto = provider.cityName == null;
        return Material(
          color: isDark ? Colors.white12 : Colors.white,
          shape: StadiumBorder(
            side: BorderSide(
              color: isDark ? Colors.white24 : AppPalette.mainColor,
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPicker(context, provider),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Icon(
                        isAuto
                            ? Icons.my_location_rounded
                            : Icons.location_city_rounded,
                        size: 16,
                        color: AppPalette.mainColor),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 110.w),
                      child: Text(
                        isAuto ? 'تلقائي' : provider.cityName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppPalette.mainColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  const Flexible(
                    child: Icon(Icons.arrow_drop_down,
                        size: 18, color: AppPalette.mainColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPicker(
      BuildContext context, PrayerTimesProvider provider) async {
    final selection =
        await showCityPicker(context, currentCity: provider.cityName);
    if (selection == null || !context.mounted) return;

    if (selection.isAutomatic) {
      final ok = await provider.useCurrentLocation();
      if (context.mounted) {
        if (ok) {
          context.read<NotificationProvider>().applyNotificationStates();
          AppHelpers.showToast('تم تفعيل الموقع التلقائي');
        } else {
          AppHelpers.showToast('تعذر الحصول على موقعك، تحقق من الإعدادات',
              status: ToastStatus.error);
        }
      }
      return;
    }

    await provider.setCity(selection.city!);
    if (context.mounted) {
      context.read<NotificationProvider>().applyNotificationStates();
      AppHelpers.showToast(
          'تم اختيار ${selection.city!.name} - ${selection.city!.country}');
    }
  }
}
