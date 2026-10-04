import 'dart:convert';
import 'dart:io';

import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/core/providers/notification_provider.dart';
import 'package:azkar_app/core/providers/theme_provider.dart';
import 'package:azkar_app/core/services/prayer_times_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:azkar_app/features/azkar/domain/usecases/delete_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/save_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/domain/usecases/update_custom_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/azkar_details_page.dart';
import 'package:azkar_app/features/azkar/presentation/pages/favorite_items_page.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/prayer_times_provider.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/add_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/city_picker_sheet.dart';
import 'package:azkar_app/features/azkar/presentation/widgets/edit_azkar_bottom_sheet.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/repositories/names_of_allah_repository.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/pages/names_of_allah_page.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/di/injection_container.dart';
import 'package:azkar_app/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:azkar_app/features/qibla/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:azkar_app/features/qibla/presentation/pages/qibla_screen.dart';
import 'package:azkar_app/features/qibla/presentation/providers/qibla_provider.dart';
import 'package:azkar_app/features/quran/data/services/tafseer_service.dart';
import 'package:azkar_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/quran_list.dart';
import 'package:azkar_app/features/quran/presentation/widgets/tafseer_sheet.dart';
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/domain/repositories/surah_repository.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/pages/surah_list_page.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/pages/tasbeh_page.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/features/widget_guide/presentation/widget_guide_page.dart';
import 'package:azkar_app/pages/adhan_page.dart';
import 'package:azkar_app/pages/contact_us_page.dart';
import 'package:azkar_app/pages/home_page.dart';
import 'package:azkar_app/pages/notifications_screen.dart';
import 'package:azkar_app/pages/prayer_times_settings_page.dart';
import 'package:azkar_app/pages/settings_page.dart';
import 'package:azkar_app/pages/splash_page.dart';
import 'package:azkar_app/widgets/arabic_time_picker_sheet.dart';
import 'package:azkar_app/widgets/time_adjustment_sheet.dart';
import 'package:dartz/dartz.dart' show Either, Right, Unit, unit;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/fake_just_audio_platform.dart';
import '../helpers/quran_test_doubles.dart';

const String _morning = 'أذكار الصباح';

/// وضع البيانات الحقيقية: النصوص القصيرة أعلاه لا تكشف كل مواضع الازدحام،
/// لأن أطول ما في التطبيق هو النص الفعلي (٣٥١ ذكراً و١٠٠ اسم و٢٥ سورة).
/// SWEEP_REAL_DATA=1 يشغّل الفحص على نفس ملفات assets/db التي يقرأها التطبيق.
final bool _useRealData = Platform.environment['SWEEP_REAL_DATA'] == '1';

List<ZekrEntity> _realAzkar = const [];
List<NamesOfAllahEntity> _realNames = const [];
List<SurahEntity> _realSurah = const [];

/// أطول نص في البيانات الحقيقية يُستخدم في [_tapThrough] عند وضع البيانات
/// الحقيقية، حتى يُبنى أعرض عنصر فعلاً لا عنصراً تجريبياً قصيراً.
String get _longestAzkarZekr => _realAzkar.isEmpty
    ? _azkarList.first.zekr
    : _realAzkar
        .reduce((ZekrEntity a, ZekrEntity b) =>
            a.zekr.length >= b.zekr.length ? a : b)
        .zekr;

Future<List<E>> _loadAssetList<E>(
  String path,
  E Function(Map<String, dynamic>) build,
) async {
  final String raw =
      utf8.decode((await rootBundle.load(path)).buffer.asUint8List());
  final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
  return decoded
      .map((e) => build(e as Map<String, dynamic>))
      .toList(growable: false);
}

Future<void> _loadRealData() async {
  _realAzkar = await _loadAssetList<ZekrEntity>(
    'assets/db/azkar.json',
    (Map<String, dynamic> e) => ZekrEntity(
      category: e['category'] as String,
      count: e['count'] as String,
      description: e['description'] as String,
      reference: e['reference'] as String,
      zekr: e['zekr'] as String,
    ),
  );
  _realNames = await _loadAssetList<NamesOfAllahEntity>(
    'assets/db/names_of_allah.json',
    (Map<String, dynamic> e) => NamesOfAllahEntity(
      id: (e['id'] as num).toInt(),
      name: e['name'] as String,
      text: e['text'] as String,
    ),
  );
  _realSurah = await _loadAssetList<SurahEntity>(
    'assets/db/surah.json',
    (Map<String, dynamic> e) => SurahEntity(
      name: e['name'] as String,
      surah: e['surah'] as String,
    ),
  );
}

