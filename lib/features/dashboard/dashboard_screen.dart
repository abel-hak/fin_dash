import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_logic.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/accounts_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/ai_insights_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/budget_overview_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/recent_transactions_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/savings_goals_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/spending_breakdown_widget.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.theming;
    final transactionsAsync = ref.watch(parsedTransactionsProvider);

    final balance = transactionsAsync.maybeWhen(
      data: DashboardData.latestBalance,
      orElse: () => 0.0,
    );
    final history = transactionsAsync.maybeWhen(
      data: DashboardData.balanceHistory,
      orElse: () => const <double>[],
    );
    final totals = transactionsAsync.maybeWhen(
      data: (txs) => DashboardData.recentTotals(txs),
      orElse: () => (income: 0.0, expenses: 0.0),
    );
    final deltaLabel = transactionsAsync.maybeWhen(
      data: DashboardData.balanceDeltaLabel,
      orElse: () => null,
    );
    final money = NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(parsedTransactionsProvider);
            await ref.read(parsedTransactionsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.xxl,
            ),
            children: [
              const _DashboardHeader(),
              const SizedBox(height: AppSpacing.l),
              BalanceHero(
                label: 'Available Balance',
                amount: balance,
                currency: 'ETB',
                history: history,
                deltaLabel: deltaLabel,
                trailing: const _PeriodChip(label: 'This month'),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.south_west_rounded,
                      label: 'Income · 7d',
                      value: money.format(totals.income).trim(),
                      tone: StatTone.positive,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: StatCard(
                      icon: Icons.north_east_rounded,
                      label: 'Expenses · 7d',
                      value: money.format(totals.expenses).trim(),
                      tone: StatTone.negative,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const SpendingBreakdownWidget(),
              const SizedBox(height: AppSpacing.l),
              const RecentTransactionsWidget(),
              const SizedBox(height: AppSpacing.l),
              const AiInsightsWidget(),
              const SizedBox(height: AppSpacing.l),
              const BudgetOverviewWidget(),
              const SizedBox(height: AppSpacing.l),
              const SavingsGoalsWidget(),
              const SizedBox(height: AppSpacing.l),
              const AccountsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.theming;
    final user = ref.watch(userProvider);
    final name = (user?.email ?? 'there').split('@').first;
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Row(
      children: [
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
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
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: theme.textTheme.bodySmall),
              Text(
                'Hello, $name',
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.goShellRoute('/inbox'),
          icon: const Icon(Icons.notifications_none_rounded),
          style: IconButton.styleFrom(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              side: BorderSide(color: t.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.expand_more_rounded, size: 16, color: t.textSecondary),
        ],
      ),
    );
  }
}
