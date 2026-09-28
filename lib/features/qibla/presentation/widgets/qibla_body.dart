import 'dart:math';

import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QiblaBody extends StatelessWidget {
  final double heading;
  final double difference;
  final bool isAligned;

  const QiblaBody({
    super.key,
    required this.heading,
    required this.difference,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    // كان حجم البوصلة يُشتق من عرض الشاشة فقط (0.7.sw)، فعلى الشاشات
    // العريضة (لوحي) ومع تكبير النص يتجاوز العمود ارتفاع الشاشة بـ385px.
    // نقيس الارتفاع المتاح لهذا العمود (قد يكون أصغر من الشاشة بسبب الشريط
    // العلوي والهوامش) ونحدّ البوصلة بـ45% منه، وBoxFit.contain يصغّر الصورة
    // داخل هذا الإطار بدل أن يفيض العمود.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double compassLimit = min(
          0.7.sw,
          constraints.maxHeight * 0.45,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Heading Degree
            Column(
              children: [
                Text('${AppHelpers.getArabicNumber(heading.toInt())}°',
                    style: TextStyle(
                        fontSize: 48.sp, fontWeight: FontWeight.bold)),
                Text('الدرجة الحالية',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
              ],
            ),

            // 2. Compass Asset
            // Flexible: النصوص تأخذ معظم الارتفاع عند تكبير النص، فالبوصلة
            // تأخذ ما تبقى بدل أن تفرض حجمها وتفيض العمود.
            Flexible(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isAligned
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 15,
                            )
                          ]
                        : [],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compassLimit,
                      maxHeight: compassLimit,
                    ),
                    child: Transform.rotate(
                      angle: (difference * pi / 180),
                      child: Image.asset(
                        'assets/images/qibla.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Status Text
            Text(
              isAligned
                  ? 'أنت باتجاه القبلة الآن'
                  : 'قم بتدوير الهاتف نحو القبلة',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isAligned ? Colors.green : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
