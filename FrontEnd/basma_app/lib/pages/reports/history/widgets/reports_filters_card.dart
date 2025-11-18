import 'package:flutter/material.dart';

import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';

class GuestFiltersCard extends StatefulWidget {
  final List<GovernmentOption> governments;
  final List<ReportTypeOption> reportTypes;

  // القيم الحالية القادمة من صفحة البلاغات (يجب أن تبقى محفوظة عند إعادة فتح الفلاتر)
  final int? selectedGovernmentId;
  final int? selectedDistrictId;
  final int? selectedAreaId;
  final int? selectedReportTypeId;

  // إرجاع القيم المختارة للـ parent (لتحديث النتائج)
  final ValueChanged<int?> onGovernmentChanged;
  final ValueChanged<int?> onDistrictChanged;
  final ValueChanged<int?> onAreaChanged;
  final ValueChanged<int?> onReportTypeChanged;

  final IconData Function(String) iconForReportType;

  const GuestFiltersCard({
    super.key,
    required this.governments,
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
  int? _currentGovernmentId;
  int? _currentDistrictId;
  int? _currentAreaId;
  int? _currentReportTypeId;

  List<DistrictOption> _districts = [];
  List<AreaOption> _areas = [];

  bool _isLoadingDistricts = false;
  bool _isLoadingAreas = false;

  @override
  void initState() {
    super.initState();

    // استرجاع القيم المختارة من الـ parent
    _currentGovernmentId = widget.selectedGovernmentId;
    _currentDistrictId = widget.selectedDistrictId;
    _currentAreaId = widget.selectedAreaId;
    _currentReportTypeId = widget.selectedReportTypeId;

    // لو كان فيه محافظة/لواء مختارين مسبقاً، حمّل الألوية والمناطق مع الحفاظ على الاختيار
    _restoreInitialLocation();
  }

  Future<void> _restoreInitialLocation() async {
    final govId = _currentGovernmentId;
    final distId = _currentDistrictId;

    if (govId == null) return;

    // 1) حمّل الألوية التابعة للمحافظة بدون مسح الاختيار
    await _loadDistricts(govId, preserveSelection: true);

    // 2) لو كان في لواء مختار، حمّل المناطق الخاصة فيه بدون مسح الاختيار
    if (distId != null) {
      await _loadAreas(distId, preserveSelection: true);
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ================= تحميل الألوية بحسب المحافظة =================

  Future<void> _loadDistricts(
    int governmentId, {
    bool preserveSelection = false,
  }) async {
    _safeSetState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _areas = [];

      // عند تغيير المحافظة من المستخدم نمسح الاختيارات
      if (!preserveSelection) {
        _currentDistrictId = null;
        _currentAreaId = null;
      }
    });

    try {
      final districts = await ApiService.listDistrictsByGovernment(
        governmentId,
      );
      if (!mounted) return;

      _safeSetState(() {
        _districts = districts;
      });
    } catch (_) {
      // تجاهل الخطأ، فقط لا نعرض ألوية
    } finally {
      _safeSetState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  // ================= تحميل المناطق بحسب اللواء =================

  Future<void> _loadAreas(
    int districtId, {
    bool preserveSelection = false,
  }) async {
    _safeSetState(() {
      _isLoadingAreas = true;
      _areas = [];

      if (!preserveSelection) {
        _currentAreaId = null;
      }
    });

    try {
      final areas = await ApiService.listAreasByDistrict(districtId);
      if (!mounted) return;

      _safeSetState(() {
        _areas = areas;
      });
    } catch (_) {
      // تجاهل الخطأ
    } finally {
      _safeSetState(() {
        _isLoadingAreas = false;
      });
    }
  }

  // ================= Handlers محلية تربط UI بالـ parent =================

  void _onGovernmentChangedLocal(int? governmentId) {
    _safeSetState(() {
      _currentGovernmentId = governmentId;
      _currentDistrictId = null;
      _currentAreaId = null;
      _districts = [];
      _areas = [];
    });

    // نخبر الـ parent بالاختيارات الجديدة
    widget.onGovernmentChanged(governmentId);
    widget.onDistrictChanged(null);
    widget.onAreaChanged(null);

    // تحميل الألوية للمحافظة الجديدة
    if (governmentId != null) {
      _loadDistricts(governmentId, preserveSelection: false);
    }
  }

  void _onDistrictChangedLocal(int? districtId) {
    _safeSetState(() {
      _currentDistrictId = districtId;
      _currentAreaId = null;
      _areas = [];
    });

    widget.onDistrictChanged(districtId);
    widget.onAreaChanged(null);

    if (districtId != null) {
      _loadAreas(districtId, preserveSelection: false);
    }
  }

  void _onAreaChangedLocal(int? areaId) {
    _safeSetState(() {
      _currentAreaId = areaId;
    });
    widget.onAreaChanged(areaId);
  }

  void _onReportTypeChangedLocal(int? typeId) {
    _safeSetState(() {
      _currentReportTypeId = typeId;
    });
    widget.onReportTypeChanged(typeId);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
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
                child: Icon(Icons.filter_list, color: kPrimaryColor, size: 20),
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

          // المحافظة
          _buildDropdown<int?>(
            key: ValueKey("gov_$_currentGovernmentId"),
            label: "المحافظة",
            value: _currentGovernmentId,
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(value: null, child: Text("الكل")),
              ...widget.governments.map(
                (g) =>
                    DropdownMenuItem<int?>(value: g.id, child: Text(g.nameAr)),
              ),
            ],
            onChanged: (value) => _onGovernmentChangedLocal(value),
          ),

          const SizedBox(height: 14),

          // اللواء / القضاء
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown<int?>(
                key: ValueKey(
                  "district_${_currentDistrictId}_$_currentGovernmentId",
                ),
                label: "اللواء / القضاء",
                value: _currentDistrictId,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("الكل"),
                  ),
                  ..._districts.map(
                    (d) => DropdownMenuItem<int?>(
                      value: d.id,
                      child: Text(d.nameAr),
                    ),
                  ),
                ],
                onChanged: (_currentGovernmentId == null || _isLoadingDistricts)
                    ? null
                    : (value) => _onDistrictChangedLocal(value),
                hintDisabled: _currentGovernmentId == null
                    ? "اختر المحافظة أولاً"
                    : _isLoadingDistricts
                    ? "جارٍ تحميل الألوية..."
                    : null,
              ),
              if (_isLoadingDistricts)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // المنطقة
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown<int?>(
                key: ValueKey("area_${_currentAreaId}_$_currentDistrictId"),
                label: "المنطقة",
                value: _currentAreaId,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("الكل"),
                  ),
                  ..._areas.map(
                    (a) => DropdownMenuItem<int?>(
                      value: a.id,
                      child: Text(a.nameAr),
                    ),
                  ),
                ],
                onChanged: (_currentDistrictId == null || _isLoadingAreas)
                    ? null
                    : (value) => _onAreaChangedLocal(value),
                hintDisabled: _currentDistrictId == null
                    ? "اختر اللواء أولاً"
                    : _isLoadingAreas
                    ? "جارٍ تحميل المناطق..."
                    : null,
              ),
              if (_isLoadingAreas)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // نوع البلاغ (نوع التشوّه البصري)
          _buildDropdown<int?>(
            key: ValueKey("type_$_currentReportTypeId"),
            label: "نوع التشوّه البصري",
            value: _currentReportTypeId,
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(value: null, child: Text("الكل")),
              ...widget.reportTypes.map(
                (t) => DropdownMenuItem<int?>(
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
            onChanged: (value) => _onReportTypeChangedLocal(value),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    Key? key,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hintDisabled,
  }) {
    final bool disabled = onChanged == null;

    // 🔐 حماية من الخطأ: لو القيمة الحالية غير موجودة في العناصر → نجعلها null
    final bool hasItemForValue =
        value != null && items.any((item) => item.value == value);
    final T? effectiveValue = hasItemForValue ? value : null;

    return DropdownButtonFormField<T>(
      key: key,
      value: effectiveValue,
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
