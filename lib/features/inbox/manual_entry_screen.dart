import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/services/sms_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste SMS'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inbox'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manual SMS Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Copy and paste the full SMS from your bank or mobile money provider. '
                      'We\'ll try to extract the transaction details automatically.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sender field
              const Text(
                'SMS Sender',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _senderController.text.isEmpty
                    ? null
                    : _senderController.text,
                decoration: InputDecoration(
                  hintText: 'Select or enter sender',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
              const SizedBox(height: 16),

              // SMS Body field
              const Text(
                'SMS Body',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste the full SMS message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(16),
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
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Process button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processSms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Process SMS'),
                ),
              ),
              const SizedBox(height: 16),

              // View Transactions button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/inbox'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0277BD),
                    side: const BorderSide(color: Color(0xFF0277BD)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
