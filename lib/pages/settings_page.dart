import 'dart:io';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:azkar_app/core/presentation/providers/notification_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer4<ThemeProvider, NotificationProvider, TasbehProvider,
          QuranProvider>(
        builder: (context, themeProvider, notificationProvider, tasbehProvider,
            quranProvider, child) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: Text(
                      'الوضع المظلم',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    activeColor: AppPalette.mainColor,
                    value: themeProvider.isLight == false,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'حجم الخط',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: themeProvider.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: themeProvider.textScaleFactor.toStringAsFixed(1),
                    onChanged: (newValue) {
                      themeProvider.setTextScaleFactor(newValue);
                    },
                    activeColor: AppPalette.mainColor,
                    inactiveColor:
                        AppPalette.mainColor.withAlpha((255 * 0.3).round()),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'هذا نص تجريبي لمعاينة حجم الخط.',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'الإشعارات',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(
                      'تفعيل الإشعارات',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    activeColor: AppPalette.mainColor,
                    value: notificationProvider.areNotificationsEnabled,
                    onChanged: (bool value) {
                      notificationProvider.toggleAllNotifications(value);
                    },
                  ),
                  SwitchListTile(
                    title: Text(
                      'إشعارات أذكار الصباح',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    activeColor: AppPalette.mainColor,
                    value:
                        notificationProvider.isMorningAzkarNotificationEnabled,
                    onChanged: (bool value) {
                      notificationProvider
                          .toggleMorningAzkarNotification(value);
                    },
                  ),
                  SwitchListTile(
                    title: Text(
                      'إشعارات أذكار المساء',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    activeColor: AppPalette.mainColor,
                    value:
                        notificationProvider.isEveningAzkarNotificationEnabled,
                    onChanged: (bool value) {
                      notificationProvider
                          .toggleEveningAzkarNotification(value);
                    },
                  ),
                  SwitchListTile(
                    title: Text(
                      'إشعارات تذكير دوري',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    activeColor: AppPalette.mainColor,
                    value: notificationProvider.isPeriodicNotificationEnabled,
                    onChanged: (bool value) {
                      notificationProvider.togglePeriodicNotification(value);
                    },
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'عام',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: Text('مسح عداد التسبيح',
                        style: TextStyle(fontSize: 16.sp)),
                    trailing: const Icon(Icons.refresh),
                    onTap: () {
                      tasbehProvider.resetAll();
                      AppHelpers.showToast('تم مسح عداد التسبيح بنجاح!');
                    },
                  ),
                  ListTile(
                    title: Text('مسح تقدمك في القرآن',
                        style: TextStyle(fontSize: 16.sp)),
                    trailing: const Icon(Icons.refresh),
                    onTap: () {
                      quranProvider.clearAllSavedQuranValues();
                      AppHelpers.showToast('تم مسح تقدمك بنجاح!');
                    },
                  ),
                  ListTile(
                    title: Text('مشاركة التطبيق',
                        style: TextStyle(fontSize: 16.sp)),
                    trailing: const Icon(Icons.share),
                    onTap: () async {
                      String appStoreLink = '';
                      if (Platform.isIOS) {
                        appStoreLink = AppConstants.appStoreURL;
                      } else if (Platform.isAndroid) {
                        appStoreLink = AppConstants.playStoreURL;
                      }

                      final String shareMessage =
                          'تطبيق أذكاري - رفيقك اليومي للذكر والدعاء. حمله الآن!\n$appStoreLink';

                      await SharePlus.instance.share(ShareParams(
                        text: shareMessage,
                        subject: 'تطبيق أذكاري',
                      ));
                    },
                  ),
                  ListTile(
                    title:
                        Text('عن التطبيق', style: TextStyle(fontSize: 16.sp)),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () {
                      _showAboutAppDialog(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appName = packageInfo.appName;
    final String version = packageInfo.version;
    final String buildNumber = packageInfo.buildNumber;
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: appName,
        applicationVersion: '$version ($buildNumber)',
        applicationIcon: Image.asset(
          'assets/images/pray.png',
          width: 50.w,
          height: 50.h,
        ),
        children: <Widget>[
          SizedBox(height: 15.h),
          Text(
            'تطبيق أذكاري هو رفيقك اليومي للذكر والدعاء، مصمم لمساعدتك على الحفاظ على وردك اليومي من الأذكار الصباحية والمسائية، والتسبيح، وأسماء الله الحسنى، وسور القرآن الكريم.',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            'تم التطوير بواسطة: يمنى', // Replace with your name or handle
            style: TextStyle(fontSize: 14.sp),
          ),
        ],
      );
    }
  }
}
