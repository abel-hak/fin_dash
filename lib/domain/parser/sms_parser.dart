import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/domain/templates/template_model.dart';
import 'package:sms_transaction_app/domain/parser/general_sms_parser.dart';
import 'package:sms_transaction_app/domain/parser/ai_sms_parser.dart';
import 'package:sms_transaction_app/services/receipt_scraper_service.dart';

class SmsParser {
  final TemplateRegistry templateRegistry;
  final _uuid = const Uuid();

  SmsParser(this.templateRegistry);

  Future<ParsedTransactionResult?> parseMessage({
    required String sender,
    required String body,
    required DateTime timestamp,
    required String userId,
  }) async {
    // STRATEGY 0: Check for receipt link and scrape (ALWAYS wait for it)
    final receiptLinkInfo = ReceiptScraperService.extractReceiptLink(body);
    Map<String, dynamic>? receiptData;
    
    if (receiptLinkInfo != null) {
      AppLogger.parser('RECEIPT', 'Receipt link found: ${receiptLinkInfo['bank']} - scraping now...');
      
      // Scrape receipt - WAIT for it to complete (no timeout override)
      try {
        receiptData = await ReceiptScraperService.scrapeReceipt(receiptLinkInfo['url']!);
        if (receiptData != null) {
          AppLogger.parser('RECEIPT', '✓ Receipt scraped successfully - got ${receiptData.length} fields');
        }
      } catch (e) {
        AppLogger.parser('RECEIPT', 'Receipt scraping failed: $e');
        // Continue without receipt data - SMS parsing will still work
      }
    }
    
    // STRATEGY 1: AI Parser FIRST (Best accuracy, FREE Gemini API) 🤖
    AppLogger.parser('HYBRID', 'Starting with AI parser (primary strategy)');
    final aiResult = await AiSmsParser.parseWithAi(body, sender);
    
    if (aiResult != null) {
      // Convert AI parser result to ParsedTransaction
      var parsedResult = _createTransactionFromGeneralParse(
        aiResult,
        body,
        timestamp,
        sender,
        userId,
      );
      
      // Merge with receipt data if available
      if (receiptData != null && receiptLinkInfo != null) {
        parsedResult = _mergeWithReceiptData(parsedResult, receiptData, receiptLinkInfo['url']!);
      }
      
      AppLogger.parser('HYBRID', '✓ AI parser succeeded (primary)');
      return parsedResult;
    }

    // STRATEGY 2: Fallback to template-based parsing
    AppLogger.parser('HYBRID', 'AI failed, trying template parsing');
    final templates = templateRegistry.getTemplatesForSender(sender);
    
    if (templates.isNotEmpty) {
      // Try each template until we find one that works
      for (final template in templates) {
        final result = _tryParseWithTemplate(
          template: template,
          body: body,
          timestamp: timestamp,
          sender: sender,
          userId: userId,
        );

        if (result != null) {
          // Merge with receipt data if available
          final finalResult = (receiptData != null && receiptLinkInfo != null)
              ? _mergeWithReceiptData(result, receiptData, receiptLinkInfo['url']!)
              : result;
          
          AppLogger.parser('HYBRID', '✓ Template-based parsing succeeded (fallback)');
          return finalResult;
        }
      }
    }

    // STRATEGY 3: Last resort - smart general parser (offline)
    AppLogger.parser('HYBRID', 'Template failed, trying smart parser');
    final generalResult = GeneralSmsParser.parseGeneral(body, sender);
    
    if (generalResult != null) {
      // Convert general parser result to ParsedTransaction
      var parsedResult = _createTransactionFromGeneralParse(
        generalResult,
        body,
        timestamp,
        sender,
        userId,
      );
      
      // Merge with receipt data if available
      if (receiptData != null && receiptLinkInfo != null) {
        parsedResult = _mergeWithReceiptData(parsedResult, receiptData, receiptLinkInfo['url']!);
      }
      
      AppLogger.parser('HYBRID', '✓ Smart parser succeeded (last resort)');
      return parsedResult;
    }

    AppLogger.parser('HYBRID', '✗ All parsing strategies failed (AI, template, smart)');
    return null; // All strategies failed
  }

