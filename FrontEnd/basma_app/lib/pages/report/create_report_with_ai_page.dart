// lib/pages/report/create_report_with_ai_page.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/pages/report/success_page.dart';
import 'package:basma_app/pages/shared/select_location_on_map_page.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const Color _primaryColor = Color(0xFF008000);

class CreateReportWithAiPage extends StatefulWidget {
  const CreateReportWithAiPage({super.key});

  @override
  State<CreateReportWithAiPage> createState() => _CreateReportWithAiPageState();
}

class _CreateReportWithAiPageState extends State<CreateReportWithAiPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loadingLocation = true;
  bool _analyzingImage = false;
  bool _sending = false;
  String? _errorMessage;
  String? _imageErrorMessage;

  ResolvedLocation? _resolvedLocation;
  LatLng? _currentLatLng;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  AiSuggestion? _aiSuggestion;

  // أنواع البلاغ + النوع المختار (باستخدام ReportTypeOption)
  List<ReportTypeOption> _types = [];
  ReportTypeOption? _selectedType;
  bool _loadingTypes = false;
  String? _typesError;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadReportTypes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Safe setState wrapper that checks `mounted` to avoid calling
  /// setState after the State object has been disposed.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _initLocation() async {
    _safeSetState(() {
      _loadingLocation = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("يرجى تفعيل خدمة الموقع (GPS) في الجهاز.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception(
          "تم رفض صلاحية الموقع. الرجاء السماح بها من إعدادات الجهاز.",
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      // استدعاء backend لتحديد المحافظة/اللواء/المنطقة
      final resolved = await ApiService.resolveLocationByLatLng(
        pos.latitude,
        pos.longitude,
      );

      _safeSetState(() {
        _resolvedLocation = resolved;
        _loadingLocation = false;
      });
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString();
        _loadingLocation = false;
      });
    }
  }

  Future<void> _loadReportTypes() async {
    _safeSetState(() {
      _loadingTypes = true;
      _typesError = null;
    });

    try {
      // هذه ترجع List<ReportTypeOption>
      final types = await ApiService.listReportTypes();
      _safeSetState(() {
        _types = types;
        _loadingTypes = false;

        // إذا كان لدينا اقتراح مسبق من الذكاء الاصطناعي، اختر نوع البلاغ المطابق له
        if (_aiSuggestion != null) {
          final match = _types
              .where((t) => t.id == _aiSuggestion!.reportTypeId)
              .toList();
          if (match.isNotEmpty) {
            _selectedType = match.first;
          }
        }
      });
    } catch (e) {
      _safeSetState(() {
        _loadingTypes = false;
        _typesError = "فشل تحميل أنواع البلاغ: $e";
      });
    }
  }

  Future<void> _changeLocationManually() async {
    // فتح صفحة الخريطة لاختيار موقع يدوي
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationOnMapPage(
          initialLat: _currentLatLng?.latitude,
          initialLng: _currentLatLng?.longitude,
        ),
      ),
    );

    if (result != null) {
      _safeSetState(() {
        _currentLatLng = result;
        _loadingLocation = true;
        _aiSuggestion = null; // إعادة ضبط الاقتراحات القديمة
        _selectedType = null; // إعادة ضبط نوع البلاغ
      });
      // إعادة استدعاء resolve-location
      try {
        final resolved = await ApiService.resolveLocationByLatLng(
          result.latitude,
          result.longitude,
        );
        _safeSetState(() {
          _resolvedLocation = resolved;
          _loadingLocation = false;
        });
      } catch (e) {
        _safeSetState(() {
          _errorMessage = e.toString();
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final img = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );
      if (img == null) return;

      _safeSetState(() {
        _imageFile = img;
        _aiSuggestion = null; // reset
        _selectedType = null;
        _errorMessage = null;
        _imageErrorMessage = null;
        _titleCtrl.clear();
        _descCtrl.clear();
        _noteCtrl.clear();
      });

      await _analyzeImageWithAi();
    } catch (e) {
      _safeSetState(() {
        _errorMessage = "حدث خطأ أثناء اختيار الصورة: $e";
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(true);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 28,
                                color: Colors.black,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'التقاط صورة',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(false);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.photo_library,
                                size: 28,
                                color: Colors.black,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'اختيار من المعرض',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImageWithAi() async {
    if (_imageFile == null || _resolvedLocation == null) return;

    _safeSetState(() {
      _analyzingImage = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();

      final suggestion = await ApiService.analyzeReportImage(
        bytes: bytes,
        filename: _imageFile!.name,
        governmentId: _resolvedLocation!.governmentId,
        districtId: _resolvedLocation!.districtId,
        areaId: _resolvedLocation!.areaId,
      );

      _safeSetState(() {
        _aiSuggestion = suggestion;

        // تعبئة الحقول المقترحة
        _titleCtrl.text = suggestion.suggestedTitle;
        _descCtrl.text = suggestion.suggestedDescription;

        // اختيار نوع البلاغ المقترح إذا كان ضمن القائمة
        final match = _types
            .where((t) => t.id == suggestion.reportTypeId)
            .toList();
        if (match.isNotEmpty) {
          _selectedType = match.first;
        }
      });
    } catch (e) {
      _safeSetState(() {
        _errorMessage = "فشل تحليل الصورة بالذكاء الاصطناعي: $e";
      });
    } finally {
      _safeSetState(() {
        _analyzingImage = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_resolvedLocation == null) {
      _safeSetState(() {
        _errorMessage = "لم يتم تحديد الموقع بعد.";
      });
      return;
    }
    if (_imageFile == null) {
      _safeSetState(() {
        _imageErrorMessage = "يرجى اختيار صورة للبلاغ.";
      });
      return;
    }
    if (_selectedType == null) {
      _safeSetState(() {
        _errorMessage = "يرجى اختيار نوع البلاغ.";
      });
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _safeSetState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      // 1) رفع الصورة (نفس دالة uploadImage الحالية لديك)
      final Uint8List bytes = await _imageFile!.readAsBytes();
      final beforeUrl = await ApiService.uploadImage(
        bytes,
        _imageFile!.name,
      ); // موجودة لديك

      // 2) بناء payload
      final payload = <String, dynamic>{
        "report_type_id": _selectedType!.id,
        "name_ar": _titleCtrl.text.trim(),
        "description_ar": _descCtrl.text.trim(),
        "note": _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        "government_id": _resolvedLocation!.governmentId,
        "district_id": _resolvedLocation!.districtId,
        "area_id": _resolvedLocation!.areaId,
        "image_before_url": beforeUrl,
        // هنا نفترض أنك تريد دائماً new_location من الإحداثيات الحالية:
        "new_location": {
          "area_id": _resolvedLocation!.areaId,
          "name_ar": _resolvedLocation!.areaNameAr,
          "latitude": _currentLatLng?.latitude,
          "longitude": _currentLatLng?.longitude,
        },
      };

      final created = await ApiService.createReport(payload);

      if (!mounted) return;

      Get.off(() => SuccessPage(reportCode: created.reportCode));
    } catch (e) {
      _safeSetState(() {
        _errorMessage = "فشل إرسال البلاغ: $e";
      });
    } finally {
      if (mounted) {
        _safeSetState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "إنشاء بلاغ بالذكاء الاصطناعي",
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          centerTitle: true,
          backgroundColor: _primaryColor,
        ),
        body: _loadingLocation
            ? const LoadingCenter()
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      if (_errorMessage != null) _buildErrorBox(),
                      const SizedBox(height: 8),
                      _buildLocationCard(),
                      const SizedBox(height: 12),
                      _buildImageCard(),
                      // 👇 تفاصيل البلاغ تظهر فقط بعد اختيار/التقاط صورة
                      if (_imageFile != null) ...[
                        const SizedBox(height: 12),
                        _buildTypeCard(),
                        const SizedBox(height: 12),
                        _buildDetailsCard(),
                      ],
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.white,
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
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
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
                    "إنشاء بلاغ بالذكاء الاصطناعي",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "سيتم تحديد موقعك تلقائياً وتحليل الصورة لتخمين نوع البلاغ واقتراح عنوان ووصف.",
                    style: TextStyle(fontSize: 12, color: Colors.black),
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
    final r = _resolvedLocation;
    final locText = r == null
        ? "لم يتم تحديد الموقع"
        : "${r.governmentNameAr} / ${r.districtNameAr} / ${r.areaNameAr}";

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: Colors.green),
                const SizedBox(width: 6),
                const Text(
                  "الموقع الحالي",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                  ),
                  onPressed: _changeLocationManually,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text("تعديل", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              locText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (_currentLatLng != null) ...[
              const SizedBox(height: 6),
              Text(
                "Lat: ${_currentLatLng!.latitude.toStringAsFixed(6)}, "
                "Lng: ${_currentLatLng!.longitude.toStringAsFixed(6)}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      color: Colors.white,
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
                  color: Colors.green,
                ),
                SizedBox(width: 6),
                Text(
                  "صورة التوشه البصري",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "التقط أو ارفع صورة للمشكلة وسيتم تحليلها تلقائياً.",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
            const SizedBox(height: 12),

            // show image-specific error above the upload box
            if (_imageErrorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _imageErrorMessage ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // upload area (single control) + thumbnail
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _analyzingImage || _sending
                          ? null
                          : _showImageSourceSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'رفع صورة البلاغ',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _imageFile != null
                      ? Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_imageFile!.path),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _analyzingImage || _sending
                                    ? null
                                    : () => _safeSetState(() {
                                        _imageFile = null;
                                        _imageErrorMessage = null;
                                        _aiSuggestion = null;
                                      }),
                                icon: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                ],
              ),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imageFile!.path),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (_analyzingImage)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "جارٍ تحليل الصورة بالذكاء الاصطناعي...",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              )
            else if (_aiSuggestion != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "نوع البلاغ المتوقع: ${_aiSuggestion!.reportTypeNameAr} "
                        "(ثقة: ${(100 * _aiSuggestion!.confidence).toStringAsFixed(1)}%)",
                        style: const TextStyle(fontSize: 12),
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

  Widget _buildDetailsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  " تفاصيل البلاغ (يمكنك التعديل)",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _titleCtrl,
              label: "عنوان البلاغ (يمكنك التعديل)",
              required: true,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _descCtrl,
              label: "الوصف (يمكنك التعديل)",
              required: true,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _noteCtrl,
              label: "ملاحظات إضافية (اختياري)",
              required: false,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.report, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  "نوع البلاغ (يمكنك التعديل)",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingTypes)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "جارٍ تحميل أنواع البلاغ...",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              )
            else if (_typesError != null)
              Text(
                _typesError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )
            else if (_types.isEmpty)
              const Text(
                "لا توجد أنواع بلاغ متاحة.",
                style: TextStyle(fontSize: 12),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<ReportTypeOption>(
                  value: _selectedType,
                  items: _types
                      .map(
                        (t) => DropdownMenuItem<ReportTypeOption>(
                          value: t,
                          child: Text(t.nameAr),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _safeSetState(() {
                      _selectedType = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: _selectedType?.nameAr ?? 'اختر نوع البلاغ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  validator: (ReportTypeOption? value) {
                    if (value == null) return 'يرجى اختيار نوع البلاغ';
                    return null;
                  },
                ),
              ),
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
          backgroundColor: _primaryColor,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    int maxLines = 1,
  }) {
    // Pill-shaped text field to match the screenshot design
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return "هذا الحقل مطلوب";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 14 : 16,
          ),
        ),
      ),
    );
  }
}
