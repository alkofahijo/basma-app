import 'package:flutter/material.dart';
import 'package:basma_app/widgets/inputs/app_text_field.dart';

/// Backwards-compatible wrapper kept for a smooth migration.
/// Prefer importing `AppTextField` from `widgets/inputs` directly.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType inputType;
  final String? errorText;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.inputType = TextInputType.text,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: obscure,
      keyboardType: inputType,
      errorText: errorText,
      onChanged: onChanged,
    );
  }
}
