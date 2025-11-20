import 'package:sms_transaction_app/core/logger.dart';

/// Enhanced General SMS parser with smart pattern matching and NLP-like capabilities
/// Works without templates using intelligent context-aware extraction
class GeneralSmsParser {
  /// Parse SMS without templates using smart patterns
  static Map<String, dynamic>? parseGeneral(String body, String sender) {
    AppLogger.parser('SMART_PARSER', 'Starting smart parse for: $sender');
    AppLogger.parser('SMART_PARSER', 'SMS: ${body.substring(0, body.length > 100 ? 100 : body.length)}...');
    
    final result = <String, dynamic>{};
    
    // 1. Extract amount (most critical field)
    final amount = _extractAmountSmart(body);
    if (amount == null) {
      AppLogger.parser('SMART_PARSER', '✗ No amount found');
      return null;
    }
    result['amount'] = amount;
    AppLogger.parser('SMART_PARSER', '✓ Amount: $amount');
    
    // 2. Detect transaction type
    final transactionType = _detectTransactionType(body);
    result['transaction_type'] = transactionType;
    AppLogger.parser('SMART_PARSER', '✓ Type: $transactionType');
    
    // 3. Extract currency
    final currency = _extractCurrency(body);
    result['currency'] = currency;
    AppLogger.parser('SMART_PARSER', '✓ Currency: $currency');
    
    // 4. Extract merchant/recipient (context-aware)
    final merchant = _extractMerchantSmart(body, transactionType, sender);
    result['merchant'] = merchant;
    AppLogger.parser('SMART_PARSER', '✓ Merchant: $merchant');
    
    // 5. Extract account number
    final account = _extractAccountSmart(body);
    if (account != null) {
      result['account_alias'] = account;
      AppLogger.parser('SMART_PARSER', '✓ Account: $account');
    }
    
    // 6. Extract balance
    final balance = _extractBalanceSmart(body);
    if (balance != null) {
      result['balance'] = balance;
      AppLogger.parser('SMART_PARSER', '✓ Balance: $balance');
    }
    
    // 7. Extract transaction ID
    final transactionId = _extractTransactionIdSmart(body);
    if (transactionId != null) {
      result['transaction_id'] = transactionId;
      AppLogger.parser('SMART_PARSER', '✓ Transaction ID: $transactionId');
    }
    
    // 8. Set confidence based on fields extracted
    final confidence = _calculateConfidence(result);
    result['confidence'] = confidence;
    AppLogger.parser('SMART_PARSER', '✓ Confidence: ${(confidence * 100).toInt()}%');
    
    return result;
  }
  
