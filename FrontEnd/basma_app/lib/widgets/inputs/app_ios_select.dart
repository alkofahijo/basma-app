import 'dart:math';

import 'package:flutter/material.dart';
import 'package:basma_app/utils/responsive.dart';
import 'package:basma_app/theme/app_constants.dart';

/// A generic iOS-style options selector that shows a rounded bottom sheet
/// with a compact list of options and a nice checkmark for the selected item.
class AppIosSelect<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final Widget? prefixIcon;

  const AppIosSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.prefixIcon,
  });

  String _labelFor(DropdownMenuItem<T> item, BuildContext context) {
    final child = item.child;

    String? tryExtract(Widget? w) {
      if (w == null) return null;
      if (w is Text) return w.data?.trim();
      if (w is RichText) {
        try {
          return w.text.toPlainText().trim();
        } catch (_) {
          return null;
        }
      }

      // Common single-child wrappers
      if (w is Expanded) return tryExtract(w.child);
      if (w is Flexible) return tryExtract(w.child);
      if (w is Padding) return tryExtract(w.child);
      if (w is Align) return tryExtract(w.child);
      if (w is Center) return tryExtract(w.child);
      if (w is Container) return tryExtract(w.child);
      if (w is SizedBox) return tryExtract(w.child);
      if (w is InkWell) return tryExtract(w.child);
      if (w is GestureDetector) return tryExtract(w.child);
      if (w is DecoratedBox) return tryExtract(w.child);
      if (w is FittedBox) return tryExtract(w.child);

      // Multi-child containers
      if (w is Row) {
        for (final c in w.children) {
          final s = tryExtract(c);
          if (s != null && s.isNotEmpty) return s;
        }
      }
      if (w is Column) {
        for (final c in w.children) {
          final s = tryExtract(c);
          if (s != null && s.isNotEmpty) return s;
        }
      }
      if (w is Wrap) {
        for (final c in w.children) {
          final s = tryExtract(c);
          if (s != null && s.isNotEmpty) return s;
        }
      }

      if (w is ListTile) {
        final t = tryExtract(w.title ?? const SizedBox.shrink());
        if (t != null && t.isNotEmpty) return t;
        final sub = tryExtract(w.subtitle ?? const SizedBox.shrink());
        if (sub != null && sub.isNotEmpty) return sub;
      }

      return null;
    }

    final extracted = tryExtract(child);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    // Fallback: short debug string
    try {
      return child.toStringShort();
    } catch (_) {
      return child.toString();
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    if (!enabled) return;

    final selected = await showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.6;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final indicatorWidth = min(56.0, screenWidth * 0.18);
        final indicatorHeight = (screenWidth * 0.01).clamp(3.0, 6.0);
        final textStyle = Theme.of(
          ctx,
        ).textTheme.bodySmall?.copyWith(fontSize: R.sp(ctx, 15));
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Container(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.medium),
                  ),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(indicatorHeight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemBuilder: (c, i) {
                          final it = items[i];
                          final label = _labelFor(it, c);
                          final isSelected = it.value == value;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(c).pop(it.value),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style:
                                            textStyle ??
                                            TextStyle(fontSize: R.sp(c, 15)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: Colors.green.shade700,
                                        size: R.sp(c, 18),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemCount: items.length,
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey[50],
                              foregroundColor: Colors.black87,
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.small,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'إلغاء',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && onChanged != null) onChanged!(selected);
  }

  @override
  Widget build(BuildContext context) {
    final height = (R.screenHeight(context) * 0.052).clamp(
      AppSizes.minTapTarget,
      52.0,
    );
    final displayItem = items.firstWhere(
      (it) => it.value == value,
      orElse: () => DropdownMenuItem<T>(value: null, child: Text(hint ?? '')),
    );
    final displayTextWidget = displayItem.child is Text
        ? Text(
            (displayItem.child as Text).data ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: R.sp(context, 14),
              color: value == null ? Colors.black45 : Colors.black87,
            ),
          )
        : displayItem.child;

    return InkWell(
      onTap: () => _showOptions(context),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md / 2),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
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
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: prefixIcon,
              ),
            Expanded(
              child: DefaultTextStyle(
                style:
                    Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                child: displayTextWidget,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: R.sp(context, 18),
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}
