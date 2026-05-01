import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Landing surface for the "More" tab. Acts as the index of secondary
/// destinations (Budgets, Goals, Accounts, Settings) plus profile / logout.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.theming;
    final user = ref.watch(userProvider);

    final email = user?.email ?? 'Signed in';
    final initial =
        (email.isNotEmpty ? email.characters.first.toUpperCase() : '?');

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          const SectionHeader(title: 'Money', padding: EdgeInsets.zero),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.savings_outlined,
                  title: 'Budgets',
                  subtitle: 'Track spending against monthly limits',
                  onTap: () => context.go('/budgets'),
                ),
                const _Divider(),
                _MoreTile(
                  icon: Icons.flag_outlined,
                  title: 'Goals',
                  subtitle: 'Save toward what matters',
                  onTap: () => context.go('/goals'),
                ),
                const _Divider(),
                _MoreTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Accounts',
                  subtitle: 'Banks and wallets connected by SMS',
                  onTap: () => context.go('/accounts'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.l),
          const SectionHeader(title: 'App', padding: EdgeInsets.zero),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Trusted senders, AI, sync',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          OutlinedButton.icon(
            onPressed: () async {
              final auth = ref.read(authServiceProvider);
              await auth.logout();
              if (!context.mounted) return;
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppTile(
      onTap: onTap,
      leading: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    return Container(height: 1, color: t.border);
  }
}
