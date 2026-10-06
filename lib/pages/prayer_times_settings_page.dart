import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/confirm_dialog.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/widgets/prayer_time_tile.dart';
import 'package:azkar_app/widgets/time_adjustment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PrayerTimesSettingsScreen extends StatelessWidget {
  const PrayerTimesSettingsScreen({super.key});

  static const _prayers = [
    ('fajr', 'الفجر', Icons.brightness_3_rounded),
    ('sunrise', 'الشروق', Icons.wb_twilight_rounded),
    ('dhuhr', 'الظهر', Icons.wb_sunny_rounded),
    ('asr', 'العصر', Icons.cloud_rounded),
    ('maghrib', 'المغرب', Icons.nights_stay_rounded),
    ('isha', 'العشاء', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: true,
        actions: [
          Consumer<PrayerTimesProvider>(
            builder: (context, provider, _) {
              final hasAny = PrayerTimeService.prayerKeys
                  .any((key) => provider.isOverridden(key));
              if (!hasAny) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: InkWell(
                  onTap: () => _confirmResetAll(context, provider),
                  child: Text(
                    'إعادة ضبط الكل',
                    style: TextStyle(
                      color: AppPalette.errorColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, _) {
          if (provider.prayerTimes == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_rounded,
                      size: 48.h, color: Colors.grey.shade400),
                  SizedBox(height: 12.h),
                  Text(
                    'لم يتم تحديد الموقع بعد',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => provider.loadPrayerTimes(),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(color: AppPalette.mainColor)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info banner
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppPalette.mainColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppPalette.mainColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppPalette.mainColor, size: 18.h),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'اضغط على وقت الصلاة لتعديله يدوياً. الأوقات المعدّلة تظهر باللون الأخضر.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppPalette.mainColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  children: [
                    Consumer<NotificationProvider>(
                      builder: (context, notify, _) =>
                          _buildAzkarSection(context, provider, notify),
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionHeader('مواقيت الصلاة'),
                    for (var i = 0; i < _prayers.length; i++) ...[
                      _buildPrayerTile(context, provider, i),
                      if (i < _prayers.length - 1) SizedBox(height: 10.h),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPrayerTime(
      BuildContext context,
      PrayerTimesProvider provider,
      String key,
      String name,
      TimeOfDay? time) async {
    final picked = await _pickTime(context, time ?? TimeOfDay.now(), name);
    if (picked != null && context.mounted) {
      provider.setOverride(key, picked);
      if (context.mounted) {
        final error = await context
            .read<NotificationProvider>()
            .applyNotificationStates();
        if (context.mounted) {
          if (error != null) {
            AppHelpers.showToast(error, status: ToastStatus.error);
          } else {
            AppHelpers.showToast('تم تعديل وقت $name');
          }
        }
      }
    }
  }

  Future<void> _confirmResetAll(
      BuildContext context, PrayerTimesProvider provider) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'إعادة ضبط جميع الأوقات؟',
      message: 'سيتم حذف جميع الأوقات المعدّلة والرجوع للأوقات المحسوبة.',
      confirmLabel: 'إعادة ضبط',
    );
    if (!confirmed || !context.mounted) return;
    provider.clearAllOverrides();
    await context.read<NotificationProvider>().applyNotificationStates();
  }

  Widget _buildPrayerTile(
      BuildContext context, PrayerTimesProvider provider, int index) {
    final (key, name, icon) = _prayers[index];
    final displayTime = provider.getDisplayTime(key);
    final isOverridden = provider.isOverridden(key);

    return PrayerTimeTile(
      name: name,
      icon: icon,
      displayTime: displayTime,
      isOverridden: isOverridden,
      onTap: () => _pickPrayerTime(context, provider, key, name, displayTime),
      onReset: isOverridden
          ? () {
              provider.clearOverride(key);
              context.read<NotificationProvider>().applyNotificationStates();
            }
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w, bottom: 10.h),
      child: Text(title,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.grey)),
    );
  }

  Widget _buildAzkarSection(BuildContext context, PrayerTimesProvider provider,
      NotificationProvider notify) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('أوقات الأذكار'),
        _buildAzkarTile(context, provider, notify, isMorning: true),
        SizedBox(height: 10.h),
        _buildAzkarTile(context, provider, notify, isMorning: false),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildAzkarTile(BuildContext context, PrayerTimesProvider provider,
      NotificationProvider notify,
      {required bool isMorning}) {
    final keyPref =
        isMorning ? PrefsKeys.morningAzkarTime : PrefsKeys.eveningAzkarTime;
    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final custom = notify.azkarTime(keyPref);
    final defaultTime = _azkarDefaultTime(provider, isMorning);

    return PrayerTimeTile(
      name: title,
      icon: icon,
      displayTime: custom ?? defaultTime,
      isOverridden: custom != null,
      onTap: () => _pickAzkarTime(context, notify, keyPref, title,
          custom ?? defaultTime ?? TimeOfDay.now()),
      onReset: custom != null ? () => notify.setAzkarTime(keyPref, null) : null,
    );
  }

  Future<void> _pickAzkarTime(BuildContext context, NotificationProvider notify,
      String keyPref, String title, TimeOfDay initial) async {
    final picked = await _pickTime(context, initial, title);
    if (picked != null && context.mounted) {
      final error = await notify.setAzkarTime(keyPref, picked);
      if (context.mounted) {
        if (error != null) {
          AppHelpers.showToast(error, status: ToastStatus.error);
        } else {
          AppHelpers.showToast('تم تحديث وقت $title');
        }
      }
    }
  }

  /// Single time-picker used by both prayer times and azkar rows. Uses the
  /// app's stepper-based [showTimeAdjustmentSheet] which shows Arabic-Indic
  /// digits regardless of the device keyboard.
  Future<TimeOfDay?> _pickTime(
      BuildContext context, TimeOfDay initial, String helpText) {
    return showTimeAdjustmentSheet(
      context: context,
      prayerName: helpText,
      initialTime: initial,
    );
  }

  /// Default morning/evening azkar time = Fajr+30 / Asr+30 using the effective
  /// (possibly overridden) prayer times.
  TimeOfDay? _azkarDefaultTime(PrayerTimesProvider provider, bool isMorning) {
    final key = isMorning ? 'fajr' : 'asr';
    final t = provider.getDisplayTime(key);
    if (t == null) return null;
    final total = t.hour * 60 + t.minute + 30;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }
}
