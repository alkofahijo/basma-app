// lib/main.dart
import 'package:basma_app/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sp = await SharedPreferences.getInstance();
  final token = sp.getString('token');

  // لو ما في توكن اعتبره ضيف ونمسح أي بقايا من مستخدم قديم
  if (token == null || token.isEmpty) {
    await sp.clear();
  }

  runApp(
    GetMaterialApp(
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
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFEFF1F1)),
      home: const SplashScreen(),
    ),
  );
}
