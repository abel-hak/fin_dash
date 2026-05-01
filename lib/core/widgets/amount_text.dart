import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Renders a monetary amount with consistent semantics, sign, and color.
/// - Income / credit -> emerald accent with leading "+"
/// - Expense / debit -> danger red with leading "-"
/// - Neutral -> primary text color
///
/// Always emits a TalkBack/VoiceOver friendly label like
/// "Expense 1,250 ETB".
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    this.kind = AmountKind.neutral,
    this.style,
    this.compact = false,
    this.semanticPrefix,
  });

  final double amount;
  final String currency;
  final AmountKind kind;
  final TextStyle? style;
  final bool compact;
  final String? semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    final color = switch (kind) {
      AmountKind.income => AppColors.success,
      AmountKind.expense => AppColors.danger,
      AmountKind.neutral => base?.color,
    };

    final formatter = compact
        ? NumberFormat.compactCurrency(symbol: '', decimalDigits: 1)
        : NumberFormat.currency(symbol: '', decimalDigits: 2);

    final prefix = switch (kind) {
      AmountKind.income => '+',
      AmountKind.expense => '\u2212', // unicode minus, prettier than ASCII
      AmountKind.neutral => '',
    };

    final formatted = formatter.format(amount.abs()).trim();
    final display = '$prefix$formatted $currency';

    final semanticKind = switch (kind) {
      AmountKind.income => 'Income',
      AmountKind.expense => 'Expense',
      AmountKind.neutral => '',
    };
    final semanticLabel = [
      semanticPrefix,
      semanticKind,
      formatted,
      currency,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Text(
        display,
        style: base?.copyWith(color: color),
      ),
    );
  }
}

enum AmountKind { income, expense, neutral }
