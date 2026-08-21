import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/app_card.dart';
import 'package:azkar_app/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  PackageInfo? packageInfo;

  bool _isLoading = false;
  bool _emailLaunched = false;

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
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_isLoading || _emailLaunched) return;

    final String subject = _subjectController.text.trim();
    final String userMessage = _messageController.text.trim();

    if (subject.isEmpty || userMessage.isEmpty) {
      AppHelpers.showToast(AppStrings.fillAllFields, status: ToastStatus.warning);
      return;
    }

    setState(() {
      _isLoading = true;
      _emailLaunched = true;
    });

    final String appVersion = packageInfo?.version ?? 'Unknown';
    final String buildNumber = packageInfo?.buildNumber ?? 'Unknown';
    final String platform =
        Theme.of(context).platform.toString().split('.').last;

    final String technicalDetails = '''


  ----------------------------------
  Technical Details (Do not delete):
  - App: Azkari (أذكاري)
  - Version: $appVersion ($buildNumber)
  - Platform: $platform
  - Date: ${DateTime.now().toIso8601String()}
  ----------------------------------
  ''';

    final String formattedSubject = '[AZKARI-SUPPORT] $subject';
    final String fullBody = '$userMessage\n$technicalDetails';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'syomna444@gmail.com',
      query:
          'subject=${Uri.encodeComponent(formattedSubject)}&body=${Uri.encodeComponent(fullBody)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch email app';
      }
    } catch (_) {
      _emailLaunched = false;
      if (mounted) {
        AppHelpers.showToast(AppStrings.emailOpenFailed,
            status: ToastStatus.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          AppStrings.contactUs,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alternate_email_rounded,
                size: 50.sp,
                color: AppPalette.mainColor,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppStrings.contactSubtitle,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppPalette.mainColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              AppStrings.contactDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 35.h),
            AppCard(
              padding: EdgeInsets.all(20.w),
              borderRadius: BorderRadius.circular(25.r),
              shadowColor: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              borderColor: AppPalette.mainColor.withValues(alpha: 0.1),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _subjectController,
                    label: AppStrings.subjectLabel,
                    hint: AppStrings.subjectHint,
                    icon: Icons.subject_rounded,
                  ),
                  SizedBox(height: 20.h),
                  CustomTextField(
                    controller: _messageController,
                    label: AppStrings.messageLabel,
                    hint: AppStrings.messageHint,
                    icon: Icons.chat_bubble_outline_rounded,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            SizedBox(height: 35.h),
            GestureDetector(
              onTap: _isLoading ? null : _sendEmail,
              child: Container(
                width: double.infinity,
                height: 55.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  gradient: LinearGradient(
                    colors: [
                      AppPalette.mainColor,
                      AppPalette.mainColor.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.mainColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, color: Colors.white),
                    SizedBox(width: 12.w),
                    Text(
                      _isLoading ? AppStrings.loadingProgress : AppStrings.sendNow,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 50.h),
            Text(
              'الإصدار ${packageInfo?.version ?? ''}',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              '${AppStrings.copyright} ${DateTime.now().year}',
              style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6), fontSize: 11.sp),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
