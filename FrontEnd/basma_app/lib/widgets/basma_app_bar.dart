import 'package:basma_app/theme/app_system_ui.dart';
import 'package:flutter/material.dart';

class BasmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const BasmaAppBar({super.key, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AppBar(
      backgroundColor: const Color(0xFFEFF1F1),
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: AppSystemUi.green,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Image.asset(
        "assets/images/logo-arabic-side.png",
        height: size.height * 0.05,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
