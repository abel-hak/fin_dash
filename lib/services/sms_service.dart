import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/data/models/raw_sms_event.dart';
import 'package:sms_transaction_app/domain/parser/sms_parser.dart';
import 'package:sms_transaction_app/services/auth_service.dart';
import 'package:sms_transaction_app/services/template_service.dart';
import 'package:sms_transaction_app/services/preferences_service.dart';

class SmsService {
  static const EventChannel _smsEventChannel =
      EventChannel('com.example.sms_transaction_app/sms_events');

  final DatabaseHelper _databaseHelper;
  final SmsParser _smsParser;
  final AuthService _authService;
  final TemplateService _templateService;
  final PreferencesService _preferencesService;
  // Riverpod-friendly hook the provider layer can wire to invalidate the
  // transaction lists after each successful parse. Replaces the previous
  // ProviderContainer-based design which was never wired by the provider
  // (the container was always null in production).
  final void Function()? _onTransactionAdded;
  final _uuid = const Uuid();

  StreamSubscription<dynamic>? _smsSubscription;
  final _trustedSendersController =
      StreamController<List<String>>.broadcast();
  // Serializes incoming-SMS handling so concurrent broadcasts can't race
  // between `transactionExists` and `insertParsedTransaction`.
  Future<void> _processingTail = Future<void>.value();

  List<String> _trustedSenders = [];

  Stream<List<String>> get trustedSenders => _trustedSendersController.stream;

  SmsService({
    required DatabaseHelper databaseHelper,
    required SmsParser smsParser,
    required AuthService authService,
    required TemplateService templateService,
    required PreferencesService preferencesService,
    void Function()? onTransactionAdded,
  })  : _databaseHelper = databaseHelper,
        _smsParser = smsParser,
        _authService = authService,
        _templateService = templateService,
        _preferencesService = preferencesService,
        _onTransactionAdded = onTransactionAdded;
  
  // Initialize the service
  Future<void> initialize() async {
    // Load trusted senders from persistent storage
    await _loadTrustedSenders();
    
    // Start listening for SMS events
    _startListening();
  }
  
  // Start listening for incoming SMS
  void _startListening() {
    _smsSubscription = _smsEventChannel
        .receiveBroadcastStream()
        .listen(_enqueueIncomingSms, onError: (error) {
      AppLogger.error('Error from SMS event channel', error);
    });
  }

  /// Funnels every event through a serial queue so two SMS arriving in the
  /// same tick can't race past `transactionExists` and double-insert.
  void _enqueueIncomingSms(dynamic event) {
    _processingTail = _processingTail
        .then((_) => _handleIncomingSms(event))
        .catchError((Object e, StackTrace st) {
      AppLogger.error('SMS handler crashed', e, st);
    });
  }

  // Handle incoming SMS
  Future<void> _handleIncomingSms(dynamic event) async {
    try {
      final Map<String, dynamic> smsData = Map<String, dynamic>.from(event);
      
      final String sender = smsData['sender'] ?? 'Unknown';
      final String body = smsData['body'] ?? '';
      final int timestampMillis = smsData['timestampMillis'] ??
          DateTime.now().millisecondsSinceEpoch;
      
      // Check if this sender is in our trusted list
      if (!_isTrustedSender(sender)) {
        AppLogger.sms('IGNORED', sender, 'Sender not in trusted list');
        return;
      }
      
      // Store raw SMS in database
      final rawSms = RawSmsEvent(
        id: _uuid.v4(),
        sender: sender,
        body: body,
        providerTs: timestampMillis,
        receivedTs: DateTime.now().millisecondsSinceEpoch,
        handled: 0,
      );
      
      await _databaseHelper.insertRawSmsEvent(rawSms);
      
      // Try to parse the SMS
      final userId = await _authService.getUserId();
      if (userId == null) {
        AppLogger.warning('User not logged in, cannot parse SMS');
        return;
      }
      
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
      final parseResult = await _smsParser.parseMessage(
        sender: sender,
        body: body,
        timestamp: timestamp,
        userId: userId,
      );

      if (parseResult != null) {
        // Check if this transaction already exists (by fingerprint)
        final exists = await _databaseHelper.transactionExists(parseResult.transaction.fingerprint);
        if (!exists) {
          // If the user has enabled auto-approve for this sender, skip the
          // manual review step and store the transaction as approved — the
          // periodic sync service will then push it to the server.
          final autoApprove = await _shouldAutoApprove(sender);
          final toStore = autoApprove
              ? parseResult.transaction
                  .copyWith(status: TransactionStatus.approved)
              : parseResult.transaction;

          // Store the parsed transaction
          await _databaseHelper.insertParsedTransaction(toStore);

          // Either drop the raw SMS (privacy setting) or mark it handled.
          await _finalizeRawSms(rawSms);

          // Notify provider layer so the inbox/transaction lists refresh.
          _onTransactionAdded?.call();

          AppLogger.sms(
            autoApprove ? 'AUTO-APPROVED' : 'PARSED',
            sender,
            'Transaction: ${toStore.amount} ${toStore.currency}',
          );
        } else {
          AppLogger.sms('DUPLICATE', sender, 'Transaction already exists');
          // Still honor the delete-raw preference for duplicates.
          await _finalizeRawSms(rawSms);
        }
      } else {
        AppLogger.sms('FAILED', sender, 'Could not parse SMS');
      }
    } catch (e) {
      AppLogger.error('Error handling SMS', e);
    }
  }

