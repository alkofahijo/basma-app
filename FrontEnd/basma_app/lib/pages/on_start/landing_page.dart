// lib/pages/on_start/landing_page.dart

import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_option_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:basma_app/pages/reports/history/reports_list_page.dart';
import 'package:basma_app/pages/auth/Login/login_page.dart';
import 'package:basma_app/pages/Accounts/accounts_list_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: const BasmaAppBar(),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.04,
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  'اختر إجراءك!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width * 0.090,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  'هل أنت مستعد لإحداث فرق في مجتمعك؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يمكنك البدء كضيف أو تسجيل الدخول للخيارات المتقدمة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: size.height * 0.08),

                // تصفح البلاغات كضيف
                HomeScreenButton(
                  icon: Icons.assignment,
                  title: 'تصفح البلاغات',
                  subtitle: 'تصفح بلاغات التشوه البصري كضيف.',
                  onTap: () {
                    Get.to(() => const GuestReportsListPage());
                  },
                  color: const Color(0xFFCAF2DB),
                  iconColor: const Color.fromARGB(255, 19, 106, 32),
                ),
                SizedBox(height: size.height * 0.03),

                // قائمة المتطوعين
                HomeScreenButton(
                  icon: Icons.volunteer_activism,
                  title: 'قائمة المتطوعين',
                  subtitle: 'عرض  الجهات المشاركة في حل مشكلات التشوه البصري.',
                  onTap: () {
                    Get.to(() => const AccountsListPage());
                  },
                  color: const Color(
                    0xFFFFF2CC,
                  ), // لون دافئ يناسب العمل التطوعي
                  iconColor: const Color(0xFFB45F06),
                ),
                SizedBox(height: size.height * 0.03),

                // تسجيل الدخول
                HomeScreenButton(
                  icon: Icons.person_outline,
                  title: 'تسجيل الدخول',
                  subtitle: 'تسجيل الدخول للتبليغ عن أو حل مشكلة تشوه بصري.',
                  onTap: () {
                    Get.to(() => LoginPage());
                  },
                  color: const Color(0xFFCAE6F2),
                  iconColor: const Color.fromARGB(255, 10, 62, 104),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
