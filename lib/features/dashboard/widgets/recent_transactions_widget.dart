import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_logic.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Recent transactions card for the dashboard — header + up to five rows,
/// rendered with the shared design-system primitives.
class RecentTransactionsWidget extends ConsumerWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(parsedTransactionsProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Transactions',
            actionLabel: 'See all',
            onAction: () => context.goShellRoute('/transactions'),
          ),
          transactions.when(
            data: (txList) {
              final recent = txList.take(5).toList();
              if (recent.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  child: Text('No transactions yet'),
                );
              }
              return Column(
                children: [
                  for (final tx in recent) _TransactionRow(tx: tx),
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
                  SkeletonBox(height: 44),
                  SizedBox(height: AppSpacing.m),
                  SkeletonBox(height: 44),
                  SizedBox(height: AppSpacing.m),
                  SkeletonBox(height: 44),
                ],
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final ParsedTransaction tx;

  @override
  Widget build(BuildContext context) {
    final income = DashboardData.isIncome(tx);
    final tone = income ? AppColors.success : AppColors.danger;
    final date = tx.occurredAt.contains('T')
        ? tx.occurredAt.split('T').first
        : tx.occurredAt;

    return AppTile(
      onTap: () => context.go('/review/${tx.id}'),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: Icon(
          income ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: tone,
          size: 20,
        ),
      ),
      title: Text(
        tx.merchant.isEmpty ? tx.sender : tx.merchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(date),
      trailing: AmountText(
        amount: tx.amount,
        currency: tx.currency.isEmpty ? 'ETB' : tx.currency,
        kind: income ? AmountKind.income : AmountKind.expense,
      ),
    );
  }
}
