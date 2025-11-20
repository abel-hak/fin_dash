import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/raw_sms_event.dart';
import 'package:sms_transaction_app/domain/parser/sms_parser.dart';
import 'package:sms_transaction_app/services/auth_service.dart';
import 'package:sms_transaction_app/services/template_service.dart';
import 'package:sms_transaction_app/services/preferences_service.dart';
import 'package:sms_transaction_app/services/providers.dart';

class SmsService {
  static const EventChannel _smsEventChannel = EventChannel('com.example.sms_transaction_app/sms_events');
  
  final DatabaseHelper _databaseHelper;
  final SmsParser _smsParser;
  final AuthService _authService;
  final TemplateService _templateService;
  final ProviderContainer? _providerContainer;
  final _uuid = const Uuid();
  
  StreamSubscription? _smsSubscription;
  final _trustedSendersController = StreamController<List<String>>.broadcast();
  
  // List of trusted senders that the user has approved
  List<String> _trustedSenders = [];
  
  // Stream of trusted senders that UI can listen to
  Stream<List<String>> get trustedSenders => _trustedSendersController.stream;
  
  SmsService({
    required DatabaseHelper databaseHelper,
    required SmsParser smsParser,
    required AuthService authService,
    required TemplateService templateService,
    ProviderContainer? providerContainer,
  }) : _databaseHelper = databaseHelper,
       _smsParser = smsParser,
       _authService = authService,
       _templateService = templateService,
       _providerContainer = providerContainer;
  
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
        .listen(_handleIncomingSms, onError: (error) {
      AppLogger.error('Error from SMS event channel', error);
    });
  }
  
  // Handle incoming SMS
  Future<void> _handleIncomingSms(dynamic event) async {
    try {
      final Map<String, dynamic> smsData = Map<String, dynamic>.from(event);
      
      final String sender = smsData['sender'] ?? 'Unknown';
      final String body = smsData['body'] ?? '';
      final String timestampStr = smsData['timestamp'] ?? '';
      final int timestampMillis = smsData['timestampMillis'] ?? DateTime.now().millisecondsSinceEpoch;
      
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
          // Store the parsed transaction
          await _databaseHelper.insertParsedTransaction(parseResult.transaction);
          
          // Mark the raw SMS as handled
          await _databaseHelper.updateRawSmsEvent(
            rawSms.copyWith(handled: 1),
          );
          
          // Trigger UI refresh
          _triggerUIRefresh();
          
          AppLogger.sms('PARSED', sender, 'Transaction: ${parseResult.transaction.amount} ${parseResult.transaction.currency}');
        } else {
          AppLogger.sms('DUPLICATE', sender, 'Transaction already exists');
        }
      } else {
        AppLogger.sms('FAILED', sender, 'Could not parse SMS');
      }
    } catch (e) {
      AppLogger.error('Error handling SMS', e);
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
      // First try to get all available senders from template registry
      final templates = await _templateService.getTemplates();
      final availableSenders = templates.getAllSenders();
      
      // Try to load user preferences
      final preferencesService = PreferencesService();
      final savedSenders = await preferencesService.getTrustedSenders();
      
      // If user has saved preferences, use those; otherwise trust all available senders
      if (savedSenders.isNotEmpty) {
        _trustedSenders = savedSenders;
        AppLogger.info('Loaded ${savedSenders.length} trusted senders from preferences');
      } else {
        // First time - trust all available senders by default
        _trustedSenders = availableSenders;
        await preferencesService.saveTrustedSenders(availableSenders);
        AppLogger.info('Initialized trusted senders with ${availableSenders.length} default senders');
      }
      
      // Notify listeners
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
      
      // Save to persistent storage
      final preferencesService = PreferencesService();
      await preferencesService.saveTrustedSenders(senders);
      AppLogger.info('Updated trusted senders: ${senders.length} senders');
      
      // Notify listeners
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
  
  // Trigger UI refresh when new transaction is added
  void _triggerUIRefresh() {
    if (_providerContainer != null) {
      try {
        // We need to import the provider from providers.dart
        // For now, let's use a simple approach - invalidate the providers directly
        _providerContainer!.invalidate(parsedTransactionsProvider);
        _providerContainer!.invalidate(pendingTransactionsProvider);
        _providerContainer!.invalidate(approvedTransactionsProvider);
      } catch (e) {
        AppLogger.error('Error triggering UI refresh', e);
      }
    }
  }
  
  // Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
    _trustedSendersController.close();
  }
}
