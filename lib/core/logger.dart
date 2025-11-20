import 'package:logger/logger.dart';
import 'package:sms_transaction_app/core/env_config.dart';

/// Centralized logging utility for the app
class AppLogger {
  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: EnvConfig.enableDebugLogs ? Level.debug : Level.info,
  );

  // Debug logs - for development only
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (EnvConfig.enableDebugLogs) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  // Info logs - general information
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning logs - potential issues
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Error logs - errors that need attention
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal logs - critical errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // SMS-specific logging
  static void sms(String action, String sender, String message) {
    if (EnvConfig.enableDebugLogs) {
      _logger.d('📱 SMS [$action] from $sender: $message');
    }
  }

  // Parser-specific logging
  static void parser(String templateId, String message) {
    if (EnvConfig.enableDebugLogs) {
      _logger.d('🔍 Parser [$templateId]: $message');
    }
  }

  // Database-specific logging
  static void database(String operation, String message) {
    if (EnvConfig.enableDebugLogs) {
      _logger.d('💾 DB [$operation]: $message');
    }
  }

  // Sync-specific logging
  static void sync(String message, [bool isError = false]) {
    if (isError) {
      _logger.e('🔄 Sync: $message');
    } else if (EnvConfig.enableDebugLogs) {
      _logger.d('🔄 Sync: $message');
    }
  }
}
