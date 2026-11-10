class ApiConfig {
  ApiConfig._();

  // Bisa di-override saat build:
  // flutter build apk --release --dart-define=API_URL=https://xxxx.ngrok-free.dev
  static const String _envUrl = String.fromEnvironment('API_URL');

  static const String _tunnelUrl =
      'https://rentable-angled-dolly.ngrok-free.dev';

  static String get baseUrl => _envUrl.isNotEmpty ? _envUrl : _tunnelUrl;

  static const apiPrefix = '/api';
}