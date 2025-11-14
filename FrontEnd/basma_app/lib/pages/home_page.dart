// lib/pages/home_page.dart

import 'package:basma_app/pages/landing_page.dart';
import 'package:basma_app/pages/custom_widgets.dart/home_screen_button.dart';
import 'package:basma_app/pages/guest/guest_reports_list_page.dart';
import 'package:basma_app/pages/report/select_location_page.dart';
import 'package:basma_app/pages/profile/profile_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'report/create_report_with_ai_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // 0 = الرئيسية, 1 = الملف الشخصي

  Future<void> _ensureLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Get.offAll(() => LandingPage());
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureLoggedIn();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await ApiService.setToken(null);
      final sp = await SharedPreferences.getInstance();
      await sp.remove('user_type');
      await sp.remove('citizen_id');
      await sp.remove('initiative_id');

      Get.offAll(() => LandingPage());
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

          // === الزر الجديد: بلاغ بالذكاء الاصطناعي ===
          HomeScreenButton(
            icon: Icons.auto_awesome_outlined,
            title: ' تقديم بلاغ بالذكاء الاصطناعي',
            subtitle:
                'يتم تحديد موقعك الحالي و عنوان ونوع ووصف التشوه البصري تلقائياً .',
            onTap: () {
              Get.to(() => const CreateReportWithAiPage());
            },
            color: const Color(0xFFE3D7FF),
            iconColor: const Color(0xFF5C2D91),
          ),
          SizedBox(height: size.height * 0.03),

          // البلاغ اليدوي السابق
          HomeScreenButton(
            icon: Icons.camera_alt_outlined,
            title: 'تقديم بلاغ جديد',
            subtitle: "اختيار  الموقع وادخال بيانات التشوه البصري ",
            onTap: () {
              Get.to(() => const SelectLocationPage());
            },
            color: const Color(0xFFCAE6F2),
            iconColor: const Color.fromARGB(255, 10, 62, 104),
          ),
          SizedBox(height: size.height * 0.03),

          HomeScreenButton(
            icon: Icons.assignment,
            title: 'تصفح البلاغات',
            subtitle: 'عرض البلاغات المتاحة في المناطق المختلفة.',
            onTap: () {
              Get.to(() => const GuestReportsListPage());
            },
            color: const Color(0xFFCAF2DB),
            iconColor: const Color.fromARGB(255, 19, 106, 32),
          ),
          SizedBox(height: size.height * 0.03),

          HomeScreenButton(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            subtitle: 'تسجيل الخروج من الحساب الحالي.',
            onTap: () => _logout(context),
            color: const Color(0xFFFAD4D4),
            iconColor: Colors.redAccent,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEFF1F1),
          elevation: 0,
          title: Image.asset(
            "assets/images/logo-arabic-side.png",
            height: size.height * 0.05,
          ),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.white,
          child: _currentIndex == 0
              ? _buildHomeTab(context, size)
              : const ProfilePage(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.teal.shade700,
          unselectedItemColor: Colors.grey.shade600,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }
}
