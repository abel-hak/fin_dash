import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Root bottom-navigation shell for authenticated routes.
///
/// Wraps the four primary destinations (Home, Inbox, Activity, More) in a
/// `StatefulNavigationShell` so each tab keeps its own navigation stack and
/// switching is instant. Renders a modern floating pill nav bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
    _NavItem(Icons.inbox_outlined, Icons.inbox_rounded, 'Inbox'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Activity'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    return Scaffold(
      backgroundColor: t.canvas,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.m,
          ),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: t.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavButton(
                  item: _items[i],
                  selected: navigationShell.currentIndex == i,
                  onTap: () => _onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 24,
                color: selected ? AppColors.accent : t.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.accent : t.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
