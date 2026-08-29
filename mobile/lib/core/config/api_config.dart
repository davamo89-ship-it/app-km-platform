class ApiConfig {
  const ApiConfig._();

  static const String identityBaseUrl = String.fromEnvironment(
    'IDENTITY_API_URL',
    defaultValue: 'http://localhost:5264',
  );

  static const String athletesBaseUrl = String.fromEnvironment(
    'ATHLETES_API_URL',
    defaultValue: 'http://localhost:5208',
  );

  static Uri identityUri(String path) {
    return _buildUri(identityBaseUrl, path);
  }

  static Uri athletesUri(String path) {
    return _buildUri(athletesBaseUrl, path);
  }

  static Uri _buildUri(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath');
  }
}