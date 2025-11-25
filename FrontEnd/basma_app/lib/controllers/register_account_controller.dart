import 'dart:io';

import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/upload_service.dart';
import 'package:basma_app/services/network_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterAccountController extends GetxController {
  // ===================== STEP 1: Info fields =====================
  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final linkCtrl = TextEditingController();

  // ===================== STEP 2: Credentials =====================
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // ===================== Error messages =====================
  final nameArError = ''.obs;
  final nameEnError = ''.obs;
  final mobileError = ''.obs;
  final govError = ''.obs;
  final accountTypeError = ''.obs;
  final usernameError = ''.obs;
  final passwordError = ''.obs;

  // ===================== Dropdown data =====================
  final governments = <Government>[].obs;
  final selectedGov = Rx<Government?>(null);

  final accountTypes = <AccountTypeOption>[].obs;
  final selectedAccountType = Rx<AccountTypeOption?>(null);

  // ===================== UI state =====================
  final isLoadingInitial = true.obs;
  final loadError = ''.obs;
  final isSubmitting = false.obs;
  final showDetails = true.obs;

  // ===================== Logo =====================
  final logoFile = Rx<File?>(null);
  String? uploadedLogoUrl;

  @override
  void onInit() {
    super.onInit();
    loadLookups();
  }

  /// دالة عامة لإعادة تحميل البيانات (أنواع الحسابات + المحافظات)
  Future<void> loadLookups() async {
    try {
      isLoadingInitial.value = true;
      loadError.value = '';

      final govs = await ApiService.governments();
      final types = await ApiService.listAccountTypes();

      governments.assignAll(govs);
      accountTypes.assignAll(types);

      if (govs.isNotEmpty) {
        selectedGov.value = govs.first;
      } else {
        selectedGov.value = null;
      }

      if (types.isNotEmpty) {
        selectedAccountType.value = types.first;
      } else {
        selectedAccountType.value = null;
      }
    } catch (e) {
      if (e is NetworkException) {
        loadError.value = e.error.message;
      } else {
        loadError.value = 'فشل تحميل البيانات: $e';
      }
    } finally {
      isLoadingInitial.value = false;
    }
  }

  // ===================== Validation =====================

  void validateArabicName(String v) {
    if (v.trim().isEmpty) {
      nameArError.value = 'الاسم بالعربية مطلوب';
    } else {
      nameArError.value = '';
    }
  }

  void validateEnglishName(String v) {
    if (v.trim().isEmpty) {
      nameEnError.value = 'الاسم بالإنجليزية مطلوب';
    } else {
      nameEnError.value = '';
    }
  }

  void validateMobile(String v) {
    final value = v.trim();
    if (value.isEmpty) {
      mobileError.value = 'رقم الهاتف مطلوب';
    } else if (!value.startsWith('07') || value.length < 10) {
      mobileError.value = 'رقم هاتف غير صالح';
    } else {
      mobileError.value = '';
    }
  }

  void validateGovernorate(Government? g) {
    if (g == null) {
      govError.value = 'المحافظة مطلوبة';
    } else {
      govError.value = '';
    }
  }

  void validateAccountType(AccountTypeOption? t) {
    if (t == null) {
      accountTypeError.value = 'نوع الحساب مطلوب';
    } else {
      accountTypeError.value = '';
    }
  }

  void validateUsername(String v) {
    final value = v.trim();
    if (value.isEmpty) {
      usernameError.value = 'اسم المستخدم مطلوب';
    } else if (value.length < 4) {
      usernameError.value = 'اسم المستخدم يجب أن يكون 4 أحرف على الأقل';
    } else {
      usernameError.value = '';
    }
  }

  void validatePassword(String v) {
    final value = v.trim();
    if (value.isEmpty) {
      passwordError.value = 'كلمة المرور مطلوبة';
    } else if (value.length < 6) {
      passwordError.value = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    } else {
      passwordError.value = '';
    }
  }

  bool validateStep1() {
    validateArabicName(nameArCtrl.text);
    validateEnglishName(nameEnCtrl.text);
    validateMobile(mobileCtrl.text);
    validateGovernorate(selectedGov.value);
    validateAccountType(selectedAccountType.value);

    return nameArError.value.isEmpty &&
        nameEnError.value.isEmpty &&
        mobileError.value.isEmpty &&
        govError.value.isEmpty &&
        accountTypeError.value.isEmpty;
  }

  bool validateStep2() {
    validateUsername(usernameCtrl.text);
    validatePassword(passwordCtrl.text);

    return usernameError.value.isEmpty && passwordError.value.isEmpty;
  }

  // ===================== Submit =====================

  Future<void> submit() async {
    if (!validateStep2()) return;

    isSubmitting.value = true;
    try {
      // 1) رفع الشعار لو موجود
      String? logoUrl;
      final file = logoFile.value;
      if (file != null) {
        final bytes = await file.readAsBytes();
        logoUrl = await UploadService.uploadImage(bytes, 'account_logo.png');
        uploadedLogoUrl = logoUrl;
      }

      final gov = selectedGov.value;
      final accType = selectedAccountType.value;

      if (gov == null || accType == null) {
        throw Exception('الرجاء اختيار المحافظة ونوع الحساب');
      }

      final payload = {
        "name_ar": nameArCtrl.text.trim(),
        "name_en": nameEnCtrl.text.trim(),
        "mobile_number": mobileCtrl.text.trim(),
        "government_id": gov.id,
        "account_type_id": accType.id,
        "account_link": linkCtrl.text.trim().isEmpty
            ? null
            : linkCtrl.text.trim(),
        "show_details": showDetails.value,
        "logo_url": logoUrl,
        "username": usernameCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      };

      await ApiService.registerAccount(payload);

      Get.snackbar(
        'تم إنشاء الحساب',
        'يمكنك الآن تسجيل الدخول باستخدام بياناتك',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(); // رجوع مثلاً لشاشة تسجيل الدخول
    } catch (e) {
      final msg = e is NetworkException ? e.error.message : e.toString();
      Get.snackbar(
        'خطأ',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha((0.1 * 255).round()),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    nameArCtrl.dispose();
    nameEnCtrl.dispose();
    mobileCtrl.dispose();
    linkCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
