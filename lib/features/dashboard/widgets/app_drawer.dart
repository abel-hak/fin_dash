import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_logic.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Navigation drawer, token-driven to match the dark Finance OS theme.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.theming;
    final money = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final transactionsAsync = ref.watch(parsedTransactionsProvider);
    final user = ref.watch(userProvider);

    final balance = transactionsAsync.maybeWhen(
      data: DashboardData.latestBalance,
      orElse: () => 0.0,
    );
    final name = (user?.email ?? 'there').split('@').first;
    final initials =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Drawer(
      backgroundColor: t.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: const EdgeInsets.all(AppSpacing.l),
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.l),
                boxShadow: AppShadows.glow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.canvas,
                    child: Text(
                      initials,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.textOnAccent),
                  ),
                  Text(
                    money.format(balance),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            _item(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
            _item(context, Icons.account_balance_wallet_rounded, 'Accounts',
                '/accounts'),
            _item(context, Icons.receipt_long_rounded, 'Transactions',
                '/transactions'),
            _item(context, Icons.pie_chart_rounded, 'Budgets', '/budgets'),
            _item(context, Icons.flag_rounded, 'Goals', '/goals'),
            Divider(color: t.border),
            _item(context, Icons.inbox_rounded, 'SMS Inbox', '/inbox'),
            _item(context, Icons.settings_rounded, 'Settings', '/settings'),
            Divider(color: t.border),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: Text(
                'Logout',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: AppColors.danger),
              ),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true && context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    final theme = Theme.of(context);
    final t = context.theming;
    final selected = context.isShellRouteSelected(route);
    final color = selected ? AppColors.accent : t.textSecondary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: selected ? AppColors.accent : t.textPrimary,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.accentSoft,
      onTap: () {
        Navigator.pop(context);
        context.goShellRoute(route);
      },
    );
  }
}
