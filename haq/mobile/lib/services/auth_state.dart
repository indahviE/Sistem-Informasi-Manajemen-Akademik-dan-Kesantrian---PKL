import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthState extends ChangeNotifier {
  final ApiClient api;
  bool _initialized = false;
  bool get initialized => _initialized;

  String? _accessToken;
  String? _refreshToken;
  UserData? _user;
  bool? _isWeb;
  Color? _brandingColor;
  String? _brandingLogo;

  UserData? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get accessToken => _accessToken;
  bool get isWeb => _isWeb ?? false;
  Color? get brandingColor => _brandingColor;
  String? get brandingLogo => _brandingLogo;

  AuthState(this.api);

  Future<void> init({required bool isWeb}) async {
    _isWeb = isWeb;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    final u = prefs.getString('user');
    if (u != null) {
      try {
        _user = UserData.fromJson(jsonDecode(u));
      } catch (_) {
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<LoginResult> login(String kodeTenant, String email, String password) async {
    final body = {
      'email': email,
      'password': password,
      if (kodeTenant.isNotEmpty) 'kodeTenant': kodeTenant,
    };
    final res = await api.postPublic(ApiUrl.authLogin, body);
    final result = LoginResult.fromJson(res as Map<String, dynamic>);
    await _persist(result.accessToken, result.refreshToken, result.user);
    await _loadBranding();
    notifyListeners();
    return result;
  }

  Future<void> _loadBranding() async {
    _brandingColor = null;
    _brandingLogo = null;
    final u = _user;
    if (u == null || u.isSuperAdmin) return;
    try {
      final res = await api.get(ApiUrl.brandingMe) as Map<String, dynamic>;
      final hex = res['warnaTema'] as String?;
      final logo = res['logoUrl'] as String?;
      if (hex != null && hex.isNotEmpty) {
        _brandingColor = Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
      }
      if (logo != null && logo.isNotEmpty) _brandingLogo = logo;
    } catch (_) {}
  }

  Future<void> refreshBranding() async {
    await _loadBranding();
    notifyListeners();
  }

  Future<void> _persist(String at, String rt, UserData user) async {
    _accessToken = at;
    _refreshToken = rt;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', at);
    await prefs.setString('refreshToken', rt);
    await prefs.setString('user', jsonEncode({
          'id': user.id,
          'nama': user.nama,
          'email': user.email,
          'role': user.role,
          'tenant': user.tenant,
        }));
  }

  Future<String?> getAccessToken() async {
    if (_accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
    }
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _refreshToken = prefs.getString('refreshToken');
    }
    return _refreshToken;
  }

  Future<Map<String, String>> refresh(String refreshToken) async {
    final res = await api.postPublic(ApiUrl.authRefresh, {'refreshToken': refreshToken});
    final m = res as Map<String, dynamic>;
    return {
      'accessToken': m['accessToken'] as String,
      'refreshToken': m['refreshToken'] as String,
    };
  }

  Future<void> saveTokens(String at, String rt) async {
    _accessToken = at;
    _refreshToken = rt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', at);
    await prefs.setString('refreshToken', rt);
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}