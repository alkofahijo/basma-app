import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/utils/responsive.dart';

class AppTypography {
  // Provide textTheme based on screen size via helper sp when used in widgets
  static TextTheme textTheme(BuildContext context) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: R.sp(context, 34),
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontSize: R.sp(context, 28),
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontSize: R.sp(context, 20),
        fontWeight: FontWeight.w700,
        color: kPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: R.sp(context, 18),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: R.sp(context, 16)),
      bodyMedium: TextStyle(fontSize: R.sp(context, 14)),
      bodySmall: TextStyle(fontSize: R.sp(context, 12)),
      labelLarge: TextStyle(
        fontSize: R.sp(context, 14),
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(fontSize: R.sp(context, 12)),
    );
  }
}
