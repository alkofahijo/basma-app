import 'package:basma_app/controllers/register_account_controller.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:basma_app/pages/auth/Registeration/Widgets/reg_success.dart';

class RegisterAccountCredentialsPage extends StatelessWidget {
  const RegisterAccountCredentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterAccountController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: const BasmaAppBar(showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(
          () => ListView(
            children: [
              const Text(
                'تفاصيل الحساب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: controller.usernameCtrl,
                label: 'اسم المستخدم',
                hint: 'أدخل اسم المستخدم',
                errorText: controller.usernameError.value,
                onChanged: controller.validateUsername,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                controller: controller.passwordCtrl,
                label: 'كلمة المرور',
                hint: 'أدخل كلمة المرور',
                obscure: true,
                errorText: controller.passwordError.value,
                onChanged: controller.validatePassword,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () {
                          // إغلاق الكيبورد
                          FocusScope.of(context).unfocus();

                          // استدعاء دالة التسجيل (ترجع void عندك)
                          controller.submit();

                          // بعد إنشاء الحساب ننتقل لصفحة النجاح
                          // (استبدال الصفحة الحالية)
                          Get.off(() => const RegisterSuccessPage());
                        },
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'إرسال',
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
