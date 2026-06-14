import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Standard in-body page header used across secondary screens (Activity,
/// Budgets, Goals, Accounts, Settings) so they match the dashboard look.
class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAvatarTap,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onAvatarTap;

  static String initialsFromEmail(String? email) {
    if (email == null || email.isEmpty) return '?';
    final name = email.split('@').first;
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.theming;
    final email = ref.watch(userProvider)?.email;
    final initials = initialsFromEmail(email);
    final scaffold = Scaffold.maybeOf(context);
    final canOpenDrawer = scaffold?.hasDrawer ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onAvatarTap ??
              (canOpenDrawer ? () => Scaffold.of(context).openDrawer() : null),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              initials,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: t.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.m),
          action!,
        ],
      ],
    );
  }
}
