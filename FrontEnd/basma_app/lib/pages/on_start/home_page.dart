import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_option_button.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/pages/reports/history/reports_list_page.dart';

import '../reports/new/new_report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// هل ما زلنا نتحقق من حالة تسجيل الدخول؟
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthGuard();
  }

  /// التحقق من تسجيل الدخول
  Future<void> _checkAuthGuard() async {
    try {
      final user = await AuthService.currentUser();

      if (!mounted) return;

      if (user == null) {
        Get.offAll(() => const LandingPage());
      } else {
        setState(() {
          _checkingAuth = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Get.offAll(() => const LandingPage());
    }
  }

  Widget _buildHomeTab(BuildContext context, Size size) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.06,
        vertical: size.height * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر إجراءك!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.width * 0.090,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Text(
            'هل أنت مستعد لإحداث فرق في مجتمعك؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.width * 0.04,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          SizedBox(height: size.height * 0.08),

          // زر تقديم بلاغ
          HomeScreenButton(
            icon: Icons.camera_alt_outlined,
            title: 'تقديم بلاغ',
            subtitle: 'تقديم بلاغ عن تشوّه بصري\nفي منطقتك.',
            onTap: () {
              Get.to(() => CreateReportWithAiPage());
            },
            color: const Color(0xFFCAE6F2),
            iconColor: const Color.fromARGB(255, 10, 62, 104),
          ),

          SizedBox(height: size.height * 0.03),

          // زر تصفح البلاغات
          HomeScreenButton(
            icon: Icons.assignment,
            title: 'تصفح البلاغات',
            subtitle: 'عرض البلاغات المتاحة في المناطق المختلفة.',
            onTap: () {
              Get.offAll(() => const GuestReportsListPage());
            },
            color: const Color(0xFFCAF2DB),
            iconColor: const Color.fromARGB(255, 19, 106, 32),
          ),

          SizedBox(height: size.height * 0.03),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: const BasmaAppBar(),
        body: _buildHomeTab(context, size),
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: 0),
      ),
    );
  }
}
