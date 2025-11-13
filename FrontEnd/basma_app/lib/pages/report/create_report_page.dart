import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/location_models.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import 'success_page.dart';

class CreateReportPage extends StatefulWidget {
  final Government government;
  final District district;
  final Area area;

  /// إذا كانت null → يكتب المستخدم موقع جديد
  final LocationModel? location;

  const CreateReportPage({
    super.key,
    required this.government,
    required this.district,
    required this.area,
    this.location,
  });

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();

  // نوع البلاغ
  List<ReportType> _types = [];
  ReportType? _selectedType;

  // معلومات موقع جديد
  final TextEditingController _locNameAr = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  // معلومات البلاغ
  final TextEditingController _nameAr = TextEditingController();
  final TextEditingController _descAr = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _reporterName = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _beforeImage;

  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final list = await ApiService.reportTypes();
      setState(() {
        _types = list;
        if (list.isNotEmpty) _selectedType = list.first;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "تعذّر تحميل أنواع البلاغ";
        _loading = false;
      });
    }
  }

  Future<void> pickCamera() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (img != null) setState(() => _beforeImage = img);
  }

  Future<void> pickGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (img != null) setState(() => _beforeImage = img);
  }

  double? tryParseD(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String? validateLat(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null || d < -90 || d > 90) {
      return "يجب أن يكون بين -90 و 90";
    }
    return null;
  }

  String? validateLng(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null || d < -180 || d > 180) {
      return "يجب أن يكون بين -180 و 180";
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      setState(() => _error = "يرجى اختيار نوع البلاغ");
      return;
    }

    if (_beforeImage == null) {
      setState(() => _error = "يرجى اختيار صورة قبل");
      return;
    }

    setState(() {
      _error = null;
      _sending = true;
    });

    try {
      // رفع الصورة
      final bytes = await _beforeImage!.readAsBytes();
      final beforeUrl = await ApiService.uploadImage(bytes, _beforeImage!.name);

      // بناء البيانات
      final payload = {
        "report_type_id": _selectedType!.id,
        "name_ar": _nameAr.text.trim(),
        "description_ar": _descAr.text.trim(),
        "note": _note.text.trim().isEmpty ? null : _note.text.trim(),
        "government_id": widget.government.id,
        "district_id": widget.district.id,
        "area_id": widget.area.id,
        "reported_by_name": _reporterName.text.trim().isEmpty
            ? null
            : _reporterName.text.trim(),
        "image_before_url": beforeUrl,
      };

      // موقع جديد
      if (widget.location == null) {
        payload["new_location"] = {
          "area_id": widget.area.id,
          "name_ar": _locNameAr.text.trim(),
          "latitude": tryParseD(_latCtrl.text),
          "longitude": tryParseD(_lngCtrl.text),
        };
      } else {
        payload["location_id"] = widget.location!.id;
      }

      // إنشاء البلاغ
      final created = await ApiService.createReport(payload);

      if (!mounted) return;

      // صفحة النجاح
      Get.off(() => SuccessPage(reportCode: created.reportCode));
    } catch (e) {
      setState(() => _error = "فشل إرسال البلاغ");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              appBar: AppBar(title: const Text("إنشاء بلاغ")),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                            ),
                          ),
                        ),

                      _contextInfo(),
                      const SizedBox(height: 20),

                      if (widget.location == null) _newLocationFields(),

                      _typeDropdown(),
                      const SizedBox(height: 20),

                      _buildField(_nameAr, "عنوان البلاغ", true),
                      const SizedBox(height: 12),

                      _buildField(_descAr, "الوصف", true, max: 3),
                      const SizedBox(height: 12),

                      _buildField(_note, "ملاحظات (اختياري)", false, max: 2),
                      const SizedBox(height: 12),

                      _imagePicker(),
                      const SizedBox(height: 22),

                      _sendButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _sending ? null : _submit,
        child: _sending
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("إرسال البلاغ", style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _contextInfo() {
    return Text(
      "الموقع:  ${widget.government.nameAr} / "
      "${widget.district.nameAr} / "
      "${widget.area.nameAr}",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Widget _newLocationFields() {
    return Column(
      children: [
        _buildField(_locNameAr, "اسم الموقع", true),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildField(
                _latCtrl,
                "خط العرض (اختياري)",
                false,
                validator: validateLat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                _lngCtrl,
                "خط الطول (اختياري)",
                false,
                validator: validateLng,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _typeDropdown() {
    return DropdownButtonFormField<ReportType>(
      isExpanded: true,
      initialValue: _selectedType,
      items: _types
          .map((t) => DropdownMenuItem(value: t, child: Text(t.nameAr)))
          .toList(),
      decoration: const InputDecoration(labelText: "نوع البلاغ"),
      onChanged: (v) => setState(() => _selectedType = v),
      validator: (v) => v == null ? "مطلوب" : null,
    );
  }

  Widget _imagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الصورة قبل:", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : pickCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text("كاميرا"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : pickGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text("معرض"),
              ),
            ),
          ],
        ),

        if (_beforeImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_beforeImage!.path),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    bool required, {
    int max = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: max,
      validator:
          validator ??
          (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return "الحقل مطلوب";
            }
            return null;
          },
      decoration: InputDecoration(labelText: label),
    );
  }
}
