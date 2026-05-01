import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sms_transaction_app/core/env_config.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';

/// Pushes locally-approved transactions to Supabase.
///
/// Lifecycle:
///   - `startSync()` should be called once an authenticated session exists
///     (post-login or on app resume); it sets up a periodic timer plus an
///     immediate sync attempt.
///   - `stopSync()` should be called on logout / disposal so the timer and
///     scheduled retries don't keep firing.
///
/// Concurrency:
///   - `_isSyncing` short-circuits overlapping ticks.
///   - `_retryTimer` is nullable + cancelled on every entry to
///     `syncApprovedTransactions`, so backoff retries can't pile up.
class SyncService {
  final DatabaseHelper _databaseHelper;

  Timer? _syncTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  SyncService({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  void startSync() {
    _syncTimer?.cancel();
    final intervalMinutes = EnvConfig.syncIntervalMinutes;
    _syncTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => syncApprovedTransactions(),
    );

    // Best-effort initial sync. Errors are handled inside the method.
    unawaited(syncApprovedTransactions());
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  Future<void> syncApprovedTransactions() async {
    if (_isSyncing) return;
    _retryTimer?.cancel();
    _retryTimer = null;

    try {
      _isSyncing = true;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        AppLogger.sync('No connectivity; will retry later.');
        _scheduleRetry();
        return;
      }

      final transactions = await _databaseHelper.getParsedTransactions(
        status: TransactionStatus.approved,
      );

      if (transactions.isEmpty) {
        AppLogger.sync('Nothing to sync.');
        _retryCount = 0;
        return;
      }

      final transactionsBySender = <String, List<ParsedTransaction>>{};
      for (final tx in transactions) {
        transactionsBySender.putIfAbsent(tx.sender, () => []).add(tx);
      }

      var allOk = true;
      for (final entry in transactionsBySender.entries) {
        final ok = await _syncBatch(entry.key, entry.value);
        if (!ok) allOk = false;
      }

      if (allOk) {
        _retryCount = 0;
      } else {
        _scheduleRetry();
      }
    } catch (e, st) {
      AppLogger.error('Sync error', e, st);
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncBatch(
    String sender,
    List<ParsedTransaction> transactions,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.sync('User not authenticated; skipping batch.');
        return false;
      }

      AppLogger.sync(
        'Syncing ${transactions.length} transaction(s) for $sender',
      );

      final rows = transactions
          .map((tx) => {
                'user_id': userId,
                'sender': tx.sender,
                'amount': tx.amount,
                'currency': tx.currency,
                'occurred_at': tx.occurredAt,
                'merchant': tx.merchant,
                'account_alias': tx.accountAlias,
                'balance': tx.balance,
                'channel': tx.channel,
                'confidence': tx.confidence,
                'fingerprint': tx.fingerprint,
                'transaction_id': tx.transactionId,
                'timestamp': tx.timestamp,
                'recipient': tx.recipient,
              })
          .toList();

      // Use upsert with the fingerprint as the conflict key so a network
      // error/crash between insert and local status flip can't double-write.
      // Requires a UNIQUE(user_id, fingerprint) constraint server-side.
      await supabase
          .from('transactions')
          .upsert(rows, onConflict: 'user_id,fingerprint', ignoreDuplicates: false);

      for (final tx in transactions) {
        await _databaseHelper.updateTransactionStatus(
          tx.id,
          TransactionStatus.synced,
        );
      }

      AppLogger.sync('Batch synced ($sender).');
      return true;
    } catch (e, st) {
      AppLogger.error('Sync batch failed for $sender', e, st);
      return false;
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      AppLogger.sync(
        'Max retries reached; will retry on next scheduled sync.',
      );
      _retryCount = 0;
      return;
    }
    _retryCount++;
    final backoffSeconds =
        min(pow(2, _retryCount).toInt() * 10, 300); // cap at 5 minutes
    AppLogger.sync(
      'Scheduling retry in ${backoffSeconds}s (attempt $_retryCount).',
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(
      Duration(seconds: backoffSeconds),
      syncApprovedTransactions,
    );
  }

  /// Manual one-shot sync for a single transaction (used from the review
  /// screen on approve). Returns `true` when the row was successfully pushed.
  Future<bool> syncTransaction(ParsedTransaction transaction) async {
    try {
      return await _syncBatch(transaction.sender, [transaction]);
    } catch (e, st) {
      AppLogger.error('Single-transaction sync failed', e, st);
      return false;
    }
  }
}
