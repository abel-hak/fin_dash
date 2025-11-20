import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/core/env_config.dart';

class ReceiptScraperService {
  // Extract receipt link from SMS text
  static Map<String, String>? extractReceiptLink(String smsBody) {
    // Telebirr pattern
    final telebirrPattern = RegExp(
      r'https://transactioninfo\.ethiotelecom\.et/receipt/[A-Z0-9]+',
      caseSensitive: false,
    );
    final telebirrMatch = telebirrPattern.firstMatch(smsBody);
    if (telebirrMatch != null) {
      return {
        'url': telebirrMatch.group(0)!,
        'bank': 'Telebirr',
        'type': 'html',
      };
    }

    // CBE pattern
    final cbePattern = RegExp(
      r'https://apps\.cbe\.com\.et:\d+/\?id=[A-Z0-9]+',
      caseSensitive: false,
    );
    final cbeMatch = cbePattern.firstMatch(smsBody);
    if (cbeMatch != null) {
      return {
        'url': cbeMatch.group(0)!,
        'bank': 'CBE',
        'type': 'pdf',
      };
    }

    // Generic URL pattern (fallback)
    final genericPattern = RegExp(r'https?://[^\s]+');
    final genericMatch = genericPattern.firstMatch(smsBody);
    if (genericMatch != null) {
      return {
        'url': genericMatch.group(0)!,
        'bank': 'Unknown',
        'type': 'unknown',
      };
    }

    return null;
  }

