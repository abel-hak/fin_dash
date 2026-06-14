import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.theming;
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final accountsAsync = ref.watch(accountsProvider);
    final transactionsAsync = ref.watch(parsedTransactionsProvider);

    final totalBalance = transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) return 0.0;
        final txWithBalance =
            transactions.where((tx) => tx.balance != null).toList();
        if (txWithBalance.isEmpty) return 0.0;
        return txWithBalance.first.balance ?? 0.0;
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
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
                title: 'Accounts',
                subtitle: 'Manage all of your financial accounts in one place',
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Accounts are automatically detected from SMS. No manual add needed!'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Account'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

            // Summary Cards - Real Data
            accountsAsync.when(
              data: (accounts) {
                final activeCount = accounts.length;
                final lastSync = accounts.isNotEmpty
                    ? _formatLastSync(accounts.first.lastSynced)
                    : 'Never';

                return Column(
                  children: [
                    StatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Total Balance',
                      value: currencyFormat.format(totalBalance),
                      delta: 'Across all accounts',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.check_circle,
                            label: 'Active Accounts',
                            value: '$activeCount',
                            delta: 'Currently connected',
                            tone: StatTone.positive,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: StatCard(
                            icon: Icons.sync,
                            label: 'Last Synced',
                            value: lastSync,
                            delta: 'Most recent',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, __) => AppErrorState(
                title: "Couldn't load accounts",
                message: '$error',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Account Cards - Real Data
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'No accounts yet',
                    message: 'Accounts are detected automatically from your transaction SMS.',
                  );
                }

                return Column(
                  children: accounts.map((account) {
                    // Calculate this month's activity from transactions
                    final monthActivity = transactionsAsync.when(
                      data: (txs) {
                        final now = DateTime.now();
                        final monthAgo = DateTime(now.year, now.month, 1);
                        final accountTxs = txs.where((tx) =>
                          tx.sender == account.sender &&
                          DateTime.parse(tx.occurredAt).isAfter(monthAgo)
                        ).toList();

                        final totalAmount = accountTxs.fold(0.0, (sum, tx) => sum + tx.amount);
                        return totalAmount > 0 ? '+${currencyFormat.format(totalAmount)}' : currencyFormat.format(0);
                      },
                      loading: () => '...',
                      error: (_, __) => 'N/A',
                    );

                    return Column(
                      children: [
                        _buildAccountCard(
                          context: context,
                          ref: ref,
                          bankName: account.name,
                          accountType: account.displayType,
                          accountSubtype: account.sender,
                          accountNumber: account.sender,
                          balance: account.balance,
                          lastSynced: DateFormat('MMM d, h:mm a').format(account.lastSynced),
                          thisMonth: monthActivity,
                          transactions: account.transactionCount,
                          isActive: true,
                        ),
                        const SizedBox(height: AppSpacing.l),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, __) => AppErrorState(
                title: "Couldn't load accounts",
                message: '$error',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Connect More Accounts Section
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadii.s),
                        ),
                        child: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          'Connect More Accounts',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Get a complete picture of your finances by connecting all your accounts. We support banks, mobile money, and more.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showConnectBankDialog(context),
                      child: const Text('Connect Bank Account'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showConnectMobileMoneyDialog(context),
                      child: const Text('Add Mobile Money'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showAddCashAccountDialog(context),
                      child: const Text('Add Cash Account'),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required BuildContext context,
    required WidgetRef ref,
    required String bankName,
    required String accountType,
    required String accountSubtype,
    required String accountNumber,
    required double balance,
    String? lastSynced,
    required String thisMonth,
    required int transactions,
    required bool isActive,
  }) {
    final t = context.theming;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                child: Icon(
                  accountType == 'Bank'
                      ? Icons.account_balance
                      : accountType == 'Mobile Money'
                          ? Icons.phone_android
                          : Icons.account_balance_wallet,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$accountType • $accountSubtype',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.16)
                      : t.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.success : t.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Container(height: 1, color: t.border),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      currencyFormat.format(balance),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      thisMonth,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
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
                      'Transactions',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$transactions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastSynced != null) ...[
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: t.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Last synced: $lastSynced',
                  style: theme.textTheme.labelSmall?.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.goShellRoute('/transactions'),
                  child: const Text('View Transactions'),
                ),
              ),
              TextButton.icon(
                onPressed: () => _syncAccount(context, ref, bankName),
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync'),
              ),
              TextButton(
                onPressed: () => _showAccountDetails(context, bankName, accountNumber, balance, transactions),
                style: TextButton.styleFrom(
                  foregroundColor: t.textSecondary,
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(lastSync);
    }
  }

  void _syncAccount(BuildContext context, WidgetRef ref, String bankName) {
    // Refresh transactions provider to sync
    ref.invalidate(parsedTransactionsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Syncing $bankName...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAccountDetails(BuildContext context, String bankName, String accountNumber, double balance, int transactions) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bankName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Account', accountNumber),
            const SizedBox(height: AppSpacing.m),
            _buildDetailRow(context, 'Balance', currencyFormat.format(balance)),
            const SizedBox(height: AppSpacing.m),
            _buildDetailRow(context, 'Transactions', '$transactions'),
            const SizedBox(height: AppSpacing.m),
            _buildDetailRow(context, 'Status', 'Active'),
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final t = context.theming;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Show connect bank dialog
  void _showConnectBankDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Bank Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to connect your bank account:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text('1. Enable SMS permissions in Settings'),
            const SizedBox(height: AppSpacing.s),
            const Text('2. Receive transaction SMS from your bank'),
            const SizedBox(height: AppSpacing.s),
            const Text('3. App automatically detects and adds your bank'),
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Supported: CBE, Telebirr, Awash Bank, M-PESA, and more!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to settings to enable SMS permissions
              context.go('/settings');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  // Show connect mobile money dialog
  void _showConnectMobileMoneyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to add mobile money accounts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text('1. Receive transaction SMS from mobile money provider'),
            const SizedBox(height: AppSpacing.s),
            const Text('2. App automatically detects transactions'),
            const SizedBox(height: AppSpacing.s),
            const Text('3. Account appears here automatically'),
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_android, color: AppColors.success, size: 20),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Supported: Telebirr, M-PESA, HelloCash, and more!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  // Show add cash account dialog
  void _showAddCashAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cash Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual cash account tracking:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text('Track your physical cash with manual entries.'),
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: const Row(
                children: [
                  Icon(Icons.construction, color: AppColors.warning, size: 20),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'This feature is coming soon! You\'ll be able to manually track cash transactions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
}
