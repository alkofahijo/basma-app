import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/utils/responsive.dart';

enum AppLogoVariant { normal, onPrimaryBg, appBar }

class AppLogo extends StatelessWidget {
  final double? sizeFactor; // fraction of height (0..1) when used
  final double? maxWidth;
  final AppLogoVariant variant;
  final String assetPath;

  const AppLogo({
    super.key,
    this.sizeFactor,
    this.maxWidth,
    this.variant = AppLogoVariant.normal,
    this.assetPath = 'assets/images/logoligth.png',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = R.screenHeight(context);
        final fallbackFactor = sizeFactor ?? 0.06;
        final h = (fallbackFactor * screenH).clamp(24.0, 300.0);
        final w = maxWidth ?? constraints.maxWidth;

        Widget img = Image.asset(
          assetPath,
          color: kPrimaryColor,
          height: h,
          width: w == double.infinity ? null : w,
          fit: BoxFit.contain,
        );

        switch (variant) {
          case AppLogoVariant.onPrimaryBg:
            // place logo on a rounded primary background to mask white background.
            return Container(
              padding: EdgeInsets.all(h * 0.18),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(h * 0.25),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: img,
              ),
            );
          case AppLogoVariant.appBar:
            return SizedBox(height: h, child: img);
          case AppLogoVariant.normal:
            return img;
        }
      },
    );
  }
}