/// نص طويل عمداً: أي سطر يتجاوز عرض الشاشة يظهر كـ overflow في هذا الاختبار.
final List<ZekrEntity> _azkarList = List.generate(
  10,
  (int i) => ZekrEntity(
    category: _morning,
    count: '${i + 1}',
    description: 'ذكر رقم ${i + 1}',
    reference: 'صحيح البخاري',
    zekr: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، '
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
        'وَلَهُ الْحَمْدُ وَعَلَيْهِ النُّصُورُ وَالْيَمِينُ وَهُوَ عَلَى كُلِّ '
        'شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ '
        'مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ '
        'مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ '
        'أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ، رَبِّ '
        'أَعُوذُ بِكَ مِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ وَفِتْنَةِ الْمَسِيحِ '
        'الدَّجَّالِ، رَبِّ أَعُوذُ بِكَ مِنْ الْهَمِّ وَالْحَزَنِ.',
  ),
);

final List<SurahEntity> _surahList = List.generate(
  6,
  (int i) => SurahEntity(name: 'سورة رقم ${i + 1}', surah: '${i + 1}'),
);

final List<NamesOfAllahEntity> _namesList = List.generate(
  20,
  (int i) => NamesOfAllahEntity(
    id: i + 1,
    name: 'الاسم رقم ${i + 1}',
    text: 'من أسماء الله الحسنى التي يذكرها المسلم في دعائه وضرورته',
  ),
);

class _FakeAzkarRepository implements AzkarRepository {
  @override
  Future<Either<Failure, List<ZekrEntity>>> getAzkar() async =>
      Right(_useRealData ? _realAzkar : _azkarList);

  @override
  Future<Either<Failure, List<ZekrEntity>>> getCustomAzkar() async =>
      const Right([]);

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<ZekrEntity> items) async =>
      const Right(unit);

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
          String categoryName) async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> updateCustomAzkarCategory(
    String oldCategory,
    List<ZekrEntity> items,
  ) async =>
      const Right(unit);
}

class _FakeNamesRepository implements NamesOfAllahRepository {
  @override
  Future<Either<Failure, List<NamesOfAllahEntity>>> getNamesOfAllah() async =>
      Right(_useRealData ? _realNames : _namesList);
}

class _FakeSurahRepository implements SurahRepository {
  @override
  Future<Either<Failure, List<SurahEntity>>> getSurah() async =>
      Right(_useRealData ? _realSurah : _surahList);
}

class _FakeQiblaRepository implements QiblaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class _FakeQiblaProvider extends QiblaProvider {
  _FakeQiblaProvider()
      : super(
          getQiblaDirectionUseCase:
              GetQiblaDirectionUseCase(_FakeQiblaRepository()),
        );

  @override
  bool get isLoading => false;

  @override
  double get currentHeading => 12;

  @override
  String? get errorMessage => null;
}

class _FakeNotificationProvider extends ChangeNotifier
    implements NotificationProvider {
  @override
  bool get areNotificationsEnabled => true;

  @override
  bool get isPrayerAdhanEnabled => true;

  @override
  bool get isMorningEveningAzkarEnabled => true;

  @override
  bool get isPeriodicAzkarEnabled => true;

  @override
  bool get isPreAdhanEnabled => true;

  @override
  bool get isQuranAfterSalahEnabled => true;

  @override
  bool get isProphetBlessingsEnabled => true;

  @override
  bool get isIslamicEventsEnabled => true;

  @override
  Future<String?> applyNotificationStates() async => null;

  @override
  Future<void> refreshNotifications() async {}

  @override
  TimeOfDay? azkarTime(String key) => null;

  @override
  Future<String?> setAzkarTime(String key, TimeOfDay? time) async => null;

  @override
  Future<String?> toggleAllNotifications(bool newValue) async => null;

  @override
  Future<void> toggleNotificationType(String key, bool value) async {}
}

/// نصوص تفسير طويلة عمداً: التفسير يُجلب من الشبكة، والنسخة الحقيقية نص
/// مُفصّل وطويل. حقن نص طويل هنا هو ما كشف ازدحام ورقة التفسير سابقاً.
class _FakeTafseerService extends TafseerService {
  _FakeTafseerService(this.text);

