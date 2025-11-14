import 'package:flutter/material.dart';
import '../../../models/report_models.dart';

class GuestFiltersCard extends StatelessWidget {
  final List<GovernmentOption> governments;
  final List<DistrictOption> districts;
  final List<AreaOption> areas;
  final List<ReportTypeOption> reportTypes;

  final int? selectedGovernmentId;
  final int? selectedDistrictId;
  final int? selectedAreaId;
  final int? selectedReportTypeId;

  final ValueChanged<int?> onGovernmentChanged;
  final ValueChanged<int?> onDistrictChanged;
  final ValueChanged<int?> onAreaChanged;
  final ValueChanged<int?> onReportTypeChanged;

  /// دالة تعطي أيقونة حسب كود نوع البلاغ
  final IconData Function(String) iconForReportType;

  const GuestFiltersCard({
    super.key,
    required this.governments,
    required this.districts,
    required this.areas,
    required this.reportTypes,
    required this.selectedGovernmentId,
    required this.selectedDistrictId,
    required this.selectedAreaId,
    required this.selectedReportTypeId,
    required this.onGovernmentChanged,
    required this.onDistrictChanged,
    required this.onAreaChanged,
    required this.onReportTypeChanged,
    required this.iconForReportType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== العنوان العلوي =====
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: Colors.teal.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "تصفية البلاغات",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                // زر واضح لمسح الفلاتر (UI فقط)
                Text(
                  "تصفية ذكية للموقع ونوع البلاغ",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 18),
            const SizedBox(height: 12),
            // ===== المحافظة =====
            _buildDropdown<int?>(
              label: "المحافظة",
              value: selectedGovernmentId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                ...governments.map(
                  (g) => DropdownMenuItem<int?>(
                    value: g.id,
                    child: Text(g.nameAr),
                  ),
                ),
              ],
              onChanged: onGovernmentChanged,
            ),
            const SizedBox(height: 16),

            // ===== اللواء =====
            _buildDropdown<int?>(
              label: "اللواء / القضاء",
              value: selectedDistrictId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                ...districts.map(
                  (d) => DropdownMenuItem<int?>(
                    value: d.id,
                    child: Text(d.nameAr),
                  ),
                ),
              ],
              onChanged: selectedGovernmentId == null
                  ? null
                  : onDistrictChanged,
              hintDisabled: "اختر المحافظة أولاً",
            ),
            const SizedBox(height: 16),

            // ===== المنطقة =====
            _buildDropdown<int?>(
              label: "المنطقة",
              value: selectedAreaId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                ...areas.map(
                  (a) => DropdownMenuItem<int?>(
                    value: a.id,
                    child: Text(a.nameAr),
                  ),
                ),
              ],
              onChanged: selectedDistrictId == null ? null : onAreaChanged,
              hintDisabled: "اختر اللواء أولاً",
            ),
            const SizedBox(height: 16),

            // ===== نوع البلاغ =====
            _buildDropdown<int?>(
              label: "نوع البلاغ",
              value: selectedReportTypeId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                ...reportTypes.map(
                  (t) => DropdownMenuItem<int?>(
                    value: t.id,
                    child: Row(
                      children: [
                        Icon(
                          iconForReportType(t.code),
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.nameAr,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: onReportTypeChanged,
            ),

            const SizedBox(height: 6),

            // سطر صغير في الأسفل يوضّح عدد الفلاتر المفعّلة (اختياري)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _buildActiveFiltersText(),
                style: TextStyle(
                  fontSize: 11,
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== دالة مساعدة لبناء Dropdown جميل ومتكرر =====

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hintDisabled,
  }) {
    final bool isDisabled = onChanged == null;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: isDisabled ? hintDisabled : null,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      iconSize: 20,
      style: const TextStyle(fontSize: 13, color: Colors.black),
    );
  }

  /// نص لطيف يوضّح عدد الفلاتر المستخدمة حالياً
  String _buildActiveFiltersText() {
    int count = 0;
    if (selectedGovernmentId != null) count++;
    if (selectedDistrictId != null) count++;
    if (selectedAreaId != null) count++;
    if (selectedReportTypeId != null) count++;

    if (count == 0) {
      return "جميع البلاغات معروضة بدون فلاتر.";
    } else {
      return "عدد الفلاتر المفعّلة: $count";
    }
  }
}
