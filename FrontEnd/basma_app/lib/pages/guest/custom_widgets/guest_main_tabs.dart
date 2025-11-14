// lib/pages/guest/widgets/guest_main_tabs.dart

import 'package:flutter/material.dart';

/// تبويب علوي لاختيار:
/// - كل البلاغات
/// - بلاغاتي (فقط للمستخدم المسجّل)
class GuestMainTabs extends StatelessWidget {
  final bool isLoggedIn;
  final String currentTab; // 'all' / 'mine'
  final ValueChanged<String> onTabChanged;

  const GuestMainTabs({
    super.key,
    required this.isLoggedIn,
    required this.currentTab,
    required this.onTabChanged,
  });

  bool get _isAllTab => currentTab == 'all';
  bool get _isMineTab => currentTab == 'mine';

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      // الضيف لا يرى تبويب "بلاغاتي"
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_pin_circle_outlined,
              size: 20,
              color: Colors.teal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(
                    label: 'كل البلاغات',
                    selected: _isAllTab,
                    onTap: () => onTabChanged('all'),
                    theme: theme,
                  ),
                  _buildChip(
                    label: 'بلاغاتي',
                    selected: _isMineTab,
                    onTap: () => onTabChanged('mine'),
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
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final Color activeColor = theme.colorScheme.primary;

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
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? activeColor : Colors.grey.shade300),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
