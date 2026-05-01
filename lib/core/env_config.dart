import 'package:flutter/foundation.dart';

/// Environment configuration sourced from `--dart-define` flags at build time.
///
/// Local dev:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=GEMINI_API_KEY=AI...
///
/// Release builds **must** pass these or `EnvConfig.validate()` will throw.
/// Never bake real secrets into source.
class EnvConfig {
  // ----- Required secrets ---------------------------------------------------

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _placeholder,
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _placeholder,
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _placeholder,
  );

  // ----- Derived ------------------------------------------------------------

  static String get apiUrl {
    if (_isPlaceholder(supabaseUrl)) return _placeholder;
    return '$supabaseUrl/rest/v1';
  }

  // ----- Feature flags ------------------------------------------------------

  static const bool enableAiParsing = bool.fromEnvironment(
    'ENABLE_AI_PARSING',
    defaultValue: true,
  );

  /// True for `flutter run` (debug). Profile and release builds report `false`.
  static bool get isDevelopment => kDebugMode;

  /// Verbose logs only in debug builds unless explicitly enabled at build time.
  /// In release, raw SMS bodies and AI responses are never logged.
  static const bool _enableDebugLogsFlag = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: false,
  );
  static bool get enableDebugLogs => kDebugMode || _enableDebugLogsFlag;

  /// When true, raw SMS body / AI response strings may be logged.
  /// Default: only in debug. Production must opt in explicitly.
  static const bool _logSensitivePayloadsFlag = bool.fromEnvironment(
    'LOG_SENSITIVE_PAYLOADS',
    defaultValue: false,
  );
  static bool get logSensitivePayloads =>
      kDebugMode || _logSensitivePayloadsFlag;

  // ----- Sync / cache -------------------------------------------------------

  static const int syncIntervalMinutes = int.fromEnvironment(
    'SYNC_INTERVAL_MINUTES',
    defaultValue: 5,
  );

  static const int templateCacheDays = int.fromEnvironment(
    'TEMPLATE_CACHE_DAYS',
    defaultValue: 1,
  );

  // ----- Validation ---------------------------------------------------------

  static const String _placeholder = '__UNSET__';

  static bool _isPlaceholder(String value) =>
      value.isEmpty ||
      value == _placeholder ||
      value.startsWith('YOUR_') ||
      value == 'YOUR_SUPABASE_URL_HERE' ||
      value == 'YOUR_SUPABASE_ANON_KEY_HERE' ||
      value == 'YOUR_GEMINI_API_KEY_HERE';

  static bool get hasSupabase =>
      !_isPlaceholder(supabaseUrl) && !_isPlaceholder(supabaseAnonKey);
  static bool get hasGemini => !_isPlaceholder(geminiApiKey);

  /// Throws in release builds if required secrets are missing. In debug it
  /// only logs warnings so dev iteration without keys is still possible.
  static void validate() {
    final missing = <String>[
      if (!hasSupabase) 'SUPABASE_URL / SUPABASE_ANON_KEY',
      if (!hasGemini) 'GEMINI_API_KEY (AI parsing will be disabled)',
    ];
    if (missing.isEmpty) return;

    final message =
        'Missing required env: ${missing.join(', ')}. '
        'Pass via --dart-define when running or building.';

    if (kReleaseMode && !hasSupabase) {
      throw StateError(message);
    }

    debugPrint('[EnvConfig] $message');
  }
}
