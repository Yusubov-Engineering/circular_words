abstract class AppConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  static const environment = String.fromEnvironment('ENVIRONMENT');
  static const enableLogs = bool.fromEnvironment(
    'ENABLE_LOGS',
    defaultValue: false,
  );

  static bool get isProd => environment == 'prod';
}
