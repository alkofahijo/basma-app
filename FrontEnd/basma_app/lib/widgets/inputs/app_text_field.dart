import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_constants.dart';
import 'package:basma_app/utils/responsive.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final Widget? labelWidget;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.validator,
    this.labelWidget,
  });

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.055).clamp(
      AppSizes.minTapTarget,
      56.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) ...[
          labelWidget!,
          const SizedBox(height: AppSpacing.xs),
        ] else if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Center(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: onChanged,
                enabled: enabled,
                maxLines: maxLines,
                validator: validator,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  border: InputBorder.none,
                  prefixIcon: prefixIcon,
                  suffixIcon: suffixIcon,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              right: AppSpacing.sm,
            ),
            child: Text(
              errorText!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
