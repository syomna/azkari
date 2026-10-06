import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/widgets/prayer_times_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

const List<String> _labels = [
  'الفجر',
  'الشروق',
  'الظهر',
  'العصر',
  'المغرب',
  'العشاء',
];

void main() {
  setUpAll(() async {
    // The production app initializes this in `main()`; mirrors it here so
    // `DateFormat.jm('ar')` inside the card can format in isolation.
    await initializeDateFormatting('ar');
  });

  PrayerTimes buildTimes() {
    final params = CalculationParameters(
      method: CalculationMethod.muslimWorldLeague,
      fajrAngle: 18,
      ishaAngle: 17,
    )..madhab = Madhab.shafi;
    return PrayerTimes(
      date: DateTime.now(),
      coordinates: const Coordinates(30.04, 31.24),
      calculationParameters: params,
    );
  }

  Map<String, TimeOfDay?> buildDisplayTimes(PrayerTimes times) {
    TimeOfDay to(T) => TimeOfDay(hour: T.hour, minute: T.minute);
    return {
      'fajr': to(times.fajr),
      'sunrise': to(times.sunrise),
      'dhuhr': to(times.dhuhr),
      'asr': to(times.asr),
      'maghrib': to(times.maghrib),
      'isha': to(times.isha),
    };
  }

  TimeOfDay at(int hour, int minute) => TimeOfDay(hour: hour, minute: minute);

  /// A full six-prayer day, overridable per key.
  Map<String, TimeOfDay?> day({Map<String, TimeOfDay?> overrides = const {}}) =>
      {
        'fajr': at(5, 24),
        'sunrise': at(6, 50),
        'dhuhr': at(12, 45),
        'asr': at(16, 5),
        'maghrib': at(18, 37),
        'isha': at(20, 0),
        ...overrides,
      };

  /// Mounts the card at [width] logical pixels with an optional text scale.
  Future<void> pump(
    WidgetTester tester, {
    required double width,
    required Map<String, TimeOfDay?> displayTimes,
    Widget? locationSlot,
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: brightness == Brightness.dark
                  ? ThemeData.dark(useMaterial3: true)
                  : ThemeData.light(useMaterial3: true),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PrayerTimesCard(
                    displayTimes: displayTimes,
                    locationSlot: locationSlot,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Stand-in for the real city picker: a small pill that ellipsizes, so the
  /// header is measured against something with a realistic footprint without
  /// dragging a PrayerTimesProvider into the test.
  Widget citySlot(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF22A351)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  /// y-offset of the tile holding [label], used to count how many tiles fit on
  /// the first row.
  double tileTop(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label)).dy;

  /// Width of the container wrapping [label], i.e. the tile or the strip.
  double boxWidth(WidgetTester tester, Finder target) => tester
      .getSize(
        find.ancestor(of: target, matching: find.byType(Container)).first,
      )
      .width;

  BoxDecoration tileDecoration(WidgetTester tester, String label) {
    final container = find
        .ancestor(of: find.text(label), matching: find.byType(Container))
        .first;
    return tester.widget<Container>(container).decoration! as BoxDecoration;
  }

  /// Minutes past midnight for [key] in [times], or null when absent.
  int? minutesOf(Map<String, TimeOfDay?> times, String key) {
    final t = times[key];
    return t == null ? null : t.hour * 60 + t.minute;
  }

  group('next prayer', () {
    test('is the first time that has not come yet', () {
      // 14:00 → dhuhr has passed, asr (16:05) is next.
      expect(
        PrayerTimesCard.nextPrayerKey(day(), nowMinutes: 14 * 60),
        'asr',
      );
    });

    test('treats sunrise as a target, matching the previous behaviour', () {
      final times = day(overrides: {'fajr': at(4, 20)});

      // 06:00 sits between fajr (04:20) and sunrise (06:50).
      expect(
        PrayerTimesCard.nextPrayerKey(times, nowMinutes: 6 * 60),
        'sunrise',
      );
    });

    test('advances at the adhan minute itself, not a minute later', () {
      // The countdown must roll over to the following prayer the moment its
      // time arrives, hence the strict greater-than comparison.
      expect(
        PrayerTimesCard.nextPrayerKey(day(), nowMinutes: 12 * 60 + 45),
        'asr',
      );
    });

    test('falls back to fajr once the last time of the day is gone', () {
      expect(
        PrayerTimesCard.nextPrayerKey(day(), nowMinutes: 23 * 60 + 30),
        'fajr',
      );
    });

    test('skips missing entries instead of selecting them', () {
      final times = day(overrides: {'dhuhr': null, 'asr': null});

      expect(
        PrayerTimesCard.nextPrayerKey(times, nowMinutes: 10 * 60),
        'maghrib',
      );
    });

    test('returns fajr when the day has no times at all', () {
      expect(
        PrayerTimesCard.nextPrayerKey(const {}, nowMinutes: 600),
        'fajr',
      );
    });

    test('an override that reorders the day picks the soonest, not the first',
        () {
      // 16:30 الآن، والعصر معدّل إلى 17:00 (قادم)، والمغرب مُعدّل إلى 16:45
      // (قادم أيضاً لكنه قبلها). الترتيب الزمني انكسر، فالأقرب هو المغرب.
      final times = day(overrides: {'asr': at(17, 0), 'maghrib': at(16, 45)});

      expect(
        PrayerTimesCard.nextPrayerKey(times, nowMinutes: 16 * 60 + 30),
        'maghrib',
      );
      expect(
        PrayerTimesCard.remainingUntilNext(times, nowMinutes: 16 * 60 + 30),
        const Duration(minutes: 15),
      );
    });

    test('a late-night override beats tomorrow\'s fajr', () {
      // 00:20، والعشاء مُعدّل إلى 00:30: هو أقرب أذان رغم أن الفجر 05:24 ما
      // زال أمامه — لا يُهمَل لمجرّد أنه يلي الفجر في ترتيب اليوم.
      final times = day(overrides: {'isha': at(0, 30)});

      expect(
        PrayerTimesCard.nextPrayerKey(times, nowMinutes: 20),
        'isha',
      );
      expect(
        PrayerTimesCard.remainingUntilNext(times, nowMinutes: 20),
        const Duration(minutes: 10),
      );
    });
  });

  group('remaining until the next adhan', () {
    test('counts down to the upcoming time', () {
      expect(
        PrayerTimesCard.remainingUntilNext(day(), nowMinutes: 14 * 60),
        const Duration(hours: 2, minutes: 5),
      );
    });

    test('is accurate to the second, not the minute', () {
      // A minute-based calculation would wrongly report 2:05:30 here.
      expect(
        PrayerTimesCard.remainingUntilNext(
          day(),
          nowMinutes: 14 * 60,
          seconds: 30,
        ),
        const Duration(hours: 2, minutes: 4, seconds: 30),
      );
    });

    test('reaches seconds, not a full minute, just before an adhan', () {
      final times = day(overrides: {'asr': at(16, 1)});

      expect(
        PrayerTimesCard.remainingUntilNext(times, nowMinutes: 16 * 60),
        const Duration(seconds: 60),
      );
      expect(
        PrayerTimesCard.remainingUntilNext(
          times,
          nowMinutes: 16 * 60,
          seconds: 59,
        ),
        const Duration(seconds: 1),
      );
    });

    test('wraps past midnight to tomorrow fajr', () {
      // 23:30 → fajr 05:24 tomorrow is 5h54m away.
      expect(
        PrayerTimesCard.remainingUntilNext(day(), nowMinutes: 23 * 60 + 30),
        const Duration(hours: 5, minutes: 54),
      );
    });

    test('is null when no times are available at all', () {
      expect(
        PrayerTimesCard.remainingUntilNext(const {}, nowMinutes: 600),
        isNull,
      );
    });

    test('agrees with nextPrayerKey on the target', () {
      for (final minute in [
        0,
        5 * 60,
        6 * 60 + 30,
        12 * 60 + 45,
        18 * 60,
        23 * 60
      ]) {
        final key = PrayerTimesCard.nextPrayerKey(day(), nowMinutes: minute);
        final remaining = PrayerTimesCard.remainingUntilNext(
          day(),
          nowMinutes: minute,
        );

        expect(remaining, isNotNull, reason: 'no countdown at $minute');
        expect(remaining!.isNegative, isFalse, reason: 'negative at $minute');
        final target = minutesOf(day(), key)!;
        var diff = target - minute;
        if (diff <= 0) diff += 1440;
        expect(
          remaining.inMinutes,
          diff,
          reason: 'countdown disagrees with next prayer $key at $minute',
        );
      }
    });
  });

  group('countdown formatting', () {
    test('pads minutes and seconds and uses Arabic-Indic digits', () {
      expect(
        PrayerTimesCard.formatCountdown(
          const Duration(minutes: 5, seconds: 7),
        ),
        '٠٥:٠٧',
      );
    });

    test('adds an hours field past sixty minutes', () {
      expect(
        PrayerTimesCard.formatCountdown(
          const Duration(hours: 1, minutes: 8, seconds: 30),
        ),
        '٠١:٠٨:٣٠',
      );
    });

    test('clamps a negative remainder to zero', () {
      expect(
        PrayerTimesCard.formatCountdown(const Duration(seconds: -5)),
        '٠٠:٠٠',
      );
    });
  });

  group('layout', () {
    testWidgets('renders six prayer cards, the header and the strip',
        (tester) async {
      await pump(
        tester,
        width: 390,
        displayTimes: buildDisplayTimes(buildTimes()),
        locationSlot: citySlot('القاهرة'),
      );

      for (final label in _labels) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.textContaining('باقي على أذان'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no longer renders midnight or since-adhan', (tester) async {
      await pump(
        tester,
        width: 390,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      expect(find.text('منتصف الليل'), findsNothing);
      expect(find.text('منذ الأذان'), findsNothing);
      expect(find.textContaining('منذ الأذان'), findsNothing);
    });

    testWidgets('keeps three columns on a narrow screen', (tester) async {
      await pump(
        tester,
        width: 300,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      // Three per row means the fourth tile starts a new, lower row. The
      // tolerance absorbs sub-pixel glyph metrics: the fallback test font
      // gives some Arabic labels a marginally taller line box than others.
      final first = tileTop(tester, 'الفجر');
      final third = tileTop(tester, 'الظهر');
      final fourth = tileTop(tester, 'العصر');

      expect(first, closeTo(third, 1));
      expect(fourth, greaterThan(first + 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps three columns on a wide screen for two even rows',
        (tester) async {
      await pump(
        tester,
        width: 430,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      final first = tileTop(tester, 'الفجر');
      final third = tileTop(tester, 'الظهر');
      final fourth = tileTop(tester, 'العصر');
      final sixth = tileTop(tester, 'العشاء');

      // Still three columns on a wide screen: two even rows, and the sixth
      // tile lands in the third column rather than spilling onto a third row.
      expect(third, closeTo(first, 1));
      expect(fourth, greaterThan(first + 50));
      expect(sixth, closeTo(fourth, 1));
      // Column position, not just row: العشاء (sixth) sits in the same column
      // as الظهر (third), which rules out a third row of leftovers.
      expect(
        tester.getTopLeft(find.text('العشاء')).dx,
        closeTo(tester.getTopLeft(find.text('الظهر')).dx, 1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('gives the countdown strip the full section width',
        (tester) async {
      await pump(
        tester,
        width: 390,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      final strip = boxWidth(tester, find.textContaining('باقي على أذان'));
      final tile = boxWidth(tester, find.text('الفجر'));

      // A strip spanning one tile would read as a seventh, undersized cell.
      expect(strip, greaterThan(tile * 2));
    });

    testWidgets('highlights exactly one tile, matching the countdown',
        (tester) async {
      await pump(
        tester,
        width: 390,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      // Time-independent invariant: whatever the wall clock says, the tinted
      // tile and the countdown must name the same prayer.
      final highlighted = _labels
          .where(
            (label) => tileDecoration(tester, label).color != Colors.white,
          )
          .toList();

      expect(highlighted, hasLength(1));
      expect(
        find.text('باقي على أذان ${highlighted.single}'),
        findsOneWidget,
      );

      final decoration = tileDecoration(tester, highlighted.single);
      expect(decoration.border?.top.width, 1.4);
      final plain = tileDecoration(
        tester,
        _labels.firstWhere((label) => label != highlighted.single),
      );
      expect(plain.color, Colors.white);
      expect(plain.border?.top.width, 1);
    });

    testWidgets('renders the header without a location slot', (tester) async {
      await pump(
        tester,
        width: 390,
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.textContaining('باقي على أذان'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('squeezes a long city name instead of overflowing',
        (tester) async {
      // The pill shares the header row with the title, so at 2x text scale it
      // must give up width and ellipsize rather than push past the card edge.
      await pump(
        tester,
        width: 320,
        textScale: 2.0,
        locationSlot: citySlot('مكة المكرمة'),
        displayTimes: buildDisplayTimes(buildTimes()),
      );

      final slot = find.text('مكة المكرمة');
      expect(slot, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a large text scale without overflow', (tester) async {
      await pump(
        tester,
        width: 320,
        textScale: 2.0,
        displayTimes: buildDisplayTimes(buildTimes()),
        locationSlot: citySlot('القاهرة'),
      );

      expect(find.textContaining('باقي على أذان'), findsOneWidget);
      expect(find.text('المغرب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode', (tester) async {
      await pump(
        tester,
        width: 390,
        brightness: Brightness.dark,
        displayTimes: buildDisplayTimes(buildTimes()),
        locationSlot: citySlot('القاهرة'),
      );

      expect(find.textContaining('باقي على أذان'), findsOneWidget);
      expect(find.text('العشاء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
