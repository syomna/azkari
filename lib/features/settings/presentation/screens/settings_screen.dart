import 'dart:io';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/settings/presentation/screens/prayer_times_settings_screen.dart';
import 'package:azkar_app/features/settings/presentation/widgets/about_app_dialog.dart';
import 'package:azkar_app/features/settings/presentation/widgets/font_slider_tile.dart';
import 'package:azkar_app/features/settings/presentation/widgets/settings_card.dart';
import 'package:azkar_app/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:azkar_app/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/widget_guide/presentation/screens/widget_guide_screen.dart';
import 'package:azkar_app/widgets/switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          children: [
            const SettingsSectionHeader(title: AppStrings.prayerTimes),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: AppStrings.widgetGuideTitle,
                  icon: Icons.widgets_rounded,
                  onTap: () {
                    WidgetGuideScreen.open(
                      context,
                      openedFromSettings: true,
                    );
                  },
                ),
                _divider(),
                SettingsListTile(
                  title: AppStrings.prayerTimesSettings,
                  icon: Icons.access_time_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrayerTimesSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 25.h),
            const SettingsSectionHeader(title: AppStrings.appearance),
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => SettingsCard(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    child: Row(
                      children: [
                        Icon(Icons.brightness_6_rounded,
                            color: AppPalette.mainColor, size: 22.h),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DropdownButtonFormField<ThemeMode>(
                            initialValue: theme.themeMode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: AppPalette.tajawalFontFamily,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(AppStrings.themeAuto),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(AppStrings.themeLight),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(AppStrings.themeDark),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) theme.setThemeMode(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FontSliderTile(),
                ],
              ),
            ),
            SizedBox(height: 25.h),
            const SettingsSectionHeader(title: AppStrings.notifications),
            Consumer<NotificationProvider>(
              builder: (context, notify, _) => SettingsCard(
                children: [
                  SwitchTile(
                    title: AppStrings.enableNotifications,
                    value: notify.areNotificationsEnabled,
                    onChanged: (v) async {
                      final error = await notify.toggleAllNotifications(v);
                      if (!context.mounted) return;
                      if (v == true && error != null) {
                        AppHelpers.showToast(error, status: ToastStatus.error);
                      } else if (v == true && error == null) {
                        AppHelpers.showToast(AppStrings.notificationsEnabled);
                      } else {
                        AppHelpers.showToast(AppStrings.notificationsDisabled);
                      }
                    },
                  ),
                  if (notify.areNotificationsEnabled) ...[
                    _divider(),
                    SwitchTile(
                      title: AppStrings.prayerAdhan,
                      value: notify.isPrayerAdhanEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.prayerAdhanKey, v),
                    ),
                    _divider(),
                    SwitchTile(
                      title: AppStrings.morningEveningAzkar,
                      value: notify.isMorningEveningAzkarEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.morningEveningAzkarKey, v),
                    ),
                    _divider(),
                    SwitchTile(
                      title: AppStrings.randomReminders,
                      value: notify.isPeriodicAzkarEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.periodicAzkarKey, v),
                    ),
                    _divider(),
                    SwitchTile(
                      title: AppStrings.preAdhanReminder,
                      value: notify.isPreAdhanEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.preAdhanKey, v),
                    ),
                    _divider(),
                    SwitchTile(
                      title: AppStrings.quranAfterPrayer,
                      value: notify.isQuranAfterSalahEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.quranAfterSalahKey, v),
                    ),
                    _divider(),
                    SwitchTile(
                      title: AppStrings.prophetBlessings,
                      value: notify.isProphetBlessingsEnabled,
                      onChanged: (v) => notify.toggleNotificationType(
                          NotificationProvider.prophetBlessingsKey, v),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 25.h),
            const SettingsSectionHeader(title: AppStrings.general),
            Consumer2<TasbehProvider, QuranProvider>(
              builder: (context, tasbeh, quran, _) => SettingsCard(
                children: [
                  SettingsListTile(
                    title: AppStrings.resetTasbihCounter,
                    icon: Icons.refresh_rounded,
                    onTap: () => _confirmReset(
                      title: AppStrings.resetTasbihCounter,
                      onConfirm: () {
                        tasbeh.resetAll();
                        AppHelpers.showToast(AppStrings.tasbihReset);
                      },
                    ),
                  ),
                  _divider(),
                  SettingsListTile(
                    title: AppStrings.resetQuranProgress,
                    icon: Icons.auto_stories_rounded,
                    onTap: () => _confirmReset(
                      title: AppStrings.resetQuranProgress,
                      onConfirm: () {
                        quran.clearAllSavedQuranValues();
                        AppHelpers.showToast(AppStrings.quranReset);
                      },
                    ),
                  ),
                  _divider(),
                  SettingsListTile(
                    title: AppStrings.shareApp,
                    icon: Icons.share_rounded,
                    onTap: () async {
                      final box = context.findRenderObject() as RenderBox?;
                      String appStoreLink = '';
                      if (Platform.isIOS) {
                        appStoreLink = AppConstants.appStoreURL;
                      } else if (Platform.isAndroid) {
                        appStoreLink = AppConstants.playStoreURL;
                      }

                      final String shareMessage =
                          '${AppStrings.shareMessage}\n$appStoreLink';

                      ShareParams params = ShareParams(
                        text: shareMessage,
                        subject: AppStrings.shareSubject,
                      );
                      if (box != null && box.hasSize) {
                        params = ShareParams(
                          text: shareMessage,
                          subject: AppStrings.shareSubject,
                          sharePositionOrigin:
                              box.localToGlobal(Offset.zero) & box.size,
                        );
                      }
                      await SharePlus.instance.share(params);
                    },
                  ),
                  _divider(),
                  SettingsListTile(
                    title: AppStrings.aboutApp,
                    icon: Icons.info_rounded,
                    onTap: () => AboutAppDialog.show(context, packageInfo),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Padding _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Divider(
          color: Theme.of(context).dividerColor,
        ),
      );

  void _confirmReset({required String title, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(AppStrings.ok,
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
