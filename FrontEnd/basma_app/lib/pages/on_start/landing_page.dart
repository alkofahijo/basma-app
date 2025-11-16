import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_option_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../reports/history/reports_list_page.dart';
import '../auth/Login/login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: const BasmaAppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06,
          vertical: size.height * 0.04,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              SizedBox(height: size.height * 0.08),
              HomeScreenButton(
                icon: Icons.assignment,
                title: 'تصفح البلاغات',
                subtitle: "تصفح بلاغات التشوه البصري كضيف",
                onTap: () {
                  Get.to(() => GuestReportsListPage());
                },
                color: const Color(0xFFCAF2DB),
                iconColor: const Color.fromARGB(255, 19, 106, 32),
              ),
              SizedBox(height: size.height * 0.03),
              HomeScreenButton(
                icon: Icons.person_outline,
                title: 'تسجيل الدخول',
                subtitle:
                    'تسجيل الدخول كمواطن او كمبادرة للتبليغ عن او حل مشكلة تشوه بصري',
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
    );
  }
}