  final String text;

  @override
  Future<TafseerEntry> fetchAyah(int surahNumber, int verseNumber) async =>
      TafseerEntry(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        edition: 'fake',
        text: text,
      );
}

class _Env {
  _Env(this.providers, this.notifiers);

  final List<SingleChildWidget> providers;
  final List<ChangeNotifier> notifiers;
}

Future<_Env> _providers() async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  SharedPreferences.setMockInitialValues({
    WidgetGuidePage.seenPreferenceKey: true,
    PrefsKeys.latitude: 30.0444,
    PrefsKeys.longitude: 31.2357,
    PrefsKeys.cityTimezone: 'UTC',
    PrefsKeys.prayerTimeDate: today,
  });
  final preferences = await SharedPreferences.getInstance();
  final azkarRepository = _FakeAzkarRepository();
  final azkar = AzkarProvider(
    getAzkarUseCase: GetAzkarUseCase(azkarRepository: azkarRepository),
    getCustomAzkarUseCase:
        GetCustomAzkarUseCase(azkarRepository: azkarRepository),
    saveCustomAzkarUseCase:
        SaveCustomAzkarUseCase(azkarRepository: azkarRepository),
    deleteCustomAzkarUseCase:
        DeleteCustomAzkarUseCase(azkarRepository: azkarRepository),
    updateCustomAzkarUseCase:
        UpdateCustomAzkarUseCase(azkarRepository: azkarRepository),
  );
  final favorites = FavoritesProvider(sharedPreferences: preferences);
  final prayer = PrayerTimesProvider(
    prayerTimeService: PrayerTimeService(),
    sharedPreferences: preferences,
  );
  final names = NamesOfAllahProvider(
    getNamesOfAllahUseCase: GetNamesOfAllahUseCase(
      namesOfAllahRepository: _FakeNamesRepository(),
    ),
  );
  final surah = SurahProvider(
    getSurahUseCase: GetSurahUseCase(surahRepository: _FakeSurahRepository()),
  );
  final tasbeh = TasbehProvider(sharedPreferences: preferences);
  final theme = ThemeProvider(prefs: preferences);
  final quran = buildTestQuranProvider();
  final notifications = _FakeNotificationProvider();
  return _Env([
    ChangeNotifierProvider<AzkarProvider>.value(value: azkar),
    ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
    ChangeNotifierProvider<PrayerTimesProvider>.value(value: prayer),
    ChangeNotifierProvider<NamesOfAllahProvider>.value(value: names),
    ChangeNotifierProvider<SurahProvider>.value(value: surah),
    ChangeNotifierProvider<ThemeProvider>.value(value: theme),
    ChangeNotifierProvider<TasbehProvider>.value(value: tasbeh),
    ChangeNotifierProvider<QuranProvider>.value(value: quran),
    ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
  ], [
    azkar,
    favorites,
    prayer,
    names,
    surah,
    theme,
    tasbeh,
    quran,
    notifications,
  ]);
}

