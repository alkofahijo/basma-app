// lib/pages/home_page.dart

import 'package:basma_app/pages/landing_page.dart';
import 'package:basma_app/pages/custom_widgets.dart/home_screen_button.dart';
import 'package:basma_app/pages/guest/guest_reports_list_page.dart';
import 'package:basma_app/pages/report/select_location_page.dart';
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
          color: const Color(0xFFEFF1F1),
          child: _buildHomeTab(context, size),
        ),
      ),
    );
  }
}
