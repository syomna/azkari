import 'dart:async';

import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// بطاقات مواقيت الصلاة: ست بطاقات مستديرة واحدة لكل صلاة، والصلاة القادمة
/// مميّزة، وشريط أسفلها يعدّ الوقت المتبقي حتى أذانها.
class PrayerTimesCard extends StatefulWidget {
  final Map<String, TimeOfDay?> displayTimes;

  /// IANA timezone the displayed times are expressed in (the picked city's
  /// zone, or the device's own zone on auto). "Now" and the next-prayer
  /// arithmetic must use this zone, not the host clock: with a city picked
  /// while the phone is in another timezone, the wall-clock strings belong to
  /// the city and judging them against the device clock shifts the countdown
  /// by the whole offset. `null`/empty falls back to the device clock.
  final String? timezone;

  /// Control placed at the end of the header row, typically the city picker.
  ///
  /// It is a slot rather than a built-in widget on purpose: the card renders
  /// plain data and must not depend on `PrayerTimesProvider`, otherwise every
  /// test that pumps it would need a provider and a preferences mock. The
  /// caller injects the picker, which reads the provider itself.
  final Widget? locationSlot;

  const PrayerTimesCard({
    super.key,
    required this.displayTimes,
    this.locationSlot,
    this.timezone,
  });

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();

  /// ترتيب المواقيت اليومي. الشروق وقتٌ لا أذان فيه فعلياً، لكنه مُدرَج هنا
  /// ليُبرز مع بقية المواقيت كما كان قبل ذلك، فيدخل في اختيار الصلاة القادمة.
  static const List<String> prayerOrder = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// الصلاة القادمة: أقرب ميقات لم يحن وقته بعد.
  ///
  /// كانت تُوزَّع على ترتيب [prayerOrder] وتختار أول ميقاتٍ مستقبلي، وهذا
  /// صحيحٌ فقط لو بقيت المواقيت مرتّبة زمنياً. التعديل اليدوي يكسر الترتيب
  /// (مغرب 18:37 ← 16:45 بينما العصر القادم 17:00)، فيُختار العصر خطأً رغم
  /// أن المغرب سيؤذَّن قبله. [nearestFuture] تأخذ أصغر فرقٍ موجب بدل ذلك،
  /// فتعمل مع أي ترتيب. بعد منتصف الليل يُعاد الفجر كأقرب ميقات من الغد.
  @visibleForTesting
  static String nextPrayerKey(
    Map<String, TimeOfDay?> times, {
    required int nowMinutes,
    int seconds = 0,
  }) {
    final next =
        _nearestFuture(times, nowMinutes: nowMinutes, seconds: seconds);
    return next == null ? prayerOrder.first : next.$1;
  }

  /// الوقت المتبقي حتى أذان الصلاة القادمة، أو [null] إذا غابت المواقيت.
  ///
  /// يُحسب بالثواني لا بالدقائق، وإلا تأخّر العدّاد ثانيةً في كل دقيقة: عند
  /// 12:00:59 ووقت الظهر 12:01 يخرج المتبقي 1:59 بدل الثانية الواحدة.
  /// يقترن دائماً بنفس الصلاة التي تختارها [nextPrayerKey].
  @visibleForTesting
  static Duration? remainingUntilNext(
    Map<String, TimeOfDay?> times, {
    required int nowMinutes,
    int seconds = 0,
  }) =>
      _nearestFuture(times, nowMinutes: nowMinutes, seconds: seconds)?.$2;

  /// أقرب (صلاة، مدة) عبر أصغر فرقٍ موجب؛ الفروق غير الموجبة تُلفّ إلى الغد.
  static (String, Duration)? _nearestFuture(
    Map<String, TimeOfDay?> times, {
    required int nowMinutes,
    int seconds = 0,
  }) {
    final nowSeconds = nowMinutes * 60 + seconds;
    String? bestKey;
    Duration bestRemaining = Duration.zero;
    for (final key in prayerOrder) {
      final minutes = _minutesOf(times[key]);
      if (minutes == null) continue;
      var diff = minutes * 60 - nowSeconds;
      if (diff <= 0) diff += 86400;
      final remaining = Duration(seconds: diff);
      if (bestKey == null || remaining < bestRemaining) {
        bestKey = key;
        bestRemaining = remaining;
      }
    }
    return bestKey == null ? null : (bestKey, bestRemaining);
  }

  /// «د:ث» أو «س:د:ث» بعد ساعة، بأرقام عربية-هندية مع الحفاظ على الأصفار.
  @visibleForTesting
  static String formatCountdown(Duration remaining) {
    // يمنع أجزاءً سالبة إن تغيّرت المواقيت أثناء العرض.
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    String two(int value) => value.toString().padLeft(2, '0');

    final body = hours > 0
        ? '${two(hours)}:${two(minutes)}:${two(seconds)}'
        : '${two(minutes)}:${two(seconds)}';
    return AppHelpers.arabicDigits(body);
  }

  static int? _minutesOf(TimeOfDay? time) =>
      time == null ? null : time.hour * 60 + time.minute;
}

/// ست بطاقات في ثلاثة أعمدة = صفّان متساويان. أربعة أعمدة كانت تترك صفاً ثانياً
/// فيه بطاقتان فقط بعد حذف بطاقتَي منتصف الليل و«منذ الأذان».
const int _columns = 3;

