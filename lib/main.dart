import 'package:azkar_app/core/presentation/providers/notification_provider.dart';
import 'package:azkar_app/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/surah/domain/usecases/get_surah_usecase.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart';
import 'package:azkar_app/features/tasbeh/presentation/providers/tasbeh_provider.dart';
import 'package:azkar_app/pages/splash_page.dart';
import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/services/notifications_service.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'di/injection_container.dart' as di;

final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await ScreenUtil.ensureScreenSize();
  tz.initializeTimeZones();
  final notificationService = sl<NotificationService>();
  await notificationService.initNotification();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AzkarProvider(
            getAzkarUseCase: sl<GetAzkarUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NamesOfAllahProvider(
            getNamesOfAllahUseCase: sl<GetNamesOfAllahUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SurahProvider(
            getSurahUseCase: sl<GetSurahUseCase>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TasbehProvider(
          sharedPreferences: sl<SharedPreferences>(),
        )),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(
                notificationService: sl<NotificationService>())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    Provider.of<ThemeProvider>(context, listen: false).loadTheme();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (ctx, screenUtilChild) {
            ScreenUtil.init(ctx);
            return MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(themeProvider.textScaleFactor),
              ),
              child: MaterialApp(
                title: 'أذكــــاري | Azkari',
                supportedLocales: const [Locale('ar')],
                locale: const Locale('ar'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                theme: themeProvider.isLight
                    ? AppPalette.lightTheme
                    : AppPalette.darkTheme,
                home: screenUtilChild,
              ),
            );
          },
          child: const SplashPage(),
        );
      },
    );
  }
}
