import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إدارة طلب تقييم التطبيق عبر نافذة `in_app_review` الأصلية من المتجر:
/// يُعرض تلقائياً بعد عدد معيّن من فتحات التطبيق، ويمكن فتحه يدوياً من
/// الإعدادات أيضاً. لا يملك المتجر زر «لا تسألني مرة أخرى» داخل نافذته،
/// لكن نظام التشغيل نفسه يحدّ من تكرار الظهور فلا يُزعج المستخدم.
class AppReviewService {
  AppReviewService._();

  /// كم فتحة تمر بين كل سؤال تقييم.
  static const int promptsEveryLaunches = 5;

  static const String launchCountKey = 'app_review_launch_count';

  /// يُستدعى عند كل فتح للتطبيق: يزيد العداد ويعيد `true` عندما حان موعد
  /// عرض نافذة التقييم (كل [promptsEveryLaunches] فتحة).
  static Future<bool> shouldPromptOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = (prefs.getInt(launchCountKey) ?? 0) + 1;
    await prefs.setInt(launchCountKey, count);
    return count % promptsEveryLaunches == 0;
  }

  /// نقطة دخول عند فتح التطبيق. عند الحلول، ينتظر قليلاً كي لا يقطع أول
  /// تفاعل مع الشاشة الرئيسية ثم يعرض نافذة التقييم الأصلية.
  static Future<void> handleAppLaunch() async {
    if (!await shouldPromptOnLaunch()) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    await requestReview();
  }

  /// يعرض نافذة التقييم الأصلية للمتجر؛ وإن لم تتوفر (كلوطة نظام التشغيل)
  /// يفتح صفحة التقييم في المتجر كبديل.
  static Future<void> requestReview() async {
    final InAppReview review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      // بيئة بلا متجر (اختبارات) أو فشل اتصال: لا نكسر التطبيق.
    }
  }
}
