import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/login_page.dart';

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEFF1F1),
        centerTitle: true,
        title: Image.asset(
          "assets/images/logo-arabic-side.png",
          height: size.height * 0.05,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.1),
              // Success Image
              Image.asset(
                "assets/images/success.png",
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              SizedBox(height: size.height * 0.04),

              // Title
              const Text(
                'تم التسجيل بنجاح!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.01),

              // Subtitle
              const Text(
                'تم تسجيل حسابك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              SizedBox(height: size.height * 0.25),

              // Back Button
              SizedBox(
                width: size.width * 0.8,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Get.offAll(() => LoginPage());
                  },
                  child: const Text(
                    'العودة إلى صفحة تسجيل الدخول',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
