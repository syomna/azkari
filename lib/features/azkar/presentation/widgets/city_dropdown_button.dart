import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// A dropdown-styled control that shows the currently selected city (or a
/// placeholder) and opens the [showCityPicker] sheet on tap.
class CityDropdownButton extends StatelessWidget {
  /// Small variant for tight spaces such as the prayer-times section header,
  /// where the control has to read as a caption next to the title rather than
  /// as a toolbar action. Behaviour and colours are identical; only the
  /// metrics shrink.
  final bool compact;

  const CityDropdownButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelSize = compact ? 10.5 : 13.0;
    final placeIconSize = compact ? 12.0 : 16.0;
    final arrowSize = compact ? 14.0 : 18.0;
    final borderWidth = compact ? 1.0 : 1.2;

    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, _) {
        final isAuto = provider.cityName == null;
        return Material(
          color: isDark ? Colors.white12 : Colors.white,
          shape: StadiumBorder(
            side: BorderSide(
              color: isDark ? Colors.white24 : AppPalette.mainColor,
              width: borderWidth,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPicker(context, provider),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7.w : 12.w,
                vertical: compact ? 4.h : 8.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Icon(
                        isAuto
                            ? Icons.my_location_rounded
                            : Icons.location_city_rounded,
                        size: placeIconSize,
                        color: AppPalette.mainColor),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: ConstrainedBox(
                      // The compact pill shares a row with the section title, so
                      // it gives up width first and lets the name ellipsize.
                      constraints: BoxConstraints(
                        maxWidth: compact ? 74.w : 110.w,
                      ),
                      child: Text(
                        isAuto ? 'تلقائي' : provider.cityName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: labelSize.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppPalette.mainColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Icon(Icons.arrow_drop_down,
                        size: arrowSize, color: AppPalette.mainColor),
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
