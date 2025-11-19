import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';

/// تابات حالة البلاغات (جديد / قيد العمل / مكتمل)
/// - currentStatusTab: 'open' / 'in_progress' / 'completed'
/// - isMyReports: في حالة "بلاغاتي" لا نظهر تبويب "جديد"
class GuestStatusTabs extends StatelessWidget {
  final String currentStatusTab;
  final bool isMyReports;
  final ValueChanged<String> onStatusChanged;

  const GuestStatusTabs({
    super.key,
    required this.currentStatusTab,
    required this.isMyReports,
    required this.onStatusChanged,
  });

  bool get _isOpenSelected => currentStatusTab == 'open';
  bool get _isInProgressSelected => currentStatusTab == 'in_progress';
  bool get _isCompletedSelected => currentStatusTab == 'completed';

  @override
  Widget build(BuildContext context) {
    final List<_StatusTabConfig> tabs = [];

    if (!isMyReports) {
      tabs.add(
        _StatusTabConfig(
          key: 'open',
          label: 'جديد',
          icon: Icons.fiber_new_outlined,
          isSelected: _isOpenSelected,
          onTap: () => onStatusChanged('open'),
        ),
      );
    }

    tabs.addAll([
      _StatusTabConfig(
        key: 'in_progress',
        label: 'قيد العمل',
        icon: Icons.autorenew_rounded,
        isSelected: _isInProgressSelected,
        onTap: () => onStatusChanged('in_progress'),
      ),
      _StatusTabConfig(
        key: 'completed',
        label: 'مكتمل',
        icon: Icons.check_circle_outline,
        isSelected: _isCompletedSelected,
        onTap: () => onStatusChanged('completed'),
      ),
    ]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: tabs
              .map((tab) => Expanded(child: _StatusTabButton(config: tab)))
              .toList(),
        ),
      ),
    );
  }
}

/// إعدادات كل تاب
class _StatusTabConfig {
  final String key;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  _StatusTabConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
}

/// زر تاب واحد بشكل Segmented Control
class _StatusTabButton extends StatelessWidget {
  final _StatusTabConfig config;

  const _StatusTabButton({required this.config});

  @override
  Widget build(BuildContext context) {
    final bool selected = config.isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: config.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          kPrimaryColor,
                          kPrimaryColor.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    config.icon,
                    size: 18,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      config.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
