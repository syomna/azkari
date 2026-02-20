import 'dart:developer';

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
  // Controllers to capture user input
  // final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  PackageInfo? packageInfo;
  @override
  initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    // final String userEmail = _emailController.text.trim();
    final String subject = _subjectController.text.trim();
    final String message = _messageController.text.trim();

    // Basic Validation
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'syomna444@gmail.com', // Your destination email
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
    );

    // Navigator.pop(context);

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      log(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق البريد الإلكتروني')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'للشكاوى والاقتراحات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Icon(
              Icons.contact_support_rounded,
              size: 80.sp,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 10.h),
            Text(
              'نحن نسعد بتواصلكم معنا',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25.h),

            // User Email Field
            // CustomTextField(
            //   controller: _emailController,
            //   label: 'بريدك الإلكتروني',
            //   hint: 'مثال: user@email.com',
            //   icon: Icons.alternate_email,
            //   keyboardType: TextInputType.emailAddress,
            // ),
            // SizedBox(height: 15.h),

            // Subject Field
            CustomTextField(
              controller: _subjectController,
              label: 'موضوع الرسالة',
              hint: 'اقتراح، شكوى، استفسار...',
              icon: Icons.subject,
            ),
            SizedBox(height: 15.h),

            // Message Field
            CustomTextField(
              controller: _messageController,
              label: 'تفاصيل الرسالة',
              hint: 'اكتب رسالتك هنا...',
              icon: Icons.edit_note,
              maxLines: 5,
            ),
            SizedBox(height: 30.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 45.h,
              child: ElevatedButton.icon(
                onPressed: _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  'إرسال الآن',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 40.h),
            Text(
              'الإصدار ${packageInfo?.version ?? ''} | جميع الحقوق محفوظة © ${DateTime.now().year}',
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
