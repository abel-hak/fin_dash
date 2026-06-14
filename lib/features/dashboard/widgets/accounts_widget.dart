import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Accounts card — unique senders with their latest known balance.
class AccountsWidget extends ConsumerWidget {
  const AccountsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(parsedTransactionsProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Accounts',
            actionLabel: 'See all',
            onAction: () => context.goShellRoute('/accounts'),
          ),
          transactionsAsync.when(
            data: (transactions) {
              final accountMap = <String, double>{};
              for (final tx in transactions) {
                if (tx.balance != null) {
                  accountMap.putIfAbsent(tx.sender, () => tx.balance!);
                }
              }
              if (accountMap.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  child: Text(
                    'No accounts found yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final accounts = accountMap.entries.take(3).toList();
              return Column(
                children: [
                  for (final account in accounts)
                    _AccountRow(
                      sender: account.key,
                      balance: account.value,
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.l,
              ),
              child: Column(
                children: [
                  SkeletonBox(height: 40),
                  SizedBox(height: AppSpacing.m),
                  SkeletonBox(height: 40),
                ],
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Text(
                'Error loading accounts',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.sender, required this.balance});

  final String sender;
  final double balance;

  String get _type {
    final s = sender.toLowerCase();
    if (s.contains('cbe') || s.contains('bank')) return 'Bank';
    if (s.contains('telebirr') || s.contains('mpesa')) return 'Mobile Money';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    return AppTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: const Icon(
          Icons.account_balance_rounded,
          color: AppColors.accent,
          size: 20,
        ),
      ),
      title: Text(
        sender,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_type),
      trailing: AmountText(
        amount: balance,
        currency: 'ETB',
        kind: AmountKind.neutral,
      ),
    );
  }
}
