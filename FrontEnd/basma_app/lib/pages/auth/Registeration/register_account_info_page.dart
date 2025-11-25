// lib/pages/auth/register/register_choice_page.dart

import 'dart:io';

import 'package:basma_app/controllers/register_account_controller.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/widgets/app_main_app_bar.dart';
import 'package:basma_app/widgets/inputs/app_text_field.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/inputs/app_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'register_account_credentials_page.dart';

class RegisterChoicePage extends StatelessWidget {
  RegisterChoicePage({super.key});

  /// نحقن الكنترولر مرة واحدة فقط
  final RegisterAccountController controller = Get.put(
    RegisterAccountController(),
  );

  /// Image picker
  final ImagePicker picker = ImagePicker();

  /// فلاغ لمنع تشغيل الـ ImagePicker أكثر من مرة في نفس الوقت
  bool _isPickingImage = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ======== حالة التحميل الأولي ========
      if (controller.isLoadingInitial.value) {
        return const Scaffold(
          backgroundColor: Color(0xFFEFF1F1),
          appBar: AppMainAppBar(showBack: true),
          body: LoadingCenter(),
        );
      }

      // ======== حالة الخطأ في تحميل الـ lookups ========
      if (controller.loadError.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFFEFF1F1),
          appBar: const AppMainAppBar(showBack: true),
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
                    onPressed: controller.loadLookups,
                    child: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // ======== الحالة الطبيعية (عرض نموذج إنشاء الحساب) ========
      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: const AppMainAppBar(showBack: true),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              children: [
                // ================= صورة/شعار الحساب (إجباري) =================
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
                            // منع استدعاء الـ picker مرتين بنفس الوقت
                            if (_isPickingImage) return;
                            _isPickingImage = true;

                            try {
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (picked != null) {
                                controller.logoFile.value = File(picked.path);
                              }
                            } catch (e) {
                              // ممكن تضيف Snackbar هنا لو حابب
                            } finally {
                              _isPickingImage = false;
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
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'يرجى رفع شعار/صورة الحساب (هذا الحقل إجباري)',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
                const SizedBox(height: 6),
                const Text(
                  'جميع الحقول التالية مطلوبة لإتمام إنشاء الحساب.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // ================= نوع الحساب (أول حقل) =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'نوع الحساب',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),

                Obx(
                  () => AppDropdownFormField<AccountTypeOption>(
                    value: controller.selectedAccountType.value,
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
                    hint: 'اختر نوع الحساب',
                    errorText: controller.accountTypeError.value.isEmpty
                        ? null
                        : controller.accountTypeError.value,
                  ),
                ),
                const SizedBox(height: 18),

                // ================= المحافظة (ثاني حقل) =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'المحافظة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),

                Obx(
                  () => AppDropdownFormField<Government>(
                    value: controller.selectedGov.value,
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
                    hint: 'اختر محافظتك',
                    errorText: controller.govError.value.isEmpty
                        ? null
                        : controller.govError.value,
                  ),
                ),
                const SizedBox(height: 18),

                // الاسم بالعربية
                Obx(
                  () => AppTextField(
                    controller: controller.nameArCtrl,
                    label: 'الاسم (بالعربية)',
                    hint: 'أدخل الاسم بالعربية',
                    errorText: controller.nameArError.value.isEmpty
                        ? null
                        : controller.nameArError.value,
                    onChanged: controller.validateArabicName,
                  ),
                ),
                const SizedBox(height: 18),

                // الاسم بالإنجليزية
                Obx(
                  () => AppTextField(
                    controller: controller.nameEnCtrl,
                    label: 'الاسم (بالإنجليزية)',
                    hint: 'أدخل الاسم بالإنجليزية',
                    errorText: controller.nameEnError.value.isEmpty
                        ? null
                        : controller.nameEnError.value,
                    onChanged: controller.validateEnglishName,
                  ),
                ),
                const SizedBox(height: 18),

                // رقم الهاتف
                Obx(
                  () => AppTextField(
                    controller: controller.mobileCtrl,
                    label: 'رقم الهاتف',
                    hint: '07XXXXXXXX',
                    keyboardType: TextInputType.phone,
                    errorText: controller.mobileError.value.isEmpty
                        ? null
                        : controller.mobileError.value,
                    onChanged: controller.validateMobile,
                  ),
                ),
                const SizedBox(height: 18),

                // نص توضيحي قبل حقل الرابط (إجباري)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'يمكنك إدخال رابط نموذج انضمام إلى فريقك التطوعي، أو رابط حسابك الشخصي إذا كنت مواطنًا،'
                    ' أو رابط الصفحة الشخصية / الموقع الإلكتروني للجهة التي تسجل فيها.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // رابط الحساب / نموذج الانضمام (إجباري)
                AppTextField(
                  controller: controller.linkCtrl,
                  label: "رابط الحساب / نموذج الانضمام",
                  hint: "أدخل الرابط هنا (حقل إجباري)",
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'هذا الحقل إجباري، تأكد من إدخال رابط صالح يمكن الوصول إليه.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 18),

                // إظهار بيانات التواصل
                Obx(
                  () => SwitchListTile(
                    title: const Text(
                      'إظهار بيانات التواصل للعامة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'في حال التفعيل سيتم إظهار رقم الهاتف ورابط الحساب / نموذج الانضمام للمستخدمين داخل التطبيق.',
                      style: TextStyle(fontSize: 12),
                    ),
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
                      // التحقق من أن الصورة مرفوعة (إجباري)
                      if (controller.logoFile.value == null) {
                        Get.snackbar(
                          'الصورة مطلوبة',
                          'يرجى رفع شعار أو صورة للحساب قبل المتابعة.',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(12),
                          backgroundColor: Colors.red.shade50,
                          colorText: Colors.red.shade900,
                        );
                        return;
                      }

                      // التحقق من أن رابط الحساب / نموذج الانضمام غير فارغ (إجباري)
                      if (controller.linkCtrl.text.trim().isEmpty) {
                        Get.snackbar(
                          'الرابط مطلوب',
                          'يرجى إدخال رابط الحساب أو نموذج الانضمام قبل المتابعة.',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(12),
                          backgroundColor: Colors.red.shade50,
                          colorText: Colors.red.shade900,
                        );
                        return;
                      }

                      // بقية التحقق (الأسماء، نوع الحساب، المحافظة، رقم الهاتف...)
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
        ),
      );
    });
  }
}
