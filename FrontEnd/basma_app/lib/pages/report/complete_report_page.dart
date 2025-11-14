import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/report_models.dart';
import '../../services/api_service.dart';

class CompleteReportPage extends StatefulWidget {
  final ReportDetail report;

  const CompleteReportPage({super.key, required this.report});

  @override
  State<CompleteReportPage> createState() => _CompleteReportPageState();
}

class _CompleteReportPageState extends State<CompleteReportPage> {
  File? _selectedImage;
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  bool _isConfirmed = false;

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
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار صورة بعد الإصلاح أولاً.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final imageUrl = await ApiService.uploadImage(bytes, "after.jpg");

      await ApiService.completeReport(
        reportId: widget.report.id,
        imageAfterUrl: imageUrl,
        note: _noteCtrl.text,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Upload Photos and details after fixing an issue."),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ====== المحتوى الرئيسي مع Scroll ======
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // عناوين قسم التحميل
                    Text(
                      "Upload After Photos",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Show How The Area Looks Now.",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "تحميل صور بعد إصلاح المشكلة",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // كارد الصور + أزرار المعرض/الكاميرا
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 230,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 230,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Colors.grey.shade100,
                                      Colors.grey.shade200,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_outlined,
                                      size: 52,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "لم يتم اختيار صورة بعد",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _pick(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: const Text("اختيار من المعرض"),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _pick(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text("التقاط صورة"),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // حقل الملاحظات
                    Text(
                      "ملاحظات بعد الإصلاح",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText:
                            "أضف أي تفاصيل أو ملاحظات إضافية بعد إصلاح المشكلة...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Checkbox التأكيد
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: CheckboxListTile(
                        value: _isConfirmed,
                        onChanged: _loading
                            ? null
                            : (v) {
                                setState(() {
                                  _isConfirmed = v ?? false;
                                });
                              },
                        title: const Text(
                          "أؤكد أننا قمنا بحل المشكلة.\n"
                          "I confirm that we have fixed the issue.",
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ====== الأزرار في الأسفل ======
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
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
                            (!_isConfirmed ||
                                _selectedImage == null ||
                                _loading)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
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
                                ),
                              )
                            : const Text("تأكيد إكمال البلاغ"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
