import 'package:adhan_dart/adhan_dart.dart';
import 'package:azkar_app/widgets/prayer_times_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // The production app now initializes this in `main()`; mirrors it here so
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

  testWidgets('six prayer columns render without overflow on a narrow card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final times = buildTimes();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(280, 600)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: PrayerTimesCard(
                  times: times,
                  displayTimes: buildDisplayTimes(times),
                  cityName: 'القاهرة',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الشروق'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prayer times card survives a large text scale factor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final times = buildTimes();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 600),
          textScaler: TextScaler.linear(2.0),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: PrayerTimesCard(
                  times: times,
                  displayTimes: buildDisplayTimes(times),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}