  /// Whether transactions from [sender] should bypass manual review, per the
  /// user's per-sender auto-approve preferences. Matching mirrors
  /// [_isTrustedSender] (case-insensitive contains) so the keys configured in
  /// Settings line up with the trusted-sender names.
  Future<bool> _shouldAutoApprove(String sender) async {
    try {
      final settings = await _preferencesService.getAutoApproveSettings();
      final lowerSender = sender.toLowerCase();
      for (final entry in settings.entries) {
        if (entry.value && lowerSender.contains(entry.key.toLowerCase())) {
          return true;
        }
      }
    } catch (e) {
      AppLogger.error('Error reading auto-approve settings', e);
    }
    return false;
  }

  /// Applies the "delete raw SMS after processing" privacy preference: deletes
  /// the stored raw event when enabled, otherwise marks it handled.
  Future<void> _finalizeRawSms(RawSmsEvent rawSms) async {
    final deleteRaw = await _preferencesService.getDeleteRawSetting();
    if (deleteRaw) {
      await _databaseHelper.deleteRawSmsEvent(rawSms.id);
    } else {
      await _databaseHelper.updateRawSmsEvent(rawSms.copyWith(handled: 1));
    }
  }
  
  // Check if a sender is trusted
  bool _isTrustedSender(String sender) {
    return _trustedSenders.any((trusted) => 
      sender.toLowerCase().contains(trusted.toLowerCase())
    );
  }
  
  // Load trusted senders from persistent storage
  Future<void> _loadTrustedSenders() async {
    try {
      final templates = await _templateService.getTemplates();
      final availableSenders = templates.getAllSenders();

      final savedSenders = await _preferencesService.getTrustedSenders();

      if (savedSenders.isNotEmpty) {
        _trustedSenders = savedSenders;
        AppLogger.info(
          'Loaded ${savedSenders.length} trusted senders from preferences',
        );
      } else {
        _trustedSenders = availableSenders;
        await _preferencesService.saveTrustedSenders(availableSenders);
        AppLogger.info(
          'Initialized trusted senders with ${availableSenders.length} default senders',
        );
      }

      _trustedSendersController.add(_trustedSenders);
    } catch (e) {
      AppLogger.error('Error loading trusted senders', e);
      _trustedSenders = [];
    }
  }

  // Update trusted senders
  Future<void> updateTrustedSenders(List<String> senders) async {
    try {
      _trustedSenders = senders;
      await _preferencesService.saveTrustedSenders(senders);
      AppLogger.info('Updated trusted senders: ${senders.length} senders');
      _trustedSendersController.add(_trustedSenders);
    } catch (e) {
      AppLogger.error('Error updating trusted senders', e);
    }
  }
  
  // Manually parse an SMS message (for the paste SMS fallback)
  Future<bool> manuallyParseSms({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        return false;
      }
      
      final parseResult = await _smsParser.parseMessage(
        sender: sender,
        body: body,
        timestamp: timestamp,
        userId: userId,
      );
      
      if (parseResult != null) {
        // Check if this transaction already exists
        final exists = await _databaseHelper.transactionExists(parseResult.transaction.fingerprint);
        if (!exists) {
          // Store the parsed transaction
          await _databaseHelper.insertParsedTransaction(parseResult.transaction);
          return true;
        } else {
          AppLogger.info('Duplicate transaction detected in manual parse');
          return false;
        }
      } else {
        AppLogger.warning('Failed to parse manual SMS');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error manually parsing SMS', e);
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
    _trustedSendersController.close();
  }
}
