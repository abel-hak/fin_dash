import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/goals/widgets/create_goal_sheet.dart';
import 'package:sms_transaction_app/features/goals/widgets/edit_goal_sheet.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/services/providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.theming;
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final goalsAsync = ref.watch(goalsProvider);

    // Calculate summary stats
    final summaryStats = goalsAsync.when(
      data: (goals) {
        final activeCount = goals.where((g) => g.isActive).length;
        final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
        // Total still needed across all goals (target − saved, never negative).
        final remaining =
            goals.fold(0.0, (sum, g) => sum + (g.remaining > 0 ? g.remaining : 0));
        return {
          'active': activeCount,
          'totalSaved': totalSaved,
          'remaining': remaining,
        };
      },
      loading: () => {'active': 0, 'totalSaved': 0.0, 'remaining': 0.0},
      error: (_, __) => {'active': 0, 'totalSaved': 0.0, 'remaining': 0.0},
    );

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
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
                title: 'Savings Goals',
                subtitle: 'Track your progress towards financial goals',
              ),
            const SizedBox(height: AppSpacing.xxl),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.flag_outlined,
                    label: 'Active Goals',
                    value: '${summaryStats['active']}',
                    delta: 'In progress',
                    tone: StatTone.neutral,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatCard(
                    icon: Icons.savings_outlined,
                    label: 'Total Saved',
                    value: currencyFormat.format(summaryStats['totalSaved']),
                    delta: 'Across all goals',
                    tone: StatTone.positive,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Remaining',
                    value: currencyFormat.format(summaryStats['remaining']),
                    delta: 'To reach goals',
                    tone: StatTone.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Goal Cards - Real Data
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No goals yet',
                    message:
                        'Set a savings goal to track progress toward what matters.',
                    actionLabel: 'Create goal',
                    onAction: () => _openCreateSheet(context),
                  );
                }

                return Column(
                  children: goals.map((goal) {
                    final accentColor = goal.percentage >= 80
                        ? AppColors.success
                        : goal.percentage >= 50
                            ? AppColors.info
                            : AppColors.violet;

                    final icon = goal.iconName == 'shield'
                        ? Icons.shield
                        : goal.iconName == 'flight_takeoff'
                            ? Icons.flight_takeoff
                            : Icons.laptop_mac;

                    return Column(
                      children: [
                        _buildGoalCard(
                          context: context,
                          goal: goal,
                          icon: icon,
                          iconColor: accentColor,
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
                title: 'Error loading goals',
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGoalSheet(),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal created successfully!')),
      );
    }
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required Goal goal,
    required IconData icon,
    required Color iconColor,
    required WidgetRef ref,
  }) {
    final t = context.theming;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final deadline = DateFormat('MMM yyyy').format(goal.deadline);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      radius: AppRadii.l,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Target: ${currencyFormat.format(goal.targetAmount)} • $deadline',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${goal.percentageInt}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.s),
            child: LinearProgressIndicator(
              value: (goal.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: t.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(goal.currentAmount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyFormat.format(goal.targetAmount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Divider(height: 1, color: t.border),
          const SizedBox(height: AppSpacing.l),

          // Details Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      currencyFormat.format(goal.remaining),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      currencyFormat.format(goal.suggestedMonthlyContribution),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days Left',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${goal.daysLeft} days left',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await _showAddFundsDialog(
                    context,
                    goal.id,
                    goal.name,
                    goal.currentAmount,
                    goal.targetAmount,
                    ref,
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Funds'),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showEditGoalSheet(context, goal),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _showDeleteGoalDialog(
                          context,
                          goal.id,
                          goal.name,
                          ref,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFundsDialog(BuildContext context, String goalId, String goalName, double current, double target, WidgetRef ref) async {
    final amountController = TextEditingController();
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        final t = context.theming;
        return AlertDialog(
          title: Text('Add Funds to $goalName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${currencyFormat.format(current)}',
                style: TextStyle(color: t.textSecondary),
              ),
              Text(
                'Target: ${currencyFormat.format(target)}',
                style: TextStyle(color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to add',
                  prefixText: 'ETB ',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty) {
                  final amount = double.parse(amountController.text);
                  Navigator.pop(context);

                  // Update goal progress in database
                  final db = ref.read(databaseHelperProvider);
                  await db.updateGoalProgress(goalId, amount);

                  // Refresh provider
                  ref.invalidate(goalsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${currencyFormat.format(amount)} to $goalName!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Funds'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditGoalSheet(BuildContext context, Goal goal) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGoalSheet(goal: goal),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal updated successfully!')),
      );
    }
  }

  Future<void> _showDeleteGoalDialog(BuildContext context, String goalId, String goalName, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "$goalName"?\n\nAll progress will be lost. This action cannot be undone.'),
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
      await db.deleteGoal(goalId);

      // Refresh provider
      ref.invalidate(goalsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$goalName deleted successfully!'),
          ),
        );
      }
    }
  }
}
