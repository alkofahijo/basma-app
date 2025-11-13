import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/pages/location/widgets/add_area_popup.dart';
import 'package:basma_app/pages/location/widgets/searchable_area_dropdown.dart';
import 'package:basma_app/pages/report/create_report_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/select_location_controller.dart';

class SelectLocationPage extends StatelessWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SelectLocationController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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

                // ---------- المحافظة ----------
                Obx(() {
                  return DropdownButtonFormField<Government>(
                    isExpanded: true,
                    hint: const Text("المحافظة"),
                    initialValue: controller.selectedGov.value,
                    items: controller.governments
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(g.nameAr)),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.selectedGov.value = v;
                      controller.loadDistricts(v!.id);
                    },
                  );
                }),

                const SizedBox(height: 20),

                // ---------- اللواء ----------
                Obx(() {
                  return DropdownButtonFormField<District>(
                    isExpanded: true,
                    hint: const Text("اللواء/القضاء"),
                    initialValue: controller.selectedDistrict.value,
                    items: controller.districts
                        .map(
                          (d) =>
                              DropdownMenuItem(value: d, child: Text(d.nameAr)),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.selectedDistrict.value = v;
                      controller.loadAreas(v!.id);
                    },
                  );
                }),

                const SizedBox(height: 20),

                // ---------- المنطقة searchable ----------
                Obx(() {
                  return SearchableAreaDropdown(
                    areas: controller.areas,
                    selected: controller.selectedArea.value,
                    onChanged: (a) => controller.selectedArea.value = a,
                    onAddNew: () async {
                      final gov = controller.selectedGov.value!;
                      final dist = controller.selectedDistrict.value!;

                      final result = await showDialog(
                        context: context,
                        builder: (_) => AddAreaPopup(
                          govName: gov.nameAr,
                          districtName: dist.nameAr,
                        ),
                      );

                      if (result != null) {
                        final ar = result["ar"];
                        final en = result["en"];

                        final newArea = await ApiService.createArea(
                          districtId: dist.id,
                          nameAr: ar,
                          nameEn: en,
                        );

                        await controller.loadAreas(dist.id);

                        controller.selectedArea.value = newArea;
                      }
                    },
                  );
                }),

                const Spacer(),

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
                              Get.to(
                                () => CreateReportPage(
                                  government: controller.selectedGov.value!,
                                  district: controller.selectedDistrict.value!,
                                  area: controller.selectedArea.value!,
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        "التالي",
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
      ),
    );
  }
}
