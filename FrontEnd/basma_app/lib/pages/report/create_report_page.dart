import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/location_models.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import 'success_page.dart';

class CreateReportPage extends StatefulWidget {
  final Government government;
  final District district;
  final Area area;

  /// If null, user can type a new location (name_ar/name_en and optional lat/lng).
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

  // report types
  List<ReportType> _types = <ReportType>[];
  ReportType? _selectedType;

  // free-typed location fields (used only when widget.location == null)
  final _locNameAr = TextEditingController();
  final _locNameEn = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  // report fields
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _descAr = TextEditingController();
  final _descEn = TextEditingController();
  final _note = TextEditingController();
  final _reporter = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _before;
  bool _loading = true;
  bool _submitting = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void dispose() {
    _locNameAr.dispose();
    _locNameEn.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();

    _nameAr.dispose();
    _nameEn.dispose();
    _descAr.dispose();
    _descEn.dispose();
    _note.dispose();
    _reporter.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final types = await ApiService.reportTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        if (_types.isNotEmpty) {
          _selectedType = _types.first;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر التحميل الأولي للبيانات';
        _loading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (img != null) {
        setState(() => _before = img);
      }
    } catch (_) {
      setState(() => _err = 'تعذّر فتح المعرض');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (img != null) {
        setState(() => _before = img);
      }
    } catch (_) {
      setState(() => _err = 'تعذّر فتح الكاميرا');
    }
  }

  double? _parseNullableDouble(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      return;
    }

    if (_selectedType == null) {
      setState(() => _err = 'يرجى اختيار نوع البلاغ');
      return;
    }
    if (_before == null) {
      setState(() => _err = 'يرجى إرفاق صورة (قبل)');
      return;
    }

    setState(() {
      _err = null;
      _submitting = true;
    });

    try {
      // 1) upload the BEFORE image
      final bytes = await _before!.readAsBytes();
      final beforeUrl = await ApiService.uploadImage(bytes, _before!.name);

      // 2) Build payload. Choose between location_id or new_location.
      final payload = <String, dynamic>{
        "report_type_id": _selectedType!.id,
        "name_ar": _nameAr.text.trim(),
        "name_en": _nameEn.text.trim(),
        "description_ar": _descAr.text.trim(),
        "description_en": _descEn.text.trim(),
        "note": _note.text.trim().isEmpty ? null : _note.text.trim(),
        "government_id": widget.government.id,
        "district_id": widget.district.id,
        "area_id": widget.area.id,
        "reported_by_name": _reporter.text.trim().isEmpty
            ? null
            : _reporter.text.trim(),
        "image_before_url": beforeUrl,
      };

      if (widget.location != null) {
        // user selected an existing location earlier
        payload["location_id"] = widget.location!.id;
      } else {
        // user must type new location
        final lat = _parseNullableDouble(_latCtrl.text);
        final lng = _parseNullableDouble(_lngCtrl.text);

        payload["new_location"] = {
          "area_id": widget.area.id,
          "name_ar": _locNameAr.text.trim(),
          "name_en": _locNameEn.text.trim(),
          "latitude": lat,
          "longitude": lng,
        };
      }

      // 3) create the report
      final created = await ApiService.createReport(payload); // ReportDetail
      if (!mounted) return;

      // 4) success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(reportCode: created.reportCode),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _err = 'إرسال البلاغ فشل');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateLat(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null; // optional
    final d = double.tryParse(t);
    if (d == null || d < -90 || d > 90) {
      return 'خط العرض يجب أن يكون بين -90 و 90';
    }
    return null;
  }

  String? _validateLng(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null; // optional
    final d = double.tryParse(t);
    if (d == null || d < -180 || d > 180) {
      return 'خط الطول يجب أن يكون بين -180 و 180';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء بلاغ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _err!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Context line
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'الإدارة: ${widget.government.nameAr} / ${widget.district.nameAr} / ${widget.area.nameAr}',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // If no existing location, show typed fields
                  if (widget.location == null) ...[
                    TextFormField(
                      controller: _locNameAr,
                      decoration: const InputDecoration(
                        labelText: 'اسم الموقع (عربي)',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locNameEn,
                      decoration: const InputDecoration(
                        labelText: 'اسم الموقع (إنجليزي)',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latCtrl,
                            decoration: const InputDecoration(
                              labelText: 'خط العرض (اختياري)',
                              hintText: 'مثال: 31.963158',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validateLat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngCtrl,
                            decoration: const InputDecoration(
                              labelText: 'خط الطول (اختياري)',
                              hintText: 'مثال: 35.930359',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validateLng,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Type dropdown
                  DropdownButtonFormField<ReportType>(
                    isExpanded: true,
                    initialValue: _selectedType,
                    items: _types
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.nameAr)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                    decoration: const InputDecoration(labelText: 'نوع البلاغ'),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // Title AR
                  TextFormField(
                    controller: _nameAr,
                    decoration: const InputDecoration(
                      labelText: 'عنوان البلاغ (عربي)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // Title EN
                  TextFormField(
                    controller: _nameEn,
                    decoration: const InputDecoration(
                      labelText: 'عنوان البلاغ (إنجليزي)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // Desc AR
                  TextFormField(
                    controller: _descAr,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (عربي)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // Desc EN
                  TextFormField(
                    controller: _descEn,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (إنجليزي)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // Note (optional)
                  TextFormField(
                    controller: _note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reporter (optional)
                  TextFormField(
                    controller: _reporter,
                    decoration: const InputDecoration(
                      labelText: 'اسم المبلِّغ (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image pick row (camera / gallery)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickFromCamera,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('التقاط بالكاميرا'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('اختيار من المعرض'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected image name (and a small preview)
                  if (_before != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _before!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_before!.path), fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إرسال'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
