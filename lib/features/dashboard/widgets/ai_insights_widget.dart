import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_logic.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Insights card driven by the user's real budgets, goals, and spending
/// history (see [DashboardData.insights]). Token-driven so it inherits the dark
/// theme. Shows a neutral prompt when there isn't enough data yet.
class AiInsightsWidget extends ConsumerWidget {
  const AiInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
    final txs = ref.watch(parsedTransactionsProvider).valueOrNull ?? const [];

    final insights = DashboardData.insights(
      budgets: budgets,
      goals: goals,
      txs: txs,
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Insights'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: insights.isEmpty
                ? _EmptyInsight()
                : Column(
                    children: [
                      for (var i = 0; i < insights.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.l),
                        _InsightItem(insight: insights[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: const Icon(Icons.insights_rounded,
              color: AppColors.info, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No insights yet', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Add budgets and goals, and keep logging transactions — '
                'insights will appear here.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: t.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.insight});

  final DashboardInsight insight;

  Color get _color {
    switch (insight.tone) {
      case InsightTone.positive:
        return AppColors.accent;
      case InsightTone.warning:
        return AppColors.warning;
      case InsightTone.danger:
        return AppColors.danger;
      case InsightTone.neutral:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (insight.tone) {
      case InsightTone.positive:
        return Icons.trending_up_rounded;
      case InsightTone.warning:
        return Icons.lightbulb_outline_rounded;
      case InsightTone.danger:
        return Icons.warning_amber_rounded;
      case InsightTone.neutral:
        return Icons.insights_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: Icon(_icon, color: _color, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(insight.message, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
