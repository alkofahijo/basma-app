import 'package:flutter/widgets.dart';

/// Simple responsive helpers.
/// Use `R.w(context, 0.5)` for 50% of screen width, or `R.sp(context, 16)` for scaled text.
class R {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// width percent in 0..1
  static double w(BuildContext context, double percent) =>
      screenWidth(context) * percent;

  /// height percent in 0..1
  static double h(BuildContext context, double percent) =>
      screenHeight(context) * percent;

  /// scaled text size based on a 375pt reference width (iPhone 8 width)
  static double sp(BuildContext context, double fontSize) {
    final baseWidth = 375.0;
    final scale = screenWidth(context) / baseWidth;
    return fontSize * scale;
  }

  /// Utility to get constrained size from LayoutBuilder constraints
  static Size sizeFromConstraints(BoxConstraints constraints) =>
      Size(constraints.maxWidth, constraints.maxHeight);
}
