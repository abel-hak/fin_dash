import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Savings goals card — top three goals with token-driven progress bars.
class SavingsGoalsWidget extends ConsumerWidget {
  const SavingsGoalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Savings Goals',
            actionLabel: 'See all',
            onAction: () => context.goShellRoute('/goals'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return Text(
                    'No goals yet. Create one to start saving.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final top = goals.take(3).toList();
                return Column(
                  children: [
                    for (var i = 0; i < top.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.m),
                      _GoalRow(goal: top[i]),
                    ],
                  ],
                );
              },
              loading: () => const Column(
                children: [
                  SkeletonBox(height: 32),
                  SizedBox(height: AppSpacing.m),
                  SkeletonBox(height: 32),
                ],
              ),
              error: (_, __) => Text(
                'Error loading goals',
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

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    final color = goal.percentage >= 80
        ? AppColors.accent
        : goal.percentage >= 50
            ? AppColors.info
            : AppColors.violet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.name,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: LinearProgressIndicator(
                  value: (goal.percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: t.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              '${goal.percentageInt}%',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}