Widget _app({
  required Widget home,
  required List<SingleChildWidget> providers,
  double textScale = 1,
}) {
  final bool dark = Platform.environment['SWEEP_THEME'] == 'dark';
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) {
      ScreenUtil.init(context, designSize: const Size(430, 932));
      return MultiProvider(
        providers: providers,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const [Locale('ar', 'EG')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppPalette.lightTheme,
          darkTheme: AppPalette.darkTheme,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      );
    },
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// الأوراق المنبثقة والحوارات لا تظهر كـ `home` أبداً، فلم تكن يغطّيها
/// الفحص إطلاقاً — ومنها ما كان فيه ازدحام حقيقي. كل مفتاح هنا ورقة تُفتح
/// فوق صفحة حقيقية بنفس الإعدادات التي تستخدمها الشاشة.
final Map<String, void Function(BuildContext)> _sheets =
    <String, void Function(BuildContext)>{
  // 2:255 = آية الكرسي، أطول آية تدخل ورقة التفسير.
  'Sheet:Tafseer': (BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TafseerSheet(
          surahNumber: 2,
          verseNumber: 255,
          service: _FakeTafseerService(
            'قال المفسرون إن الآية الكريمة لا تنال مراتبها إلا بالثبات على '
                    'الذكر والصلاة، وهي أعظم آية في القرآن بعد الفاتحة. ' *
                6,
          ),
        ),
      ),
  'Sheet:QuranList': (BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) => QuranList(
            selectedSurahNumber: 2,
            onSurahSelected: (_) {},
          ),
        ),
      ),
  'Sheet:ArabicTimePicker': (BuildContext context) => showArabicTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 5, minute: 20),
        title: 'وقت أذان الفجر',
      ),
  'Sheet:TimeAdjustment': (BuildContext context) => showTimeAdjustmentSheet(
        context: context,
        prayerName: 'الفجر',
        initialTime: const TimeOfDay(hour: 5, minute: 20),
      ),
  'Sheet:CityPicker': (BuildContext context) =>
      showCityPicker(context, currentCity: 'الرياض'),
  'Sheet:AddAzkar': (BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddAzkarBottomSheet(onChangeFilter: () {}),
      ),
  'Sheet:EditAzkar': (BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditAzkarBottomSheet(
          category: _morning,
          currentAzkar: _useRealData ? _realAzkar.take(8).toList() : _azkarList,
        ),
      ),
  'Dialog:About': (BuildContext context) => showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('عن التطبيق'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أذكاري — تطبيق إسلامي يجمع الأذكار والأدعية '
                    'وآيات القرآن الكريم ومواقيت الصلاة، مع widget على الشاشة '
                    'الرئيسية يعرض ذكر اليوم ومواعيد الصلاة القادمة.'),
                const SizedBox(height: 12),
                Text('الإصدار 4.3.31+78', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
};

/// صفحة مضيفة تفتح الورقة/الحوار بعد أول إطار، بنفس طريقة فتحه من الشاشة
/// الحقيقية.
Widget _sheetHost(void Function(BuildContext) open) {
  return Scaffold(
    body: Builder(builder: (BuildContext context) {
      WidgetsBinding.instance.addPostFrameCallback((_) => open(context));
      return const SizedBox.shrink();
    }),
  );
}

/// يستخرج موضع الازدحام من قسم "الـ widget المسبّب" في تفاصيل FlutterError:
/// اسم ملف المصدر ورقم السطر. takeException وحده لا يُرجع هذه المعلومات،
/// فبدونها يبقى السبب مخفياً في مكدّس طويل.
String? _culprit(List<FlutterErrorDetails> details) {
  for (final FlutterErrorDetails d in details) {
    final RegExpMatch? section = RegExp(
            r'The relevant error-causing widget was:\n([^\n]*(?:\n[^\n]*){0,3})')
        .firstMatch(d.toString());
    if (section == null) continue;
    final RegExpMatch? where =
        RegExp(r'([\w\-]+\.dart):(\d+):(\d+)').firstMatch(section.group(1)!);
    if (where != null) {
      return '${where.group(1)}:${where.group(2)}';
    }
    final List<String> lines = section
        .group(1)!
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();
    if (lines.isNotEmpty) return lines.first;
  }
  return null;
}

/// يحوّل الاستثناء إلى سطر واحد مختصر: حجم الازدحام واتجاهه، والـ widget
/// المسبّب، حتى لا يضيع السبب في مكدّس استثناء طويل.
String _describe(
  Object thrown,
  String screen,
  String surface,
  double scale,
  String? culprit,
) {
  final String head = '$screen @ $surface @ text x$scale';
  final RegExpMatch? overflow = RegExp(
    r'overflowed by ([\d.]+) pixels on the (right|left|bottom|top)',
  ).firstMatch(thrown.toString());
  final String where = culprit == null ? '' : ' — $culprit';
  if (overflow != null) {
    return '$head: RenderFlex overflowed by ${overflow.group(1)}px on the '
        '${overflow.group(2)}$where';
  }
  return '$head: ${thrown.runtimeType}$where — '
      '${thrown.toString().split('\n').first}';
}

