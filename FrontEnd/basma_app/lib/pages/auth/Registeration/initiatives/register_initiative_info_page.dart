import 'dart:io';

import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_text_field.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../controllers/register_initiative_controller.dart';
import 'register_initiative_account_page.dart';

class RegisterInitiativeInfoPage extends StatelessWidget {
  const RegisterInitiativeInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterInitiativeController());
    final picker = ImagePicker();

    return Obx(() {
      if (controller.isLoadingGovs.value) {
        return const LoadingCenter();
      }

      if (controller.loadError.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFFEFF1F1),
          appBar: const BasmaAppBar(showBack: true),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.loadError.value),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.fetchGovernments,
                  child: const Text("إعادة المحاولة"),
                ),
              ],
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
              // ===== Logo Picker =====
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
                                Icons.person_outlined,
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
                'معلومات المبادرة',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

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

              CustomTextField(
                controller: controller.joinFormCtrl,
                label: "رابط نموذج الانضمام",
                hint: "أدخل رابط النموذج (اختياري)",
              ),
              const SizedBox(height: 18),

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
                  onPressed: () {
                    if (controller.validateStep1()) {
                      Get.to(() => const RegisterInitiativeAccountPage());
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
