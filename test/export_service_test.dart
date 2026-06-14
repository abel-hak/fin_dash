import 'package:flutter_test/flutter_test.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/services/export_service.dart';

ParsedTransaction _tx({
  String merchant = 'Cafe',
  double amount = 100,
  String? reason,
  TransactionStatus status = TransactionStatus.approved,
}) {
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
    status: status,
    createdAt: '2026-06-01T10:00:00Z',
    reason: reason,
  );
}

void main() {
  const service = ExportService();

  test('buildCsv emits a header row plus one row per transaction', () {
    final csv = service.buildCsv([_tx(), _tx(merchant: 'Taxi')]);
    final lines = csv.trim().split('\n');
    expect(lines.length, 3); // header + 2 rows
    expect(lines.first, contains('Date'));
    expect(lines.first, contains('Amount'));
    expect(lines.first, contains('Status'));
  });

  test('buildCsv includes core field values', () {
    final csv = service.buildCsv([
      _tx(merchant: 'Cafe Mokarar', amount: 250, reason: 'Lunch'),
    ]);
    expect(csv, contains('Cafe Mokarar'));
    expect(csv, contains('250'));
    expect(csv, contains('Lunch'));
    expect(csv, contains('approved'));
  });

  test('buildCsv handles empty list (header only)', () {
    final csv = service.buildCsv([]);
    expect(csv.trim().split('\n').length, 1);
  });
}
