import 'package:basma_app/pages/custom_widgets.dart/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/register_citizen_controller.dart';
import '../../../models/location_models.dart';

class RegisterCitizenPage extends StatelessWidget {
  const RegisterCitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterCitizenController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF1F1),
        centerTitle: true,
        title: Image.asset(
          "assets/images/logo-arabic-side.png",
          height: size.height * 0.05,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Title =====
                Text(
                  'Register as Citizen',
                  style: TextStyle(
                    color: const Color(0xFF008000),
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.08,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Text(
                  'Please fill in the details below to create your account.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (controller.errorMessage.isNotEmpty)
                  Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),

                SizedBox(height: size.height * 0.02),

                // ===== Arabic Name =====
                Obx(
                  () => CustomTextField(
                    hint: 'Enter your name in Arabic',
                    controller: controller.arController,
                    label: 'Name (Arabic)',
                    errorText: controller.nameArError.value,
                    onChanged: controller.validateArabicName,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== English Name =====
                Obx(
                  () => CustomTextField(
                    hint: 'Enter your name in English',
                    controller: controller.enController,
                    label: 'Name (English)',
                    errorText: controller.nameEnError.value,
                    onChanged: controller.validateEnglishName,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Username =====
                Obx(
                  () => CustomTextField(
                    hint: 'Enter your username',
                    controller: controller.userController,
                    label: 'Username',
                    errorText: controller.userError.value,
                    onChanged: controller.validateUsername,
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                // ===== Password =====
                Obx(
                  () => CustomTextField(
                    hint: 'Enter your Password',
                    controller: controller.passController,
                    label: 'Password',
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
                    'Governorate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: size.height * 0.01),
                Obx(
                  () => DropdownButtonFormField<Government>(
                    hint: const Text('Select your governorate'),
                    initialValue: controller.gov.value,
                    items: controller.govs
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(g.nameEn)),
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
                    hint: 'Enter your mobile number',
                    controller: controller.mobileController,
                    label: 'Mobile Number',
                    inputType: TextInputType.phone,
                    errorText: controller.mobileError.value,
                    onChanged: controller.validateMobile,
                  ),
                ),
                SizedBox(height: size.height * 0.05),

                // ===== Submit Button =====
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          controller.isFormValid && controller.isFormFilled
                          ? controller.submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Register',
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
        );
      }),
    );
  }
}
