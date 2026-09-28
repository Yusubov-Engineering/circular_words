abstract interface class LoggerApi {
  void info(String message);
  void debug(String message);
  void warning(String message);
  void error(String message, [Object? exception, StackTrace? stackTrace]);

  LoggerApi withTag(String tag);

  Object get rawInstance;
}
