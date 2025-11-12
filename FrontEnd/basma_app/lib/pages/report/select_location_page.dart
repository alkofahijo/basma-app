import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/pages/custom_widgets.dart/custom_dropdown.dart';
import 'package:basma_app/pages/report/create_report_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/select_location_controller.dart';

class SelectLocationPage extends StatelessWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SelectLocationController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF1F1),
        centerTitle: true,
        title: Image.asset(
          "assets/images/logo-arabic-side.png",
          height: MediaQuery.of(context).size.height * 0.05,
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'اختر الموقع',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // ========== Government Dropdown ==========
              Obx(() {
                if (controller.isLoadingGov.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return buildDropdownBox<Government>(
                  label: 'المحافظة',
                  items: controller.governments,
                  selected: controller.selectedGov.value,
                  onChanged: (g) {
                    controller.selectedGov.value = g;
                    if (g != null) controller.loadDistricts(g.id);
                  },
                  getName: (g) => g.nameAr,
                );
              }),
              const SizedBox(height: 20),

              // ========== District Dropdown ==========
              Obx(() {
                if (controller.isLoadingDistrict.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return buildDropdownBox<District>(
                  label: 'اللواء/القضاء',
                  items: controller.districts,
                  selected: controller.selectedDistrict.value,
                  onChanged: (d) {
                    controller.selectedDistrict.value = d;
                    if (d != null) controller.loadAreas(d.id);
                  },
                  getName: (d) => d.nameAr,
                );
              }),
              const SizedBox(height: 20),

              // ========== Area Dropdown ==========
              Obx(() {
                if (controller.isLoadingArea.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return buildDropdownBox<Area>(
                  label: 'المنطقة',
                  items: controller.areas,
                  selected: controller.selectedArea.value,
                  onChanged: (a) => controller.selectedArea.value = a,
                  getName: (a) => a.nameAr,
                );
              }),

              SizedBox(height: 120),
              Obx(() {
                final enabled = controller.isValidSelection;
                return SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: enabled
                        ? () {
                            final gov = controller.selectedGov.value!;
                            final dist = controller.selectedDistrict.value!;
                            final area = controller.selectedArea.value!;

                            Get.to(
                              () => CreateReportPage(
                                government: gov,
                                district: dist,
                                area: area,
                              ),
                            );
                          }
                        : null,
                    child: const Text(
                      'التالي',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
