import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:basma_app/pages/on_start/home_page.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/pages/profile/profile_page.dart';
import 'package:basma_app/pages/reports/history/reports_list_page.dart';

class BasmaBottomNavPage extends StatefulWidget {
  final int currentIndex;

  const BasmaBottomNavPage({super.key, required this.currentIndex});

  @override
  State<BasmaBottomNavPage> createState() => _BasmaBottomNavPageState();
}

class _BasmaBottomNavPageState extends State<BasmaBottomNavPage>
    with SingleTickerProviderStateMixin {
  // Visual constants
  // Compact, modern sizing
  static const double _kBarHeight = 64.0;
  // removed _kHorizontalPadding as it is unused
  static const double _kItemSpacing = 6.0;
  static const double _kIconSize = 20.0;
  static const double _kActiveIconSize = 22.0;
  static const double _kActivePillHeight = 34.0;
  static const double _kRadius = 16.0;

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('token');
      if (!mounted) return;
      setState(() => _isLoggedIn = token != null && token.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggedIn = false);
    }
  }

  void _onTap(int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Get.offAll(() => const HomePage());
        break;
      case 1:
        Get.offAll(() => const GuestReportsListPage(initialMainTab: 'mine'));
        break;
      case 2:
        Get.offAll(() => const ProfilePage());
        break;
    }
  }

  int _normalizedIndex(int raw) {
    if (raw < 0) return -1;
    if (raw == 3) return 2;
    return raw;
  }

  Color _unselectedColor(BuildContext context) => Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    final activeIndex = _normalizedIndex(widget.currentIndex);

    // Compute a small responsive bottom padding based on the device
    // bottom inset (home indicator area). We keep SafeArea bottom=false
    // to allow the bar to visually touch the screen edge, but add a
    // small internal padding so the bar doesn't interfere with gestures.
    final double bottomViewInset = MediaQuery.of(context).viewPadding.bottom;
    final double responsiveBottom = bottomViewInset > 0
        ? (bottomViewInset * 0.4).clamp(6.0, 18.0)
        : 8.0;

    // Use a non-const constraint since responsiveBottom is dynamic.
    return SafeArea(
      top: false,
      bottom: false,
      // removed outer horizontal padding so the nav is edge-to-edge
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: _kBarHeight + responsiveBottom),
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 6,
          bottom: responsiveBottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.98 * 255).round()),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kRadius),
            topRight: Radius.circular(_kRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.10 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha((0.03 * 255).round()),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              index: 2,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'ملفي',
              isActive: activeIndex == 2,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt,
              label: 'بلاغاتي',
              isActive: activeIndex == 1,
            ),
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'الرئيسية',
              isActive: activeIndex == 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
  }) {
    final Color activeBg = kPrimaryColor; // on-brand
    final Color inactiveColor = _unselectedColor(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onTap(index),
          splashColor: kPrimaryColor.withAlpha((0.12 * 255).round()),
          highlightColor: kPrimaryColor.withAlpha((0.06 * 255).round()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated active pill behind icon (compact)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: isActive ? _kActivePillHeight : 34,
                  width: isActive ? 52 : 40,
                  decoration: BoxDecoration(
                    color: isActive ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: activeBg.withAlpha((0.16 * 255).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey<bool>(isActive),
                        size: isActive ? _kActiveIconSize : _kIconSize,
                        color: isActive ? Colors.white : inactiveColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _kItemSpacing - 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? kPrimaryColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
                // small active indicator dot
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: isActive ? 18 : 0,
                  decoration: BoxDecoration(
                    color: isActive ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
