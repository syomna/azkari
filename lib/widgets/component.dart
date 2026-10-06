import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بطاقة وجهة في شبكة التنقل. الأيقونة من طقم الأيقونات الإسلامية (خط
/// IslamicIcons) بلون واحد وبنمط solid واحد، بعد أن كانت صوراً ملونة لكل
/// بطاقة: الصور كانت مرسومة لأسماء مختلفة (منها "أسماء الله الحسنى" وقد
/// ورثت أيقونة أذكار المساء) ولا تعطي الشبكة وحدة بصرية.
class Component extends StatelessWidget {
  const Component({
    super.key,
    required this.text,
    required this.icon,
    required this.page,
  });

  final String text;
  final IconData icon;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: AppPalette.tileShadow(Theme.of(context).brightness),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Ink(
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.03)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppPalette.mainColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22.h, color: AppPalette.mainColor),
                ),
                SizedBox(height: 10.h),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                    // سطران: أطول عنوان في الشبكة هو "أسماء الله الحسنى" وكان
                    // يظهر مبتوراً "أسماء الله..." في عرض العمود الثالث.
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
