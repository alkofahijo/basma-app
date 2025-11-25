import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_constants.dart';
import 'package:basma_app/utils/responsive.dart';

typedef VoidCallbackNullable = void Function()?;

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallbackNullable onPressed;
  final bool isLoading;
  final bool fullWidth;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.07).clamp(
      AppSizes.minTapTarget,
      64.0,
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? kPrimaryColor.withAlpha((0.5 * 255).round())
              : kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          elevation: onPressed == null ? 0 : 2,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallbackNullable onPressed;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.065).clamp(
      AppSizes.minTapTarget,
      60.0,
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kPrimaryColor.withAlpha((0.8 * 255).round())),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: kPrimaryColor),
        ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallbackNullable onPressed;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: kPrimaryColor),
      ),
    );
  }
}

class AppCardButton extends StatelessWidget {
  final String label;
  final VoidCallbackNullable onPressed;

  const AppCardButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
