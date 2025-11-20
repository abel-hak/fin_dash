import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _trustedSendersKey = 'trusted_senders';
  static const String _autoApproveKey = 'auto_approve';
  static const String _deleteRawKey = 'delete_raw';
  static const String _diagnosticsKey = 'diagnostics_enabled';
  
  // Get trusted senders
  Future<List<String>> getTrustedSenders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_trustedSendersKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error parsing trusted senders: $e');
      return [];
    }
  }
  
  // Save trusted senders
  Future<void> saveTrustedSenders(List<String> senders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trustedSendersKey, jsonEncode(senders));
  }
  
  // Get auto-approve settings for each sender
  Future<Map<String, bool>> getAutoApproveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_autoApproveKey);
    
    if (jsonString == null) {
      return {};
    }
    
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return jsonMap.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      print('Error parsing auto-approve settings: $e');
      return {};
    }
  }
  
  // Save auto-approve setting for a sender
  Future<void> saveAutoApproveSetting(String sender, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await getAutoApproveSettings();
    
    settings[sender] = enabled;
    await prefs.setString(_autoApproveKey, jsonEncode(settings));
  }
  
  // Get delete raw SMS setting
  Future<bool> getDeleteRawSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deleteRawKey) ?? false;
  }
  
  // Save delete raw SMS setting
  Future<void> saveDeleteRawSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deleteRawKey, enabled);
  }
  
  // Get diagnostics enabled setting
  Future<bool> getDiagnosticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_diagnosticsKey) ?? true;
  }
  
  // Save diagnostics enabled setting
  Future<void> saveDiagnosticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_diagnosticsKey, enabled);
  }
}
