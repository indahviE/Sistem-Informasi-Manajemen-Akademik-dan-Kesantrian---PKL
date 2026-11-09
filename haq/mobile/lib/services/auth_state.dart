import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_client.dart';

/// Versi Firebase: login lewat Firebase Auth, profil user di Firestore
/// (users/{uid}), warna/logo pondok di Firestore (tenants/{tenantId}).
///
/// Semua fungsi publik dipertahankan (login, logout, getAccessToken, refresh,
/// saveTokens, updateProfil, refreshBranding) supaya layar lain tidak perlu
/// diubah. Panggilan ke ApiClient untuk data lain baru diganti per modul.
class AuthState extends ChangeNotifier {
  final ApiClient api;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;
  bool get initialized => _initialized;

  UserData? _user;
  bool? _isWeb;
  Color? _brandingColor;
  String? _brandingLogo;

  UserData? get user => _user;
  bool get isLoggedIn => _user != null;
  // Token Firebase tidak disimpan di sini; ambil lewat getAccessToken().
  String? get accessToken => null;
  bool get isWeb => _isWeb ?? false;
  Color? get brandingColor => _brandingColor;
  String? get brandingLogo => _brandingLogo;

  AuthState(this.api);

  Future<void> init({required bool isWeb}) async {
    _isWeb = isWeb;
    // Tunggu Firebase selesai memulihkan sesi login sebelumnya (kalau ada).
    final fbUser = await _auth.authStateChanges().first;
    if (fbUser != null) {
      try {
        _user = await _loadUser(fbUser.uid);
      } catch (e) {
        debugPrint('Gagal muat profil: $e');
        await _auth.signOut();
        _user = null;
      }
    }
    if (_user != null) await _loadBranding();
    _initialized = true;
    notifyListeners();
  }

  /// Baca users/{uid} lalu ubah ke UserData (bentuk sama seperti dulu).
  Future<UserData> _loadUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final d = snap.data();
    if (!snap.exists || d == null) {
      throw ApiException(403, 'Akun belum terdaftar di sistem. Hubungi admin.');
    }
    if ((d['status'] ?? 'AKTIF') != 'AKTIF') {
      throw ApiException(403, 'Akun tidak aktif. Hubungi admin.');
    }
    // 'tenant' berisi salinan ringkas: id, kodeTenant, namaPondok, status.
    return UserData.fromJson({
      'id': uid,
      'nama': d['nama'] ?? '',
      'email': d['email'] ?? '',
      'role': d['role'] ?? '',
      'tenant': d['tenant'],
      'waliKelasIds': d['waliKelasIds'] ?? [],
    });
  }

  Future<LoginResult> login(String kodeTenant, String email, String password) async {
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw ApiException(401, _pesanAuth(e));
    }

    UserData u;
    try {
      u = await _loadUser(cred.user!.uid);
      // Kode pondok (kalau diisi) harus cocok dengan pondok milik akun.
      final kode = (u.tenant?['kodeTenant'] as String?) ?? '';
      if (kodeTenant.isNotEmpty && kode.toLowerCase() != kodeTenant.trim().toLowerCase()) {
        throw ApiException(401, 'Kode pondok tidak sesuai dengan akun ini.');
      }
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }

    _user = u;
    await _loadBranding();
    notifyListeners();
    final token = await cred.user!.getIdToken() ?? '';
    return LoginResult(accessToken: token, refreshToken: '', user: u);
  }

  String _pesanAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Email atau kata sandi salah.';
      case 'user-disabled':
        return 'Akun dinonaktifkan. Hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung ke server. Periksa jaringan Anda.';
      default:
        return 'Gagal masuk (${e.code}).';
    }
  }

  Future<void> _loadBranding() async {
    _brandingColor = null;
    _brandingLogo = null;
    final u = _user;
    if (u == null || u.isSuperAdmin) return;
    final tenantId = u.tenant?['id'] as String?;
    if (tenantId == null) return;
    try {
      final snap = await _db.collection('tenants').doc(tenantId).get();
      final d = snap.data();
      if (d == null) return;
      final hex = d['warnaTema'] as String?;
      final logo = d['logoUrl'] as String?;
      if (hex != null && hex.isNotEmpty) {
        _brandingColor = Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
      }
      if (logo != null && logo.isNotEmpty) _brandingLogo = logo;
    } catch (e) {
      debugPrint('Gagal muat branding: $e');
    }
  }

  Future<void> refreshBranding() async {
    await _loadBranding();
    notifyListeners();
  }

  // Token sekarang dikelola Firebase. Fungsi di bawah dipertahankan agar
  // ApiClient lama (yang belum dimigrasi) tetap bisa dikompilasi.
  Future<String?> getAccessToken() async => _auth.currentUser?.getIdToken();

  Future<String?> getRefreshToken() async => '';

  Future<Map<String, String>> refresh(String refreshToken) async {
    final t = await _auth.currentUser?.getIdToken(true);
    return {'accessToken': t ?? '', 'refreshToken': ''};
  }

  Future<void> saveTokens(String at, String rt) async {
    // Tidak ada yang perlu disimpan: Firebase menyimpan sesi sendiri.
  }

  Future<void> updateProfil({required String nama, required String email}) async {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(nama: nama, email: email);
    try {
      // Hanya nama yang disimpan ke Firestore. Ganti email butuh alur
      // tersendiri di Firebase Auth (belum dikerjakan).
      await _db.collection('users').doc(current.id).update({'nama': nama});
    } catch (e) {
      debugPrint('Gagal simpan profil: $e');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _brandingColor = null;
    _brandingLogo = null;
    await _auth.signOut();
    notifyListeners();
  }
}