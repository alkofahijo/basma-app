import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import '../../../../models/report_models.dart';

class GuestFiltersCard extends StatefulWidget {
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
  State<GuestFiltersCard> createState() => _GuestFiltersCardState();
}

class _GuestFiltersCardState extends State<GuestFiltersCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.08),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "تصفية البلاغات",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 18),
          const SizedBox(height: 12),

          // GOVERNMENT
          _buildDropdown<int?>(
            key: ValueKey("gov_${widget.selectedGovernmentId}"),
            label: "المحافظة",
            value: widget.selectedGovernmentId,
            items: [
              const DropdownMenuItem(value: null, child: Text("الكل")),
              ...widget.governments.map(
                (g) => DropdownMenuItem(value: g.id, child: Text(g.nameAr)),
              ),
            ],
            onChanged: (value) {
              widget.onGovernmentChanged(value);
              widget.onDistrictChanged(null);
              widget.onAreaChanged(null);
              setState(() {});
            },
          ),

          const SizedBox(height: 14),

          // DISTRICT
          _buildDropdown<int?>(
            key: ValueKey(
              "district_${widget.selectedDistrictId}_${widget.selectedGovernmentId}",
            ),
            label: "اللواء / القضاء",
            value: widget.selectedDistrictId,
            items: [
              const DropdownMenuItem(value: null, child: Text("الكل")),
              ...widget.districts.map(
                (d) => DropdownMenuItem(value: d.id, child: Text(d.nameAr)),
              ),
            ],
            onChanged: widget.selectedGovernmentId == null
                ? null
                : (value) {
                    widget.onDistrictChanged(value);
                    widget.onAreaChanged(null);
                    setState(() {});
                  },
            hintDisabled: "اختر المحافظة أولاً",
          ),

          const SizedBox(height: 14),

          // AREA
          _buildDropdown<int?>(
            key: ValueKey(
              "area_${widget.selectedAreaId}_${widget.selectedDistrictId}",
            ),
            label: "المنطقة",
            value: widget.selectedAreaId,
            items: [
              const DropdownMenuItem(value: null, child: Text("الكل")),
              ...widget.areas.map(
                (a) => DropdownMenuItem(value: a.id, child: Text(a.nameAr)),
              ),
            ],
            onChanged: widget.selectedDistrictId == null
                ? null
                : (value) {
                    widget.onAreaChanged(value);
                    setState(() {});
                  },
            hintDisabled: "اختر اللواء أولاً",
          ),

          const SizedBox(height: 14),

          // REPORT TYPE
          _buildDropdown<int?>(
            key: ValueKey("type_${widget.selectedReportTypeId}"),
            label: "نوع البلاغ",
            value: widget.selectedReportTypeId,
            items: [
              const DropdownMenuItem(value: null, child: Text("الكل")),
              ...widget.reportTypes.map(
                (t) => DropdownMenuItem(
                  value: t.id,
                  child: Row(
                    children: [
                      Icon(
                        widget.iconForReportType(t.code),
                        size: 18,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.nameAr)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              widget.onReportTypeChanged(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    Key? key,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hintDisabled,
  }) {
    final bool disabled = onChanged == null;

    return DropdownButtonFormField<T>(
      key: key,
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: disabled ? hintDisabled : null,
        filled: true,
        fillColor: disabled ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
