import 'package:basma_app/theme/app_colors.dart';
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
    return Row(
      children: [
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              if (!isMyReports)
                _buildChip(
                  label: 'جديد',
                  selected: _isOpenTab,
                  color: kPrimaryColor,
                  onTap: () => onStatusChanged('open'),
                ),
              _buildChip(
                label: 'قيد العمل',
                selected: _isInProgressTab,
                color: kPrimaryColor,
                onTap: () => onStatusChanged('in_progress'),
              ),
              _buildChip(
                label: 'مكتمل',
                selected: _isCompletedTab,
                color: kPrimaryColor,
                onTap: () => onStatusChanged('completed'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
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
