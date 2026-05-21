abstract final class ApiConfig {
  static const String apiPath = '/api/v1';
  static const String localBackendUrl = 'http://localhost:8080';

  static const String baseUrl = String.fromEnvironment(
    'PLUMORA_API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
