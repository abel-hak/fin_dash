import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/services/providers.dart';

class BudgetOverviewWidget extends ConsumerWidget {
  const BudgetOverviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    
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
          const Text(
            'Budget Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) {
                return const Center(
                  child: Text(
                    'No budgets yet. Create one!',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }
              
              // Show top 3 budgets
              final topBudgets = budgets.take(3).toList();
              return Column(
                children: topBudgets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final budget = entry.value;
                  
                  final color = budget.isOverBudget 
                      ? Colors.red 
                      : budget.isNearLimit 
                          ? Colors.orange 
                          : Colors.cyan;
                  
                  return Column(
                    children: [
                      if (index > 0) const SizedBox(height: 16),
                      _buildBudgetItem(
                        title: budget.name,
                        spent: budget.spent,
                        total: budget.limit,
                        color: color,
                      ),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Error loading budgets', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem({
    required String title,
    required double spent,
    required double total,
    required Color color,
  }) {
    final percentage = (spent / total * 100).toInt();
    final progress = spent / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'ETB ${spent.toStringAsFixed(0)} / ETB ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage% used',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
