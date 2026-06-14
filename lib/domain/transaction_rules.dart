import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';

/// Single source of truth for transaction classification heuristics.
///
/// These rules were previously copy-pasted inline across `budgetsProvider`,
/// `DashboardData`, and `TransactionsScreen`, which meant a tweak in one place
/// silently diverged from the others. Keep them here so income detection and
/// category grouping stay consistent everywhere.
class TransactionRules {
  const TransactionRules._();

  static const List<String> _incomeKeywords = [
    'salary',
    'income',
    'deposit',
  ];

  /// True when a merchant string looks like incoming money (salary, deposit…).
  static bool isIncomeMerchant(String merchant) {
    final m = merchant.toLowerCase();
    return _incomeKeywords.any(m.contains);
  }

  /// True when a parsed transaction represents income rather than an expense.
  static bool isIncome(ParsedTransaction tx) => isIncomeMerchant(tx.merchant);

  /// Deterministic dedup fingerprint for a transaction. Single source of truth
  /// shared by the parser (on first import) and the review screen (when a user
  /// edits amount/merchant before approving), so an edited transaction's
  /// fingerprint stays consistent with how an identical fresh import would hash
  /// — preventing both phantom duplicates and false-duplicate suppression.
  ///
  /// The timestamp is rounded to the minute to tolerate small clock skew, and
  /// the merchant is normalized (lowercase + trimmed). [amount] uses its
  /// absolute value so sign conventions don't matter.
  static String fingerprint({
    required String userId,
    required double amount,
    required DateTime timestamp,
    required String merchant,
    String? accountAlias,
  }) {
    final roundedTimestamp = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
    );
    final normalizedMerchant = merchant.toLowerCase().trim();
    final dataToHash =
        '$userId|${amount.abs()}|$roundedTimestamp|$normalizedMerchant|${accountAlias ?? ""}';
    return sha256.convert(utf8.encode(dataToHash)).toString();
  }
}
