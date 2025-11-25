// Deprecated compatibility wrapper.
// Use `AppMainAppBar` instead. This file remains to avoid a breaking change
// during transition; it delegates to `AppMainAppBar`.

import 'package:flutter/material.dart';
import 'package:basma_app/widgets/app_main_app_bar.dart';

@Deprecated(
  'Use `AppMainAppBar` instead. This wrapper will be removed in a future release.',
)
class BasmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const BasmaAppBar({super.key, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppMainAppBar(showBack: showBack, onBack: onBack);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