  ParsedTransactionResult? _tryParseWithTemplate({
    required SmsTemplate template,
    required String body,
    required DateTime timestamp,
    required String sender,
    required String userId,
  }) {
    final extractedData = <String, dynamic>{};
    double confidence = 0.0;
    int matchCount = 0;
    int totalPatterns = template.patterns.length;

    AppLogger.parser(template.id, 'Trying for sender: $sender');

    // Try to extract each field using the template patterns
    template.patterns.forEach((field, pattern) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(body);

      if (match != null && match.groupCount >= 1) {
        String value = match.group(1)!.trim();
        
        // Process numeric values
        if (field == 'amount' || field == 'balance') {
          value = value.replaceAll(',', '');
          extractedData[field] = double.tryParse(value) ?? 0.0;
        } else {
          extractedData[field] = value;
        }
        
        matchCount++;
        AppLogger.parser(template.id, '✓ Matched $field: ${extractedData[field]}');
      } else {
        AppLogger.parser(template.id, '✗ Failed to match $field');
      }
    });

    // Calculate confidence based on how many fields were matched
    if (totalPatterns > 0) {
      confidence = matchCount / totalPatterns;
    }

    AppLogger.parser(template.id, 'Confidence: ${(confidence * 100).toInt()}% ($matchCount/$totalPatterns fields)');

    // If we didn't extract amount (required), return null
    if (!extractedData.containsKey('amount')) {
      AppLogger.parser(template.id, '✗ Template failed: No amount found');
      return null;
    }

    // Merchant is optional - use sender name if not found
    if (!extractedData.containsKey('merchant')) {
      extractedData['merchant'] = sender;
      AppLogger.parser(template.id, 'ℹ Using sender as merchant: $sender');
    }

    // Add post-processing fields from template
    template.post.forEach((key, value) {
      extractedData[key] = value;
    });

    // Format the timestamp
    final formattedTimestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(timestamp);

    // Create fingerprint for deduplication
    final fingerprint = _generateFingerprint(
      userId: userId,
      amount: extractedData['amount'] as double,
      timestamp: timestamp,
      merchant: extractedData['merchant'] as String,
      accountAlias: extractedData['account_alias'] as String?,
    );

