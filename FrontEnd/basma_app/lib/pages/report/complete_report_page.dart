import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/report_models.dart';
import '../../services/api_service.dart';

const Color _primaryColor = Color(0xFF008000);

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
    if (_selectedImage == null || !_isConfirmed) return;

    setState(() => _loading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final url = await ApiService.uploadImage(bytes, "after.jpg");

      await ApiService.completeReport(
        reportId: widget.report.id,
        imageAfterUrl: url,
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: _primaryColor,
          centerTitle: true,
          title: const Text(
            "إكمال البلاغ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
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

                // ----- Checkbox (no container wrapper) -----
                CheckboxListTile(
                  value: _isConfirmed,
                  activeColor: _primaryColor,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _isConfirmed = v ?? false),
                  title: const Text("أؤكد أننا قمنا بحل المشكلة."),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 20),

                // ----- Buttons (no background container) -----
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor),
                          foregroundColor: _primaryColor,
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
                          backgroundColor: _primaryColor,
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
      ),
    );
  }

  //============================================================================
  //                                UPLOAD BOX
  //============================================================================

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _loading
          ? null
          : () => showModalBottomSheet(
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
            ),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: _buildDashedBorder(),
          color: Colors.white,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 52,
                    color: Colors.black54, // dark gray
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

                  // Delete icon
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

  // ------- Dashed Border Painter -------
  Border _buildDashedBorder() {
    return Border.all(
      color: Colors.green.withOpacity(0.5),
      width: 1.4,
      strokeAlign: BorderSide.strokeAlignInside,
      style: BorderStyle.solid, // real dashed border using paint below
    );
  }
}
