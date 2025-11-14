import 'package:basma_app/controllers/select_location_controller.dart';
import 'package:flutter/material.dart';

/// Custom area selector with search and "add new area" option.
class AreaSearchDropdown extends StatelessWidget {
  final SelectLocationController controller;

  const AreaSearchDropdown({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selectedArea = controller.selectedArea.value;
    final text = selectedArea?.nameAr ?? 'اختر المنطقة';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'المنطقة',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openAreaBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedArea == null
                          ? Colors.grey
                          : Colors.grey[900],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openAreaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              final allAreas = controller.areas;
              final filtered = allAreas
                  .where(
                    (a) =>
                        a.nameAr.contains(searchQuery) ||
                        a.nameEn.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'اختر المنطقة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ابحث عن المنطقة',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setState(() => searchQuery = val.trim());
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد مناطق مطابقة'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final area = filtered[index];
                                return ListTile(
                                  title: Text(area.nameAr),
                                  subtitle: Text(area.nameEn),
                                  onTap: () {
                                    controller.selectedArea.value = area;
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _openAddAreaDialog(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة منطقة جديدة'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openAddAreaDialog(BuildContext context) async {
    final TextEditingController nameArCtrl = TextEditingController();
    final TextEditingController nameEnCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final gov = controller.selectedGov.value;
    final dist = controller.selectedDistrict.value;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('إضافة منطقة جديدة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (gov != null && dist != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'المحافظة: ${gov.nameAr}\n'
                            'اللواء/القضاء: ${dist.nameAr}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameArCtrl,
                              decoration: const InputDecoration(
                                labelText: 'اسم المنطقة (عربي)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المنطقة بالعربية';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameEnCtrl,
                              decoration: const InputDecoration(
                                labelText: 'اسم المنطقة (إنجليزي)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المنطقة بالإنجليزية';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                          },
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isSubmitting = true);
                            try {
                              await controller.createAndSelectArea(
                                nameArCtrl.text.trim(),
                                nameEnCtrl.text.trim(),
                              );
                              Navigator.of(ctx).pop();
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'فشل في إضافة المنطقة: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
