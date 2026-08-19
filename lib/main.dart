import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/add_structure_provider.dart';
import 'package:sams_engineering_console/provider/add_structure_ratings_provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/provider/quantification_provider.dart';
import 'package:sams_engineering_console/provider/testing_provider.dart';
import 'package:sams_engineering_console/provider/testing_results_provider.dart';
import 'package:sams_engineering_console/service/navigator_service.dart';
import 'package:sams_engineering_console/ui/auth/onboarding_screen.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await ScreenUtil.ensureScreenSize();

      runApp(MyApp());
    },
    (error, stack) {
      debugPrint("Error while launching application $error && $stack");
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Key _appKey = UniqueKey();

  void restartApp() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return DevicePreview(
          enabled: false,
          tools: const [...DevicePreview.defaultTools],
          builder: (context) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider<CommonProvider>(
                  create: (context) => CommonProvider(),
                ),
                ChangeNotifierProvider<AddstructureProvider>(
                  create: (context) => AddstructureProvider(),
                ),
                ChangeNotifierProvider<GetstructureProvider>(
                  create: (context) => GetstructureProvider(),
                ),
                ChangeNotifierProvider<AddRatingsStructureProvider>(
                  create: (context) => AddRatingsStructureProvider(),
                ),
                ChangeNotifierProvider<QuantificationProvider>(
                  create: (context) => QuantificationProvider(),
                ),
                ChangeNotifierProvider<TestingProvider>(
                  create: (context) => TestingProvider(),
                ),
                ChangeNotifierProvider<TestingResultsProvider>(
                  create: (context) => TestingResultsProvider(),
                ),
              ],
              child: MaterialApp(
                key: _appKey,
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'SplashScreen',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  scaffoldBackgroundColor: const Color(0xffF7F8FA),
                  canvasColor: Colors.white,
                  dialogBackgroundColor: Colors.white,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    background: const Color(0xffF7F8FA),
                    surface: Colors.white,
                  ),
                  textTheme: Typography.englishLike2018.apply(
                    fontSizeFactor: 1.sp,
                  ),
                ),
                home: child,
              ),
            );
          },
        );
      },
      // ─── FIX: removed MyHomePage wrapper — it had a nested Scaffold
      // ─── that was rendering a black background behind OnboardingScreen
      child: const OnboardingScreen(),
    );
  }
}
