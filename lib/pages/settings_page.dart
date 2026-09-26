import 'dart:io';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/notifications_screen.dart';
import 'package:azkar_app/pages/prayer_times_settings_page.dart';
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

  Future<void> _confirmClear(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              message,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء',
                    style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(confirmLabel,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          children: [
            _buildSectionHeader('مواقيت الصلاة'),
            _buildSettingsCard([
              _buildListTile(
                  'مواقيت الصلاة والأذكار', Icons.access_time_rounded, () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PrayerTimesSettingsScreen()));
              }, subtitle: 'ضبط أوقات الصلاة وأذكار الصباح والمساء'),
            ]),
            SizedBox(height: 25.h),
            _buildSectionHeader('المظهر العام'),
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => _buildSettingsCard([
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode_rounded,
                          color: AppPalette.mainColor, size: 22.h),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text('مظهر التطبيق',
                            style: TextStyle(
                                fontSize: _rowTitleFontSize,
                                fontWeight: FontWeight.w500)),
                      ),
                      DropdownButton<ThemeMode>(
                        value: theme.themeMode,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(14.r),
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: AppPalette.mainColor),
                        items: const [
                          DropdownMenuItem(
                              value: ThemeMode.system, child: Text('تلقائي')),
                          DropdownMenuItem(
                              value: ThemeMode.light, child: Text('فاتح')),
                          DropdownMenuItem(
                              value: ThemeMode.dark, child: Text('داكن')),
                        ],
                        onChanged: (mode) {
                          if (mode != null) theme.setThemeMode(mode);
                        },
                      ),
                    ],
                  ),
                ),
                _divider(),
                _buildFontSlider(theme, context),
              ]),
            ),
            SizedBox(height: 25.h),
            _buildSectionHeader('التنبيهات'),
            _buildSettingsCard([
              _buildListTile('إدارة الإشعارات', Icons.notifications_rounded,
                  () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()));
              }, subtitle: 'أذان الصلاة وأذكار الصباح والمساء والتذكيرات'),
            ]),
            SizedBox(height: 25.h),
            _buildSectionHeader('عام'),
            _buildSettingsCard([
              _buildListTile('مسح عداد التسبيح', Icons.refresh_rounded, () {
                _confirmClear(context,
                    title: 'مسح عداد التسبيح؟',
                    message:
                        'سيتم تصفير إجمالي التسبيحات وعداد الجلسة نهائياً.',
                    confirmLabel: 'مسح الكل', onConfirm: () async {
                  await context.read<TasbehProvider>().resetAll();
                  AppHelpers.showToast('تم مسح العداد!');
                });
              }),
              _divider(),
              _buildListTile('مسح تقدم القرآن', Icons.auto_stories_rounded, () {
                _confirmClear(context,
                    title: 'مسح تقدم القرآن؟',
                    message: 'سيتم حذف آخر سورة ورقم الصفحة المحفوظين.',
                    confirmLabel: 'مسح التقدم', onConfirm: () async {
                  await context
                      .read<QuranProvider>()
                      .clearAllSavedQuranValues();
                  AppHelpers.showToast('تم مسح التقدم!');
                });
              }),
              _divider(),
              _buildListTile('مشاركة التطبيق', Icons.share_rounded, () async {
                final box = context.findRenderObject() as RenderBox?;
                String appStoreLink = '';
                if (Platform.isIOS) {
                  appStoreLink = AppConstants.appStoreURL;
                } else if (Platform.isAndroid) {
                  appStoreLink = AppConstants.playStoreURL;
                }

                final String shareMessage =
                    'تطبيق أذكاري - رفيقك اليومي للذكر والدعاء. حمله الآن!\n$appStoreLink';

                ShareParams params = ShareParams(
                  text: shareMessage,
                  subject: 'تطبيق أذكاري',
                );
                if (box != null && box.hasSize) {
                  params = ShareParams(
                    text: shareMessage,
                    subject: 'تطبيق أذكاري',
                    sharePositionOrigin:
                        box.localToGlobal(Offset.zero) & box.size,
                  );
                }
                await SharePlus.instance.share(params);
              }),
              _divider(),
              _buildListTile('عن التطبيق', Icons.info_rounded,
                  () => _showAboutAppDialog(context, packageInfo)),
            ]),
            SizedBox(height: 40.h),
          ],
        ),
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

final double _sectionHeaderFontSize = 14.sp;
final double _rowTitleFontSize = 15.sp;
final double _rowSubtitleFontSize = 12.sp;

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: EdgeInsets.only(right: 8.w, bottom: 10.h),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(title,
          style: TextStyle(
              fontSize: _sectionHeaderFontSize,
              fontWeight: FontWeight.w900,
              color: Colors.grey)),
    ),
  );
}

Widget _buildSettingsCard(List<Widget> children) {
  return Builder(
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppPalette.mainColor.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
    },
  );
}

Widget _buildListTile(String title, IconData icon, VoidCallback onTap,
    {String? subtitle}) {
  return ListTile(
    tileColor: Colors.transparent,
    leading: Icon(icon, color: AppPalette.mainColor, size: 22.h),
    title: Text(title,
        style: TextStyle(
            fontSize: _rowTitleFontSize, fontWeight: FontWeight.w500)),
    subtitle: subtitle != null
        ? Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(subtitle,
                style: TextStyle(
                    fontSize: _rowSubtitleFontSize,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400)),
          )
        : null,
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
                style: TextStyle(
                    fontSize: _rowTitleFontSize, fontWeight: FontWeight.w500)),
          ],
        ),
        Slider(
          value: theme.textScaleFactor.clamp(0.8, 1.5).toDouble(),
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
        child: SingleChildScrollView(
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
                  Flexible(
                    child: Text(
                      'تم التطوير بواسطة: يمنى',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.mainColor,
                      ),
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
    ),
  );
}