/// يفتح كل شاشات التطبيق على أربعة مقاسات شاشة ومقاسي خط، ويبلّغ عن أي
/// Overflow أو استثناء باسم الشاشة والمقاس المسبّب له بدل تجاهله.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar_EG');
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    // بدون الخط الحقيقي تتغير مقاسات النص ويصبح الفحص أضيق(strict) من الواقع،
    // ويمثّل الحالة التي يمرّ بها المستخدم لو فشل تحميل خط التطبيق على
    // الجهاز فيستخدم خط النظام. الوضع الافتراضي هو الخط الحقيقي، والوضع
    // الأضيق عبر SWEEP_FALLBACK_FONT=1.
    if (Platform.environment['SWEEP_FALLBACK_FONT'] != '1') {
      // Amiri لا يقل Tajawal: نصوص القرآن والتفسير ترسم بخط Amiri، وبدون
      // تحميله كان الفحص يقيس نص المصحف بخط بديل فله مقاسات مختلفة.
      for (final (String, String) font in const <(String, String)>[
        ('Tajawal', 'assets/fonts/tajawal.ttf'),
        ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
        ('Amiri', 'assets/fonts/Amiri-Bold.ttf'),
      ]) {
        final loader = FontLoader(font.$1)..addFont(rootBundle.load(font.$2));
        await loader.load();
      }
    }
    if (_useRealData) {
      await _loadRealData();
      // ignore: avoid_print
      print('SWEEP_REAL_DATA: ${_realAzkar.length} azkar, '
          '${_realNames.length} names, ${_realSurah.length} surah');
    }
  });

  final Map<String, Widget Function()> screens = {
    'HomePage': () => const HomePage(),
    'AllAzkarPage': () => const AllAzkarPage(selectedFilter: 'أذكاري'),
    'AzkarDetailsPage': () =>
        const AzkarDetailsPage(title: _morning, categoryName: _morning),
    'FavoriteItemsPage': () => const FavoriteItemsPage(),
    'NamesOfAllahPage': () => const NamesOfAllahPage(),
    'SurahListPage': () => const SurahListPage(),
    'QuranDetailPage': () => const QuranDetailPage(),
    'TasbehPage': () => const TasbehPage(),
    'QiblaScreen': () => const QiblaScreen(key: ValueKey('body-state')),
    'WidgetGuidePage': () => const WidgetGuidePage(),
    'SettingsPage': () => const SettingsPage(),
    'NotificationsScreen': () => const NotificationsScreen(),
    'PrayerTimesSettingsScreen': () => const PrayerTimesSettingsScreen(),
    'ContactUsPage': () => const ContactUsPage(),
    'AdhanPage': () => const AdhanPage(prayerKey: 'fajr'),
    'SplashPage': () => const SplashPage(),
  };

  // 1.5 هو أقصى ما يسمح به شريط حجم الخط في الإعدادات، و2.0 يغطّي ما بعده.
  final List<double> scales =
      (Platform.environment['SWEEP_SCALES'] ?? '1.0,2.0')
          .split(',')
          .map(double.parse)
          .toList();

  final Map<String, Size> surfaces = {
    '320x600': const Size(320, 600),
    '390x844': const Size(390, 844),
    '430x932': const Size(430, 932),
    '1000x1200': const Size(1000, 1200),
  };

  // ScreenUtil مقياس عام للـ isolate، وثوابت home_page ثابتة تُحسب مرة واحدة،
  // لذا لا يصحّ تشغيل مقاسات مختلفة داخل نفس العملية: النتيجة تتسرّب من
  // الاختبار إلى التالي. لذلك يعمل هذا الملف على مقاس واحد لكل تشغيل: مقاس
  // التصميم 430x932 افتراضياً (وهي الحالة التي تعمل بها CI)، وبقية المقاسات
  // عبر متغير بيئة: SWEEP_CASE="320x600@x2.0" flutter test ...
  final String requested = Platform.environment['SWEEP_CASE'] ?? '430x932@x1.0';
  final String? onlyScreens = Platform.environment['SWEEP_SCREEN'];
  final Set<String>? screenFilter = onlyScreens?.split(',').toSet();

  // الأوراق تنضم إلى الشاشات في نفس الحلقة: نفس المقاسات ونفس مقاييس الخط.
  final Map<String, Widget Function()> targets = <String, Widget Function()>{
    ...screens,
    for (final MapEntry<String, void Function(BuildContext)> s
        in _sheets.entries)
      s.key: () => _sheetHost(s.value),
  };

  for (final entry in targets.entries) {
    for (final surface in surfaces.entries) {
      for (final textScale in scales) {
        final String caseName = '${surface.key}@x$textScale';
        if (requested != caseName) continue;
        if (screenFilter != null && !screenFilter.contains(entry.key)) {
          continue;
        }
        testWidgets('${entry.key} @ ${surface.key} @ text x$textScale',
            (tester) async {
          tester.view.physicalSize = surface.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final List<FlutterErrorDetails> details = <FlutterErrorDetails>[];
          final env = await _providers();
          //Providers غير مُصفَّرة تترك استثناءات تتسرّب إلى الاختبار التالي،
          // فيُبلَّغ عن خطأ في الشاشة الخطأ. نُفكّك الشجرة ثم نتخلص منها.
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            for (final ChangeNotifier notifier in env.notifiers) {
              notifier.dispose();
            }
          });
          // QiblaScreen يقرأ QiblaProvider من حاوية GetIt لا من Provider.
          if (sl.isRegistered<QiblaProvider>()) {
            await sl.unregister<QiblaProvider>();
          }
          sl.registerFactory<QiblaProvider>(_FakeQiblaProvider.new);
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            if (sl.isRegistered<QiblaProvider>()) {
              await sl.unregister<QiblaProvider>();
            }
          });

          // نلتقط تفاصيل FlutterError كاملة لأن takeException يُرجع الرسالة
          // فقط، بينما "الـ widget المسبّب" فيه اسم الملف ورقم السطر — وهو
          // أسرع طريق لتحديد موضع الازدحام.
          final void Function(FlutterErrorDetails)? prevOnError =
              FlutterError.onError;
          FlutterError.onError = (FlutterErrorDetails d) {
            details.add(d);
            prevOnError?.call(d);
          };
          addTearDown(() => FlutterError.onError = prevOnError);
          await tester.pumpWidget(
            _app(
              home: entry.value(),
              providers: env.providers,
              textScale: textScale,
            ),
          );
          // SplashPage ينتظر 2.5 ثانية قبل الانتقال، فنفوّت ذلك بمضخة واحدة.
          if (entry.key == 'SplashPage') {
            await tester.pump(const Duration(milliseconds: 3000));
          }
          await _settle(tester);
          await _tapThrough(tester, entry.key);
          // takeException() يُرجع أول استثناء ويمسحه، فلا يكفي لفحص شاشة قد
          // يكون فيها أكثر من موضع ازدحام: نجمعها كلها في قائمة واحدة.
          final List<String> problems = <String>[];
          while (true) {
            final Object? thrown = tester.takeException();
            if (thrown == null) break;
            problems.add(_describe(
              thrown,
              entry.key,
              surface.key,
              textScale,
              _culprit(details),
            ));
          }
          expect(
            problems,
            isEmpty,
            reason: problems.join('\n\n'),
          );
        });
      }
    }
  }
}

