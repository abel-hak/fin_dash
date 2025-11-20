import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/balance_card.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/recent_transactions_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/ai_insights_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/budget_overview_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/savings_goals_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/accounts_widget.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/services/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final transactionsAsync = ref.watch(parsedTransactionsProvider);
    
    // Calculate real balance and stats from transactions
    final totalBalance = transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) return 0.0;
        // Get the most recent balance from transactions
        final txWithBalance = transactions.where((tx) => tx.balance != null).toList();
        if (txWithBalance.isEmpty) return 0.0;
        return txWithBalance.first.balance ?? 0.0;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    
    // Calculate this week's income and expenses
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final weekStats = transactionsAsync.when(
      data: (transactions) {
        double income = 0.0;
        double expenses = 0.0;
        
        for (var tx in transactions) {
          try {
            final txDate = DateTime.parse(tx.occurredAt);
            if (txDate.isAfter(weekAgo)) {
              // Simple heuristic: if merchant contains salary/income, it's income
              if (tx.merchant.toLowerCase().contains('salary') ||
                  tx.merchant.toLowerCase().contains('income') ||
                  tx.merchant.toLowerCase().contains('deposit')) {
                income += tx.amount;
              } else {
                expenses += tx.amount;
              }
            }
          } catch (e) {
            // Skip invalid dates
          }
        }
        
        return {'income': income, 'expenses': expenses};
      },
      loading: () => {'income': 0.0, 'expenses': 0.0},
      error: (_, __) => {'income': 0.0, 'expenses': 0.0},
    );
    
    final weekIncome = weekStats['income'] as double;
    final weekExpenses = weekStats['expenses'] as double;
    
    // Calculate percentage changes (mock for now, would need historical data)
    final balanceChange = totalBalance > 0 ? '+2.4% from last month' : 'No data';
    final incomeChange = weekIncome > 0 ? '+2% vs last' : 'No data';
    final expenseChange = weekExpenses > 0 ? '+12% last 7 days' : 'No data';
    
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
              'FinanceDash',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currencyFormat.format(totalBalance),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.normal,
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
            // Welcome Section
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s what\'s happening with your finances today.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Balance Cards - Real Data
            BalanceCard(
              title: 'All Accounts',
              amount: totalBalance,
              change: balanceChange,
              isPositive: true,
              isPrimary: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BalanceCard(
                    title: 'This Week',
                    subtitle: 'Income',
                    amount: weekIncome,
                    change: incomeChange,
                    isPositive: true,
                    isPrimary: false,
                    color: Colors.green.shade50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BalanceCard(
                    title: 'This Week',
                    subtitle: 'Expenses',
                    amount: weekExpenses,
                    change: expenseChange,
                    isPositive: false,
                    isPrimary: false,
                    color: Colors.red.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            const RecentTransactionsWidget(),
            const SizedBox(height: 16),

            // AI Insights
            AiInsightsWidget(),
            const SizedBox(height: 16),

            // Budget Overview
            const BudgetOverviewWidget(),
            const SizedBox(height: 16),

            // Savings Goals
            SavingsGoalsWidget(),
            const SizedBox(height: 16),

            // Accounts
            AccountsWidget(),
          ],
        ),
      ),
    );
  }
}
