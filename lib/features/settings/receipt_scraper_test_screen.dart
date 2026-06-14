import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:http/io_client.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import '../../core/env_config.dart';

class ReceiptScraperTestScreen extends StatefulWidget {
  const ReceiptScraperTestScreen({super.key});

  @override
  State<ReceiptScraperTestScreen> createState() =>
      _ReceiptScraperTestScreenState();
}

class _ReceiptScraperTestScreenState extends State<ReceiptScraperTestScreen> {
  final TextEditingController _smsController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _scrapedData;
  String? _error;
  String? _rawHtml;
  bool _showRawHtml = false;
  String? _extractedLink;
  String? _detectedBank;

  @override
  void initState() {
    super.initState();
    // Pre-fill with example SMS for testing
    _smsController.text =
        '''Dear Customer, You have successfully paid 3.00 Birr to Ethio telecom.
Transaction ID: CJ99D8Z5WV
View receipt: https://transactioninfo.ethiotelecom.et/receipt/CJ99D8Z5WV''';
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  // Extract receipt link from SMS text
  Map<String, String>? _extractReceiptLink(String smsBody) {
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
        'bank': 'Commercial Bank of Ethiopia (CBE)',
      };
    }

    // Generic URL pattern (fallback)
    final genericPattern = RegExp(r'https?://[^\s]+');
    final genericMatch = genericPattern.firstMatch(smsBody);
    if (genericMatch != null) {
      return {
        'url': genericMatch.group(0)!,
        'bank': 'Unknown Bank',
      };
    }

