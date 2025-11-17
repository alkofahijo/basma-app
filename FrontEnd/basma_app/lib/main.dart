import 'package:basma_app/pages/on_start/splash_screen.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ إعداد شريط الحالة/التنقل الأخضر للتطبيق كله
  AppSystemUi.applyGreen();

  final sp = await SharedPreferences.getInstance();
  final token = sp.getString('token');

  // لو ما في توكن اعتبره ضيف ونمسح أي بقايا من مستخدم قديم
  if (token == null || token.isEmpty) {
    await sp.clear();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        fontFamily: 'Cairo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: const Color(0xFFEFF1F1),
        chipTheme: const ChipThemeData(showCheckmark: false),
      ),
      home: const SplashScreen(),
    );
  }
}
