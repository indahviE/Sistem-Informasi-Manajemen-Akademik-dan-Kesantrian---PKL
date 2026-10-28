import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  // Ganti dengan IP laptop kamu di WiFi (cek lewat `ipconfig`, IPv4 Address WiFi).
  // Bisa juga di-override saat build:
  // flutter build apk --release --dart-define=API_URL=http://192.168.1.10:3000
  static const String _lanUrl = 'http://192.168.100.92:3000';

  static const String _envUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return _lanUrl;
    return 'http://localhost:3000';
  }

  static const apiPrefix = '/api';
}