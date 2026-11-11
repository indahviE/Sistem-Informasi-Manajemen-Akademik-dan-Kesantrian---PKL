class ApiConfig {
  ApiConfig._();

  // Bisa di-override saat build:
  static const String _envUrl = String.fromEnvironment('API_URL');

  static const String _tunnelUrl =
      'https://sim-pesantren-gamma.vercel.app';

  static String get baseUrl => _envUrl.isNotEmpty ? _envUrl : _tunnelUrl;

  static const apiPrefix = '/api';
}