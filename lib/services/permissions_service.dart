import 'package:flutter/services.dart';

class PermissionsService {
  static const MethodChannel _channel = MethodChannel('com.example.sms_transaction_app/sms_methods');

  // Check if SMS permission is granted
  Future<bool> checkSmsPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkSmsPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Failed to check SMS permission: ${e.message}');
      return false;
    }
  }

  // Request SMS permission
  Future<bool> requestSmsPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestSmsPermission');
      return granted;
    } on PlatformException catch (e) {
      print('Failed to request SMS permission: ${e.message}');
      return false;
    }
  }
}
