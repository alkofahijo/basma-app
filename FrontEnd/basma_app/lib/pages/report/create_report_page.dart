import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/location_models.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import 'success_page.dart';

import 'package:latlong2/latlong.dart';
import '../shared/select_location_on_map_page.dart'; // عدّل المسار حسب مكان الملف

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
  LatLng? _selectedLatLng; // فقط من الخريطة

  // معلومات البلاغ
  final TextEditingController _nameAr = TextEditingController();
  final TextEditingController _descAr = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _reporterName = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _openMapToSelectLocation() async {
    // محاولة تمرير قيمة مبدئية لو كانت موجودة
    final double? currentLat = _selectedLatLng?.latitude;
    final double? currentLng = _selectedLatLng?.longitude;

    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationOnMapPage(
          initialLat: currentLat,
          initialLng: currentLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatLng = result;
      });
    }
  }

  XFile? _beforeImage;

  bool _loading = true;
  bool _sending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _locNameAr.dispose();
    _nameAr.dispose();
    _descAr.dispose();
    _note.dispose();
    _reporterName.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final list = await ApiService.reportTypes();
      setState(() {
        _types = list;
        if (list.isNotEmpty) _selectedType = list.first;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "تعذّر تحميل أنواع البلاغ، حاول مرة أخرى.";
        _loading = false;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (img != null) setState(() => _beforeImage = img);
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (img != null) setState(() => _beforeImage = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      setState(() => _errorMessage = "يرجى اختيار نوع البلاغ.");
      return;
    }

    if (_beforeImage == null) {
      setState(() => _errorMessage = "يرجى اختيار صورة (قبل).");
      return;
    }

    setState(() {
      _errorMessage = null;
      _sending = true;
    });

    try {
      // رفع الصورة
      final bytes = await _beforeImage!.readAsBytes();
      final beforeUrl = await ApiService.uploadImage(bytes, _beforeImage!.name);

      // بناء البيانات
      final payload = <String, dynamic>{
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
          "latitude": _selectedLatLng?.latitude,
          "longitude": _selectedLatLng?.longitude,
        };
      } else {
        payload["location_id"] = widget.location!.id;
      }

      // إنشاء البلاغ
      final created = await ApiService.createReport(payload);

      if (!mounted) return;

      // صفحة النجاح
      Get.off(() => SuccessPage(reportCode: created.reportCode));
    } catch (e, stack) {
      // اطبع في الـ console
      debugPrint("CreateReport error: $e");
      debugPrint(stack.toString());

      setState(() {
        _errorMessage = e.toString(); // مؤقتاً عشان تشوف الرسالة الحقيقية
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              backgroundColor: const Color(0xFFF4F7F8),
              appBar: AppBar(
                title: const Text("إنشاء بلاغ جديد"),
                elevation: 0,
                backgroundColor: Colors.teal.shade600,
              ),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) _buildErrorBox(),
                      const SizedBox(height: 8),
                      _buildLocationCard(),
                      const SizedBox(height: 14),
                      if (widget.location == null) _buildNewLocationCard(),
                      const SizedBox(height: 14),
                      _buildReportTypeCard(),
                      const SizedBox(height: 14),
                      _buildDetailsCard(),
                      const SizedBox(height: 14),
                      _buildImageCard(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ======================= UI SECTIONS =======================

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(
                Icons.report_gmailerrorred_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "إبلاغ عن تشوه بصري",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "ساعدنا في تحسين منطقتك من خلال إرسال تفاصيل البلاغ وصورة توضح الوضع الحالي.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? "",
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final locationText =
        "${widget.government.nameAr} / ${widget.district.nameAr} / ${widget.area.nameAr}";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "الموقع الأساسي",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              locationText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (widget.location != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.location!.nameAr,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.add_location_alt_outlined,
                  size: 18,
                  color: Colors.teal,
                ),
                SizedBox(width: 6),
                Text(
                  "تفاصيل موقع جديد",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "أدخل اسم المكان (مثال: قرب المدرسة، بجانب المسجد...). "
              "ثم حدّد الموقع مباشرة من الخريطة وسيتم حفظ الإحداثيات داخلياً.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // اسم الموقع
            _buildTextField(
              controller: _locNameAr,
              label: "اسم الموقع",
              required: true,
            ),
            const SizedBox(height: 10),

            // زر الخريطة فقط (بدون حقول خط العرض/خط الطول)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sending ? null : _openMapToSelectLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.teal.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text("تحديد الموقع على الخريطة"),
              ),
            ),
            const SizedBox(height: 10),

            if (_selectedLatLng != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        "تم اختيار موقع من الخريطة بنجاح.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                "لم يتم اختيار موقع من الخريطة بعد (اختياري، لكن يُفضّل تحديده لتحسين دقة البلاغ).",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category_outlined, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "نوع البلاغ",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ReportType>(
              isExpanded: true,
              initialValue: _selectedType,
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.nameAr)))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "اختر نوع البلاغ",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => setState(() => _selectedType = v),
              validator: (v) => v == null ? "هذا الحقل مطلوب" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "تفاصيل البلاغ",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nameAr,
              label: "عنوان البلاغ",
              required: true,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _descAr,
              label: "الوصف",
              required: true,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _note,
              label: "ملاحظات إضافية (اختياري)",
              required: false,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  size: 18,
                  color: Colors.teal,
                ),
                SizedBox(width: 6),
                Text(
                  "الصورة قبل المعالجة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "ارفع صورة توضّح المشكلة الحالية في الموقع.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _pickFromCamera,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.teal.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("التقاط من الكاميرا"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _pickFromGallery,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.teal.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("اختيار من المعرض"),
                  ),
                ),
              ],
            ),
            if (_beforeImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_beforeImage!.path),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _sending ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _sending
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "إرسال البلاغ",
                style: TextStyle(fontSize: 17, color: Colors.white),
              ),
      ),
    );
  }

  // ======================= GENERIC TEXT FIELD =======================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          validator ??
          (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return "هذا الحقل مطلوب";
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
