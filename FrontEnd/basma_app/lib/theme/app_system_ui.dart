import 'package:flutter/services.dart';
import 'package:basma_app/theme/app_colors.dart';

class AppSystemUi {
  static final SystemUiOverlayStyle green = SystemUiOverlayStyle(
    statusBarColor: kPrimaryColor,
    statusBarIconBrightness: Brightness.light, // أيقونات بيضاء (Android)
    statusBarBrightness: Brightness.dark, // نص غامق في iOS
    systemNavigationBarColor: Color(0xFFEFF1F1),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static void applyGreen() {
    SystemChrome.setSystemUIOverlayStyle(green);
  }
}
