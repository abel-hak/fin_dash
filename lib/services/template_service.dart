import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_transaction_app/domain/templates/template_model.dart';

class TemplateService {
  static const String _templateCacheKey = 'template_registry_cache';
  static const String _templateLastUpdatedKey = 'template_registry_last_updated';
  static const Duration _cacheValidDuration = Duration(days: 1);

  // Default templates in case the API is unavailable
  static final List<Map<String, dynamic>> _defaultTemplates = [
    {
      "id": "telebirr_sms_en_v1",
      "sender": "Telebirr",
      "locale": "en",
      "patterns": {
        "amount": r"ETB\s*([\d,]+(?:\.\d{2})?)",
        "merchant": r"(?:to|at)\s+([^,\n]+)",
        "balance": r"Balance:?\s*ETB\s*([\d,]+(?:\.\d{2})?)",
        "account_alias": r"(?:Acct|A/C|Wallet)\s*([*\d]+)"
      },
      "post": {"currency": "ETB", "channel": "telebirr"}
    },
    {
      "id": "cbe_sms_en_v1",
      "sender": "CBE",
      "patterns": {
        "amount": r"ETB\s*([\d,]+(?:\.\d{2})?)",
        "merchant": r"at\s+([^,\n]+)",
        "balance": r"(?:New\s+)?Bal(?:ance)?:\s*ETB\s*([\d,]+(?:\.\d{2})?)"
      },
      "post": {"currency": "ETB", "channel": "cbe"}
    }
  ];

  Future<TemplateRegistry> getTemplates() async {
    try {
      // Check if we have a valid cached version
      final prefs = await SharedPreferences.getInstance();
      final lastUpdated = prefs.getInt(_templateLastUpdatedKey);
      final cachedData = prefs.getString(_templateCacheKey);

      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheValid = lastUpdated != null && 
          now - lastUpdated < _cacheValidDuration.inMilliseconds &&
          cachedData != null;

      if (cacheValid) {
        return TemplateRegistry.fromJson(jsonDecode(cachedData!));
      }

      // Load from local assets instead of API
      try {
        final String templatesJson = await rootBundle.loadString('assets/templates.json');
        final List<dynamic> templates = jsonDecode(templatesJson);
        
        // Cache the templates
        await prefs.setString(_templateCacheKey, templatesJson);
        await prefs.setInt(_templateLastUpdatedKey, now);
        
        return TemplateRegistry.fromJson(templates);
      } catch (assetError) {
        debugPrint('Error loading templates from assets: $assetError');
        // If assets fail, use default templates
        return _getDefaultTemplates();
      }
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return _getDefaultTemplates();
    }
  }

  TemplateRegistry _getDefaultTemplates() {
    return TemplateRegistry.fromJson(_defaultTemplates);
  }
}
