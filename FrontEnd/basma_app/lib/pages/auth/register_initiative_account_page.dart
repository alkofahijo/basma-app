import 'package:basma_app/pages/custom_widgets.dart/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/register_initiative_controller.dart';

class RegisterInitiativeAccountPage extends StatelessWidget {
  const RegisterInitiativeAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterInitiativeController>();

    return Scaffold(
      backgroundColor: Color(0xFFEFF1F1),
      appBar: AppBar(
        title: const Text('معلومات الحساب'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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

              Obx(
                () => CustomTextField(
                  controller: controller.usernameCtrl,
                  label: 'اسم المستخدم',
                  hint: 'أدخل اسم المستخدم',
                  errorText: controller.usernameError.value,
                ),
              ),
              const SizedBox(height: 18),

              Obx(
                () => CustomTextField(
                  controller: controller.passwordCtrl,
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  obscure: true,
                  errorText: controller.passwordError.value,
                ),
              ),
              const SizedBox(height: 30),

              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submit,
                  child: controller.isSubmitting.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال',
                          style: TextStyle(color: Colors.white),
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
