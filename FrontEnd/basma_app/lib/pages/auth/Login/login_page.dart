import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/app_main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:basma_app/widgets/buttons/app_buttons.dart';
import 'package:basma_app/widgets/inputs/app_text_field.dart';
import 'package:basma_app/widgets/inputs/app_password_field.dart';

import '../../../controllers/login_controller.dart';
import '../Registeration/register_account_info_page.dart';
import 'forgot_credentials_help_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: AppMainAppBar(
        showBack: true,
        onBack: () => Get.offAll(() => const LandingPage()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.04,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
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

              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                child: const Text(
                  'اسم المستخدم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              AppTextField(
                onChanged: (v) => controller.email.value = v,
                hint: 'أدخل اسم المستخدم',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: size.height * 0.02),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                child: const Text(
                  'كلمة المرور',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              AppPasswordField(
                hint: 'أدخل كلمة المرور',
                onChanged: (v) => controller.password.value = v,
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
                  child: AppPrimaryButton(
                    label: 'تسجيل الدخول',
                    isLoading: controller.isLoading.value,
                    onPressed:
                        controller.isLoading.value && controller.isFormValid
                        ? null
                        : controller.login,
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
