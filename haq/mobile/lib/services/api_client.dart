import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

typedef AuthProvider = Future<Map<String, String>> Function(); // headers auth

class ApiClient {
  final String Function() baseUrl;
  final Future<String?> Function() getAccessToken;
  final Future<String?> Function() getRefreshToken;
  final Future<Map<String, String>> Function(String refreshToken) refreshTokens;
  final Future<void> Function(String accessToken, String refreshToken) saveTokens;
  final Future<void> Function() clearTokens;

  ApiClient({
    required this.baseUrl,
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.refreshTokens,
    required this.saveTokens,
    required this.clearTokens,
  });

  Uri _uri(String path, [Map<String, String>? query]) {
    final q = query;
    q?.removeWhere((k, v) => v == null || v.isEmpty);
    return Uri.parse('${baseUrl()}${ApiUrl.prefix}$path').replace(queryParameters: q == null || q.isEmpty ? null : q);
  }

  Map<String, String> _jsonHeaders([Map<String, String>? extra]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?extra,
      };

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, [dynamic body]) => _send('POST', path, body: body, auth: true);

  Future<dynamic> patch(String path, [dynamic body]) => _send('PATCH', path, body: body, auth: true);

  Future<dynamic> put(String path, [dynamic body]) => _send('PUT', path, body: body, auth: true);

  Future<dynamic> delete(String path, {bool auth = true}) => _send('DELETE', path, auth: auth);

  Future<dynamic> postPublic(String path, [dynamic body]) => _send('POST', path, body: body, auth: false);

  Future<dynamic> _send(String method, String path,
      {dynamic body, Map<String, String>? query, bool auth = true}) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      var headers = _jsonHeaders();
      if (auth) {
        final token = await getAccessToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
      }

      http.Response res;
      final uri = _uri(path, query);
      try {
        switch (method) {
          case 'GET':
            res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
            break;
          case 'POST':
            res = await http
                .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
                .timeout(const Duration(seconds: 20));
            break;
          case 'PATCH':
            res = await http
                .patch(uri, headers: headers, body: body == null ? null : jsonEncode(body))
                .timeout(const Duration(seconds: 20));
            break;
          case 'PUT':
            res = await http
                .put(uri, headers: headers, body: body == null ? null : jsonEncode(body))
                .timeout(const Duration(seconds: 20));
            break;
          default:
            res = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
        }
      } catch (e) {
        throw ApiException(0, 'Tidak dapat terhubung ke server. Periksa jaringan Anda.');
      }

      // Coba refresh sekali saat 401
      if (res.statusCode == 401 && auth && attempt == 0) {
        final rt = await getRefreshToken();
        if (rt != null) {
          try {
            final t = await refreshTokens(rt);
            await saveTokens(t['accessToken']!, t['refreshToken']!);
            continue;
          } catch (_) {
            await clearTokens();
            throw ApiException(401, 'Sesi berakhir. Silakan login kembali.');
          }
        }
        throw ApiException(401, 'Sesi berakhir. Silakan login kembali.');
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) return null;
        return jsonDecode(res.body);
      }

      throw _toError(res);
    }
    throw ApiException(0, 'Gagal memproses permintaan.');
  }

  ApiException _toError(http.Response res) {
    var message = 'Terjadi kesalahan (${res.statusCode}).';
    try {
      final d = jsonDecode(res.body);
      if (d is Map && d['message'] != null) {
        message = d['message'].toString();
      }
    } catch (_) {}
    return ApiException(res.statusCode, message);
  }
}

class ApiUrl {
  ApiUrl._();
  static const prefix = '/api';

  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const dashboard = '/dashboard';
  static const tenantSignup = '/tenants/signup';
  static const tenants = '/tenants';
  static const tenantApprove = '/tenants/approve';
  static const tenantSuspend = '/tenants/suspend';
  static const tenantArchive = '/tenants/archive';
  static const tenantUnarchive = '/tenants/unarchive';
  static const tenantDeletePending = '/tenants/delete-pending';
  static const users = '/users';
  static const santri = '/santri';
  static const ustadz = '/ustadz';
  static const kelas = '/kelas';
  static const mapel = '/mapel';
  static const absensi = '/absensi';
  static const nilai = '/nilai';
  static const tahfidz = '/tahfidz';
  static const pelanggaran = '/pelanggaran';
  static const perizinan = '/perizinan';
  static const kesehatan = '/kesehatan';
  static const kunjungan = '/kunjungan';
  static const tataTertib = '/tata-tertib';
  static const notifikasi = '/notifikasi';
  static const notifikasiUnreadCount = '/notifikasi/unread-count';
  static const wali = '/wali';
  static const waliMe = '/wali/me';

  static const ppdb = '/ppdb';
  static const ppdbDaftar = '/ppdb/daftar';
  static const branding = '/tenants/branding';
  static const ppdbLookup = '/ppdb/lookup';
  static const brandingMe = '/tenants/branding/me';
  static const kurikulum = '/kurikulum';
  static const silabus = '/silabus';
  static const rpp = '/rpp';
  static const rekamMedis = '/rekam-medis';
  static const paket = '/paket';
  static const subscriptions = '/subscriptions';
  static const invoices = '/invoices';

  static const ujian = '/ujian';
  static const remedial = '/remedial';
  static const rapor = '/rapor';
  static const raporGenerate = '/rapor/generate';
  static const kelulusan = '/kelulusan';
  static const konseling = '/konseling';

  static const pembinaanKarakter = '/pembinaan-karakter';
  static const pembinaanIbadah = '/pembinaan-ibadah';
  static const keadaanDarurat = '/keadaan-darurat';

  static const tenantSlugCheck = '/tenants/check-slug'; 

  static const auditLog = '/audit-log';
  static const pengaturan = '/pengaturan';
  static const pengaturanProfil = '/pengaturan/profil';
  static const pengaturanUbahPassword = '/pengaturan/ubah-password';
  static const pengaturanKebijakanOnboarding = '/pengaturan/kebijakan-onboarding';
  static const pengaturanNotifikasi = '/pengaturan/notifikasi';
  static const pengaturanSubAdmin = '/pengaturan/sub-admin';
  static String pengaturanSubAdminDelete(String id) => '/pengaturan/sub-admin/$id';
}