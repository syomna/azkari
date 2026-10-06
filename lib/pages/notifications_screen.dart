import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Dedicated screen for managing all notifications, reached from the settings
/// screen. Keeps settings page focused on navigation instead of stacking every
/// notification toggle on it.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التنبيهات'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Consumer<NotificationProvider>(
          builder: (context, notify, _) => _buildSettingsCard([
            SwitchTile(
              title: 'تفعيل الإشعارات',
              value: notify.areNotificationsEnabled,
              onChanged: (v) async {
                final error = await notify.toggleAllNotifications(v);
                if (!context.mounted) return;
                if (v == true && error != null) {
                  AppHelpers.showToast(error, status: ToastStatus.error);
                } else if (v == true && error == null) {
                  AppHelpers.showToast('تم تفعيل الإشعارات');
                } else {
                  AppHelpers.showToast('تم إيقاف الإشعارات');
                }
              },
            ),
            if (notify.areNotificationsEnabled) ...[
              _divider(),
              SwitchTile(
                title: 'أذان الصلاة',
                value: notify.isPrayerAdhanEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.prayerAdhanKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'أذكار الصباح والمساء',
                value: notify.isMorningEveningAzkarEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.morningEveningAzkarKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'تذكيرات عشوائية',
                value: notify.isPeriodicAzkarEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.periodicAzkarKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'تذكير ما قبل الأذان',
                value: notify.isPreAdhanEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.preAdhanKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'ورد القرآن بعد الصلاة',
                value: notify.isQuranAfterSalahEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.quranAfterSalahKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'الصلاة على النبي ﷺ',
                value: notify.isProphetBlessingsEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.prophetBlessingsKey, v),
              ),
              _divider(),
              SwitchTile(
                title: 'المناسبات الإسلامية',
                value: notify.isIslamicEventsEnabled,
                onChanged: (v) => notify.toggleNotificationType(
                    NotificationProvider.islamicEventsKey, v),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Divider(color: Colors.grey.shade300),
      );

  Widget _buildSettingsCard(List<Widget> children) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: isDark ? AppPalette.darkElevatedSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side:
                BorderSide(color: AppPalette.mainColor.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        );
      },
    );
  }
}
