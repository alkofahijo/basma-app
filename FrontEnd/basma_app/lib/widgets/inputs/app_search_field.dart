import 'package:flutter/material.dart';
import 'package:basma_app/utils/responsive.dart';
import 'package:basma_app/theme/app_constants.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSearch;
  final bool isLoading;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.055).clamp(44.0, 56.0);
    final iconSize = (height * 0.45).clamp(14.0, 22.0);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(Icons.search, size: iconSize, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration.collapsed(hintText: hint ?? 'Search'),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch?.call(),
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (onSearch != null)
            IconButton(onPressed: onSearch, icon: const Icon(Icons.check))
          else if (onClear != null)
            IconButton(
              icon: Icon(Icons.close, size: iconSize),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
