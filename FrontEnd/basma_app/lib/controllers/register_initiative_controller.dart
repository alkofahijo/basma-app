import 'dart:io';
import 'package:basma_app/pages/auth/reg_success.dart';
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
      governments.value = await ApiService.governments();
    } catch (e) {
      loadError.value = 'فشل تحميل المحافظات';
    } finally {
      isLoadingGovs.value = false;
    }
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

  // ===== STEP VALIDATION CHECKS =====
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

  VoidCallback? get fetchGovernments => null;

  // ===== STEP 1 VALIDATION CALLER =====
  bool validateStep1() {
    validateArabicName(nameArCtrl.text);
    validateEnglishName(nameEnCtrl.text);
    validateMobile(mobileCtrl.text);
    validateGovernorate(selectedGov.value);
    return isStep1Valid;
  }

  // ===== STEP 2 VALIDATION CALLER =====
  bool validateStep2() {
    validateUsername(usernameCtrl.text);
    validatePassword(passwordCtrl.text);
    return isStep2Valid;
  }

  // ===== SUBMIT =====
  Future<void> submit() async {
    validateUsername(usernameCtrl.text);
    validatePassword(passwordCtrl.text);

    if (!isStep2Valid) return;

    isSubmitting.value = true;
    try {
      await ApiService.registerInitiative({
        "name_ar": nameArCtrl.text.trim(),
        "name_en": nameEnCtrl.text.trim(),
        "mobile_number": mobileCtrl.text.trim(),
        "join_form_link": joinFormCtrl.text.trim().isEmpty
            ? null
            : joinFormCtrl.text.trim(),
        "government_id": selectedGov.value?.id,
        "username": usernameCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      });

      // Navigate to success screen
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
