import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/budgets/widgets/create_budget_sheet.dart';
import 'package:sms_transaction_app/features/budgets/widgets/edit_budget_sheet.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/services/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.theming;
    final budgetsAsync = ref.watch(budgetsProvider);

    // Calculate summary stats
    final summaryStats = budgetsAsync.when(
      data: (budgets) {
        final totalBudgets = budgets.length;
        final onTrack = budgets.where((b) => b.status == 'On Track').length;
        final needsAttention = budgets.where((b) => b.status != 'On Track').length;
        return {'total': totalBudgets, 'onTrack': onTrack, 'needsAttention': needsAttention};
      },
      loading: () => {'total': 0, 'onTrack': 0, 'needsAttention': 0},
      error: (_, __) => {'total': 0, 'onTrack': 0, 'needsAttention': 0},
    );

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.l,
            AppSpacing.xl,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ScreenHeader(
                title: 'Budgets',
                subtitle: 'Track and manage your spending limits',
              ),
              const SizedBox(height: AppSpacing.xxl),

            // Summary Cards - Real Data
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.pie_chart,
                    label: 'Total Budgets',
                    value: '${summaryStats['total']}',
                    delta: 'Active this month',
                    tone: StatTone.neutral,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle,
                    label: 'On Track',
                    value: '${summaryStats['onTrack']}',
                    delta: 'Under threshold',
                    tone: StatTone.positive,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatCard(
                    icon: Icons.warning,
                    label: 'Needs Attention',
                    value: '${summaryStats['needsAttention']}',
                    delta: 'Over threshold',
                    tone: StatTone.negative,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Budget Cards - Real Data
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No budgets yet',
                    message:
                        'Create a budget to track spending against monthly limits.',
                    actionLabel: 'Create budget',
                    onAction: () => _openCreateSheet(context),
                  );
                }

                return Column(
                  children: budgets.map((budget) {
                    final color = budget.isOverBudget
                        ? AppColors.danger
                        : budget.isNearLimit
                            ? AppColors.warning
                            : AppColors.accent;

                    return Column(
                      children: [
                        _buildBudgetCard(
                          context: context,
                          budget: budget,
                          color: color,
                          ref: ref,
                        ),
                        const SizedBox(height: AppSpacing.l),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const AppErrorState(
                title: 'Error loading budgets',
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateBudgetSheet(),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget created successfully!'),
        ),
      );
    }
  }

  Widget _buildBudgetCard({
    required BuildContext context,
    required Budget budget,
    required Color color,
    required WidgetRef ref,
  }) {
    final theme = Theme.of(context);
    final t = context.theming;
    final percentage = budget.percentageInt;
    final progress = budget.percentage / 100;
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final onTrack = budget.status == 'On Track';
    final statusColor = onTrack ? AppColors.success : AppColors.warning;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      radius: AppRadii.l,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Monthly Budget',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  budget.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Progress Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${currencyFormat.format(budget.spent)} / ${currencyFormat.format(budget.limit)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: t.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '$percentage% used • ${budget.daysLeft} days left',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.l),
          Divider(height: 1, color: t.border),
          const SizedBox(height: AppSpacing.l),

          // Details Section
          Row(
            children: [
              Expanded(
                child: _buildDetailColumn(
                  context,
                  'Remaining',
                  currencyFormat.format(budget.remaining),
                ),
              ),
              Expanded(
                child: _buildDetailColumn(
                  context,
                  'Daily Average',
                  currencyFormat.format(budget.dailyAverage),
                ),
              ),
              Expanded(
                child: _buildDetailColumn(
                  context,
                  'Projected Total',
                  currencyFormat.format(budget.projectedTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _showBudgetDetailsDialog(context, budget);
                  },
                  child: const Text('View Details'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _showEditBudgetDialog(context, budget, ref);
                },
                style: TextButton.styleFrom(
                  foregroundColor: t.textSecondary,
                ),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () async {
                  await _showDeleteBudgetDialog(context, budget, ref);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  void _showBudgetDetailsDialog(BuildContext context, Budget budget) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', budget.status),
            _buildDetailRow('Spent', currencyFormat.format(budget.spent)),
            _buildDetailRow('Budget', currencyFormat.format(budget.limit)),
            _buildDetailRow('Remaining', currencyFormat.format(budget.remaining)),
            _buildDetailRow('Progress', '${budget.percentageInt}%'),
            _buildDetailRow('Time Left', '${budget.daysLeft} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _showEditBudgetDialog(BuildContext context, Budget budget, WidgetRef ref) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBudgetSheet(budget: budget),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget updated successfully!'),
        ),
      );
    }
  }

  Future<void> _showDeleteBudgetDialog(BuildContext context, Budget budget, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Delete from database
      final db = ref.read(databaseHelperProvider);
      await db.deleteBudget(budget.id);

      // Refresh provider
      ref.invalidate(budgetsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${budget.name} deleted successfully!'),
          ),
        );
      }
    }
  }
}