    return null;
  }

  // Create HTTP client that accepts bad certificates (for testing only)
  http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    httpClient.connectionTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  Future<void> _scrapeReceipt() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _scrapedData = null;
      _rawHtml = null;
      _extractedLink = null;
      _detectedBank = null;
    });

    http.Client? client;
    try {
      final smsText = _smsController.text.trim();

      if (smsText.isEmpty) {
        throw Exception('Please paste SMS text');
      }

      // Extract receipt link from SMS
      final linkInfo = _extractReceiptLink(smsText);

      if (linkInfo == null) {
        throw Exception(
            'No receipt link found in SMS text. Make sure the SMS contains a receipt URL.');
      }

      final url = linkInfo['url']!;
      final bank = linkInfo['bank']!;

      setState(() {
        _extractedLink = url;
        _detectedBank = bank;
      });

      // Create custom HTTP client that bypasses SSL verification
      client = _createHttpClient();

      // Fetch the receipt page
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timed out after 30 seconds. The receipt page may be slow or unavailable.');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load receipt: ${response.statusCode}');
      }

      // Check content type
      final contentType = response.headers['content-type'] ?? '';
      final scrapedData = <String, dynamic>{};

      if (contentType.contains('pdf') || response.bodyBytes[0] == 0x25) {
        // PDF starts with %
        // Handle PDF with AI
        scrapedData['content_type'] = 'PDF';
        scrapedData['pdf_size'] =
            '${(response.bodyBytes.length / 1024).toStringAsFixed(2)} KB';

        try {
          // Extract text from PDF using Syncfusion
          final PdfDocument document =
              PdfDocument(inputBytes: response.bodyBytes);
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String pdfText = extractor.extractText();
          document.dispose();

          scrapedData['pdf_text'] = pdfText;

          // Use AI to parse PDF text
          final model = GenerativeModel(
            model: 'gemini-pro',
            apiKey: EnvConfig.geminiApiKey,
          );

          final prompt = '''
Extract transaction data from this receipt text and return ONLY valid JSON (no markdown, no code blocks):

$pdfText

Return JSON with these exact fields:
{
  "transaction_id": "...",
  "payer_name": "...",
  "payer_phone": "...",
  "merchant": "...",
  "merchant_account": "...",
  "amount": "...",
  "total_amount": "...",
  "date": "...",
  "status": "...",
  "payment_method": "...",
  "description": "...",
  "vat": "...",
  "service_charge": "..."
}

If a field is not found, use null. Return ONLY the JSON object, nothing else.
''';

          final content = [Content.text(prompt)];
          final aiResponse = await model.generateContent(content);
          final aiText = aiResponse.text ?? '';

          // Parse AI response
          try {
            // Remove markdown code blocks if present
            var jsonText = aiText.trim();
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
            scrapedData.addAll(aiData);
            scrapedData['ai_parsed'] = true;
          } catch (e) {
            scrapedData['ai_error'] = 'Failed to parse AI response: $e';
            scrapedData['ai_raw_response'] = aiText;
          }
        } catch (e) {
          scrapedData['error'] = 'PDF extraction failed: $e';
        }

        setState(() {
          _scrapedData = scrapedData;
          _isLoading = false;
        });
        return;
      }

      // Handle HTML
      scrapedData['content_type'] = 'HTML';

      // Store raw HTML for debugging
      _rawHtml = response.body;

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Strategy 1: Extract from table cells (Telebirr format)
      final allCells = document.querySelectorAll('td');

      for (int i = 0; i < allCells.length; i++) {
        final cellText = allCells[i].text.trim();

        // Look for specific labels and get next cell value
        if (i + 1 < allCells.length) {
          final nextCellText = allCells[i + 1].text.trim();

          // Payer Name
          if (cellText.contains('Payer Name') || cellText.contains('የከፋይ ስም')) {
            scrapedData['payer_name'] = nextCellText;
          }

          // Payer Phone
          if (cellText.contains('Payer telebirr no') ||
              cellText.contains('የከፋይ ቴሌብር ቁ')) {
            scrapedData['payer_phone'] = nextCellText;
          }

          // Merchant/Credited Party
          if (cellText.contains('Credited Party name') ||
              cellText.contains('የገንዘብ ተቀባይ ስም')) {
            scrapedData['merchant'] = nextCellText;
          }

          // Merchant Account
          if (cellText.contains('Credited party account') ||
              cellText.contains('የገንዘብ ተቀባይ ቴሌብር ቁ')) {
            scrapedData['merchant_account'] = nextCellText;
          }

          // Status
          if (cellText.contains('transaction status') ||
              cellText.contains('የክፍያው ሁኔታ')) {
            scrapedData['status'] = nextCellText;
          }

          // Payment Mode
          if (cellText.contains('Payment Mode') ||
              cellText.contains('የክፍያ ዘዴ')) {
            scrapedData['payment_method'] = nextCellText;
          }

          // Payment Reason
          if (cellText.contains('Payment Reason') ||
              cellText.contains('የክፍያ ምክንያት')) {
            scrapedData['description'] = nextCellText;
          }

          // Payment Channel
          if (cellText.contains('Payment channel') ||
              cellText.contains('የክፍያ መንገድ')) {
            scrapedData['payment_channel'] = nextCellText;
          }
        }
      }

      // Strategy 2: Extract from receipttableTd cells (invoice details)
      final receiptCells =
          document.querySelectorAll('.receipttableTd, .receipttableTd2');
      if (receiptCells.length >= 3) {
        // First row after header should have: Invoice No, Date, Amount
        if (receiptCells.length >= 6) {
          scrapedData['transaction_id'] = receiptCells[3].text.trim();
          scrapedData['date'] = receiptCells[4].text.trim();
          scrapedData['amount'] = receiptCells[5].text.trim();
        }
      }

      // Strategy 3: Look for specific patterns in raw HTML
      // Extract VAT
      final vatMatch = RegExp(
              r'15%\s*ተ\.እ\.ታ/VAT\s*&nbsp;&nbsp;\s*</td>\s*<td[^>]*>\s*([\d.]+)\s*Birr')
          .firstMatch(_rawHtml ?? '');
      if (vatMatch != null) {
        scrapedData['vat'] = '${vatMatch.group(1)} Birr';
      }

      // Extract Service Fee
      final serviceFeeMatch = RegExp(
              r'የአገልግሎት ክፍያ/service fee\s*&nbsp;&nbsp;\s*</td>\s*<td[^>]*>\s*([\d.]+)\s*Birr')
          .firstMatch(_rawHtml ?? '');
      if (serviceFeeMatch != null) {
        scrapedData['service_charge'] = '${serviceFeeMatch.group(1)} Birr';
      }

      // Extract Total Paid
      final totalMatch = RegExp(
              r'ጠቅላላ የተከፈለ/Total Paid Amount\s*&nbsp;&nbsp;\s*</td>\s*<td[^>]*>\s*([\d.]+)\s*Birr')
          .firstMatch(_rawHtml ?? '');
      if (totalMatch != null) {
        scrapedData['total_amount'] = '${totalMatch.group(1)} Birr';
      }

      // Extract Amount in Words
      final amountWordsMatch = RegExp(
              r'የገንዘቡ ልክ በፊደል/Total Amount in word</td>\s*<td[^>]*>\s*([^<]+)</td>')
          .firstMatch(_rawHtml ?? '');
      if (amountWordsMatch != null) {
        scrapedData['amount_in_words'] = amountWordsMatch.group(1)?.trim();
      }

      // Strategy 2: Extract all text content for analysis
      final bodyText = document.body?.text ?? '';
      scrapedData['full_text'] =
          bodyText.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Strategy 3: Extract all key-value pairs from tables
      final tables = document.querySelectorAll('table');
      final tableData = <String, String>{};
      for (var table in tables) {
        final rows = table.querySelectorAll('tr');
        for (var row in rows) {
          final cells = row.querySelectorAll('td, th');
          if (cells.length >= 2) {
            final key = cells[0].text.trim().toLowerCase();
            final value = cells[1].text.trim();
            if (key.isNotEmpty && value.isNotEmpty) {
              tableData[key] = value;
            }
          }
        }
      }
      scrapedData['table_data'] = tableData;

      // Strategy 4: Extract all meta tags
      final metaTags = document.querySelectorAll('meta');
      final metaData = <String, String>{};
      for (var meta in metaTags) {
        final name = meta.attributes['name'] ?? meta.attributes['property'];
        final content = meta.attributes['content'];
        if (name != null && content != null) {
          metaData[name] = content;
        }
      }
      scrapedData['meta_data'] = metaData;

      // Strategy 5: Look for JSON-LD structured data
      final jsonLdScripts =
          document.querySelectorAll('script[type="application/ld+json"]');
      if (jsonLdScripts.isNotEmpty) {
        scrapedData['structured_data'] =
            jsonLdScripts.map((s) => s.text).toList();
      }

      setState(() {
        _scrapedData = scrapedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      // Clean up HTTP client
      client?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        title: const Text('Receipt Scraper Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Test SMS → Receipt Scraping',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paste SMS text containing receipt link',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),

            // SSL Warning
            AppCard(
              color: AppColors.warningSoft,
              borderColor: AppColors.warning,
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'SSL verification disabled for testing. This bypasses certificate errors.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // URL Input
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMS Text',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: _smsController,
                    decoration: const InputDecoration(
                      hintText:
                          'Paste your SMS message here...\n\nExample: Dear Customer, You have paid 100 ETB.\nReceipt: https://...',
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _scrapeReceipt,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnAccent,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(_isLoading
                              ? 'Processing...'
                              : 'Extract & Scrape'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      IconButton(
                        onPressed: () {
                          Clipboard.getData(Clipboard.kTextPlain).then((data) {
                            if (data?.text != null) {
                              _smsController.text = data!.text!;
                            }
                          });
                        },
                        icon: const Icon(Icons.paste),
                        style: IconButton.styleFrom(
                          backgroundColor: t.surfaceElevated,
                        ),
                        tooltip: 'Paste from clipboard',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Extracted Link Display
            if (_extractedLink != null && _detectedBank != null) ...[
              AppCard(
                color: AppColors.accentSoft,
                borderColor: AppColors.success,
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          'Receipt Link Found!',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Text(
                          'Bank: ',
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          _detectedBank!,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Link:',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: t.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadii.s),
                      ),
                      child: SelectableText(
                        _extractedLink!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],

            // Error Display
            if (_error != null) ...[
              AppCard(
                color: AppColors.dangerSoft,
                borderColor: AppColors.danger,
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: t.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            // Scraped Data Display
            if (_scrapedData != null) ...[
              // PDF Detection Message
              if (_scrapedData!['content_type'] == 'PDF') ...[
                // PDF Header
                AppCard(
                  color: AppColors.infoSoft,
                  borderColor: AppColors.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              color: AppColors.info, size: 32),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PDF Receipt - AI Parsed',
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  'PDF Size: ${_scrapedData!['pdf_size']}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (_scrapedData!['ai_parsed'] == true)
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Show PDF Text Button
                if (_scrapedData!['pdf_text'] != null) ...[
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Extracted PDF Text'),
                          content: SingleChildScrollView(
                            child: SelectableText(
                              _scrapedData!['pdf_text'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: _scrapedData!['pdf_text'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('PDF text copied to clipboard')),
                                );
                              },
                              child: const Text('Copy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.text_fields),
                    label: const Text('View Extracted PDF Text'),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],

                // AI Extracted Data
                if (_scrapedData!['ai_parsed'] == true) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: AppColors.violet, size: 20),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              'AI Extracted Data',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),
                        _buildDataRow(
                            'Transaction ID', _scrapedData!['transaction_id']),
                        _buildDataRow(
                            'Payer Name', _scrapedData!['payer_name']),
                        _buildDataRow(
                            'Payer Phone', _scrapedData!['payer_phone']),
                        _buildDataRow('Merchant', _scrapedData!['merchant']),
                        _buildDataRow('Merchant Account',
                            _scrapedData!['merchant_account']),
                        _buildDataRow('Amount', _scrapedData!['amount']),
                        _buildDataRow(
                            'Total Amount', _scrapedData!['total_amount']),
                        _buildDataRow('Date', _scrapedData!['date']),
                        _buildDataRow('Status', _scrapedData!['status']),
                        _buildDataRow(
                            'Payment Method', _scrapedData!['payment_method']),
                        _buildDataRow(
                            'Description', _scrapedData!['description']),
                        _buildDataRow('VAT', _scrapedData!['vat']),
                        _buildDataRow(
                            'Service Charge', _scrapedData!['service_charge']),
                      ],
                    ),
                  ),
                ] else if (_scrapedData!['ai_error'] != null) ...[
                  AppCard(
                    color: AppColors.dangerSoft,
                    borderColor: AppColors.danger,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              'AI Parsing Error',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          _scrapedData!['ai_error'] ?? '',
                          style: TextStyle(color: t.textPrimary),
                        ),
                        if (_scrapedData!['ai_raw_response'] != null) ...[
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'AI Raw Response:',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            decoration: BoxDecoration(
                              color: t.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadii.s),
                            ),
                            child: SelectableText(
                              _scrapedData!['ai_raw_response'] ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (_scrapedData!['error'] != null) ...[
                  AppCard(
                    color: AppColors.warningSoft,
                    borderColor: AppColors.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: AppColors.warning),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              'Extraction Error',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          _scrapedData!['error'] ?? '',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // HTML Data - Main Data
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            'Extracted Data',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.l),
                      _buildDataRow(
                          'Transaction ID', _scrapedData!['transaction_id']),
                      _buildDataRow('Payer Name', _scrapedData!['payer_name']),
                      _buildDataRow(
                          'Payer Phone', _scrapedData!['payer_phone']),
                      _buildDataRow('Merchant', _scrapedData!['merchant']),
                      _buildDataRow('Merchant Account',
                          _scrapedData!['merchant_account']),
                      _buildDataRow('Amount', _scrapedData!['amount']),
                      _buildDataRow(
                          'Total Amount', _scrapedData!['total_amount']),
                      _buildDataRow(
                          'Amount in Words', _scrapedData!['amount_in_words']),
                      _buildDataRow('Date', _scrapedData!['date']),
                      _buildDataRow('Status', _scrapedData!['status']),
                      _buildDataRow(
                          'Payment Method', _scrapedData!['payment_method']),
                      _buildDataRow(
                          'Payment Channel', _scrapedData!['payment_channel']),
                      _buildDataRow(
                          'Description', _scrapedData!['description']),
                      _buildDataRow('VAT', _scrapedData!['vat']),
                      _buildDataRow(
                          'Service Charge', _scrapedData!['service_charge']),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Table Data
                if (_scrapedData!['table_data'] != null &&
                    (_scrapedData!['table_data'] as Map).isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table Data',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        ...(_scrapedData!['table_data'] as Map<String, String>)
                            .entries
                            .map((e) => _buildDataRow(e.key, e.value)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],

                // Raw HTML Toggle
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showRawHtml = !_showRawHtml;
                    });
                  },
                  icon: Icon(
                      _showRawHtml ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showRawHtml ? 'Hide Raw HTML' : 'Show Raw HTML'),
                ),

                if (_showRawHtml && _rawHtml != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  AppCard(
                    color: t.surfaceElevated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Raw HTML',
                              style: theme.textTheme.titleSmall,
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: t.textSecondary),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _rawHtml!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('HTML copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            _rawHtml!,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    final t = context.theming;
    final hasValue = value != null && value.toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasValue ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: hasValue ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    hasValue ? value.toString() : 'Not found',
                    style: TextStyle(
                      color: hasValue ? t.textPrimary : AppColors.danger,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
