import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Which legal document to display.
enum LegalDocument { termsOfService, privacyPolicy }

/// A simple, self-contained in-app reader for legal documents. Content is
/// placeholder text until real legal copy is provided — replace the strings in
/// [_termsSections] / [_privacySections] when the final documents exist.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  /// Convenience for `Navigator.push` from anywhere.
  static Future<void> show(BuildContext context, LegalDocument document) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(document: document)),
    );
  }

  bool get _isTerms => document == LegalDocument.termsOfService;

  String get _title => _isTerms ? 'Terms of Service' : 'Privacy Policy';

  List<_LegalSection> get _sections =>
      _isTerms ? _termsSections : _privacySections;

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        backgroundColor: t.canvas,
        elevation: 0,
        title: Text(_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Last updated: June 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
              child: Text(
                'This is placeholder text and is not a legally binding document. '
                'Final terms will be published before release.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.warning),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            for (final section in _sections) ...[
              Text(section.heading, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: t.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

const List<_LegalSection> _termsSections = [
  _LegalSection(
    '1. Acceptance of Terms',
    'By creating an account and using this application, you agree to be bound '
        'by these Terms of Service. If you do not agree, please do not use the app.',
  ),
  _LegalSection(
    '2. Description of Service',
    'The app reads financial SMS messages on your device to automatically '
        'detect and organize your transactions. Parsing happens on your device, '
        'and you control which senders are trusted.',
  ),
  _LegalSection(
    '3. Your Responsibilities',
    'You are responsible for keeping your account credentials secure and for '
        'verifying the accuracy of transactions before relying on them. The app '
        'is a tracking aid and does not replace your bank\'s official records.',
  ),
  _LegalSection(
    '4. Limitation of Liability',
    'The app is provided "as is" without warranties of any kind. We are not '
        'liable for any financial decisions made based on data shown in the app.',
  ),
  _LegalSection(
    '5. Changes to These Terms',
    'We may update these terms from time to time. Continued use of the app '
        'after changes take effect constitutes acceptance of the revised terms.',
  ),
];

const List<_LegalSection> _privacySections = [
  _LegalSection(
    '1. Information We Process',
    'The app processes the contents of financial SMS messages from senders you '
        'mark as trusted. This includes transaction amounts, merchants, and '
        'account balances contained in those messages.',
  ),
  _LegalSection(
    '2. On-Device Processing',
    'SMS parsing happens locally on your device. Your messages are not uploaded '
        'in raw form. You can choose to delete raw SMS after processing in Settings.',
  ),
  _LegalSection(
    '3. Data You Sync',
    'If you sign in, approved transactions may be synced to your account so they '
        'are available across sessions. You control what gets approved and synced.',
  ),
  _LegalSection(
    '4. Diagnostics',
    'With your consent, anonymous diagnostics may be collected to improve '
        'parsing accuracy. You can disable this at any time in Settings.',
  ),
  _LegalSection(
    '5. Your Choices',
    'You may revoke SMS permission, delete your data, or log out at any time. '
        'Removing the app deletes all locally stored transaction data.',
  ),
];
