import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/theme/app_colors.dart';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';

import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/pages/reports/new/widgets/success_page.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';

import 'widgets/select_location_page.dart';

/// صفحة إنشاء بلاغ تشوّه بصري باستخدام الذكاء الاصطناعي
class CreateReportWithAiPage extends StatefulWidget {
  const CreateReportWithAiPage({super.key});

  @override
  State<CreateReportWithAiPage> createState() => _CreateReportWithAiPageState();
}

class _CreateReportWithAiPageState extends State<CreateReportWithAiPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Auth Guard & Loading Flags ---
  bool _isCheckingAuth = true;

  bool _isLocationLoading = true;
  bool _isImageAnalyzing = false;
  bool _isSubmitting = false;

  String? _generalErrorMessage;
  String? _imageErrorMessage;

  // --- Location ---
  ResolvedLocation? _resolvedLocation;
  LatLng? _currentLocation;

  // --- Text Controllers ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // --- Image & AI Suggestion ---
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImageFile;
  AiSuggestion? _aiSuggestion;

  // --- Report Types ---
  List<ReportTypeOption> _reportTypes = [];
  ReportTypeOption? _selectedReportType;
  bool _isReportTypesLoading = false;
  String? _reportTypesErrorMessage;

  @override
  void initState() {
    super.initState();
    _runAuthGuard();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ========= Helpers =========

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _clearTextFields() {
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
  }

  // ========= Auth Guard =========

  Future<void> _runAuthGuard() async {
    try {
      final user = await AuthService.currentUser();
      if (!mounted) return;

      if (user == null) {
        // المستخدم ضيف → نرجع لصفحة الهبوط
        Get.offAll(() => const LandingPage());
        return;
      }

      _safeSetState(() {
        _isCheckingAuth = false;
      });

      // بعد التأكد من تسجيل الدخول:
      await _initCurrentLocation();
      await _loadReportTypes();
    } catch (_) {
      if (!mounted) return;
      Get.offAll(() => const LandingPage());
    }
  }

  // ========= Location =========

  Future<void> _initCurrentLocation() async {
    _safeSetState(() {
      _isLocationLoading = true;
      _generalErrorMessage = null;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("يرجى تفعيل خدمة الموقع (GPS) في الجهاز.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          "تم رفض صلاحية الموقع. الرجاء السماح بها من إعدادات الجهاز.",
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);

      final resolvedLocation = await ApiService.resolveLocationByLatLng(
        position.latitude,
        position.longitude,
      );

      _safeSetState(() {
        _resolvedLocation = resolvedLocation;
        _isLocationLoading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _generalErrorMessage = e.toString();
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _changeLocationFromMap() async {
    final LatLng? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationOnMapPage(
          initialLat: _currentLocation?.latitude,
          initialLng: _currentLocation?.longitude,
        ),
      ),
    );

    if (selected == null) return;

    _safeSetState(() {
      _currentLocation = selected;
      _isLocationLoading = true;
      _aiSuggestion = null;
      _selectedReportType = null;
      _generalErrorMessage = null;
    });

    try {
      final resolved = await ApiService.resolveLocationByLatLng(
        selected.latitude,
        selected.longitude,
      );

      _safeSetState(() {
        _resolvedLocation = resolved;
        _isLocationLoading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _generalErrorMessage = e.toString();
        _isLocationLoading = false;
      });
    }
  }

  // ========= Report Types =========

  Future<void> _loadReportTypes() async {
    _safeSetState(() {
      _isReportTypesLoading = true;
      _reportTypesErrorMessage = null;
    });

    try {
      final types = await ApiService.listReportTypes();

      // إعادة ترتيب القائمة بحيث تكون "أخرى" في النهاية دائماً
      types.sort((a, b) {
        final aIsOthers = a.nameAr.trim() == 'أخرى';
        final bIsOthers = b.nameAr.trim() == 'أخرى';

        if (aIsOthers == bIsOthers) return 0;
        if (aIsOthers) return 1;
        return -1;
      });

      _safeSetState(() {
        _reportTypes = types;
        _isReportTypesLoading = false;

        // في حال كان عندنا اقتراح سابق من الذكاء الاصطناعي
        if (_aiSuggestion != null) {
          final match = _reportTypes
              .where((t) => t.id == _aiSuggestion!.reportTypeId)
              .toList();
          if (match.isNotEmpty) {
            _selectedReportType = match.first;
          }
        }
      });
    } catch (e) {
      _safeSetState(() {
        _isReportTypesLoading = false;
        _reportTypesErrorMessage = "فشل تحميل أنواع البلاغ: $e";
      });
    }
  }

  // ========= Image Picking & AI Analysis =========

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedImage == null) return;

      _safeSetState(() {
        _selectedImageFile = pickedImage;
        _aiSuggestion = null;
        _selectedReportType = null;
        _imageErrorMessage = null;
        _generalErrorMessage = null;

        _clearTextFields();
      });

      await _analyzeImageWithAi();
    } catch (e) {
      _safeSetState(() {
        _generalErrorMessage = "حدث خطأ أثناء اختيار الصورة: $e";
      });
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'اختر مصدر الصورة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isImageAnalyzing || _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _pickImage(fromCamera: true);
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: .8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 28),
                              SizedBox(height: 6),
                              Text('التقاط صورة'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _isImageAnalyzing || _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _pickImage(fromCamera: false);
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: .8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 28),
                              SizedBox(height: 6),
                              Text('اختيار من المعرض'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
    if (_selectedImageFile == null || _resolvedLocation == null) return;

    _safeSetState(() {
      _isImageAnalyzing = true;
      _generalErrorMessage = null;
    });

    try {
      final Uint8List imageBytes = await _selectedImageFile!.readAsBytes();

      final suggestion = await ApiService.analyzeReportImage(
        bytes: imageBytes,
        filename: _selectedImageFile!.name,
        governmentId: _resolvedLocation!.governmentId,
        districtId: _resolvedLocation!.districtId,
        areaId: _resolvedLocation!.areaId,
      );

      _safeSetState(() {
        _aiSuggestion = suggestion;
        _titleController.text = suggestion.suggestedTitle;
        _descriptionController.text = suggestion.suggestedDescription;

        final matchedType = _reportTypes
            .where((t) => t.id == suggestion.reportTypeId)
            .toList();
        if (matchedType.isNotEmpty) {
          _selectedReportType = matchedType.first;
        }
      });
    } catch (e) {
      _safeSetState(() {
        _generalErrorMessage = "فشل تحليل الصورة بالذكاء الاصطناعي: $e";
      });
    } finally {
      _safeSetState(() {
        _isImageAnalyzing = false;
      });
    }
  }

  // ========= Submit =========

  Future<void> _submitReport() async {
    if (_resolvedLocation == null) {
      _safeSetState(() {
        _generalErrorMessage = "لم يتم تحديد موقع البلاغ بعد.";
      });
      return;
    }

    if (_selectedImageFile == null) {
      _safeSetState(() {
        _imageErrorMessage = "يرجى إضافة صورة للتشوّه البصري.";
      });
      return;
    }

    if (_selectedReportType == null) {
      _safeSetState(() {
        _generalErrorMessage = "يرجى اختيار نوع التشوّه البصري.";
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _safeSetState(() {
      _isSubmitting = true;
      _generalErrorMessage = null;
    });

    try {
      // 1) رفع الصورة
      final Uint8List imageBytes = await _selectedImageFile!.readAsBytes();
      final String beforeImageUrl = await ApiService.uploadImage(
        imageBytes,
        _selectedImageFile!.name,
      );

      // 2) بناء بيانات البلاغ
      final Map<String, dynamic> payload = {
        "report_type_id": _selectedReportType!.id,
        "name_ar": _titleController.text.trim(),
        "description_ar": _descriptionController.text.trim(),
        "note": _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        "government_id": _resolvedLocation!.governmentId,
        "district_id": _resolvedLocation!.districtId,
        "area_id": _resolvedLocation!.areaId,
        "image_before_url": beforeImageUrl,
        "new_location": {
          "area_id": _resolvedLocation!.areaId,
          "name_ar": _resolvedLocation!.areaNameAr,
          "latitude": _currentLocation?.latitude,
          "longitude": _currentLocation?.longitude,
        },
      };

      final createdReport = await ApiService.createReport(payload);

      if (!mounted) return;

      // استخدام نسخة SuccessPage الخاصة بإنشاء بلاغ جديد
      Get.offAll(
        () => SuccessPage.forNewReport(reportCode: createdReport.reportCode),
      );
    } catch (e) {
      _safeSetState(() {
        _generalErrorMessage = "فشل إرسال البلاغ: $e";
      });
    } finally {
      _safeSetState(() {
        _isSubmitting = false;
      });
    }
  }

  // ========= Build =========

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Color(0xFFEFF1F1),
          body: LoadingCenter(),
        ),
      );
    }

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
            "بلاغ تشوّه بصري",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: kPrimaryColor,
          systemOverlayStyle: AppSystemUi.green,
        ),
        body: _isLocationLoading
            ? const LoadingCenter()
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 12),
                      if (_generalErrorMessage != null) _buildErrorBanner(),
                      const SizedBox(height: 8),
                      _buildLocationCard(),
                      const SizedBox(height: 12),
                      _buildImageCard(),
                      if (_selectedImageFile != null) ...[
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
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: -1),
      ),
    );
  }

  // ========= UI Sections =========

  Widget _buildIntroCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "إنشاء بلاغ تشوّه بصري",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "التقط صورة للمشكلة، وسنحدّد موقعك ونقترح نوع البلاغ والعنوان والوصف باستخدام الذكاء الاصطناعي. يمكنك تعديل كل شيء قبل الإرسال.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black87,
                      height: 1.4,
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _generalErrorMessage ?? "",
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = _resolvedLocation;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: kPrimaryColor),
                const SizedBox(width: 6),
                const Text(
                  "موقع البلاغ",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "سيتم إرسال البلاغ حسب هذا الموقع. تأكّد من صحته أو قم بتعديله من الخريطة.",
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            if (location == null)
              const Text(
                "لم يتم تحديد الموقع.",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationRow(
                          label: "المحافظة",
                          value: location.governmentNameAr,
                        ),
                        const SizedBox(height: 4),
                        _buildLocationRow(
                          label: "اللواء",
                          value: location.districtNameAr,
                        ),
                        const SizedBox(height: 4),
                        _buildLocationRow(
                          label: "المنطقة",
                          value: location.areaNameAr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _changeLocationFromMap,
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 16,
                    ),
                    label: const Text("تعديل", style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({required String label, required String value}) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  size: 18,
                  color: kPrimaryColor,
                ),
                const SizedBox(width: 6),
                const Text(
                  "صورة التشوّه البصري",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "التقط أو ارفع صورة للموقع المتضرّر، وسيتم تحليلها تلقائياً لتخمين نوع البلاغ.",
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            if (_imageErrorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
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
            GestureDetector(
              onTap: _isImageAnalyzing || _isSubmitting
                  ? null
                  : _showImageSourceBottomSheet,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.6),
                    width: 1.4,
                  ),
                  color: Colors.white,
                ),
                child: _selectedImageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 52,
                            color: Colors.black54,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "اضغط لالتقاط أو رفع صورة",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_selectedImageFile!.path),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: GestureDetector(
                              onTap: _isImageAnalyzing || _isSubmitting
                                  ? null
                                  : () {
                                      _safeSetState(() {
                                        _selectedImageFile = null;
                                        _imageErrorMessage = null;
                                        _aiSuggestion = null;
                                        _selectedReportType = null;
                                        _clearTextFields();
                                      });
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isImageAnalyzing)
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
                  color: Colors.green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "تحليل الذكاء الاصطناعي: ${_aiSuggestion!.reportTypeNameAr} ",

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

  Widget _buildTypeCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_outlined, size: 18, color: kPrimaryColor),
                const SizedBox(width: 6),
                const Text(
                  "نوع التشوّه البصري",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isReportTypesLoading)
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
            else if (_reportTypesErrorMessage != null)
              Text(
                _reportTypesErrorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )
            else if (_reportTypes.isEmpty)
              const Text(
                "لا توجد أنواع بلاغ متاحة.",
                style: TextStyle(fontSize: 12),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<ReportTypeOption>(
                  initialValue: _selectedReportType,
                  items: _reportTypes
                      .map(
                        (type) => DropdownMenuItem<ReportTypeOption>(
                          value: type,
                          child: Text(type.nameAr),
                        ),
                      )
                      .toList(),
                  onChanged: (ReportTypeOption? value) {
                    _safeSetState(() {
                      if (value != null && value != _selectedReportType) {
                        // عند تغيير نوع البلاغ يدويًا:
                        // امسح الحقول + امسح اقتراح AI
                        _clearTextFields();
                        _aiSuggestion = null;
                      }
                      _selectedReportType = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'اختر نوع التشوّه البصري',
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
                    if (value == null) {
                      return 'يرجى اختيار نوع البلاغ';
                    }
                    return null;
                  },
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: kPrimaryColor,
                ),
                const SizedBox(width: 6),
                const Text(
                  "تفاصيل البلاغ",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildBasmaTextField(
              controller: _titleController,
              label: "عنوان البلاغ (يمكنك التعديل)",
              isRequired: true,
            ),
            const SizedBox(height: 10),
            _buildBasmaTextField(
              controller: _descriptionController,
              label: "وصف المشكلة (يمكنك التعديل)",
              isRequired: true,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _buildBasmaTextField(
              controller: _notesController,
              label: "ملاحظات إضافية (اختياري)",
              isRequired: false,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
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
                style: TextStyle(
                  fontSize: 16.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ========= Shared TextField =========

  Widget _buildBasmaTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
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
