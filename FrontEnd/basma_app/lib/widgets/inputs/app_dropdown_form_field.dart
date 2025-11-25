import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_constants.dart';
import 'package:basma_app/utils/responsive.dart';
import 'package:basma_app/widgets/inputs/app_ios_select.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final Widget? labelWidget;
  final String? hint;
  final String? errorText;
  final bool isDense;
  final bool isEnabled;
  final Widget? prefixIcon;

  const AppDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.isDense = false,
    this.isEnabled = true,
    this.prefixIcon,
    this.labelWidget,
  });

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.052).clamp(
      AppSizes.minTapTarget,
      52.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) ...[
          labelWidget!,
          const SizedBox(height: AppSpacing.xs),
        ] else if (label != null) ...[
          Text(
            label!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: R.sp(context, 13)),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm / 1.2),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.02 * 255).round()),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: prefixIcon,
                ),
              ],
              Expanded(
                child: AppIosSelect<T>(
                  value: value,
                  items: items,
                  onChanged: isEnabled ? onChanged : null,
                  hint: hint,
                  prefixIcon: null,
                  enabled: isEnabled,
                ),
              ),
            ],
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