const Map<String, String> _prayerLabels = {
  'fajr': 'الفجر',
  'sunrise': 'الشروق',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

const Map<String, IconData> _prayerIcons = {
  // الفجر تشرق فيه الشمس على الأفق، والشروق يُمثَّل بالشمس، والظهر ذروتها؛
  // حزمة Material لا فيها أيقونة غروب منفصلة، فالمغرب يُمثَّل بشمس low rays
  // والعشاء بقمر.
  'fajr': Icons.wb_twilight,
  'sunrise': Icons.brightness_2,
  'dhuhr': Icons.wb_sunny,
  'asr': Icons.wb_sunny_outlined,
  'maghrib': Icons.brightness_4,
  'isha': Icons.nightlight_round,
};

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // الشريط يعدّ بالثواني، فالتحديث كل دقيقة لا يكفي. التصيير يقع على
    // البطاقة كاملة لأن ستة عناصر صغيرة لا تستحق مقياساً منفصلاً، وdispose
    // يوقف المؤقت فلا يتسرب.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) => time == null
      ? '--:--'
      : DateFormat.jm('ar').format(DateTime(0, 0, 0, time.hour, time.minute));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tzName = widget.timezone;
    final now = (tzName == null || tzName.isEmpty)
        ? DateTime.now()
        : tz.TZDateTime.now(PrayerTimeService().displayLocation(tzName));
    final nowMinutes = now.hour * 60 + now.minute;
    final nextKey = PrayerTimesCard.nextPrayerKey(
      widget.displayTimes,
      nowMinutes: nowMinutes,
      seconds: now.second,
    );
    final remaining = PrayerTimesCard.remainingUntilNext(
      widget.displayTimes,
      nowMinutes: nowMinutes,
      seconds: now.second,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        // خلفية نعناعية خفيفة للقسم والبطاقات فوقها بيضاء، فالتباين يأتي من
        // لون الخلفية نفسه لا من الظل.
        color:
            isDark ? AppPalette.prayerPanelDark : AppPalette.prayerPanelLight,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isDark),
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 8.w;
              final itemWidth =
                  (constraints.maxWidth - gap * (_columns - 1)) / _columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final key in PrayerTimesCard.prayerOrder)
                    SizedBox(
                      width: itemWidth,
                      child: _buildPrayerTile(
                        key,
                        isDark,
                        isNext: key == nextKey,
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: 10.h),
          _buildCountdownStrip(nextKey, remaining, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final deepGreen =
        isDark ? AppPalette.deepGreenDark : AppPalette.deepGreenLight;
    final slot = widget.locationSlot;

    return Row(
      children: [
        Expanded(
          child: Text(
            'مواقيت الصلاة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: deepGreen,
            ),
          ),
        ),
        if (slot != null) ...[
          SizedBox(width: 8.w),
          // مرن بحد ذاته: عند تكبير الخط إلى 2× يتقلّص العمود المرن فيقتصّ الزر
          // من عرضه بدل أن يفيض على حافة البطاقة.
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: slot,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrayerTile(String key, bool isDark, {required bool isNext}) {
    final deepGreen =
        isDark ? AppPalette.deepGreenDark : AppPalette.deepGreenLight;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: isNext
            ? AppPalette.mainColor.withValues(alpha: isDark ? 0.24 : 0.14)
            : (isDark ? AppPalette.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isNext
              ? AppPalette.mainColor.withValues(alpha: 0.55)
              : AppPalette.mainColor.withValues(alpha: isDark ? 0.14 : 0.10),
          width: isNext ? 1.4 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_prayerIcons[key], size: 18.h, color: deepGreen),
          SizedBox(height: 5.h),
          Text(
            _prayerLabels[key]!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: isNext
                  ? deepGreen
                  : (isDark
                      ? AppPalette.darkMutedText
                      : AppPalette.lightMutedText),
            ),
          ),
          SizedBox(height: 3.h),
          // الوقت أهم رقم في البطاقة، وFittedBox يمنع التمدد أفقياً عند تكبير
          // الخط إلى 2× بدل أن يدفع البطاقة إلى overflow. الارتفاع ثابت لأن
          // التصغير يشمل المحورين، فبلا ارتفاع ثابت كانت الأرقام الأضيق تُصغَّر
          // فتصير أقصر من جاراتها، ويصير صف البطاقات غير مستوٍ.
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _formatTime(widget.displayTimes[key]),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppPalette.darkText : AppPalette.lightText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// شريط الوقت المتبقي. يملأ العرض كاملاً ليقرأ كعنصر مستقل لا كبطاقة سابعة
  /// ناقصة، ويعتمد تعبئةً خضراء صريحة ليتميّز عن بطاقة الصلاة القادمة التي هي
  /// تعبئة خفيفة.
  Widget _buildCountdownStrip(
    String nextKey,
    Duration? remaining,
    bool isDark,
  ) {
    final label = _prayerLabels[nextKey] ?? '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppPalette.mainColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 18.h,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          SizedBox(width: 8.w),
          // الجانبان مرنان: العدّاد كان داخل FittedBox غير محدود العرض، فيأخذ
          // عرضه الطبيعي كاملاً ويضغط الجار المرن إلى صفر. حصة كل طرف متناسبة
          // مع طوله، فلا يحدث تمدد أبداً.
          Expanded(
            flex: 3,
            child: Text(
              'باقي على أذان $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                remaining == null
                    ? '--:--'
                    : PrayerTimesCard.formatCountdown(remaining),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
