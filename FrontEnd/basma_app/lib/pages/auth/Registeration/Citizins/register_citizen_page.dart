import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/register_citizen_controller.dart';
import '../../../../../models/location_models.dart';
import 'package:basma_app/widgets/loading_center.dart';

class RegisterCitizenPage extends StatelessWidget {
  const RegisterCitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterCitizenController());
    final size = MediaQuery.of(context).size;

    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingCenter();
      }

      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: const BasmaAppBar(showBack: true),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Title =====
                Center(
                  child: Text(
                    'التسجيل كمواطن',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Center(
                  child: Text(
                    'الرجاء تعبئة البيانات أدناه لإنشاء حسابك.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                if (controller.errorMessage.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(height: size.height * 0.02),

                // ===== Arabic Name =====
                Obx(
                  () => CustomTextField(
                    hint: 'أدخل اسمك بالعربية',
                    controller: controller.arController,
                    label: 'الاسم (بالعربية)',
                    errorText: controller.nameArError.value,
                    onChanged: controller.validateArabicName,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== English Name =====
                Obx(
                  () => CustomTextField(
                    hint: 'أدخل اسمك بالإنجليزية',
                    controller: controller.enController,
                    label: 'الاسم (بالإنجليزية)',
                    errorText: controller.nameEnError.value,
                    onChanged: controller.validateEnglishName,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Username =====
                Obx(
                  () => CustomTextField(
                    hint: 'أدخل اسم المستخدم',
                    controller: controller.userController,
                    label: 'اسم المستخدم',
                    errorText: controller.userError.value,
                    onChanged: controller.validateUsername,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Password =====
                Obx(
                  () => CustomTextField(
                    hint: 'أدخل كلمة المرور',
                    controller: controller.passController,
                    label: 'كلمة المرور',
                    obscure: true,
                    errorText: controller.passError.value,
                    onChanged: controller.validatePassword,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Governorate =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                  child: const Text(
                    'المحافظة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                Obx(
                  () => DropdownButtonFormField<Government>(
                    hint: const Text('اختر محافظتك'),
                    initialValue: controller.gov.value,
                    items: controller.govs
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(g.nameAr)),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.gov.value = v;
                      controller.validateGovernorate(v);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorText: controller.govError.value,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Mobile =====
                Obx(
                  () => CustomTextField(
                    hint: 'أدخل رقم الجوال',
                    controller: controller.mobileController,
                    label: 'رقم الجوال',
                    inputType: TextInputType.phone,
                    errorText: controller.mobileError.value,
                    onChanged: controller.validateMobile,
                  ),
                ),
                SizedBox(height: size.height * 0.05),

                // ===== Submit Button =====
                Obx(
                  () => SizedBox(
                    width: size.width,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          controller.isFormValid && controller.isFormFilled
                          ? controller.submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'تسجيل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
