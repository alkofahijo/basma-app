import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/location_models.dart';
import '../services/api_service.dart';

class SelectLocationController extends GetxController {
  // Observables
  var governments = <Government>[].obs;
  var districts = <District>[].obs;
  var areas = <Area>[].obs;

  var selectedGov = Rxn<Government>();
  var selectedDistrict = Rxn<District>();
  var selectedArea = Rxn<Area>();

  var isLoadingGov = true.obs;
  var isLoadingDistrict = false.obs;
  var isLoadingArea = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGovernments();
  }

  // Load governments
  Future<void> loadGovernments() async {
    try {
      isLoadingGov.value = true;
      governments.value = await ApiService.governments();
    } catch (e) {
      Get.snackbar("Error", "Failed to load governments: $e",
          backgroundColor: const Color(0xFFEF5350), colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoadingGov.value = false;
    }
  }

  // Load districts
  Future<void> loadDistricts(int govId) async {
    try {
      isLoadingDistrict.value = true;
      districts.clear();
      selectedDistrict.value = null;
      areas.clear();
      selectedArea.value = null;

      districts.value = await ApiService.districts(govId);
    } catch (e) {
      Get.snackbar("Error", "Failed to load districts: $e",
          backgroundColor: const Color(0xFFEF5350), colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoadingDistrict.value = false;
    }
  }

  // Load areas
  Future<void> loadAreas(int districtId) async {
    try {
      isLoadingArea.value = true;
      areas.clear();
      selectedArea.value = null;

      areas.value = await ApiService.areas(districtId);
    } catch (e) {
      Get.snackbar("Error", "Failed to load areas: $e",
          backgroundColor: const Color(0xFFEF5350), colorText: const Color(0xFFFFFFFF));
    } finally {
      isLoadingArea.value = false;
    }
  }

  bool get isValidSelection =>
      selectedGov.value != null &&
      selectedDistrict.value != null &&
      selectedArea.value != null;
}
