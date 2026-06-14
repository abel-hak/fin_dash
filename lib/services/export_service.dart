import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';

/// Exports transactions to a CSV file and hands it to the OS share sheet so the
/// user can save it, email it, or open it in a spreadsheet app.
class ExportService {
  const ExportService();

  static final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmmss');

  /// Column order for the exported CSV. Kept explicit so the header row and
  /// each data row can't drift out of sync.
  static const List<String> _headers = [
    'Date',
    'Sender',
    'Merchant',
    'Reason',
    'Amount',
    'Currency',
    'Balance',
    'Account',
    'Channel',
    'Status',
  ];

  /// Builds CSV text for [transactions]. Public + pure so it can be unit-tested
  /// without touching the filesystem or share sheet.
  String buildCsv(List<ParsedTransaction> transactions) {
    final rows = <List<dynamic>>[
      _headers,
      for (final tx in transactions)
        [
          tx.occurredAt,
          tx.sender,
          tx.merchant,
          tx.reason ?? '',
          tx.amount,
          tx.currency,
          tx.balance ?? '',
          tx.accountAlias ?? '',
          tx.channel,
          tx.status.name,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Writes [transactions] to a temp CSV file and opens the share sheet.
  /// Returns false (and logs) if there's nothing to export or sharing fails.
  Future<bool> shareTransactionsCsv(
    List<ParsedTransaction> transactions,
  ) async {
    if (transactions.isEmpty) return false;

    try {
      final csv = buildCsv(transactions);
      final dir = await getTemporaryDirectory();
      final fileName = 'transactions_${_fileStamp.format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: fileName)],
        subject: 'My transactions',
        text: 'Exported ${transactions.length} transactions.',
      );
      return true;
    } catch (e, st) {
      AppLogger.error('CSV export failed', e, st);
      return false;
    }
  }
}
