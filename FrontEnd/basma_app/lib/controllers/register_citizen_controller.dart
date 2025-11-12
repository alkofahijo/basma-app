import 'package:basma_app/pages/auth/reg_success.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../models/location_models.dart';

class RegisterCitizenController extends GetxController {
  // Controllers
  final arController = TextEditingController();
  final enController = TextEditingController();
  final mobileController = TextEditingController();
  final userController = TextEditingController();
  final passController = TextEditingController();

  // Observables
  var gov = Rxn<Government>();
  var govs = <Government>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // Validation messages
  var nameArError = RxnString();
  var nameEnError = RxnString();
  var mobileError = RxnString();
  var userError = RxnString();
  var passError = RxnString();
  var govError = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadGovernments();
  }

  Future<void> _loadGovernments() async {
    try {
      govs.value = await ApiService.governments();
    } catch (e) {
      errorMessage.value = 'Failed to load governments';
    } finally {
      isLoading.value = false;
    }
  }

  // ===== Validation Methods =====
  void validateArabicName(String value) {
    nameArError.value = value.trim().isEmpty ? 'Arabic name required' : null;
  }

  void validateEnglishName(String value) {
    nameEnError.value = value.trim().isEmpty ? 'English name required' : null;
  }

  void validateMobile(String value) {
    if (value.trim().isEmpty) {
      mobileError.value = 'Mobile number required';
    } else if (!RegExp(r'^[0-9]{10,12}$').hasMatch(value)) {
      mobileError.value = 'Invalid phone number';
    } else {
      mobileError.value = null;
    }
  }

  void validateUsername(String value) {
    userError.value = value.trim().isEmpty ? 'Username required' : null;
  }

  void validatePassword(String value) {
    if (value.isEmpty) {
      passError.value = 'Password required';
    } else if (value.length < 8) {
      passError.value = 'At least 8 characters';
    } else {
      passError.value = null;
    }
  }

  void validateGovernorate(Government? value) {
    govError.value = (value == null) ? 'Select a governorate' : null;
  }

  bool get isFormValid =>
      nameArError.value == null &&
      nameEnError.value == null &&
      mobileError.value == null &&
      userError.value == null &&
      passError.value == null &&
      govError.value == null;

  bool get isFormFilled =>
      arController.text.isNotEmpty &&
      enController.text.isNotEmpty &&
      mobileController.text.isNotEmpty &&
      userController.text.isNotEmpty &&
      passController.text.isNotEmpty &&
      gov.value != null;

  // ===== Submit =====
  Future<void> submit() async {
    validateArabicName(arController.text);
    validateEnglishName(enController.text);
    validateMobile(mobileController.text);
    validateUsername(userController.text);
    validatePassword(passController.text);
    validateGovernorate(gov.value);

    if (!isFormValid) return;

    try {
      await ApiService.registerCitizen({
        "name_ar": arController.text,
        "name_en": enController.text,
        "mobile_number": mobileController.text,
        "government_id": gov.value?.id,
        "username": userController.text,
        "password": passController.text,
      });
      Get.off(() => RegisterSuccessPage()); // success → go back
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red.shade300,
        colorText: Colors.white,
      );
    }
  }
}
