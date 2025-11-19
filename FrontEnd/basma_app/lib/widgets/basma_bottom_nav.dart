import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:basma_app/pages/on_start/home_page.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/pages/profile/profile_page.dart';
import 'package:basma_app/pages/reports/history/reports_list_page.dart';

// use central primary color

class BasmaBottomNavPage extends StatefulWidget {
  final int currentIndex;

  const BasmaBottomNavPage({super.key, required this.currentIndex});

  @override
  State<BasmaBottomNavPage> createState() => _BasmaBottomNavPageState();
}

class _BasmaBottomNavPageState extends State<BasmaBottomNavPage> {
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

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return Container(
      height: 80,
      padding: EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_outlined,
            index: 2,
            label: "ملفي",
          ),
          _navItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            index: 1,
            label: "بلاغاتي",
          ),
          _navItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_outlined,
            index: 0,
            label: "الرئيسية",
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
  }) {
    final int activeIndex = _normalizedIndex(widget.currentIndex);
    final bool isActive = activeIndex >= 0 && index == activeIndex;

    return GestureDetector(
      onTap: () => _onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 30,
            color: isActive ? kPrimaryColor : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? kPrimaryColor : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _normalizedIndex(int raw) {
    // Some pages pass `3` for profile (historical), while the nav uses `2`.
    // Normalize older values so the correct icon shows active.
    if (raw < 0) return -1;
    if (raw == 3) return 2; // treat 3 as profile
    return raw;
  }
}
