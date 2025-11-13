import 'package:flutter/material.dart';

class AddAreaPopup extends StatefulWidget {
  final String govName;
  final String districtName;

  const AddAreaPopup({
    super.key,
    required this.govName,
    required this.districtName,
  });

  @override
  State<AddAreaPopup> createState() => _AddAreaPopupState();
}

class _AddAreaPopupState extends State<AddAreaPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ar = TextEditingController();
  final TextEditingController _en = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("إضافة منطقة جديدة"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("المحافظة: ${widget.govName}"),
            Text("اللواء/القضاء: ${widget.districtName}"),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ar,
              decoration: const InputDecoration(
                labelText: "اسم المنطقة (عربي)",
              ),
              validator: (v) => v!.trim().isEmpty ? "الحقل مطلوب" : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _en,
              decoration: const InputDecoration(
                labelText: "اسم المنطقة (إنجليزي)",
              ),
              validator: (v) => v!.trim().isEmpty ? "الحقل مطلوب" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("إلغاء"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text("إضافة"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                "ar": _ar.text.trim(),
                "en": _en.text.trim(),
              });
            }
          },
        ),
      ],
    );
  }
}
