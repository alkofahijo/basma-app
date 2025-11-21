// lib/pages/auth/register/register_choice_page.dart

import 'dart:io';

import 'package:basma_app/controllers/register_account_controller.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_text_field.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'register_account_credentials_page.dart';

class RegisterChoicePage extends StatelessWidget {
  const RegisterChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterAccountController());
    final picker = ImagePicker();

    return Obx(() {
      if (controller.isLoadingInitial.value) {
        return const Scaffold(
          backgroundColor: Color(0xFFEFF1F1),
          appBar: BasmaAppBar(showBack: true),
          body: LoadingCenter(),
        );
      }

      if (controller.loadError.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFFEFF1F1),
          appBar: const BasmaAppBar(showBack: true),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.loadError.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller
                        .loadLookups, // دالة إعادة التحميل في الـ Controller
                    child: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: const BasmaAppBar(showBack: true),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              // ================= صورة/شعار الحساب =================
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Obx(() {
                      final image = controller.logoFile.value;
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: image != null
                            ? FileImage(image)
                            : null,
                        child: image == null
                            ? const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.grey,
                                size: 40,
                              )
                            : null,
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            controller.logoFile.value = File(picked.path);
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                'معلومات الحساب',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // الاسم بالعربية
              Obx(
                () => CustomTextField(
                  controller: controller.nameArCtrl,
                  label: 'الاسم (بالعربية)',
                  hint: 'أدخل الاسم بالعربية',
                  errorText: controller.nameArError.value,
                  onChanged: controller.validateArabicName,
                ),
              ),
              const SizedBox(height: 18),

              // الاسم بالإنجليزية
              Obx(
                () => CustomTextField(
                  controller: controller.nameEnCtrl,
                  label: 'الاسم (بالإنجليزية)',
                  hint: 'أدخل الاسم بالإنجليزية',
                  errorText: controller.nameEnError.value,
                  onChanged: controller.validateEnglishName,
                ),
              ),
              const SizedBox(height: 18),

              // رقم الهاتف
              Obx(
                () => CustomTextField(
                  controller: controller.mobileCtrl,
                  label: 'رقم الهاتف',
                  hint: '07XXXXXXXX',
                  inputType: TextInputType.phone,
                  errorText: controller.mobileError.value,
                  onChanged: controller.validateMobile,
                ),
              ),
              const SizedBox(height: 18),

              // رابط الحساب / نموذج الانضمام
              CustomTextField(
                controller: controller.linkCtrl,
                label: "رابط الحساب / نموذج الانضمام",
                hint: "أدخل رابط (اختياري)",
              ),
              const SizedBox(height: 18),

              // ================= نوع الحساب =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'نوع الحساب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),

              Obx(
                () => DropdownButtonFormField<AccountTypeOption>(
                  initialValue: controller.selectedAccountType.value,
                  hint: const Text('اختر نوع الحساب'),
                  items: controller.accountTypes
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t, child: Text(t.nameAr)),
                      )
                      .toList(),
                  onChanged: (v) {
                    controller.selectedAccountType.value = v;
                    controller.validateAccountType(v);
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
                    errorText: controller.accountTypeError.value,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ================= المحافظة =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'المحافظة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),

              Obx(
                () => DropdownButtonFormField<Government>(
                  initialValue: controller.selectedGov.value,
                  hint: const Text('اختر محافظتك'),
                  items: controller.governments
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g, child: Text(g.nameAr)),
                      )
                      .toList(),
                  onChanged: (v) {
                    controller.selectedGov.value = v;
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
              const SizedBox(height: 18),

              // إظهار التفاصيل
              Obx(
                () => SwitchListTile(
                  title: const Text('إظهار تفاصيل الحساب في واجهة التطبيق'),
                  value: controller.showDetails.value,
                  onChanged: (v) => controller.showDetails.value = v,
                ),
              ),
              const SizedBox(height: 30),

              // زر التالي
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
                  onPressed: () {
                    if (controller.validateStep1()) {
                      Get.to(() => const RegisterAccountCredentialsPage());
                    }
                  },
                  child: const Text(
                    'التالي',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
