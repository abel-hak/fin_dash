import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/parser/sms_parser.dart';
import '../../domain/templates/template_model.dart';

class TestSmsScreen extends StatefulWidget {
  const TestSmsScreen({super.key});

  @override
  State<TestSmsScreen> createState() => _TestSmsScreenState();
}

class _TestSmsScreenState extends State<TestSmsScreen> {
  final _smsController = TextEditingController();
  final _senderController = TextEditingController();
  SmsParser? _parser;
  ParsedTransactionResult? _result;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      // Load templates from assets
      final String templatesJson = await rootBundle.loadString('templates.json');
      final List<dynamic> templatesData = json.decode(templatesJson);
      final templateRegistry = TemplateRegistry.fromJson(templatesData);
      _parser = SmsParser(templateRegistry);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load templates: $e';
        _isLoading = false;
      });
    }
  }

  final List<Map<String, String>> _testSamples = [
    {
      'sender': 'CBE',
      'message': 'Dear Abel, You have transferred ETB 100.00 to Kidus Yared on 17/10/2025 at 16:21:36 from your account 1*********8193. Your Current Balance is ETB 481.47. Thank you for Banking with CBE!'
    },
    {
      'sender': 'CBE', 
      'message': 'Dear Abel your Account 1*********8193 has been Credited with ETB 100.00 from Nathnael Adinew. on 15/10/2025 at 13:49:25 with Ref No FT2528885KX6 Your Current Balance is ETB 273.79. Thank you for Banking with CBE!'
    },
    {
      'sender': 'Telebirr',
      'message': 'You have transferred ETB 500.00 to (0912345678) John Doe on 12/10/2025 12:34:56. Your transaction number is CJ123456789. Your current E-Money Account balance is ETB 1,234.56.'
    },
    {
      'sender': 'Telebirr',
      'message': 'You have paid ETB 150.00 for Mobile Data Bundle. Your current E-Money Account balance is ETB 850.00.'
    },
  ];

  Future<void> _parseSms() async {
    if (_parser == null) {
      setState(() {
        _error = 'Parser not initialized. Please wait for templates to load.';
      });
      return;
    }

    setState(() {
      _error = null;
      _result = null;
    });

    try {
      final result = await _parser!.parseMessage(
        sender: _senderController.text,
        body: _smsController.text,
        timestamp: DateTime.now(),
        userId: 'test-user',
      );
      
      setState(() {
        _result = result;
        if (result == null) {
          _error = 'No matching template found for this SMS';
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _loadTestSample(Map<String, String> sample) {
    _senderController.text = sample['sender']!;
    _smsController.text = sample['message']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test SMS Parser'),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test samples
            const Text(
              'Quick Test Samples:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _testSamples.length,
                itemBuilder: (context, index) {
                  final sample = _testSamples[index];
                  return Card(
                    child: ListTile(
                      title: Text(sample['sender']!),
                      subtitle: Text(
                        sample['message']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _loadTestSample(sample),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Sender input
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Sender',
                border: OutlineInputBorder(),
                hintText: 'e.g., CBE, Telebirr',
              ),
            ),
            const SizedBox(height: 16),
            
            // SMS content input
            TextField(
              controller: _smsController,
              decoration: const InputDecoration(
                labelText: 'SMS Content',
                border: OutlineInputBorder(),
                hintText: 'Paste SMS message here...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            // Parse button
            ElevatedButton(
              onPressed: _parseSms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0277BD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Parse SMS'),
            ),
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      const Text(
                        'Error:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!),
                      ),
                    ],
                    if (_result != null) ...[
                      const Text(
                        'Parsed Result:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Template: ${_result!.matchedTemplateId}'),
                            Text('Confidence: ${(_result!.confidence * 100).toStringAsFixed(1)}%'),
                            const SizedBox(height: 8),
                            const Text('Transaction Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Amount: ${_result!.transaction.amount} ${_result!.transaction.currency}'),
                            Text('Merchant: ${_result!.transaction.merchant}'),
                            if (_result!.transaction.balance != null)
                              Text('Balance: ${_result!.transaction.balance} ${_result!.transaction.currency}'),
                            if (_result!.transaction.transactionId != null)
                              Text('Transaction ID: ${_result!.transaction.transactionId}'),
                            if (_result!.transaction.timestamp != null)
                              Text('Timestamp: ${_result!.transaction.timestamp}'),
                            if (_result!.transaction.recipient != null)
                              Text('Recipient: ${_result!.transaction.recipient}'),
                            Text('Channel: ${_result!.transaction.channel}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _smsController.dispose();
    _senderController.dispose();
    super.dispose();
  }
}
