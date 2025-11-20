import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/services/sync_service.dart';

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
      // Update transaction with edited values
      final updatedTransaction = _transaction.copyWith(
        amount: double.tryParse(_amountController.text) ?? _transaction.amount,
        merchant: _merchantController.text,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        accountAlias:
            _accountController.text.isEmpty ? null : _accountController.text,
        balance: double.tryParse(_balanceController.text),
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
        print('Sync error: $syncError');
      }

      // Show success message with sync status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(syncSuccess
                ? 'Transaction approved and synced successfully'
                : 'Transaction approved locally but sync failed${syncError != null ? ': $syncError' : ''}')));

        // Navigate back to inbox
        context.go('/inbox');
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
      // Delete the transaction
      final databaseHelper = ref.read(databaseHelperProvider);
      await databaseHelper.deleteRawSmsEvent(_transaction.id);

      // Navigate back to inbox
      if (mounted) {
        context.go('/inbox');
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/inbox'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0277BD),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Back to Inbox'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Review Transaction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/inbox'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _transaction.sender,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _transaction.channel.toLowerCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Confidence score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confidence Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _transaction.confidence,
                              backgroundColor: Colors.grey[200],
                              color: Colors.green,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_transaction.confidence * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount field
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'ETB  ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Merchant field
                const Text(
                  'Merchant / Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason field
                const Text(
                  'Reason / Purpose',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    hintText: 'e.g., Internet Package, Fund Transfer, Bill Payment',
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time field
                const Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    await _showDateTimePicker();
                  },
                ),
                const SizedBox(height: 16),

                // Account and Balance fields
                Row(
                  children: [
                    // Account field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _accountController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              hintText: '****1234',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Balance field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _balanceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Approve button
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _approveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSyncing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Approve & Sync'),
              ),
              const SizedBox(height: 12),

              // Ignore button
              OutlinedButton.icon(
                onPressed: _isSyncing ? null : _ignoreTransaction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
