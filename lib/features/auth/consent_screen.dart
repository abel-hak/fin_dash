import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/services/permissions_service.dart';
import 'package:sms_transaction_app/services/preferences_service.dart';
import 'package:sms_transaction_app/services/providers.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isLoading = false;
  
  // Toggle values for trusted senders
  bool _telebirrEnabled = true;
  bool _cbeEnabled = true;
  bool _awashEnabled = false;
  bool _bankOfAbyssiniaEnabled = false;

  Future<void> _requestSmsPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissionsService = ref.read(permissionsServiceProvider);
      final granted = await permissionsService.requestSmsPermission();

      if (granted) {
        // Save trusted senders to preferences
        final preferencesService = ref.read(preferencesServiceProvider);
        final trustedSenders = <String>[];
        
        if (_telebirrEnabled) trustedSenders.add('Telebirr');
        if (_cbeEnabled) trustedSenders.add('CBE');
        if (_awashEnabled) trustedSenders.add('Awash Bank');
        if (_bankOfAbyssiniaEnabled) trustedSenders.add('Bank of Abyssinia');
        
        await preferencesService.saveTrustedSenders(trustedSenders);

        // Navigate to inbox screen
        if (mounted) {
          context.go('/inbox');
        }
      } else {
        // Show error dialog if permission is denied
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'SMS permission is required for this app to function. '
          'Please grant the permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF0277BD),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SMS Permissions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We need access to read SMS from your bank and mobile money providers to automatically track your transactions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Why we need SMS access section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why we need SMS access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                      'To extract your transaction details from trusted banks',
                      Icons.account_balance,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint(
                      'To identify payment amount, recipient, and balances',
                      Icons.receipt_long,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint(
                      'We approve each transaction before it is saved',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Privacy protection section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your privacy is protected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                      'All SMS processing happens right on your device',
                      Icons.phone_android,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint(
                      'Only approved, structured transaction data is stored',
                      Icons.lock,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint(
                      'We only read messages from the senders you enable below',
                      Icons.message,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Trusted Senders section
              const Text(
                'Trusted Senders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Telebirr toggle
              _buildSenderToggle('Telebirr', _telebirrEnabled, (value) {
                setState(() {
                  _telebirrEnabled = value;
                });
              }),
              const Divider(),
              
              // CBE toggle
              _buildSenderToggle('CBE', _cbeEnabled, (value) {
                setState(() {
                  _cbeEnabled = value;
                });
              }),
              const Divider(),
              
              // Awash Bank toggle
              _buildSenderToggle('Awash Bank', _awashEnabled, (value) {
                setState(() {
                  _awashEnabled = value;
                });
              }),
              const Divider(),
              
              // Bank of Abyssinia toggle
              _buildSenderToggle('Bank of Abyssinia', _bankOfAbyssiniaEnabled, (value) {
                setState(() {
                  _bankOfAbyssiniaEnabled = value;
                });
              }),
              const SizedBox(height: 32),
              
              // Enable SMS Access button
              ElevatedButton(
                onPressed: _isLoading ? null : _requestSmsPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enable SMS Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Use Manual Import button
              Center(
                child: TextButton(
                  onPressed: () => context.go('/inbox'),
                  child: const Text(
                    'Use Manual Import Instead',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Footer note
              const Center(
                child: Text(
                  'You can change these permissions anytime in Settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text, IconData icon, {Color color = const Color(0xFF0277BD)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSenderToggle(String name, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0277BD),
          ),
        ],
      ),
    );
  }
}
