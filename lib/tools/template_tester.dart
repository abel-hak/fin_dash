import 'dart:convert';
import 'dart:io';

import 'package:sms_transaction_app/domain/parser/sms_parser.dart';
import 'package:sms_transaction_app/domain/templates/template_model.dart';

void main() async {
  // Load templates
  final templateFile = File('improved_templates.json');
  final templateJson = await templateFile.readAsString();
  final List<dynamic> templateList = jsonDecode(templateJson);
  
  final templates = templateList.map((t) => SmsTemplate.fromJson(t)).toList();
  final registry = TemplateRegistry(templates: templates);
  final parser = SmsParser(registry);
  
  // Load test samples
  final sampleFile = File('test_sms_samples.json');
  final sampleJson = await sampleFile.readAsString();
  final Map<String, dynamic> samples = jsonDecode(sampleJson);
  
  // Test each sample
  int passed = 0;
  int failed = 0;
  
  for (final entry in samples.entries) {
    final sender = entry.key;
    final sampleList = entry.value as List;
    
    print('\n===== Testing $sender =====');
    
    for (final sample in sampleList) {
      final body = sample['body'] as String;
      final expected = sample['expected'] as Map<String, dynamic>;
      
      print('\nSMS: $body');
      print('Expected: $expected');
      
      final result = await parser.parseMessage(
        sender: sender, 
        body: body,
        timestamp: DateTime.now(),
        userId: 'test-user',
      );
      
      if (result != null) {
        print('Parsed: ${result.transaction.toMap()}');
        
        // Compare results
        bool allMatch = true;
        for (final key in expected.keys) {
          final expectedValue = expected[key];
          dynamic actualValue;
          
          switch (key) {
            case 'amount':
              actualValue = result.transaction.amount;
              break;
            case 'merchant':
              actualValue = result.transaction.merchant;
              break;
            case 'recipient':
              actualValue = result.transaction.recipient;
              break;
            case 'balance':
              actualValue = result.transaction.balance;
              break;
            case 'transaction_id':
              actualValue = result.transaction.transactionId;
              break;
            case 'timestamp':
              actualValue = result.transaction.timestamp;
              break;
          }
          
          bool isMatch = false;
          if (expectedValue is num && actualValue is num) {
            // Compare numeric values with some tolerance
            isMatch = (expectedValue - actualValue).abs() < 0.001;
          } else {
            // Compare string values
            isMatch = expectedValue.toString() == actualValue.toString();
          }
          
          if (!isMatch) {
            allMatch = false;
            print('❌ Mismatch on $key: expected=$expectedValue, actual=$actualValue');
          }
        }
        
        if (allMatch) {
          print('✅ All fields match!');
          passed++;
        } else {
          print('❌ Some fields did not match');
          failed++;
        }
      } else {
        print('❌ Failed to parse SMS');
        failed++;
      }
    }
  }
  
  print('\n===== Test Summary =====');
  print('Passed: $passed');
  print('Failed: $failed');
  print('Total: ${passed + failed}');
}
