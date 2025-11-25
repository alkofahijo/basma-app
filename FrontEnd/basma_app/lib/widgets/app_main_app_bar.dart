import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/app_logo.dart';

/// A reusable main AppBar for the app.
///
/// - Primary color: `Color(0xFF039844)`
/// - White title and icons
/// - Proper SafeArea / status bar handling via `AppSystemUi.green`
class AppMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;

  const AppMainAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    // Apply a consistent system overlay style for status bar icons.
    // AppSystemUi.green already configures status bar colors/brightness.
    // Using AnnotatedRegion ensures the style is applied while this AppBar is visible.
    // include the status bar height so the AppBar paints behind the status bar
    final windowPadding = MediaQuery.of(context).padding;
    final double topPadding = windowPadding.top;

    final double totalHeight = kToolbarHeight + topPadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.green,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // background for status bar and appbar
            Container(color: kPrimaryColor),
            // actual AppBar content positioned below status bar
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: centerTitle,
                systemOverlayStyle: AppSystemUi.green,
                leading: showBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      )
                    : null,
                title:
                    titleWidget ??
                    (title != null
                        ? Text(
                            title!,
                            style: const TextStyle(color: Colors.white),
                          )
                        : null),
                actions: actions,
                // show logo when no title
                flexibleSpace: title == null && titleWidget == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AppLogo(
                            variant: AppLogoVariant.onPrimaryBg,
                            sizeFactor: 0.04,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    final windowPadding = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).padding;
    final double topPadding = windowPadding.top;
    return Size.fromHeight(kToolbarHeight + topPadding);
  }
}
