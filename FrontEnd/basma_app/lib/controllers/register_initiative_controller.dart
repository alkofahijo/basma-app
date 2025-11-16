import 'dart:io';
import 'package:basma_app/pages/auth/Registeration/shared/reg_success.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/location_models.dart';
import '../services/api_service.dart';

class RegisterInitiativeController extends GetxController {
  // Step 1 controllers
  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final joinFormCtrl = TextEditingController();

  var selectedGov = Rxn<Government>();
  var governments = <Government>[].obs;
  var isLoadingGovs = true.obs;
  var loadError = ''.obs;
  var logoFile = Rxn<File>();

  // Step 2 controllers
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // Validation messages
  var nameArError = RxnString();
  var nameEnError = RxnString();
  var mobileError = RxnString();
  var govError = RxnString();
  var usernameError = RxnString();
  var passwordError = RxnString();

  var isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchGovernments();
  }

  Future<void> _fetchGovernments() async {
    try {
      isLoadingGovs.value = true;
      loadError.value = '';
      governments.value = await ApiService.governments();
    } catch (e) {
      loadError.value = 'فشل تحميل المحافظات';
    } finally {
      isLoadingGovs.value = false;
    }
  }

  Future<void> fetchGovernments() async {
    await _fetchGovernments();
  }

  // ===== VALIDATION METHODS =====
  void validateArabicName(String value) {
    nameArError.value = value.trim().isEmpty ? 'الاسم بالعربية مطلوب' : null;
  }

  void validateEnglishName(String value) {
    nameEnError.value = value.trim().isEmpty ? 'الاسم بالإنجليزية مطلوب' : null;
  }

  void validateMobile(String value) {
    if (value.trim().isEmpty) {
      mobileError.value = 'رقم الجوال مطلوب';
    } else if (!RegExp(r'^[0-9]{9,}$').hasMatch(value)) {
      mobileError.value = 'رقم جوال غير صالح';
    } else {
      mobileError.value = null;
    }
  }

  void validateGovernorate(Government? value) {
    govError.value = value == null ? 'اختر محافظة' : null;
  }

  void validateUsername(String value) {
    usernameError.value = value.trim().isEmpty ? 'اسم المستخدم مطلوب' : null;
  }

  void validatePassword(String value) {
    if (value.trim().isEmpty) {
      passwordError.value = 'كلمة المرور مطلوبة';
    } else if (value.length < 8) {
      passwordError.value = 'يجب أن لا تقل عن 8 أحرف';
    } else {
      passwordError.value = null;
    }
  }

  bool get isStep1Valid =>
      nameArError.value == null &&
      nameEnError.value == null &&
      mobileError.value == null &&
      govError.value == null;

  bool get isStep1Filled =>
      nameArCtrl.text.isNotEmpty &&
      nameEnCtrl.text.isNotEmpty &&
      mobileCtrl.text.isNotEmpty &&
      selectedGov.value != null;

  bool get isStep2Valid =>
      usernameError.value == null && passwordError.value == null;

  bool get isStep2Filled =>
      usernameCtrl.text.isNotEmpty && passwordCtrl.text.isNotEmpty;

  bool validateStep1() {
    validateArabicName(nameArCtrl.text);
    validateEnglishName(nameEnCtrl.text);
    validateMobile(mobileCtrl.text);
    validateGovernorate(selectedGov.value);
    return isStep1Valid;
  }

  bool validateStep2() {
    validateUsername(usernameCtrl.text);
    validatePassword(passwordCtrl.text);
    return isStep2Valid;
  }

  Future<void> submit() async {
    // تأكيد خطوة 1
    validateStep1();
    if (!isStep1Valid) {
      Get.snackbar(
        'تنبيه',
        'الرجاء التأكد من تعبئة بيانات المبادرة بشكل صحيح.',
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedGov.value == null) {
      govError.value = 'اختر محافظة';
      Get.snackbar(
        'تنبيه',
        'الرجاء اختيار المحافظة.',
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
      );
      return;
    }

    // تأكيد بيانات الحساب
    validateUsername(usernameCtrl.text);
    validatePassword(passwordCtrl.text);
    if (!isStep2Valid) return;

    isSubmitting.value = true;
    try {
      String? logoUrl;

      if (logoFile.value != null) {
        final file = logoFile.value!;

        // ✅ تأكد أن الملف موجود قبل القراءة
        final exists = await file.exists();
        if (!exists) {
          Get.snackbar(
            'خطأ',
            'تعذّر الوصول إلى ملف الشعار، الرجاء اختيار الصورة من جديد.',
            backgroundColor: Colors.red.shade300,
            colorText: Colors.white,
          );
          isSubmitting.value = false;
          return;
        }

        final bytes = await file.readAsBytes();
        logoUrl = await ApiService.uploadImage(
          bytes,
          file.path.split('/').last,
        );
      }

      await ApiService.registerInitiative({
        "name_ar": nameArCtrl.text.trim(),
        "name_en": nameEnCtrl.text.trim(),
        "mobile_number": mobileCtrl.text.trim(),
        "join_form_link": joinFormCtrl.text.trim().isEmpty
            ? null
            : joinFormCtrl.text.trim(),
        "government_id": selectedGov.value!.id,
        "logo_url": logoUrl,
        "username": usernameCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      });

      Get.offAll(() => const RegisterSuccessPage());
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString(),
        backgroundColor: Colors.red.shade300,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
