/// Environment configuration for the app
/// This file should be used to manage environment-specific settings
class EnvConfig {
  // Supabase configuration
  // IMPORTANT: Replace these with your actual credentials before running
  // Get your credentials from: https://supabase.com/dashboard/project/_/settings/api
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';

  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  // API configuration
  static const String apiUrl = 'YOUR_SUPABASE_URL_HERE/rest/v1';

  // AI Configuration (Google Gemini - FREE tier)
  // Get your free API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const bool enableAiParsing =
      true; // Using REST API directly (v1beta endpoint) to disable AI fallback

  // App configuration
  static const bool isDevelopment = true;

  static const bool enableDebugLogs = true;

  // Sync configuration
  static const int syncIntervalMinutes = 5;

  // Template cache configuration
  static const int templateCacheDays = 1;
}
