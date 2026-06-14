import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/services/demo_data_service.dart';
import 'package:sms_transaction_app/features/dashboard/widgets/app_drawer.dart';
import 'package:sms_transaction_app/features/legal/legal_screen.dart';
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

  Future<void> _loadDemoData() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(demoDataServiceProvider).seed();
      invalidateDemoDataProviders(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo data loaded: ${result.transactions} transactions, '
            '${result.budgets} budgets, ${result.goals} goals.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load demo data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearDemoData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(demoDataServiceProvider).clear();
      invalidateDemoDataProviders(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data cleared.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear demo data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    final transactions = ref.read(parsedTransactionsProvider).valueOrNull;
    if (transactions == null || transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export yet.')),
      );
      return;
    }

    final ok = await ref
        .read(exportServiceProvider)
        .shareTransactionsCsv(transactions);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export failed. Please try again.')),
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
    final t = context.theming;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.canvas,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.l,
                  AppSpacing.xl,
                  AppSpacing.huge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(
                      title: 'Settings',
                      subtitle: 'Manage your app preferences and account',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                  // SMS Permissions Card
                  const SectionHeader(
                    title: 'SMS Permissions',
                    padding: EdgeInsets.zero,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.sms,
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
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Trusted Senders Card
                  const SectionHeader(
                    title: 'Trusted Senders',
                    padding: EdgeInsets.zero,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children:
                          _trustedSenders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sender = entry.value;
                        return Column(
                          children: [
                            if (index > 0) _divider(t),
                            _buildSwitchTile(
                              icon: Icons.verified_user,
                              title: sender,
                              subtitle: _autoApproveSettings[sender] ?? false
                                  ? 'Auto-approve: ON'
                                  : 'Auto-approve: OFF',
                              value: _autoApproveSettings[sender] ?? false,
                              onChanged: (value) =>
                                  _saveAutoApproveSettings(sender, value),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Privacy & Data Card
                  const SectionHeader(
                    title: 'Privacy & Data',
                    padding: EdgeInsets.zero,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.privacy_tip,
                          title: 'Delete Raw SMS After Processing',
                          subtitle:
                              'Remove original SMS messages after they are parsed',
                          value: _deleteRawSms,
                          onChanged: _saveDeleteRawSetting,
                        ),
                        _divider(t),
                        _buildSwitchTile(
                          icon: Icons.insights,
                          title: 'Send Anonymous Diagnostics',
                          subtitle: 'Help us improve parsing accuracy',
                          value: _diagnosticsEnabled,
                          onChanged: _saveDiagnosticsEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Data Management Card
                  const SectionHeader(
                    title: 'Data Management',
                    padding: EdgeInsets.zero,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
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
                        _divider(t),
                        _buildActionTile(
                          title: 'Test Receipt Scraper',
                          subtitle: 'Test receipt link data extraction',
                          icon: Icons.receipt_long,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReceiptScraperTestScreen(),
                              ),
                            );
                          },
                        ),
                        _divider(t),
                        _buildActionTile(
                          title: 'Export My Data',
                          subtitle: 'Download all your transaction data',
                          icon: Icons.download,
                          onTap: _exportData,
                        ),
                        if (kDebugMode) ...[
                          _divider(t),
                          _buildActionTile(
                            title: 'Load Demo Data',
                            subtitle:
                                'Populate transactions, budgets, and goals for UI preview',
                            icon: Icons.dataset_outlined,
                            onTap: _loadDemoData,
                          ),
                          _divider(t),
                          _buildActionTile(
                            title: 'Clear Demo Data',
                            subtitle: 'Remove sample data tagged as demo',
                            icon: Icons.delete_sweep_outlined,
                            onTap: _clearDemoData,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Account Card
                  const SectionHeader(
                    title: 'Account',
                    padding: EdgeInsets.zero,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildActionTile(
                          title: 'Privacy Policy',
                          icon: Icons.open_in_new,
                          onTap: () => LegalScreen.show(
                            context,
                            LegalDocument.privacyPolicy,
                          ),
                        ),
                        _divider(t),
                        _buildActionTile(
                          title: 'Terms of Service',
                          icon: Icons.open_in_new,
                          onTap: () => LegalScreen.show(
                            context,
                            LegalDocument.termsOfService,
                          ),
                        ),
                        _divider(t),
                        _buildActionTile(
                          title: 'Log Out',
                          icon: Icons.logout,
                          destructive: true,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // App version
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
      ),
    );
  }

  Widget _divider(AppTheming t) => Container(height: 1, color: t.border);

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AppTile(
      leading: _iconChip(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    final t = context.theming;
    final color = destructive ? AppColors.danger : null;
    return AppTile(
      onTap: onTap,
      leading: _iconChip(icon, destructive: destructive),
      title: Text(
        title,
        style: color == null ? null : TextStyle(color: color),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(
        destructive ? icon : Icons.chevron_right_rounded,
        color: destructive ? AppColors.danger : t.textMuted,
        size: 20,
      ),
    );
  }

  Widget _iconChip(IconData icon, {bool destructive = false}) {
    return Container(
      height: 40,
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: destructive ? AppColors.dangerSoft : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      child: Icon(
        icon,
        color: destructive ? AppColors.danger : AppColors.accent,
        size: 20,
      ),
    );
  }
}
