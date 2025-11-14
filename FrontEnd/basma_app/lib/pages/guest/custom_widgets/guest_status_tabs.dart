// lib/pages/guest/widgets/guest_status_tabs.dart

import 'package:flutter/material.dart';

class GuestStatusTabs extends StatelessWidget {
  /// 'open' / 'in_progress' / 'completed'
  final String currentStatusTab;

  /// هل نحن في تبويب "بلاغاتي"؟
  final bool isMyReports;

  final ValueChanged<String> onStatusChanged;

  const GuestStatusTabs({
    super.key,
    required this.currentStatusTab,
    required this.isMyReports,
    required this.onStatusChanged,
  });

  bool get _isOpenTab => currentStatusTab == 'open';
  bool get _isInProgressTab => currentStatusTab == 'in_progress';
  bool get _isCompletedTab => currentStatusTab == 'completed';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.timeline_outlined, size: 20, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  // في "بلاغاتي" لا نعرض تبويب "جديد"
                  if (!isMyReports)
                    _buildChip(
                      label: 'جديد',
                      selected: _isOpenTab,
                      color: Colors.blue,
                      onTap: () => onStatusChanged('open'),
                      theme: theme,
                    ),
                  _buildChip(
                    label: 'قيد العمل',
                    selected: _isInProgressTab,
                    color: Colors.orange,
                    onTap: () => onStatusChanged('in_progress'),
                    theme: theme,
                  ),
                  _buildChip(
                    label: 'مكتمل',
                    selected: _isCompletedTab,
                    color: Colors.green,
                    onTap: () => onStatusChanged('completed'),
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      selectedColor: color,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? color : Colors.grey.shade300),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
