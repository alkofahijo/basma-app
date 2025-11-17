// lib/pages/reports/history/details/complete_report_page.dart

import 'dart:io';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';

// use central primary color
const Color _pageBackground = Color(0xFFEFF1F1);

class CompleteReportPage extends StatefulWidget {
  final ReportDetail report;

  const CompleteReportPage({super.key, required this.report});

  @override
  State<CompleteReportPage> createState() => _CompleteReportPageState();
}

class _CompleteReportPageState extends State<CompleteReportPage> {
  File? _selectedImage;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _loading = false;
  bool _isConfirmed = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source);
      if (x != null) {
        setState(() => _selectedImage = File(x.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء اختيار الصورة: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null || !_isConfirmed) return;

    setState(() => _loading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final url = await ApiService.uploadImage(bytes, "after.jpg");

      await ApiService.completeReport(
        reportId: widget.report.id,
        imageAfterUrl: url,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل إكمال البلاغ: $e")));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                      colors: [Color(0xFF004d00), kPrimaryColor],
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
                  "بتأكيد إتمام البلاغ، سيُسجَّل البلاغ كمكتمل وسيتم حفظ صور الإكمال."
                  " تأكد من أن الصور والملاحظات تعكس الحل النهائي.",
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
                    color: const Color.fromARGB(
                      255,
                      0,
                      150,
                      10,
                    ).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "تأكد أنك قادر على متابعة البلاغ بعد اكتماله ومراجعة الصور المرفوعة.",
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

  void _showImageSourceSheet() {
    if (_loading) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Border _buildBorder() {
    return Border.all(color: kPrimaryColor.withOpacity(0.5), width: 1.4);
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: _buildBorder(),
          color: Colors.white,
        ),
        child: _selectedImage == null
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
                    "اضغط لرفع أو التقاط صورة",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: _loading
                          ? null
                          : () => setState(() => _selectedImage = null),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
    return Scaffold(
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
            fontSize: 20,
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
                      "تحميل صور بعد الإصلاح",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "اعرض كيف أصبح المكان الآن.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildUploadBox(),
              const SizedBox(height: 24),
              Text(
                "ملاحظات بعد الإصلاح",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "أضف أي تفاصيل قصيرة حول ما قمت به...",
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
                value: _isConfirmed,
                activeColor: kPrimaryColor,
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _isConfirmed = v ?? false),
                title: const Text("أؤكد أننا قمنا بحل المشكلة."),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
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
                          (!_isConfirmed || _selectedImage == null || _loading)
                          ? null
                          : () async {
                              final confirmed =
                                  await _showConfirmCompleteDialog();
                              if (confirmed == true) {
                                await _submit();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
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
    );
  }
}
