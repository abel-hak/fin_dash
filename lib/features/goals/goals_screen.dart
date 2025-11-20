import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/goals/widgets/create_goal_sheet.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/services/providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final goalsAsync = ref.watch(goalsProvider);
    final transactionsAsync = ref.watch(parsedTransactionsProvider);
    
    // Get real balance from transactions
    final totalBalance = transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) return 0.0;
        final txWithBalance = transactions.where((tx) => tx.balance != null).toList();
        if (txWithBalance.isEmpty) return 0.0;
        return txWithBalance.first.balance ?? 0.0;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    
    // Calculate summary stats
    final summaryStats = goalsAsync.when(
      data: (goals) {
        final activeCount = goals.where((g) => g.isActive).length;
        final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
        final thisMonth = totalSaved * 0.15; // Estimate 15% saved this month
        return {'active': activeCount, 'totalSaved': totalSaved, 'thisMonth': thisMonth};
      },
      loading: () => {'active': 0, 'totalSaved': 0.0, 'thisMonth': 0.0},
      error: (_, __) => {'active': 0, 'totalSaved': 0.0, 'thisMonth': 0.0},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Balance',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            Text(
              currencyFormat.format(totalBalance),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () => context.go('/inbox'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.cyan,
              child: const Text('JD', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Goals',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your progress towards financial goals',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const CreateGoalSheet(),
                    );
                    
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Goal created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Goal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Cards - Real Data
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.flag,
                    iconColor: Colors.purple,
                    title: 'Active Goals',
                    value: '${summaryStats['active']}',
                    subtitle: 'In progress',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.savings,
                    iconColor: Colors.green,
                    title: 'Total Saved',
                    value: currencyFormat.format(summaryStats['totalSaved']),
                    subtitle: 'Across all goals',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                    title: 'This Month',
                    value: currencyFormat.format(summaryStats['thisMonth']),
                    subtitle: 'Contributions',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Goal Cards - Real Data
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No goals yet. Create your first savings goal!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: goals.map((goal) {
                    final iconColor = goal.percentage >= 80 
                        ? Colors.green 
                        : goal.percentage >= 50 
                            ? Colors.blue 
                            : Colors.purple;
                    
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
                          iconColor: iconColor,
                          ref: ref,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading goals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required Goal goal,
    required IconData icon,
    required Color iconColor,
    required WidgetRef ref,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final deadline = DateFormat('MMM yyyy').format(goal.deadline);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${currencyFormat.format(goal.targetAmount)} • $deadline',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: goal.percentage >= 80 ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goal.percentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: goal.percentage >= 80 ? Colors.green : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(goal.currentAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                currencyFormat.format(goal.targetAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Details Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(goal.remaining),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(goal.suggestedMonthlyContribution),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Days Left',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${goal.daysLeft} days left',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddFundsDialog(context, goal.id, goal.name, goal.currentAmount, goal.targetAmount, ref);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Funds'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _showEditGoalDialog(context, goal.name);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await _showDeleteGoalDialog(context, goal.id, goal.name, ref);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Delete'),
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
      builder: (context) => AlertDialog(
        title: Text('Add Funds to $goalName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${currencyFormat.format(current)}',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              'Target: ${currencyFormat.format(target)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to add',
                prefixText: 'ETB ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
            ),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }
  
  void _showEditGoalDialog(BuildContext context, String goalName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $goalName'),
        content: const Text('Edit goal feature will allow you to modify target amounts and deadlines.\n\n(Coming soon!)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
