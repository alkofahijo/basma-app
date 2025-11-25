import 'package:basma_app/pages/on_start/splash_screen.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/services/global_error_handler.dart';
// app colors used via AppTheme
import 'package:basma_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Run the app inside a guarded zone to catch uncaught async errors.
  // Ensure all initialization (including `WidgetsFlutterBinding.ensureInitialized`)
  // runs inside the same zone as `runApp` to avoid Zone mismatch errors.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppSystemUi.applyGreen();

    // Initialize global error handling (shows network errors via snackbar)
    initGlobalErrorHandler();

    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');

    if (token == null || token.isEmpty) {
      await sp.clear();
    }

    runApp(const MyApp());
  }, (error, stack) {
    // forward to the global handler
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
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
      theme: AppTheme.themeFor(context),
      home: const SplashScreen(),
    );
  }
}