    // Create the parsed transaction
    final parsedTx = ParsedTransaction(
      id: _uuid.v4(),
      sender: sender,
      amount: extractedData['amount'] as double,
      currency: extractedData['currency'] as String,
      occurredAt: formattedTimestamp,
      merchant: extractedData['merchant'] as String,
      accountAlias: extractedData['account_alias'] as String?,
      balance: extractedData['balance'] as double?,
      channel: extractedData['channel'] as String,
      confidence: confidence,
      fingerprint: fingerprint,
      status: TransactionStatus.pending,
      createdAt: DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now()),
      transactionId: extractedData['transaction_id'] as String?,
      timestamp: extractedData['timestamp'] as String?,
      recipient: extractedData['recipient'] as String?,
    );

    return ParsedTransactionResult(
      transaction: parsedTx,
      confidence: confidence,
      matchedTemplateId: template.id,
    );
  }

  /// Create ParsedTransaction from general parser result
  ParsedTransactionResult _createTransactionFromGeneralParse(
    Map<String, dynamic> generalResult,
    String body,
    DateTime timestamp,
    String sender,
    String userId,
  ) {
    final amount = generalResult['amount'] as double;
    final merchant = generalResult['merchant'] as String;
    final currency = generalResult['currency'] as String;
    final confidence = generalResult['confidence'] as double;
    
    // Format the timestamp
    final formattedTimestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(timestamp);
    
    // Create fingerprint for deduplication
    final fingerprint = _generateFingerprint(
      userId: userId,
      amount: amount,
      timestamp: timestamp,
      merchant: merchant,
      accountAlias: generalResult['account_alias'] as String?,
    );
    
    // Determine channel from sender
    String channel = sender.toLowerCase();
    if (channel.contains('telebirr')) {
      channel = 'telebirr';
    } else if (channel.contains('cbe')) {
      channel = 'cbe';
    } else if (channel.contains('awash')) {
      channel = 'awash_bank';
    } else if (channel.contains('mpesa')) {
      channel = 'mpesa';
    }
    
    final parsedTx = ParsedTransaction(
      id: _uuid.v4(),
      sender: sender,
      amount: amount,
      currency: currency,
      occurredAt: formattedTimestamp,
      merchant: merchant,
      accountAlias: generalResult['account_alias'] as String?,
      balance: generalResult['balance'] as double?,
      channel: channel,
      confidence: confidence,
      fingerprint: fingerprint,
      status: TransactionStatus.pending,
      createdAt: DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now()),
      transactionId: generalResult['transaction_id'] as String?,
      timestamp: null,
      recipient: null,
    );
    
    return ParsedTransactionResult(
      transaction: parsedTx,
      confidence: confidence,
      matchedTemplateId: 'general_parser',
    );
  }

  // Merge SMS-parsed data with receipt data
  ParsedTransactionResult _mergeWithReceiptData(
    ParsedTransactionResult smsResult,
    Map<String, dynamic> receiptData,
    String receiptLink,
  ) {
    final smsTransaction = smsResult.transaction;
    
    // Extract receipt fields
    final payerAccount = receiptData['payer_account'] as String?;
    final merchantAccount = receiptData['merchant_account'] as String?;
    final serviceCharge = _parseDouble(receiptData['service_charge']);
    final vat = _parseDouble(receiptData['vat']);
    final totalAmount = _parseDouble(receiptData['total_amount']);
    final paymentMethod = receiptData['payment_method'] as String?;
    final branch = receiptData['branch'] as String?;
    final dataSource = receiptData['source'] as String?;
    final reason = receiptData['reason'] as String? ?? receiptData['description'] as String?;
    
    // Use receipt amount if available and different
    final amount = _parseDouble(receiptData['amount']) ?? smsTransaction.amount;
    
    // Use receipt merchant if available and not empty
    final merchant = (receiptData['merchant'] as String?)?.isNotEmpty == true
        ? receiptData['merchant'] as String
        : smsTransaction.merchant;
    
    // Create enhanced transaction
    final enhancedTransaction = smsTransaction.copyWith(
      amount: amount,
      merchant: merchant,
      receiptLink: receiptLink,
      hasReceipt: true,
      dataSource: dataSource ?? 'receipt',
      payerAccount: payerAccount,
      merchantAccount: merchantAccount,
      serviceCharge: serviceCharge,
      vat: vat,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      branch: branch,
      reason: reason,
      confidence: 95.0, // Higher confidence with receipt data
    );
    
    AppLogger.parser('RECEIPT_MERGE', 'Enhanced transaction with receipt data');
    
    return ParsedTransactionResult(
      transaction: enhancedTransaction,
      confidence: 95.0,
      matchedTemplateId: smsResult.matchedTemplateId,
    );
  }
  
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  String _generateFingerprint({
    required String userId,
    required double amount,
    required DateTime timestamp,
    required String merchant,
    String? accountAlias,
  }) {
    // Round timestamp to the nearest minute to allow for small time differences
    final roundedTimestamp = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
    );
    
    // Normalize merchant name (lowercase, trim spaces)
    final normalizedMerchant = merchant.toLowerCase().trim();
    
    // Create a string to hash
    final dataToHash = '$userId|${amount.abs()}|$roundedTimestamp|$normalizedMerchant|${accountAlias ?? ""}';
    
    // Create SHA-256 hash
    final bytes = utf8.encode(dataToHash);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
}

class ParsedTransactionResult {
  final ParsedTransaction transaction;
  final double confidence;
  final String matchedTemplateId;

  ParsedTransactionResult({
    required this.transaction,
    required this.confidence,
    required this.matchedTemplateId,
  });
}
