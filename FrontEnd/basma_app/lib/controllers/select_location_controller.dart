import 'package:get/get.dart';
import '../models/location_models.dart';
import '../services/api_service.dart';

class SelectLocationController extends GetxController {
  final governments = <Government>[].obs;
  final districts = <District>[].obs;
  final areas = <Area>[].obs;

  final selectedGov = Rx<Government?>(null);
  final selectedDistrict = Rx<District?>(null);
  final selectedArea = Rx<Area?>(null);

  final isLoadingGov = false.obs;
  final isLoadingDistrict = false.obs;
  final isLoadingArea = false.obs;

  /// ✔ getter مطلوب للزر (التالي)
  bool get isValidSelection =>
      selectedGov.value != null &&
      selectedDistrict.value != null &&
      selectedArea.value != null;

  @override
  void onInit() {
    super.onInit();
    loadGovernments();
  }

  Future<void> loadGovernments() async {
    isLoadingGov.value = true;
    final data = await ApiService.governments();
    governments.assignAll(data);
    isLoadingGov.value = false;
  }

  Future<void> loadDistricts(int govId) async {
    isLoadingDistrict.value = true;

    selectedDistrict.value = null;
    selectedArea.value = null;
    districts.clear();
    areas.clear();

    final data = await ApiService.districts(govId);
    districts.assignAll(data);

    isLoadingDistrict.value = false;
  }

  Future<void> loadAreas(int districtId) async {
    isLoadingArea.value = true;

    selectedArea.value = null;
    areas.clear();

    final data = await ApiService.areas(districtId);
    areas.assignAll(data);

    isLoadingArea.value = false;
  }

  /// إنشاء منطقة جديدة + تحديدها
  Future<Area> createAndSelectArea(String nameAr, String nameEn) async {
    if (selectedDistrict.value == null) {
      throw Exception("لم يتم اختيار اللواء");
    }

    final newArea = await ApiService.createArea(
      districtId: selectedDistrict.value!.id,
      nameAr: nameAr,
      nameEn: nameEn,
    );

    await loadAreas(selectedDistrict.value!.id);

    selectedArea.value =
        areas.firstWhereOrNull((a) => a.id == newArea.id) ?? newArea;

    return newArea;
  }
}
