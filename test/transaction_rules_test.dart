import 'package:flutter_test/flutter_test.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/domain/transaction_rules.dart';

ParsedTransaction _tx({required String merchant, double amount = 100}) {
  return ParsedTransaction(
    id: 'x',
    sender: 'CBE',
    amount: amount,
    currency: 'ETB',
    occurredAt: '2026-06-01T10:00:00Z',
    merchant: merchant,
    channel: 'cbe',
    confidence: 0.9,
    fingerprint: 'fp',
    status: TransactionStatus.pending,
    createdAt: '2026-06-01T10:00:00Z',
  );
}

void main() {
  group('TransactionRules.isIncomeMerchant', () {
    test('detects salary/income/deposit', () {
      expect(TransactionRules.isIncomeMerchant('Monthly Salary'), isTrue);
      expect(TransactionRules.isIncomeMerchant('Cash Deposit'), isTrue);
      expect(TransactionRules.isIncomeMerchant('Other income'), isTrue);
    });

    test('treats ordinary merchants as expenses', () {
      expect(TransactionRules.isIncomeMerchant('Lunch at cafe'), isFalse);
      expect(TransactionRules.isIncomeMerchant('Taxi ride'), isFalse);
    });

    test('isIncome delegates to merchant rule', () {
      expect(TransactionRules.isIncome(_tx(merchant: 'Salary')), isTrue);
      expect(TransactionRules.isIncome(_tx(merchant: 'Groceries')), isFalse);
    });
  });

  group('TransactionRules.fingerprint', () {
    final ts = DateTime.parse('2026-06-01T10:00:30Z');

    test('is deterministic for identical inputs', () {
      final a = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 250.0,
        timestamp: ts,
        merchant: 'Cafe Mokarar',
      );
      final b = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 250.0,
        timestamp: ts,
        merchant: 'Cafe Mokarar',
      );
      expect(a, equals(b));
    });

    test('rounds timestamp to the minute (seconds ignored)', () {
      final a = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 250.0,
        timestamp: DateTime.parse('2026-06-01T10:00:05Z'),
        merchant: 'Cafe',
      );
      final b = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 250.0,
        timestamp: DateTime.parse('2026-06-01T10:00:55Z'),
        merchant: 'Cafe',
      );
      expect(a, equals(b));
    });

    test('normalizes merchant case and whitespace', () {
      final a = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 10,
        timestamp: ts,
        merchant: 'Cafe Mokarar',
      );
      final b = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 10,
        timestamp: ts,
        merchant: '  CAFE MOKARAR  ',
      );
      expect(a, equals(b));
    });

    test('changes when amount changes (edit produces new fingerprint)', () {
      final a = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 100,
        timestamp: ts,
        merchant: 'Cafe',
      );
      final b = TransactionRules.fingerprint(
        userId: 'u1',
        amount: 1000,
        timestamp: ts,
        merchant: 'Cafe',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
