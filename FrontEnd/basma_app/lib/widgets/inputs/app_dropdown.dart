import 'package:flutter/material.dart';
import 'package:basma_app/widgets/inputs/app_ios_select.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AppIosSelect<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
    );
  }
}
