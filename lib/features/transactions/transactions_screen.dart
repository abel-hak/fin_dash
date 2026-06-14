import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/domain/transaction_rules.dart';
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
    final t = context.theming;
    final transactions = ref.watch(parsedTransactionsProvider);
    final currencyFormat =
        NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: t.canvas,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.l,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    title: 'Activity',
                    subtitle:
                        'Your transaction history — approved and synced only',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Filter Buttons and Actions
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: AppSpacing.s),
                            _buildFilterChip('Income'),
                            const SizedBox(width: AppSpacing.s),
                            _buildFilterChip('Expenses'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _buildActionButton(
                      icon: Icons.filter_list,
                      onPressed: () => _showBankFilterDialog(),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _buildActionButton(
                      icon: Icons.date_range,
                      onPressed: () => _showDateRangePicker(),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _buildActionButton(
                      icon: Icons.download,
                      onPressed: () => _exportTransactions(),
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
                    child: AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No activity yet',
                      message:
                          'Approved and synced transactions show up here. '
                          'New SMS messages appear in Inbox first.',
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
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: groupedTx.length,
                  itemBuilder: (context, index) {
                    final date = groupedTx.keys.elementAt(index);
                    final dayTransactions = groupedTx[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: AppSpacing.l,
                            top: index == 0 ? 0 : AppSpacing.xxl,
                          ),
                          child: Text(
                            _formatDate(date),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: t.textSecondary,
                                ),
                          ),
                        ),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: dayTransactions.asMap().entries.map((entry) {
                              final txIndex = entry.key;
                              final tx = entry.value;
                              return Column(
                                children: [
                                  _buildTransactionItem(tx, currencyFormat),
                                  if (txIndex < dayTransactions.length - 1)
                                    Container(height: 1, color: t.border),
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
                child: AppErrorState(
                  title: 'Something went wrong',
                  message: '$error',
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final t = context.theming;
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: t.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          side: BorderSide(color: t.border),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(ParsedTransaction tx, NumberFormat currencyFormat) {
    final t = context.theming;
    final isIncome = TransactionRules.isIncomeMerchant(tx.merchant);
    final tone = isIncome ? AppColors.success : AppColors.danger;
    final category = _getCategory(tx.merchant, tx.reason);
    final Color categoryColor = category['color'] as Color;
    final statusLabel = tx.status == TransactionStatus.synced ? 'Synced' : 'Approved';
    final statusColor =
        tx.status == TransactionStatus.synced ? AppColors.success : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tx.sender,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.textSecondary),
                    ),
                    Text(
                      '•',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        category['name'],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                      ),
                    ),
                    Text(
                      '•',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                      ),
                    ),
                    if (isIncome) ...[
                      Text(
                        '•',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: t.textMuted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                        ),
                        child: Text(
                          'Recurring',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.info,
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
          AmountText(
            amount: tx.amount,
            currency: 'ETB',
            kind: isIncome ? AmountKind.income : AmountKind.expense,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  /// Resolves a transaction's display category. Category *naming* lives in the
  /// shared `Budget.getCategoryFromMerchant` rules (also used by the dashboard
  /// and budgets), and the icon/color come from `CategoryVisuals`, so this
  /// screen no longer carries its own divergent copy of the mapping.
  Map<String, dynamic> _getCategory(String merchant, String? reason) {
    final name = TransactionRules.isIncomeMerchant(merchant)
        ? 'Income'
        : Budget.getCategoryFromMerchant(merchant, reason: reason);
    final visual = CategoryVisuals.forName(name);
    return {'name': name, 'icon': visual.icon, 'color': visual.color};
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
    // Activity is the ledger — exclude items still in the inbox workflow.
    var filtered = transactions
        .where((tx) =>
            tx.status == TransactionStatus.approved ||
            tx.status == TransactionStatus.synced)
        .toList();
    
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
      filtered =
          filtered.where((tx) => TransactionRules.isIncomeMerchant(tx.merchant)).toList();
    } else if (_selectedFilter == 'Expenses') {
      filtered = filtered
          .where((tx) => !TransactionRules.isIncomeMerchant(tx.merchant))
          .toList();
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
  
  // Export the currently-filtered transactions to CSV via the share sheet.
  Future<void> _exportTransactions() async {
    final txAsync = ref.read(parsedTransactionsProvider);
    final all = txAsync.valueOrNull;
    if (all == null) return;

    final filtered = _applyFilters(all).cast<ParsedTransaction>();
    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    final ok =
        await ref.read(exportServiceProvider).shareTransactionsCsv(filtered);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export failed. Please try again.')),
    );
  }

  // Show add transaction dialog
  void _showAddTransactionDialog() {
    context.go('/manual-entry');
  }
}
