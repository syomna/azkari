import 'dart:io';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/presentation/providers/notification_provider.dart';
import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/prayer_times_settings_page.dart';
import 'package:azkar_app/widgets/switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22.sp)),
        centerTitle: true,
      ),
      body: Consumer4<ThemeProvider, NotificationProvider, TasbehProvider,
          QuranProvider>(
        builder: (context, theme, notify, tasbeh, quran, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              children: [
                _buildSectionHeader('مواقيت الصلاة'),
                _buildSettingsCard([
                  _buildListTile('ضبط مواقيت الصلاة', Icons.access_time_rounded,
                      () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PrayerTimesSettingsScreen()));
                  }),
                ]),

                SizedBox(height: 25.h),
                // 1. Appearance Section
                _buildSectionHeader('المظهر العام'),
                _buildSettingsCard([
                  SwitchTile(
                    title: 'الوضع المظلم',
                    // icon: Icons.dark_mode_rounded,
                    value: !theme.isLight,
                    onChanged: (v) => theme.toggleTheme(),
                  ),
                  _divider(),
                  _divider(),
                  _buildFontSlider(theme, context),
                ]),

                SizedBox(height: 25.h),

                // 2. Notifications Section (Simplified)
                _buildSectionHeader('التنبيهات'),
                _buildSettingsCard([
                  SwitchTile(
                    title: 'تفعيل الإشعارات',
                    // icon: Icons.notifications_active_rounded,
                    value: notify.areNotificationsEnabled,
                    onChanged: (v) => notify.toggleAllNotifications(v),
                  ),
                ]),

                SizedBox(height: 25.h),

                // 3. General Section
                _buildSectionHeader('عام'),

                _buildSettingsCard([
                  _buildListTile('مسح عداد التسبيح', Icons.refresh_rounded, () {
                    tasbeh.resetAll();
                    AppHelpers.showToast('تم مسح العداد!');
                  }),
                  _divider(),
                  _buildListTile('مسح تقدم القرآن', Icons.auto_stories_rounded,
                      () {
                    quran.clearAllSavedQuranValues();
                    AppHelpers.showToast('تم مسح التقدم!');
                  }),
                  _divider(),
                  _buildListTile('مشاركة التطبيق', Icons.share_rounded,
                      () async {
                    final box = context.findRenderObject() as RenderBox?;
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
                      sharePositionOrigin:
                          box!.localToGlobal(Offset.zero) & box.size,
                    ));
                  }),
                  _divider(),
                  _buildListTile('عن التطبيق', Icons.info_rounded,
                      () => _showAboutAppDialog(context, packageInfo)),
                ]),

                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Divider(
          color: Colors.grey.shade300,
        ),
      );
}

// --- UI Helper Methods ---

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: EdgeInsets.only(right: 8.w, bottom: 10.h),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(title,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.grey)),
    ),
  );
}

Widget _buildSettingsCard(List<Widget> children) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05), // For Dark Mode
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.1)),
    ),
    child: Column(children: children),
  );
}

Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: AppPalette.mainColor, size: 22.h),
    title: Text(title,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
    onTap: onTap,
  );
}

Widget _buildFontSlider(ThemeProvider theme, BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(16.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields_rounded,
                color: AppPalette.mainColor, size: 22.h),
            SizedBox(width: 15.w),
            Text('حجم الخط',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
          ],
        ),
        Slider(
          value: theme.textScaleFactor,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          activeColor: AppPalette.mainColor,
          onChanged: (v) => theme.setTextScaleFactor(v),
        ),
      ],
    ),
  );
}

void _showAboutAppDialog(BuildContext context, PackageInfo? packageInfo) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo
            CircleAvatar(
              radius: 40.r,
              backgroundColor: AppPalette.mainColor.withValues(alpha: 0.1),
              child: Image.asset('assets/images/pray.png', width: 50.w),
            ),
            SizedBox(height: 16.h),

            // App Name & Version
            Text('تطبيق أذكاري',
                style: TextStyle(
                    fontFamily: AppPalette.amiriFontFamily,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold)),
            Text('الإصدار ${packageInfo?.version}',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            SizedBox(height: 15.h),

            // Description
            Text(
              'رفيقك في رحلة الذكر والتقرب إلى الله.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  height: 1.5,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),

            SizedBox(height: 20.h),
            Divider(
                color: AppPalette.mainColor.withValues(alpha: 0.1),
                thickness: 1),
            SizedBox(height: 15.h),

            // YOUR NAME (Developer Credit)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code_rounded,
                    size: 16.sp, color: AppPalette.mainColor),
                SizedBox(width: 8.w),
                Text(
                  'تم التطوير بواسطة: يمنى',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.mainColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: 25.h),

            // Close Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r)),
                minimumSize: Size(double.infinity, 45.h),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    ),
  );
}