  /// Smart amount extraction with context awareness
  static double? _extractAmountSmart(String body) {
    // Patterns for amount extraction
    final patterns = [
      // "ETB 1000.00", "ETB1000", "ETB 1,000.00"
      RegExp(r'(?:ETB|Birr|birr)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      // "Ksh 1000", "KES 1000"
      RegExp(r'(?:Ksh|KES)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      // "debited with ETB1000", "credited with ETB1000"
      RegExp(r'(?:debited|credited|paid|received|sent)\s+(?:with\s+)?(?:ETB|Ksh|KES|Birr)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      // "amount: 1000.00", "Amount 1000"
      RegExp(r'amount[:\s]+(?:ETB|Ksh|KES|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    
    return null;
  }
  
  /// Detect transaction type from SMS body
  static String _detectTransactionType(String body) {
    final bodyLower = body.toLowerCase();
    
    // Debit keywords
    if (bodyLower.contains('debited') || 
        bodyLower.contains('debit') ||
        bodyLower.contains('paid') ||
        bodyLower.contains('payment') ||
        bodyLower.contains('purchase') ||
        bodyLower.contains('withdrawn')) {
      return 'debit';
    }
    
    // Credit keywords
    if (bodyLower.contains('credited') || 
        bodyLower.contains('credit') ||
        bodyLower.contains('received') ||
        bodyLower.contains('deposit')) {
      return 'credit';
    }
    
    // Transfer keywords
    if (bodyLower.contains('transfer') || 
        bodyLower.contains('sent to') ||
        bodyLower.contains('sent money')) {
      return 'transfer';
    }
    
    // Default to debit (most common)
    return 'debit';
  }
  
  /// Extract currency from SMS body
  static String _extractCurrency(String body) {
    final bodyUpper = body.toUpperCase();
    
    if (bodyUpper.contains('ETB') || bodyUpper.contains('BIRR')) {
      return 'ETB';
    }
    if (bodyUpper.contains('KSH') || bodyUpper.contains('KES')) {
      return 'KES';
    }
    if (bodyUpper.contains('USD') || bodyUpper.contains('\$')) {
      return 'USD';
    }
    
    // Default to ETB (Ethiopian Birr)
    return 'ETB';
  }
  
  /// Smart merchant extraction with sentence structure analysis
  static String _extractMerchantSmart(String body, String transactionType, String sender) {
    // STRATEGY 1: Try specific patterns based on transaction type
    if (transactionType == 'transfer') {
      // For transfers, look for "to [Name]"
      final transferPattern = RegExp(
        r'(?:transferred|transfered)\s+ETB\s*[\d,]+(?:\.\d{2})?\s+to\s+([A-Za-z][A-Za-z\s]{2,40})\s+on',
        caseSensitive: false,
      );
      final match = transferPattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final merchant = match.group(1)!.trim();
        AppLogger.parser('SMART_PARSER', 'Found transfer merchant: $merchant');
        return merchant;
      }
    }
    
    // STRATEGY 2: Try payment patterns
    if (transactionType == 'debit') {
      // For payments, look for "for package [Name]"
      final packagePattern = RegExp(
        r'for\s+package\s+([A-Za-z][A-Za-z\s]{2,50})\s+(?:purchase|made)',
        caseSensitive: false,
      );
      final match = packagePattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final merchant = match.group(1)!.trim();
        AppLogger.parser('SMART_PARSER', 'Found package merchant: $merchant');
        return merchant;
      }
    }
    
    // STRATEGY 3: General patterns
    final patterns = [
      // Name with phone: "John Doe (251912345678)"
      RegExp(r'to\s+([A-Za-z][A-Za-z\s]{2,40})\s*\([0-9*\s]{8,}\)', caseSensitive: false),
      // "to John Doe on"
      RegExp(r'to\s+([A-Za-z][A-Za-z\s]{2,30})\s+on', caseSensitive: false),
      // "at Starbucks"
      RegExp(r'at\s+([A-Za-z][A-Za-z\s]{2,30})(?:\.|,|$)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final merchant = match.group(1)!.trim();
        if (!_isCommonWord(merchant) && merchant.length >= 3) {
          AppLogger.parser('SMART_PARSER', 'Found general merchant: $merchant');
          return merchant;
        }
      }
    }
    
    // STRATEGY 4: Default to sender if no merchant found
    AppLogger.parser('SMART_PARSER', 'No merchant found, using sender: $sender');
    return sender;
  }
  
  /// Smart account extraction
  static String? _extractAccountSmart(String body) {
    // Patterns for account extraction
    final patterns = [
      // "Account 1234567890", "A/C 1234567890"
      RegExp(r'(?:Account|A/C|Acct|account)\s+([0-9*]{8,})', caseSensitive: false),
      // "from your account 1234567890"
      RegExp(r'from\s+your\s+account\s+([0-9*]{8,})', caseSensitive: false),
      // Masked account: "1*********8193"
      RegExp(r'\b([0-9]{1,2}\*+[0-9]{3,4})\b'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!.trim();
      }
    }
    
    return null;
  }
  
  /// Smart balance extraction
  static double? _extractBalanceSmart(String body) {
    // Patterns for balance extraction
    final patterns = [
      // "Balance: ETB 1000.00", "Bal: ETB1000"
      RegExp(r'(?:Balance|Bal|balance|bal)[:\s]+(?:ETB|Ksh|KES|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      // "Current Balance is ETB 1000"
      RegExp(r'Current\s+Balance\s+is\s+(?:ETB|Ksh|KES|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      // "balance is ETB 1000"
      RegExp(r'balance\s+is\s+(?:ETB|Ksh|KES|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final balanceStr = match.group(1)!.replaceAll(',', '');
        final balance = double.tryParse(balanceStr);
        if (balance != null && balance >= 0) {
          return balance;
        }
      }
    }
    
    return null;
  }
  
  /// Smart transaction ID extraction
  static String? _extractTransactionIdSmart(String body) {
    // Patterns for transaction ID extraction
    final patterns = [
      // "transaction number is ABC123"
      RegExp(r'transaction\s+(?:number|id|ref|reference)\s+(?:is\s+)?([A-Z0-9]{6,})', caseSensitive: false),
      // "Ref: ABC123", "TxnID: ABC123"
      RegExp(r'(?:Ref|TxnID|TransID|ID)[:\s]+([A-Z0-9]{6,})', caseSensitive: false),
      // Standalone alphanumeric code (6-15 chars)
      RegExp(r'\b([A-Z]{2}[0-9A-Z]{6,13})\b'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!.trim();
      }
    }
    
    return null;
  }
  
  /// Calculate confidence score based on extracted fields
  static double _calculateConfidence(Map<String, dynamic> result) {
    int score = 0;
    int maxScore = 7;
    
    if (result.containsKey('amount')) score++;
    if (result.containsKey('currency')) score++;
    if (result.containsKey('merchant') && result['merchant'] != null) score++;
    if (result.containsKey('account_alias')) score++;
    if (result.containsKey('balance')) score++;
    if (result.containsKey('transaction_id')) score++;
    if (result.containsKey('transaction_type')) score++;
    
    return score / maxScore;
  }
  
  /// Check if a word is a common false positive
  static bool _isCommonWord(String word) {
    final commonWords = [
      'your', 'account', 'balance', 'current', 'new', 'thank', 'you',
      'banking', 'service', 'charge', 'fee', 'total', 'amount', 'transaction',
      'the', 'and', 'for', 'with', 'from', 'has', 'been', 'is', 'was'
    ];
    
    return commonWords.contains(word.toLowerCase());
  }
}
