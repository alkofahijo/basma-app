import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:basma_app/theme/app_colors.dart';

/// مكان واحد نعرّف فيه شكل شريط الحالة وشريط التنقل
class AppSystemUi {
  static final SystemUiOverlayStyle green = SystemUiOverlayStyle(
    statusBarColor: kPrimaryColor,
    statusBarIconBrightness: Brightness.light, // أيقونات بيضاء (Android)
    statusBarBrightness: Brightness.dark, // نص غامق في iOS
    systemNavigationBarColor: Color(0xFFEFF1F1),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// نستخدمها في main مرة واحدة
  static void applyGreen() {
    SystemChrome.setSystemUIOverlayStyle(green);
  }
}
