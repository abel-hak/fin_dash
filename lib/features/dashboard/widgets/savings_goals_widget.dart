import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/services/providers.dart';

class SavingsGoalsWidget extends ConsumerWidget {
  const SavingsGoalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    
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
            'Savings Goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return const Center(
                  child: Text(
                    'No goals yet. Create one!',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }
              
              // Show top 3 goals
              final topGoals = goals.take(3).toList();
              return Column(
                children: topGoals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final goal = entry.value;
                  
                  final color = goal.percentage >= 80 
                      ? Colors.green 
                      : goal.percentage >= 50 
                          ? Colors.cyan 
                          : Colors.purple;
                  
                  return Column(
                    children: [
                      if (index > 0) const SizedBox(height: 12),
                      _buildGoalItem(
                        title: goal.name,
                        progress: goal.percentage / 100,
                        color: color,
                      ),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Error loading goals', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required String title,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
