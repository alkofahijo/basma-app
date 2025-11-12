import 'package:basma_app/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

void main() {
  runApp(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale('ar'),
        fallbackLocale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFEFF1F1)),
        home: SplashScreen(),
      ),
  );
}