/// يضغط عناصر أساسية في الشاشة حتى تُبنى البطاقات غير المرئية أيضاً، لأن
/// كثيراً من أخطاء التخطيط لا تظهر إلا بعد التفاعل.
Future<void> _tapThrough(WidgetTester tester, String screen) async {
  final List<String> labels = switch (screen) {
    'TasbehPage' => const [
        'السبحان',
        'الحمد لله',
        'الله أكبر',
        'لا إله إلا الله',
        'الصلاة على النبي',
      ],
    'SurahListPage' => [_useRealData ? _realSurah.first.name : 'سورة رقم 1'],
    'AllAzkarPage' => [_morning],
    'AzkarDetailsPage' => [
        _morning,
        // أطول نص في الفئة هو العنصر الأكثر عرضاً، وهو ما لا يظهر إن لم
        // نمرّر إليه لأن ListView لا تبني ما هو خارج الشاشة.
        _longestAzkarZekr.split('\n').first.trim(),
      ],
    _ => const <String>[],
  };
  for (final label in labels) {
    final Finder target = find.text(label);
    if (target.evaluate().isEmpty) continue;
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first, warnIfMissed: false);
    await _settle(tester);
  }

  // شريط الاستماع معلّق فوق الصفحة بـ Stack/Align، فلا يُبنى إلا بعد الضغط
  // على زر السمّاعة. بدون هذه الخطوة لم يفحصه الفحص إطلاقاً: توسّعه كان يوماً
  // يتجاوز الشاشة كاملة دون أن يلتقطه الاختبار.
  if (screen == 'QuranDetailPage') {
    final Finder audio = find.byTooltip('الاستماع');
    if (audio.evaluate().isNotEmpty) {
      await tester.tap(audio.first, warnIfMissed: false);
      await _settle(tester);
    }
  }
}
