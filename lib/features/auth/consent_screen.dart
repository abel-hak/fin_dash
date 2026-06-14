import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/auth/widgets/auth_layout.dart';
import 'package:sms_transaction_app/services/providers.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isLoading = false;

  bool _telebirrEnabled = true;
  bool _cbeEnabled = true;
  bool _awashEnabled = false;
  bool _bankOfAbyssiniaEnabled = false;

  Future<void> _requestSmsPermission() async {
    setState(() => _isLoading = true);

    try {
      final permissionsService = ref.read(permissionsServiceProvider);
      final granted = await permissionsService.requestSmsPermission();

      if (granted) {
        final preferencesService = ref.read(preferencesServiceProvider);
        final trustedSenders = <String>[];

        if (_telebirrEnabled) trustedSenders.add('Telebirr');
        if (_cbeEnabled) trustedSenders.add('CBE');
        if (_awashEnabled) trustedSenders.add('Awash Bank');
        if (_bankOfAbyssiniaEnabled) {
          trustedSenders.add('Bank of Abyssinia');
        }

        await preferencesService.saveTrustedSenders(trustedSenders);

        if (mounted) context.go('/inbox');
      } else if (mounted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      if (mounted) _showPermissionDeniedDialog();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
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
    final theme = Theme.of(context);
    final t = context.theming;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.m),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadii.l),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.sms_outlined,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'SMS Permissions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'We read SMS from your bank and mobile money providers to '
            'automatically track transactions.',
            style: theme.textTheme.bodyMedium?.copyWith(color: t.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            color: AppColors.infoSoft.withValues(alpha: 0.15),
            borderColor: AppColors.info.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we need SMS access',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const _InfoPoint(
                  icon: Icons.account_balance_outlined,
                  text: 'Extract transaction details from trusted banks',
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.s),
                const _InfoPoint(
                  icon: Icons.receipt_long_outlined,
                  text: 'Identify amount, recipient, and balances',
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.s),
                const _InfoPoint(
                  icon: Icons.check_circle_outline_rounded,
                  text: 'You approve each transaction before it is saved',
                  color: AppColors.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            color: AppColors.accentSoft.withValues(alpha: 0.2),
            borderColor: AppColors.accent.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy is protected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const _InfoPoint(
                  icon: Icons.phone_android_outlined,
                  text: 'All SMS processing happens on your device',
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.s),
                const _InfoPoint(
                  icon: Icons.lock_outline_rounded,
                  text: 'Only approved transaction data is stored',
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.s),
                const _InfoPoint(
                  icon: Icons.filter_alt_outlined,
                  text: 'We only read messages from senders you enable',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Trusted Senders', padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SenderToggle(
                  name: 'Telebirr',
                  value: _telebirrEnabled,
                  onChanged: (v) => setState(() => _telebirrEnabled = v),
                ),
                Divider(height: 1, color: t.border, indent: AppSpacing.l),
                _SenderToggle(
                  name: 'CBE',
                  value: _cbeEnabled,
                  onChanged: (v) => setState(() => _cbeEnabled = v),
                ),
                Divider(height: 1, color: t.border, indent: AppSpacing.l),
                _SenderToggle(
                  name: 'Awash Bank',
                  value: _awashEnabled,
                  onChanged: (v) => setState(() => _awashEnabled = v),
                ),
                Divider(height: 1, color: t.border, indent: AppSpacing.l),
                _SenderToggle(
                  name: 'Bank of Abyssinia',
                  value: _bankOfAbyssiniaEnabled,
                  onChanged: (v) =>
                      setState(() => _bankOfAbyssiniaEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AuthPrimaryButton(
            label: 'Enable SMS Access',
            isLoading: _isLoading,
            onPressed: _requestSmsPermission,
          ),
          const SizedBox(height: AppSpacing.m),
          Center(
            child: TextButton(
              onPressed: () => context.go('/inbox'),
              child: Text(
                'Use Manual Import Instead',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'You can change these permissions anytime in Settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  const _InfoPoint({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _SenderToggle extends StatelessWidget {
  const _SenderToggle({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(name, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      activeTrackColor: AppColors.accent.withValues(alpha: 0.45),
      activeThumbColor: AppColors.accent,
    );
  }
}
