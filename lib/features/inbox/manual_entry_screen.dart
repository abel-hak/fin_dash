import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/services/providers.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _senderSuggestions = [
    'Telebirr',
    'CBE',
    'Awash Bank',
    'Bank of Abyssinia',
  ];

  @override
  void dispose() {
    _senderController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _processSms() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final smsService = ref.read(smsServiceProvider);
      final success = await smsService.manuallyParseSms(
        sender: _senderController.text,
        body: _bodyController.text,
        timestamp: DateTime.now(),
      );

      if (success) {
        // Invalidate the providers to refresh the UI
        ref.invalidate(pendingTransactionsProvider);
        ref.invalidate(approvedTransactionsProvider);
        ref.invalidate(parsedTransactionsProvider);
        ref.invalidate(syncedTransactionsProvider);

        setState(() {
          _successMessage = 'SMS processed successfully!';
          _bodyController.clear();
        });
      } else {
        setState(() {
          _errorMessage =
              'Could not parse transaction from SMS. Please check the format.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing SMS: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        title: const Text('Paste SMS'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inbox'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              AppCard(
                color: AppColors.infoSoft,
                borderColor: AppColors.info.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          'Manual SMS Entry',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Copy and paste the full SMS from your bank or mobile money provider. '
                      'We\'ll try to extract the transaction details automatically.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Sender field
              Text(
                'SMS Sender',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.s),
              DropdownButtonFormField<String>(
                value: _senderController.text.isEmpty
                    ? null
                    : _senderController.text,
                decoration: const InputDecoration(
                  hintText: 'Select or enter sender',
                ),
                items: _senderSuggestions.map((sender) {
                  return DropdownMenuItem<String>(
                    value: sender,
                    child: Text(sender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _senderController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select or enter a sender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // SMS Body field
              Text(
                'SMS Body',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _bodyController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste the full SMS message here...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the SMS body';
                  }
                  if (value.length < 20) {
                    return 'SMS seems too short. Please paste the full message.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadii.s),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadii.s),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.xxl),

              // Process button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _processSms,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.textOnAccent),
                          ),
                        )
                      : const Text('Process SMS'),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // View Transactions button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/inbox'),
                  child: const Text('View Transactions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
