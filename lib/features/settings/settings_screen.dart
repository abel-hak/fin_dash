import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/services/auth_service.dart';
import 'package:sms_transaction_app/services/permissions_service.dart';
import 'package:sms_transaction_app/services/preferences_service.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'test_sms_screen.dart';
import 'receipt_scraper_test_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  bool _deleteRawSms = false;
  bool _diagnosticsEnabled = true;
  bool _hasSmsPermission = false;
  Map<String, bool> _autoApproveSettings = {};
  List<String> _trustedSenders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferencesService = ref.read(preferencesServiceProvider);
      final permissionsService = ref.read(permissionsServiceProvider);

      // Load settings
      _deleteRawSms = await preferencesService.getDeleteRawSetting();
      _diagnosticsEnabled = await preferencesService.getDiagnosticsEnabled();
      _hasSmsPermission = await permissionsService.checkSmsPermission();
      _autoApproveSettings = await preferencesService.getAutoApproveSettings();
      _trustedSenders = await preferencesService.getTrustedSenders();

      // If no trusted senders are set, use defaults
      if (_trustedSenders.isEmpty) {
        _trustedSenders = [
          'Telebirr',
          'CBE',
          'Awash Bank',
          'Bank of Abyssinia'
        ];
      }

      // Ensure all trusted senders have auto-approve settings
      for (final sender in _trustedSenders) {
        if (!_autoApproveSettings.containsKey(sender)) {
          _autoApproveSettings[sender] = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAutoApproveSettings(String sender, bool value) async {
    try {
      final preferencesService = ref.read(preferencesServiceProvider);
      await preferencesService.saveAutoApproveSetting(sender, value);

      setState(() {
        _autoApproveSettings[sender] = value;
      });
    } catch (e) {
      debugPrint('Error saving auto-approve setting: $e');
    }
  }

  Future<void> _saveDeleteRawSetting(bool value) async {
    try {
      final preferencesService = ref.read(preferencesServiceProvider);
      await preferencesService.saveDeleteRawSetting(value);

      setState(() {
        _deleteRawSms = value;
      });
    } catch (e) {
      debugPrint('Error saving delete raw setting: $e');
    }
  }

  Future<void> _saveDiagnosticsEnabled(bool value) async {
    try {
      final preferencesService = ref.read(preferencesServiceProvider);
      await preferencesService.saveDiagnosticsEnabled(value);

      setState(() {
        _diagnosticsEnabled = value;
      });
    } catch (e) {
      debugPrint('Error saving diagnostics setting: $e');
    }
  }

  Future<void> _requestSmsPermission() async {
    try {
      final permissionsService = ref.read(permissionsServiceProvider);
      final granted = await permissionsService.requestSmsPermission();

      setState(() {
        _hasSmsPermission = granted;
      });

      if (!granted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'SMS permission is required for automatic transaction detection. '
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

  Future<void> _exportData() async {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export not implemented yet'),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final transactionsAsync = ref.watch(parsedTransactionsProvider);
    
    // Get real balance from transactions
    final totalBalance = transactionsAsync.when(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your app preferences and account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // SMS Permissions Card
                  _buildCard(
                    title: 'SMS Permissions',
                    icon: Icons.sms,
                    iconColor: Colors.blue,
                    children: [
                      _buildSwitchTile(
                        title: 'SMS Access',
                        subtitle: _hasSmsPermission
                            ? 'Enabled - automatic transaction detection'
                            : 'Disabled - manual entry only',
                        value: _hasSmsPermission,
                        onChanged: (value) {
                          if (value) {
                            _requestSmsPermission();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Trusted Senders Card
                  _buildCard(
                    title: 'Trusted Senders',
                    icon: Icons.verified_user,
                    iconColor: Colors.green,
                    children: _trustedSenders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sender = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          _buildSwitchTile(
                            title: sender,
                            subtitle: _autoApproveSettings[sender] ?? false
                                ? 'Auto-approve: ON'
                                : 'Auto-approve: OFF',
                            value: _autoApproveSettings[sender] ?? false,
                            onChanged: (value) => _saveAutoApproveSettings(sender, value),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Privacy & Data Card
                  _buildCard(
                    title: 'Privacy & Data',
                    icon: Icons.privacy_tip,
                    iconColor: Colors.purple,
                    children: [
                      _buildSwitchTile(
                        title: 'Delete Raw SMS After Processing',
                        subtitle: 'Remove original SMS messages after they are parsed',
                        value: _deleteRawSms,
                        onChanged: _saveDeleteRawSetting,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Send Anonymous Diagnostics',
                        subtitle: 'Help us improve parsing accuracy',
                        value: _diagnosticsEnabled,
                        onChanged: _saveDiagnosticsEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data Management Card
                  _buildCard(
                    title: 'Data Management',
                    icon: Icons.storage,
                    iconColor: Colors.orange,
                    children: [
                      _buildActionTile(
                        title: 'Test SMS Parser',
                        subtitle: 'Test SMS parsing with sample messages',
                        icon: Icons.bug_report,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TestSmsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Test Receipt Scraper',
                        subtitle: 'Test receipt link data extraction',
                        icon: Icons.receipt_long,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReceiptScraperTestScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Export My Data',
                        subtitle: 'Download all your transaction data',
                        icon: Icons.download,
                        onTap: _exportData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Card
                  _buildCard(
                    title: 'Account',
                    icon: Icons.person,
                    iconColor: Colors.cyan,
                    children: [
                      _buildActionTile(
                        title: 'Privacy Policy',
                        icon: Icons.open_in_new,
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Terms of Service',
                        icon: Icons.open_in_new,
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        title: 'Log Out',
                        icon: Icons.logout,
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        onTap: _logout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // App version
                  const Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              icon,
              color: iconColor ?? Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
