import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/data/services/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart' as quran;

/// نافذة سفلية تعرض تفسير آية واحدة. التحميل كسول: أول مرة تُفتح الآية يتم
/// جلب النص من الشبكة، ثم يُخزن مؤقتاً في [TafseerService].
class TafseerSheet extends StatefulWidget {
  const TafseerSheet({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.service,
  });

  final int surahNumber;
  final int verseNumber;
  final TafseerService? service;

  @override
  State<TafseerSheet> createState() => _TafseerSheetState();
}

class _TafseerSheetState extends State<TafseerSheet> {
  late final TafseerService _service;
  late Future<TafseerEntry> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TafseerService();
    _future = _service.fetchAyah(widget.surahNumber, widget.verseNumber);
  }

  void _retry() {
    setState(() {
      _future = _service.fetchAyah(widget.surahNumber, widget.verseNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verseText = quran.getVerse(widget.surahNumber, widget.verseNumber);

    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'تفسير الآية ${AppHelpers.getArabicNumber(widget.surahNumber)}:${AppHelpers.getArabicNumber(widget.verseNumber)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppPalette.amiriFontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppPalette.mainColor,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppPalette.mainColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Text(
                verseText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppPalette.amiriFontFamily,
                  fontSize: 17.sp,
                  height: 1.9,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: FutureBuilder<TafseerEntry>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تعذر تحميل التفسير، تحقق من الاتصال ثم أعد المحاولة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  final entry = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          entry.text,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: AppPalette.amiriFontFamily,
                            fontSize: 16.sp,
                            height: 1.9,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'التفسير الميسر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
