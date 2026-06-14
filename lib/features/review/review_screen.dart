import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/domain/transaction_rules.dart';
import 'package:sms_transaction_app/features/shell/shell_navigation.dart';
import 'package:sms_transaction_app/services/providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const ReviewScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late ParsedTransaction _transaction;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;

  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _accountController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _reasonController.dispose();
    _dateTimeController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final databaseHelper = ref.read(databaseHelperProvider);
      final transaction = await databaseHelper.getTransactionById(widget.transactionId);

      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      _transaction = transaction;

      // Populate form fields
      _amountController.text = transaction.amount.toString();
      _merchantController.text = transaction.merchant;
      _reasonController.text = transaction.reason ?? '';

      final dateTime = DateTime.parse(transaction.occurredAt);
      _dateTimeController.text =
          DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);

      _accountController.text = transaction.accountAlias ?? '';
      _balanceController.text = transaction.balance?.toString() ?? '';
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load transaction: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTransaction() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      final newAmount =
          double.tryParse(_amountController.text) ?? _transaction.amount;
      final newMerchant = _merchantController.text;
      final newAccount =
          _accountController.text.isEmpty ? null : _accountController.text;

      // If the user edited any field that feeds the dedup fingerprint, the
      // stored fingerprint (computed from the original SMS) is now stale.
      // Recompute it with the SAME algorithm the parser uses so an identical
      // SMS re-arriving is still recognized as a duplicate, and so distinct
      // edits don't collide. Falls back to the original on any failure.
      var fingerprint = _transaction.fingerprint;
      final fingerprintInputsChanged = newAmount != _transaction.amount ||
          newMerchant != _transaction.merchant ||
          newAccount != _transaction.accountAlias;
      if (fingerprintInputsChanged) {
        final userId = await ref.read(authServiceProvider).getUserId();
        final occurredAt = DateTime.tryParse(_transaction.occurredAt);
        if (userId != null && occurredAt != null) {
          fingerprint = TransactionRules.fingerprint(
            userId: userId,
            amount: newAmount,
            timestamp: occurredAt,
            merchant: newMerchant,
            accountAlias: newAccount,
          );
        }
      }

      // Update transaction with edited values
      final updatedTransaction = _transaction.copyWith(
        amount: newAmount,
        merchant: newMerchant,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        accountAlias: newAccount,
        balance: double.tryParse(_balanceController.text),
        fingerprint: fingerprint,
        status: TransactionStatus.approved,
        transactionId: _transaction.transactionId,
        timestamp: _transaction.timestamp,
        recipient: _transaction.recipient,
      );

      // Update in database
      final databaseHelper = ref.read(databaseHelperProvider);
      await databaseHelper.updateParsedTransaction(updatedTransaction);
      // Invalidate the providers to refresh the UI
      ref.invalidate(pendingTransactionsProvider);
      ref.invalidate(approvedTransactionsProvider);
      ref.invalidate(parsedTransactionsProvider);
      ref.invalidate(syncedTransactionsProvider);

      // Try to sync to server, but don't fail if sync fails
      bool syncSuccess = false;
      String? syncError;
      try {
        final syncService = ref.read(syncServiceProvider);
        syncSuccess = await syncService.syncTransaction(updatedTransaction);
      } catch (syncE) {
        syncError = syncE.toString();
        AppLogger.sync('review approve sync failed: $syncError', isError: true);
      }

      // Show success message with sync status. On sync failure the transaction
      // is safely approved locally and the background SyncService will retry
      // automatically — we still surface a one-tap Retry for immediacy.
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        if (syncSuccess) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Transaction approved and synced successfully'),
          ));
        } else {
          messenger.showSnackBar(SnackBar(
            content: const Text(
              'Approved. Sync will retry automatically when you\'re online.',
            ),
            action: SnackBarAction(
              label: 'Retry now',
              onPressed: () =>
                  ref.read(syncServiceProvider).syncApprovedTransactions(),
            ),
          ));
        }

        // Navigate back to inbox
        context.goShellRoute('/inbox');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to approve transaction: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _ignoreTransaction() async {
    try {
      // Mark the parsed transaction as ignored. Previously this called
      // `deleteRawSmsEvent(_transaction.id)`, which targeted the wrong table
      // (parsed_tx ids are not raw_sms_event ids), leaving the parsed row
      // in place and silently corrupting the user's inbox.
      final databaseHelper = ref.read(databaseHelperProvider);
      await databaseHelper.markTransactionIgnored(_transaction.id);

      ref.invalidate(pendingTransactionsProvider);
      ref.invalidate(approvedTransactionsProvider);
      ref.invalidate(parsedTransactionsProvider);

      if (mounted) {
        context.goShellRoute('/inbox');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to ignore transaction: $e';
      });
    }
  }

  Future<void> _showDateTimePicker() async {
    final currentDate = DateTime.parse(_transaction.occurredAt);

    // Show date picker
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) return;

    // Show time picker
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );

    if (selectedTime == null) return;

    // Combine date and time
    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Update the controller and transaction
    setState(() {
      _dateTimeController.text = DateFormat('MM/dd/yyyy hh:mm a').format(newDateTime);
      _transaction = _transaction.copyWith(
        occurredAt: DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(newDateTime),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;

    return Scaffold(
      backgroundColor: AppColors.overlay,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadii.l),
              border: Border.all(color: t.border),
              boxShadow: AppShadows.card,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildReviewForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: AppErrorState(
        title: 'Something went wrong',
        message: _errorMessage,
        onRetry: () => context.goShellRoute('/inbox'),
        retryLabel: 'Back to Inbox',
      ),
    );
  }

  Widget _buildReviewForm() {
    final t = context.theming;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              Text(
                'Review Transaction',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.goShellRoute('/inbox'),
              ),
            ],
          ),
        ),
        Container(height: 1, color: t.border),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(AppRadii.s),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _transaction.sender,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          _transaction.channel.toLowerCase(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Confidence score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Score',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                            child: LinearProgressIndicator(
                              value: _transaction.confidence,
                              backgroundColor: t.border,
                              color: AppColors.success,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        ConfidenceBadge(
                          confidence: _transaction.confidence,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Amount field
                Text(
                  'Amount',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'ETB  ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Merchant field
                Text(
                  'Merchant / Description',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _merchantController,
                ),
                const SizedBox(height: AppSpacing.l),

                // Reason field
                Text(
                  'Reason / Purpose',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Internet Package, Fund Transfer, Bill Payment',
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Date & Time field
                Text(
                  'Date & Time',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    await _showDateTimePicker();
                  },
                ),
                const SizedBox(height: AppSpacing.l),

                // Account and Balance fields
                Row(
                  children: [
                    // Account field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          TextFormField(
                            controller: _accountController,
                            decoration: const InputDecoration(
                              hintText: '****1234',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),

                    // Balance field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          TextFormField(
                            controller: _balanceController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Approve button
              FilledButton.icon(
                onPressed: _isSyncing ? null : _approveTransaction,
                icon: _isSyncing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.textOnAccent),
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Approve & Sync'),
              ),
              const SizedBox(height: AppSpacing.m),

              // Ignore button
              OutlinedButton.icon(
                onPressed: _isSyncing ? null : _ignoreTransaction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.close),
                label: const Text('Ignore Transaction'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
