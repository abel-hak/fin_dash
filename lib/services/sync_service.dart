import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  final DatabaseHelper _databaseHelper;
  final String _apiUrl;
  final String Function() _getAuthToken;
  final _uuid = const Uuid();

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _retryCount = 0;
  final int _maxRetries = 5;

  SyncService({
    required DatabaseHelper databaseHelper,
    required String apiUrl,
    required String Function() getAuthToken,
  })  : _databaseHelper = databaseHelper,
        _apiUrl = apiUrl,
        _getAuthToken = getAuthToken;

  void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncApprovedTransactions();
    });

    // Do an initial sync immediately
    syncApprovedTransactions();
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncApprovedTransactions() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;

      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection. Will retry later.');
        _scheduleRetry();
        return;
      }

      // Get all approved transactions that need to be synced
      final transactions = await _databaseHelper.getParsedTransactions(
        status: TransactionStatus.approved,
      );

      if (transactions.isEmpty) {
        debugPrint('No transactions to sync');
        _isSyncing = false;
        _retryCount = 0;
        return;
      }

      // Group transactions by sender for batch processing
      final Map<String, List<ParsedTransaction>> transactionsBySender = {};
      for (final tx in transactions) {
        if (!transactionsBySender.containsKey(tx.sender)) {
          transactionsBySender[tx.sender] = [];
        }
        transactionsBySender[tx.sender]!.add(tx);
      }

      // Process each batch
      for (final sender in transactionsBySender.keys) {
        final batch = transactionsBySender[sender]!;
        await _syncBatch(sender, batch);
      }

      _retryCount = 0;
    } catch (e) {
      debugPrint('Error during sync: $e');
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncBatch(
      String sender, List<ParsedTransaction> transactions) async {
    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection for sync');
        return false;
      }

      // Get Supabase client
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated');
        return false;
      }

      debugPrint('Syncing transactions to Supabase');

      // Prepare data for insertion
      final List<Map<String, dynamic>> rows = transactions.map((tx) {
        return {
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
          'recipient': tx.recipient
        };
      }).toList();

      debugPrint('Inserting ${rows.length} transactions');

      // Insert data using Supabase client
      final response = await supabase.from('transactions').insert(rows);

      debugPrint('Sync successful');

      // Update transaction status to synced
      for (final tx in transactions) {
        await _databaseHelper.updateTransactionStatus(
            tx.id, TransactionStatus.synced);
      }

      return true;
    } catch (e) {
      debugPrint('Error syncing batch for sender $sender: $e');
      return false; // Return false instead of re-throwing
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      debugPrint('Max retries reached. Will try again on next scheduled sync.');
      _retryCount = 0;
      return;
    }

    _retryCount++;
    final backoffSeconds =
        min(pow(2, _retryCount).toInt() * 10, 300); // Max 5 minutes
    debugPrint(
        'Scheduling retry in $backoffSeconds seconds (attempt $_retryCount)');

    Timer(Duration(seconds: backoffSeconds), syncApprovedTransactions);
  }

  // Method to manually trigger sync for a specific transaction
  Future<bool> syncTransaction(ParsedTransaction transaction) async {
    try {
      return await _syncBatch(transaction.sender, [transaction]);
    } catch (e) {
      debugPrint('Error syncing individual transaction: $e');
      return false;
    }
  }
}
