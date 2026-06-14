import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshTransactions() {
    ref.invalidate(parsedTransactionsProvider);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(approvedTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;

    // Get transaction counts for dynamic tab labels
    final pendingTransactions = ref.watch(pendingTransactionsProvider);
    final approvedTransactions = ref.watch(approvedTransactionsProvider);

    final pendingCount =
        pendingTransactions.maybeWhen(data: (txs) => txs.length, orElse: () => 0);
    final approvedCount =
        approvedTransactions.maybeWhen(data: (txs) => txs.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/manual-entry'),
        icon: const Icon(Icons.add),
        label: const Text('Add SMS'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.l,
                AppSpacing.xl,
                0,
              ),
              child: ScreenHeader(
                title: 'Inbox',
                subtitle: 'Review and approve new SMS transactions',
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.accent,
              unselectedLabelColor: t.textSecondary,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Needs review ($pendingCount)'),
                Tab(text: 'Ready to sync ($approvedCount)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(TransactionStatus.pending),
                  _buildTransactionList(TransactionStatus.approved),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionStatus status) {
    final transactionsAsyncValue = status == TransactionStatus.pending
        ? ref.watch(pendingTransactionsProvider)
        : ref.watch(approvedTransactionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        _refreshTransactions();
        // Wait for the providers to refresh
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: AppSpacing.huge),
              AppEmptyState(
                icon: Icons.inbox_outlined,
                title: status == TransactionStatus.pending
                    ? 'Nothing to review'
                    : 'Nothing ready to sync',
                message: status == TransactionStatus.pending
                    ? 'New SMS transactions will appear here for you to approve.'
                    : 'Approved transactions waiting to sync will show here.',
                actionLabel: status == TransactionStatus.pending ? 'Add SMS' : null,
                onAction: status == TransactionStatus.pending
                    ? () => context.go('/manual-entry')
                    : null,
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              child: TransactionItem(
                transaction: transaction,
                onTap: () => context.go('/review/${transaction.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => ListView(
        children: [
          const SizedBox(height: AppSpacing.huge),
          AppErrorState(
            title: 'Error loading transactions',
            message: error.toString(),
          ),
        ],
      ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final ParsedTransaction transaction;
  final VoidCallback onTap;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');
    final dateTime = DateTime.parse(transaction.occurredAt);
    final formattedDate = dateFormat.format(dateTime);
    Color confidenceColor;
    if (transaction.confidence >= 0.9) {
      confidenceColor = AppColors.success;
    } else if (transaction.confidence >= 0.7) {
      confidenceColor = AppColors.warning;
    } else {
      confidenceColor = AppColors.danger;
    }

    final confidencePercentage = (transaction.confidence * 100).toInt();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant name and tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _InboxStatusChip(status: transaction.status),
                        const SizedBox(width: AppSpacing.s),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            transaction.channel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          transaction.sender,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    amount: transaction.amount,
                    currency: transaction.currency,
                    kind: AmountKind.neutral,
                  ),
                  if (transaction.balance != null)
                    Text(
                      'Balance: ${transaction.balance!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Date and confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Tap to review • $formattedDate',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Confidence indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: confidenceColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$confidencePercentage%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxStatusChip extends StatelessWidget {
  const _InboxStatusChip({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TransactionStatus.pending => ('Pending', AppColors.warning),
      TransactionStatus.approved => ('Approved', AppColors.info),
      TransactionStatus.synced => ('Synced', AppColors.success),
      TransactionStatus.ignored => ('Ignored', AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}
