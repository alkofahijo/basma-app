import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_typography.dart';
import 'package:basma_app/theme/app_system_ui.dart';

class AppTheme {
  static ThemeData themeFor(BuildContext context) {
    return ThemeData(
      fontFamily: 'Cairo',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: const Color(0xFFEFF1F1),
      chipTheme: const ChipThemeData(showCheckmark: false),
      textTheme: AppTypography.textTheme(context),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: AppSystemUi.green,
      ),
    );
  }
}
