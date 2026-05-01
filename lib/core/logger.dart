import 'package:logger/logger.dart';
import 'package:sms_transaction_app/core/env_config.dart';

/// Centralized logger.
///
/// PII safety: SMS bodies, AI prompts/responses, and other sensitive payloads
/// are only logged when `EnvConfig.logSensitivePayloads` is true. Otherwise
/// they're redacted to a length-and-hash summary so we can correlate without
/// leaking content.
class AppLogger {
  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    level: EnvConfig.enableDebugLogs ? Level.debug : Level.info,
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (EnvConfig.enableDebugLogs) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// SMS-specific logger. The `message` parameter is treated as sensitive and
  /// redacted unless explicit sensitive-payload logging is enabled.
  static void sms(String action, String sender, String message) {
    if (!EnvConfig.enableDebugLogs) return;
    final safeMessage = EnvConfig.logSensitivePayloads
        ? message
        : _redact(message);
    _logger.d('SMS [$action] from $sender: $safeMessage');
  }

  static void parser(String templateId, String message) {
    if (!EnvConfig.enableDebugLogs) return;
    _logger.d('Parser [$templateId]: $message');
  }

  /// AI parser logs: redact the raw response unless explicitly opted in,
  /// since the response echoes the SMS contents (PII).
  static void aiPayload(String tag, String payload) {
    if (!EnvConfig.enableDebugLogs) return;
    final safe =
        EnvConfig.logSensitivePayloads ? payload : _redact(payload);
    _logger.d('AI [$tag]: $safe');
  }

  static void database(String operation, String message) {
    if (!EnvConfig.enableDebugLogs) return;
    _logger.d('DB [$operation]: $message');
  }

  static void sync(String message, {bool isError = false}) {
    if (isError) {
      _logger.e('Sync: $message');
    } else if (EnvConfig.enableDebugLogs) {
      _logger.d('Sync: $message');
    }
  }

  /// Replaces a payload with `<redacted len=N hash=XXXX>` to keep correlation
  /// without leaking content. Hash is short and non-cryptographic.
  static String _redact(String value) {
    if (value.isEmpty) return '<empty>';
    final hash = value.hashCode.toUnsigned(16).toRadixString(16).padLeft(4, '0');
    return '<redacted len=${value.length} hash=$hash>';
  }
}
