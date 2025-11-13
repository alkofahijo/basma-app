import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() => _selectedImage = File(x.path));
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) return;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إكمال البلاغ")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            onPressed: _pick,
            child: const Text("اختيار صورة بعد"),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 15),
            Image.file(_selectedImage!, height: 250),
          ],

          const SizedBox(height: 20),

          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "ملاحظات",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text("إكمال البلاغ"),
          ),
        ],
      ),
    );
  }
}
