import 'dart:developer';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
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
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final String subject = _subjectController.text.trim();
    final String message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      AppHelpers.showToast('يرجى ملء جميع الحقول', status: ToastStatus.warning);
      return;
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'syomna444@gmail.com',
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      log(e.toString());
      if (mounted) {
        AppHelpers.showToast('تعذر فتح تطبيق البريد الإلكتروني',
            status: ToastStatus.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'تواصل معنا',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22.sp),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            // 1. Decorative Header Icon
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
              'يسعدنا سماع اقتراحاتكم',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppPalette.mainColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'سوف نقوم بالرد عليكم في أقرب وقت ممكن',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 35.h),

            // 2. Form Container (Card Style)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(
                  color: AppPalette.mainColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _subjectController,
                    label: 'موضوع الرسالة',
                    hint: 'اقتراح، شكوى، استفسار...',
                    icon: Icons.subject_rounded,
                  ),
                  SizedBox(height: 20.h),
                  CustomTextField(
                    controller: _messageController,
                    label: 'تفاصيل الرسالة',
                    hint: 'اكتب رسالتك هنا...',
                    icon: Icons.chat_bubble_outline_rounded,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            SizedBox(height: 35.h),

            // 3. Submit Button (Gradient Style)
            GestureDetector(
              onTap: _sendEmail,
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
                      'إرسال الآن',
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

            // 4. Footer Info
            Text(
              'الإصدار ${packageInfo?.version ?? ''}',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              'جميع الحقوق محفوظة لـ يمنى © ${DateTime.now().year}',
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
