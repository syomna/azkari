import 'package:azkar_app/pages/splash_page.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/providers/theme_provider.dart';
import 'package:azkar_app/utils/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  NotificationService().initNotification();
  tz.initializeTimeZones();
  NotificationService().scheduleNotifications();
  NotificationService().periodicallyShowNotification();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => AzkarProvider()), // Add your new provider here
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
  // This widget is the root of your application.

  @override
  void initState() {
    Provider.of<ThemeProvider>(context, listen: false).loadTheme();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (ctx, child) {
        ScreenUtil.init(ctx);
        return MaterialApp(
          title: 'أذكــــاري | Azkari',
          supportedLocales: const [Locale('ar')],
          locale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: !themeProvider.isLight
              ? ThemeData.dark().copyWith(
                  textTheme: Typography.englishLike2018
                      .apply(fontSizeFactor: 1.sp)
                      .apply(fontFamily: 'Tajawal', bodyColor: Colors.white),
                )
              : ThemeData.light()
                  .copyWith(
                    textTheme: Typography.englishLike2018
                        .apply(fontSizeFactor: 1.sp)
                        .apply(fontFamily: 'Tajawal', bodyColor: Colors.black),
                  )
                  .copyWith(primaryColorDark: Colors.white),
          home: child,
        );
      },
      child: const SplashPage(),
    );
  }
}
