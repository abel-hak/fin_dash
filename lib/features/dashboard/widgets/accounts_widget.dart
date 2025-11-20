import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/services/providers.dart';

class AccountsWidget extends ConsumerWidget {
  const AccountsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(parsedTransactionsProvider);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Accounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/accounts'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          transactionsAsync.when(
            data: (transactions) {
              // Group transactions by sender to get unique accounts
              final accountMap = <String, double>{};
              for (var tx in transactions) {
                if (tx.balance != null) {
                  accountMap[tx.sender] = tx.balance!;
                }
              }
              
              if (accountMap.isEmpty) {
                return const Text(
                  'No accounts found',
                  style: TextStyle(color: Colors.black54),
                );
              }
              
              final accounts = accountMap.entries.take(3).toList();
              return Column(
                children: accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  return Column(
                    children: [
                      if (index > 0) const SizedBox(height: 12),
                      _buildAccountItem(
                        bank: account.key,
                        accountType: _getAccountType(account.key),
                        balance: account.value,
                      ),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading accounts'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required String bank,
    required String accountType,
    required double balance,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bank,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              accountType,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            Text(
              'ETB ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _getAccountType(String sender) {
    final lowerSender = sender.toLowerCase();
    if (lowerSender.contains('cbe') || lowerSender.contains('bank')) {
      return 'Bank';
    } else if (lowerSender.contains('telebirr') || lowerSender.contains('mpesa')) {
      return 'Mobile Money';
    } else {
      return 'Other';
    }
  }
}
