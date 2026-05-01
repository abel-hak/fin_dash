import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sms_transaction_app/core/env_config.dart';
import 'package:sms_transaction_app/core/logger.dart';

/// AI-powered SMS parser using Google Gemini (FREE tier) via REST API
/// This is the ultimate fallback when templates and smart parser fail
class AiSmsParser {
  static bool _initialized = false;
  
  /// Initialize the AI model
  static void initialize() {
    if (!EnvConfig.hasGemini) {
      AppLogger.parser(
        'AI_PARSER',
        'Gemini API key not configured - AI parsing disabled',
      );
      return;
    }

    if (!EnvConfig.enableAiParsing) {
      AppLogger.parser('AI_PARSER', 'AI parsing disabled in config');
      return;
    }

    _initialized = true;
    AppLogger.parser('AI_PARSER', 'Gemini AI initialized (REST API)');
  }
  
  /// Parse SMS using AI
  static Future<Map<String, dynamic>?> parseWithAi(String body, String sender) async {
    if (!_initialized) {
      AppLogger.parser('AI_PARSER', '✗ AI not initialized');
      return null;
    }
    
    AppLogger.parser('AI_PARSER', '🤖 Starting AI parse for: $sender');
    
    try {
      final prompt = _buildPrompt(body, sender);
      
      // Use REST API directly with v1beta endpoint and gemini-2.5-flash model (FREE tier)
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${EnvConfig.geminiApiKey}'
      );
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );
      
      if (response.statusCode != 200) {
        AppLogger.parser('AI_PARSER', '✗ API error: ${response.statusCode} - ${response.body}');
        return null;
      }
      
      final jsonResponse = jsonDecode(response.body);
      final responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      if (responseText == null || responseText.isEmpty) {
        AppLogger.parser('AI_PARSER', '✗ Empty AI response');
        return null;
      }
      
      AppLogger.aiPayload('RESPONSE', responseText);

      final result = _parseAiResponse(responseText);

      if (result != null) {
        AppLogger.parser('AI_PARSER', 'AI parsing successful');
        return result;
      } else {
        AppLogger.parser('AI_PARSER', 'Failed to parse AI response');
        return null;
      }
    } catch (e) {
      AppLogger.parser('AI_PARSER', '✗ AI parsing error: $e');
      return null;
    }
  }
  
  /// Build the prompt for AI
  static String _buildPrompt(String smsBody, String sender) {
    return '''
You are an expert at extracting transaction data from SMS messages.

SMS Sender: $sender
SMS Body: $smsBody

Extract the following information and return ONLY a valid JSON object (no markdown, no explanation):

{
  "amount": <number>,
  "merchant": "<merchant or recipient name>",
  "account_alias": "<account number if present, null otherwise>",
  "balance": <number if present, null otherwise>,
  "transaction_id": "<transaction ID if present, null otherwise>",
  "transaction_type": "<debit, credit, or transfer>",
  "currency": "<ETB, KES, USD, etc>",
  "reason": "<payment purpose/description if mentioned>"
}

Rules:
1. Extract the MAIN transaction amount (not fees or charges)
2. For merchant: extract the person/business name, NOT the entire SMS body
3. For transfers: merchant is the recipient name (e.g., "Kidus Yared")
4. For payments: merchant is the service/package name (e.g., "Hourly unlimited Internet")
5. For debits without merchant: use the sender name (e.g., "CBE")
6. Extract masked account numbers like "1*********8193"
7. Extract balance from phrases like "Current Balance is ETB 481.47"
8. For reason: extract payment purpose like "Internet Package", "Fund Transfer", "Bill Payment", "Purchase", etc.
9. Return ONLY the JSON object, nothing else

Example for: "You have transfered ETB 100.00 to Kidus Yared on 17/10/2025 at 16:21:36 from your account 1*********8193. Your Current Balance is ETB 481.47."

{
  "amount": 100.00,
  "merchant": "Kidus Yared",
  "account_alias": "1*********8193",
  "balance": 481.47,
  "transaction_id": null,
  "transaction_type": "transfer",
  "currency": "ETB",
  "reason": "Fund Transfer"
}

Now extract from the SMS above:
''';
  }
  
  /// Parse AI response to extract JSON. The model may return ints, doubles,
  /// strings (with currency symbols/commas), or `null` for numeric fields,
  /// so coerce defensively rather than relying on `as double` casts.
  static Map<String, dynamic>? _parseAiResponse(String responseText) {
    try {
      String jsonStr = responseText.trim();

      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final Map<String, dynamic> parsed = jsonDecode(jsonStr);

      // Coerce numeric fields. Required: amount.
      final amount = _coerceDouble(parsed['amount']);
      if (amount == null || amount.isNaN || amount.isInfinite) {
        AppLogger.parser('AI_PARSER', 'Missing/invalid amount in AI response');
        return null;
      }
      parsed['amount'] = amount;
      parsed['balance'] = _coerceDouble(parsed['balance']);

      // Default currency if the model omitted it.
      final currency = parsed['currency'];
      if (currency is! String || currency.isEmpty) {
        parsed['currency'] = 'ETB';
      }

      // Provide a default merchant so downstream code doesn't crash.
      final merchant = parsed['merchant'];
      if (merchant is! String || merchant.isEmpty) {
        parsed['merchant'] = 'Unknown';
      }

      // Confidence stays on the 0-1 scale shared by every parser strategy.
      parsed['confidence'] = 0.9;

      return parsed;
    } catch (e) {
      AppLogger.parser('AI_PARSER', 'Failed to parse JSON from AI: $e');
      return null;
    }
  }

  static double? _coerceDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final d = value.toDouble();
      if (d.isNaN || d.isInfinite) return null;
      return d;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
      // Strip everything except digits, sign, decimal point.
      final cleaned = trimmed.replaceAll(RegExp(r'[^\d.\-]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }
}
