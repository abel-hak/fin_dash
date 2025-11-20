import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/services/providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'All';
  String? _selectedBank;
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Rebuild on search text change
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final transactions = ref.watch(parsedTransactionsProvider);
    
    // Get real balance from transactions
    final totalBalance = transactions.when(
      data: (txs) {
        if (txs.isEmpty) return 0.0;
        final txWithBalance = txs.where((tx) => tx.balance != null).toList();
        if (txWithBalance.isEmpty) return 0.0;
        return txWithBalance.first.balance ?? 0.0;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
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
            onPressed: () {},
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTransactionDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'View and manage all your financial transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Buttons and Actions
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Income'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Expenses'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showBankFilterDialog(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _showDateRangePicker(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _exportTransactions(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: transactions.when(
              data: (txList) {
                // Apply all filters
                var filteredTx = _applyFilters(txList);
                
                if (filteredTx.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group transactions by date
                final groupedTx = <String, List<dynamic>>{};
                for (var tx in filteredTx) {
                  final date = tx.occurredAt.split('T')[0];
                  if (!groupedTx.containsKey(date)) {
                    groupedTx[date] = [];
                  }
                  groupedTx[date]!.add(tx);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: groupedTx.length,
                  itemBuilder: (context, index) {
                    final date = groupedTx.keys.elementAt(index);
                    final dayTransactions = groupedTx[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 16, top: index == 0 ? 0 : 24),
                          child: Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: dayTransactions.asMap().entries.map((entry) {
                              final txIndex = entry.key;
                              final tx = entry.value;
                              return Column(
                                children: [
                                  _buildTransactionItem(tx, currencyFormat),
                                  if (txIndex < dayTransactions.length - 1)
                                    Divider(height: 1, color: Colors.grey.shade200),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.cyan,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildTransactionItem(dynamic tx, NumberFormat currencyFormat) {
    final isIncome = tx.merchant.toLowerCase().contains('salary');
    final category = _getCategory(tx.merchant, tx.reason);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tx.sender,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: category['color'],
                        ),
                      ),
                    ),
                    if (isIncome) ...[
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Recurring',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Amount
          Text(
            '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategory(String merchant, String? reason) {
    // Priority 1: Check reason field first (most accurate)
    if (reason != null && reason.isNotEmpty) {
      final lowerReason = reason.toLowerCase();
      
      // Transfer
      if (lowerReason.contains('transfer') || lowerReason.contains('fund transfer')) {
        return {'name': 'Transfer', 'icon': Icons.swap_horiz, 'color': Colors.indigo};
      }
      
      // Utilities (Internet, Bills, etc.)
      if (lowerReason.contains('internet') || lowerReason.contains('data') || 
          lowerReason.contains('package') || lowerReason.contains('electric') || 
          lowerReason.contains('bill payment')) {
        return {'name': 'Utilities', 'icon': Icons.flash_on, 'color': Colors.amber};
      }
      
      // Food & Dining
      if (lowerReason.contains('food') || lowerReason.contains('restaurant') || 
          lowerReason.contains('lunch') || lowerReason.contains('cafe') || 
          lowerReason.contains('coffee')) {
        return {'name': 'Food & Dining', 'icon': Icons.restaurant, 'color': Colors.orange};
      }
      
      // Transportation
      if (lowerReason.contains('ride') || lowerReason.contains('taxi') || 
          lowerReason.contains('transport') || lowerReason.contains('fuel')) {
        return {'name': 'Transportation', 'icon': Icons.directions_car, 'color': Colors.blue};
      }
      
      // Shopping
      if (lowerReason.contains('shop') || lowerReason.contains('purchase') || 
          lowerReason.contains('buy')) {
        return {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple};
      }
      
      // Entertainment
      if (lowerReason.contains('movie') || lowerReason.contains('entertainment') || 
          lowerReason.contains('game')) {
        return {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.teal};
      }
      
      // Healthcare
      if (lowerReason.contains('health') || lowerReason.contains('hospital') || 
          lowerReason.contains('pharmacy') || lowerReason.contains('doctor')) {
        return {'name': 'Healthcare', 'icon': Icons.local_hospital, 'color': Colors.red};
      }
    }
    
    // Priority 2: Fallback to merchant name
    final lowerMerchant = merchant.toLowerCase();
    
    if (lowerMerchant.contains('lunch') || lowerMerchant.contains('food') || lowerMerchant.contains('restaurant')) {
      return {'name': 'Food & Dining', 'icon': Icons.restaurant, 'color': Colors.orange};
    } else if (lowerMerchant.contains('ride') || lowerMerchant.contains('taxi') || lowerMerchant.contains('transport')) {
      return {'name': 'Transportation', 'icon': Icons.directions_car, 'color': Colors.blue};
    } else if (lowerMerchant.contains('salary') || lowerMerchant.contains('income')) {
      return {'name': 'Income', 'icon': Icons.arrow_downward, 'color': Colors.green};
    } else if (lowerMerchant.contains('electric') || lowerMerchant.contains('bill') || lowerMerchant.contains('utilities')) {
      return {'name': 'Utilities', 'icon': Icons.flash_on, 'color': Colors.amber};
    } else if (lowerMerchant.contains('shop') || lowerMerchant.contains('clothing') || lowerMerchant.contains('market')) {
      return {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple};
    } else if (lowerMerchant.contains('movie') || lowerMerchant.contains('entertainment') || lowerMerchant.contains('cinema')) {
      return {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.teal};
    } else {
      return {'name': 'Other', 'icon': Icons.receipt, 'color': Colors.grey};
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(date.year, date.month, date.day);

      if (txDate == today) {
        return 'Today';
      } else if (txDate == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('MMMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }
  
  // Apply all filters to transaction list
  List<dynamic> _applyFilters(List<dynamic> transactions) {
    var filtered = transactions;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((tx) {
        return tx.merchant.toLowerCase().contains(query) ||
               tx.sender.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply income/expense filter
    if (_selectedFilter == 'Income') {
      filtered = filtered.where((tx) {
        return tx.merchant.toLowerCase().contains('salary') ||
               tx.merchant.toLowerCase().contains('income') ||
               tx.merchant.toLowerCase().contains('deposit');
      }).toList();
    } else if (_selectedFilter == 'Expenses') {
      filtered = filtered.where((tx) {
        final merchant = tx.merchant.toLowerCase();
        return !merchant.contains('salary') &&
               !merchant.contains('income') &&
               !merchant.contains('deposit');
      }).toList();
    }
    
    // Apply bank filter
    if (_selectedBank != null) {
      filtered = filtered.where((tx) => tx.sender == _selectedBank).toList();
    }
    
    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered.where((tx) {
        try {
          final txDate = DateTime.parse(tx.occurredAt);
          return txDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                 txDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    return filtered;
  }
  
  // Show bank filter dialog
  void _showBankFilterDialog() async {
    final transactions = await ref.read(parsedTransactionsProvider.future);
    final banks = transactions.map((tx) => tx.sender).toSet().toList();
    banks.sort();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Banks'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedBank,
                onChanged: (value) {
                  setState(() => _selectedBank = value);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => _selectedBank = null);
                Navigator.pop(context);
              },
            ),
            ...banks.map((bank) => ListTile(
              title: Text(bank),
              leading: Radio<String?>(
                value: bank,
                groupValue: _selectedBank,
                onChanged: (value) {
                  setState(() => _selectedBank = value);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => _selectedBank = bank);
                Navigator.pop(context);
              },
            )),
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
  
  // Show date range picker
  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }
  
  // Export transactions
  void _exportTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon! Will export to CSV/Excel.'),
        backgroundColor: Colors.cyan,
      ),
    );
  }
  
  // Show add transaction dialog
  void _showAddTransactionDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual transaction entry coming soon!'),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}
