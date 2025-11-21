import 'dart:io';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class CompleteReportPage extends StatefulWidget {
  final ReportDetail report;

  const CompleteReportPage({super.key, required this.report});

  @override
  State<CompleteReportPage> createState() => _CompleteReportPageState();
}

class _CompleteReportPageState extends State<CompleteReportPage> {
  final TextEditingController _completionNotesController =
      TextEditingController();

  File? _afterImageFile;

  bool _isSubmitting = false;
  bool _isCompletionConfirmed = false;

  @override
  void dispose() {
    _completionNotesController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ========= Image Picking =========

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;

      _safeSetState(() {
        _afterImageFile = File(picked.path);
      });
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء اختيار الصورة: $e");
    }
  }

  void _showImageSourceBottomSheet() {
    if (_isSubmitting) return;

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
                  Icon(
                    Icons.photo_camera_back_outlined,
                    size: 20,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "اختر مصدر الصورة",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
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
                              Icon(Icons.camera_alt_outlined, size: 26),
                              SizedBox(height: 6),
                              Text("التقاط صورة"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
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
                              Icon(Icons.photo_library_outlined, size: 26),
                              SizedBox(height: 6),
                              Text("اختيار من المعرض"),
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
                onPressed: () => Navigator.pop(context),
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

  // ========= Submit =========

  Future<void> _submitCompletion() async {
    if (_afterImageFile == null || !_isCompletionConfirmed) return;

    _safeSetState(() {
      _isSubmitting = true;
    });

    try {
      final bytes = await _afterImageFile!.readAsBytes();
      final imageUrl = await ApiService.uploadImage(bytes, "after.jpg");

      await ApiService.completeReport(
        reportId: widget.report.id,
        imageAfterUrl: imageUrl,
        note: _completionNotesController.text.trim().isEmpty
            ? null
            : _completionNotesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar("فشل إكمال البلاغ: $e");
    } finally {
      _safeSetState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<bool?> _showConfirmCompleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            titlePadding: const EdgeInsets.only(top: 16),
            backgroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "تأكيد إتمام البلاغ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "بتأكيد إتمام البلاغ، سيتم تسجيله كمكتمل وحفظ صورة ما بعد الإصلاح مع ملاحظاتك.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "تأكد أن الصورة توضح النتيجة النهائية للموقع بعد المعالجة.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 4,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(110, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "تأكيد الإتمام",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ========= UI Helpers =========

  Border _buildUploadBorder() {
    return Border.all(color: kPrimaryColor.withValues(alpha: 0.5), width: 1.4);
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _showImageSourceBottomSheet,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: _buildUploadBorder(),
          color: Colors.white,
        ),
        child: _afterImageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 52,
                    color: Colors.black54,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "اضغط لرفع أو التقاط صورة بعد الإصلاح",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _afterImageFile!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              _safeSetState(() {
                                _afterImageFile = null;
                              });
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          backgroundColor: kPrimaryColor,
          systemOverlayStyle: AppSystemUi.green,
          centerTitle: true,
          title: const Text(
            "إكمال البلاغ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        "أضف صورة بعد الإصلاح",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "ساعدنا في توثيق تحوّل الموقع بعد معالجة التشوّه البصري.",
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildUploadBox(),
                const SizedBox(height: 24),
                Text(
                  "ملاحظات بعد الإصلاح (اختياري)",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _completionNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          "اذكر بإيجاز ما تم عمله لمعالجة التشوّه البصري...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _isCompletionConfirmed,
                  activeColor: kPrimaryColor,
                  onChanged: _isSubmitting
                      ? null
                      : (v) => _safeSetState(
                          () => _isCompletionConfirmed = v ?? false,
                        ),
                  title: const Text("أؤكد أن المشكلة تم حلّها في الموقع."),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimaryColor),
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("إلغاء"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (!_isCompletionConfirmed ||
                                _afterImageFile == null ||
                                _isSubmitting)
                            ? null
                            : () async {
                                final confirmed =
                                    await _showConfirmCompleteDialog();
                                if (confirmed == true) {
                                  await _submitCompletion();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "تأكيد إكمال البلاغ",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: 1),
      ),
    );
  }
}