  // Create HTTP client that bypasses SSL verification (for testing)
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    httpClient.connectionTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  // Scrape receipt and return structured data
  static Future<Map<String, dynamic>?> scrapeReceipt(String url) async {
    http.Client? client;
    try {
      AppLogger.parser('RECEIPT', 'Starting receipt scraping: $url');
      
      client = _createHttpClient();

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Receipt scraping timeout after 90 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load receipt: ${response.statusCode}');
      }

      final contentType = response.headers['content-type'] ?? '';
      
      // Check if PDF
      if (contentType.contains('pdf') || response.bodyBytes[0] == 0x25) {
        AppLogger.parser('RECEIPT', 'Detected PDF receipt, extracting text...');
        return await _scrapePdfReceipt(response.bodyBytes);
      } else {
        AppLogger.parser('RECEIPT', 'Detected HTML receipt, parsing...');
        return _scrapeHtmlReceipt(response.body);
      }
    } catch (e) {
      AppLogger.parser('RECEIPT', 'Receipt scraping failed: $e');
      return null;
    } finally {
      client?.close();
    }
  }

  // Scrape HTML receipt (Telebirr)
  static Map<String, dynamic> _scrapeHtmlReceipt(String html) {
    final data = <String, dynamic>{};
    data['source'] = 'receipt_html';
    
    try {
      final document = html_parser.parse(html);
      final allCells = document.querySelectorAll('td');

      for (int i = 0; i < allCells.length; i++) {
        final cellText = allCells[i].text.trim();

        if (i + 1 < allCells.length) {
          final nextCellText = allCells[i + 1].text.trim();

          if (cellText.contains('Payer Name') || cellText.contains('የከፋይ ስም')) {
            data['payer_name'] = nextCellText;
          }
          if (cellText.contains('Payer telebirr no') || cellText.contains('የከፋይ ቴሌብር ቁ')) {
            data['payer_phone'] = nextCellText;
          }
          if (cellText.contains('Credited Party name') || cellText.contains('የገንዘብ ተቀባይ ስም')) {
            data['merchant'] = nextCellText;
          }
          if (cellText.contains('Credited party account') || cellText.contains('የገንዘብ ተቀባይ ቴሌብር ቁ')) {
            data['merchant_account'] = nextCellText;
          }
          if (cellText.contains('transaction status') || cellText.contains('የክፍያው ሁኔታ')) {
            data['status'] = nextCellText;
          }
          if (cellText.contains('Payment Mode') || cellText.contains('የክፍያ ዘዴ')) {
            data['payment_method'] = nextCellText;
          }
          if (cellText.contains('Payment Reason') || cellText.contains('የክፍያ ምክንያት')) {
            data['description'] = nextCellText;
          }
          if (cellText.contains('Payment channel') || cellText.contains('የክፍያ መንገድ')) {
            data['payment_channel'] = nextCellText;
          }
        }
      }

      // Extract amounts
      final receiptCells = document.querySelectorAll('.receipttable td');
      for (int i = 0; i < receiptCells.length; i++) {
        final cellText = receiptCells[i].text.trim();
        if (i + 1 < receiptCells.length) {
          final nextCellText = receiptCells[i + 1].text.trim();
          
          if (cellText.contains('Amount') || cellText.contains('መጠን')) {
            final amountMatch = RegExp(r'([\d,]+\.?\d*)').firstMatch(nextCellText);
            if (amountMatch != null) {
              data['amount'] = amountMatch.group(1)?.replaceAll(',', '');
            }
          }
          if (cellText.contains('Transaction ID') || cellText.contains('የግብይት መለያ')) {
            data['transaction_id'] = nextCellText;
          }
          if (cellText.contains('Date') || cellText.contains('ቀን')) {
            data['date'] = nextCellText;
          }
        }
      }

      AppLogger.parser('RECEIPT_HTML', 'HTML receipt parsed: ${data.length} fields extracted');
    } catch (e) {
      AppLogger.parser('RECEIPT_HTML', 'HTML parsing error: $e');
    }

    return data;
  }

  // Scrape PDF receipt with AI (CBE)
  static Future<Map<String, dynamic>> _scrapePdfReceipt(List<int> pdfBytes) async {
    final data = <String, dynamic>{};
    data['source'] = 'receipt_pdf_ai';

    try {
      // Extract text from PDF
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String pdfText = extractor.extractText();
      document.dispose();

      AppLogger.parser('RECEIPT_PDF', 'PDF text extracted: ${pdfText.length} characters');

      // Use AI to parse PDF text via REST API (same as AI parser)
      final prompt = '''
Extract transaction data from this receipt and return ONLY valid JSON:

$pdfText

Return JSON with these fields (use null if not found):
{
  "transaction_id": "...",
  "payer_name": "...",
  "payer_account": "...",
  "merchant": "...",
  "merchant_account": "...",
  "amount": "...",
  "service_charge": "...",
  "vat": "...",
  "total_amount": "...",
  "date": "...",
  "status": "...",
  "description": "...",
  "reason": "...",
  "branch": "...",
  "payment_method": "..."
}

Notes:
- "description" is any transaction description on the receipt
- "reason" is the purpose/type of payment (e.g., "Fund Transfer", "Bill Payment", "Purchase", "Internet Package")

Return ONLY the JSON, no markdown or code blocks.
''';

      // Use REST API with gemini-2.5-flash (same as AI parser)
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
        throw Exception('AI API error: ${response.statusCode} - ${response.body}');
      }
      
      final jsonResponse = jsonDecode(response.body);
      final aiText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      // Parse AI response
      try {
        var jsonText = aiText.trim();
        // Remove markdown code blocks
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        }
        if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        jsonText = jsonText.trim();

        final aiData = jsonDecode(jsonText) as Map<String, dynamic>;
        data.addAll(aiData);
        
        AppLogger.parser('RECEIPT_PDF_AI', 'AI parsed PDF: ${aiData.length} fields extracted');
      } catch (e) {
        AppLogger.parser('RECEIPT_PDF_AI', 'AI response parsing failed: $e');
        data['ai_error'] = e.toString();
      }
    } catch (e) {
      AppLogger.parser('RECEIPT_PDF', 'PDF extraction failed: $e');
      data['error'] = e.toString();
    }

    return data;
  }

  // Merge SMS data with receipt data (receipt takes priority)
  static Map<String, dynamic> mergeData(
    Map<String, dynamic> smsData,
    Map<String, dynamic> receiptData,
  ) {
    final merged = <String, dynamic>{};
    
    // Start with SMS data as base
    merged.addAll(smsData);
    
    // Override with receipt data (more accurate)
    receiptData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value != 'null') {
        merged[key] = value;
      }
    });
    
    // Mark as receipt-enhanced
    merged['has_receipt'] = true;
    merged['data_source'] = receiptData['source'] ?? 'receipt';
    
    AppLogger.parser('RECEIPT_MERGE', 'Merged data: SMS + Receipt = ${merged.length} fields');
    
    return merged;
  }
}
