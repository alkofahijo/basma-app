// lib/pages/on_start/login_page.dart

import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/login_controller.dart';
import '../Registeration/register_account_info_page.dart';
import 'forgot_credentials_help_page.dart'; // ✅ استيراد صفحة المساعدة

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: BasmaAppBar(
        showBack: true,
        onBack: () => Get.offAll(() => const LandingPage()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.04,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl, // ✅ RTL
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تسجيل الدخول إلى حسابك',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              const Text(
                'الرجاء إدخال بياناتك للوصول إلى حسابك.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Obx(
                () => controller.errorMessage.isNotEmpty
                    ? Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                            size: 19,
                          ),
                          SizedBox(width: size.width * 0.01),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: size.height * 0.01),

              // ===== اسم المستخدم =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                child: const Text(
                  'اسم المستخدم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              TextField(
                onChanged: (v) => controller.email.value = v,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'أدخل اسم المستخدم',
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 154, 157, 154),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.02,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // ===== كلمة المرور =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                child: const Text(
                  'كلمة المرور',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Obx(
                () => TextField(
                  onChanged: (v) => controller.password.value = v,
                  obscureText: controller.obscurePassword.value,
                  decoration: InputDecoration(
                    hintText: 'أدخل كلمة المرور',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 154, 157, 154),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color.fromARGB(255, 117, 119, 117),
                      ),
                      onPressed: controller.togglePassword,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.02,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.01),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.to(() => const ForgotCredentialsHelpPage());
                  },
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color.fromARGB(255, 117, 119, 117),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              Obx(
                () => SizedBox(
                  width: size.width * 0.8,
                  height: size.height * 0.06,
                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading.value && controller.isFormValid
                        ? null
                        : controller.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟ '),
                    GestureDetector(
                      onTap: () => Get.to(() => const RegisterChoicePage()),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
