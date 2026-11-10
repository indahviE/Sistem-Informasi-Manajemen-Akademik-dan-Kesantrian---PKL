import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'api_client.dart' show ApiClient, ApiException;

part 'firestore/helpers.dart';
part 'firestore/absensi.dart';
part 'firestore/kelulusan.dart';
part 'firestore/notifikasi.dart';
part 'firestore/nilai.dart';
part 'firestore/tahfidz.dart';
part 'firestore/ujian.dart';
part 'firestore/rapor.dart';
part 'firestore/dashboard.dart';
part 'firestore/santri_kelas.dart';
part 'firestore/jurnal.dart';

/// Pengganti ApiClient (HTTP -> NestJS) dengan Firestore.
/// Method get/post/patch/put/delete dan path-nya SAMA dengan ApiClient lama,
/// jadi layar yang sudah ada tidak perlu diubah.
/// Modul lain (absensi, nilai, dst.) ditambah di _route() mengikuti pola di bawah.
class FirestoreApiClient extends ApiClient {
  // Turunan ApiClient supaya AuthState & layar lama tetap kompatibel.
  // Parameter super hanya pengisi; semua request dialihkan ke Firestore.
  FirestoreApiClient()
      : super(
          baseUrl: () => '',
          getAccessToken: () async => null,
          getRefreshToken: () async => null,
          refreshTokens: (_) async => {},
          saveTokens: (_, __) async {},
          clearTokens: () async {},
        );

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _me;

  /// Panggil saat logout.
  void clearCache() => _me = null;

  // ---------- antarmuka sama dengan ApiClient ----------
  @override
  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) =>
      _route('GET', path, query: query);
  @override
  Future<dynamic> post(String path, [dynamic body]) => _route('POST', path, body: body);
  @override
  Future<dynamic> patch(String path, [dynamic body]) => _route('PATCH', path, body: body);
  @override
  Future<dynamic> put(String path, [dynamic body]) => _route('PUT', path, body: body);
  @override
  Future<dynamic> delete(String path, {bool auth = true}) => _route('DELETE', path);

  @override
  Future<dynamic> postPublic(String path, [dynamic body]) =>
      throw ApiException(501, 'Login/endpoint publik belum dipindah ke Firebase: $path');

  // ---------- dasar ----------
  Future<Map<String, dynamic>> _user() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _me = null;
      throw ApiException(401, 'Sesi berakhir. Silakan login kembali.');
    }
    // Cache hanya dipakai kalau masih akun yang sama (aman saat ganti akun).
    if (_me != null && _me!['userId'] == uid) return _me!;
    final s = await _db.collection('users').doc(uid).get();
    if (!s.exists) throw ApiException(401, 'Akun tidak ditemukan.');
    return _me = {...s.data()!, 'userId': uid};
  }

  Future<String> _tid() async => (await _user())['tenantId'] as String;

  Future<DocumentReference<Map<String, dynamic>>> _ref(String col, [String? id]) async {
    final c = _db.collection('tenants').doc(await _tid()).collection(col);
    return id == null ? c.doc() : c.doc(id);
  }

  Future<CollectionReference<Map<String, dynamic>>> _col(String col) async =>
      _db.collection('tenants').doc(await _tid()).collection(col);

  Map<String, dynamic> _map(DocumentSnapshot<Map<String, dynamic>> s) => {'id': s.id, ...?s.data()};

  Future<List<Map<String, dynamic>>> _all(String col) async =>
      (await (await _col(col)).get()).docs.map(_map).toList();

  Future<Map<String, dynamic>> _must(String col, String id, String label) async {
    final s = await (await _ref(col, id)).get();
    if (!s.exists) throw ApiException(404, '$label tidak ditemukan.');
    return _map(s);
  }

  String _now() => DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> _body(dynamic b) => Map<String, dynamic>.from((b as Map?) ?? {});

  // ---------- validasi (pengganti class-validator di NestJS) ----------
  static const _allowed = {
    'santri': ['nis', 'nama', 'jenisKelamin', 'tanggalLahir', 'kelasId', 'asrama', 'waliId', 'tahunMasuk'],
    'santriUpdate': ['nama', 'jenisKelamin', 'tanggalLahir', 'kelasId', 'asrama', 'waliId'],
    'kelas': ['namaKelas', 'tingkat', 'waliKelasId', 'tahunAjaranId'],
    'mapel': ['namaMapel', 'kode', 'jenis', 'kkm'],
    'ustadz': ['nama', 'jenis', 'noHp'],
    'tahunAjaran': ['nama', 'aktif'],
  };
  static const _required = {
    'santri': ['nama', 'jenisKelamin', 'tahunMasuk'],
    'kelas': ['namaKelas', 'tingkat'],
    'mapel': ['namaMapel'],
    'ustadz': ['nama', 'jenis'],
    'tahunAjaran': ['nama'],
  };
  static const _pesan = {'nama': 'Nama', 'namaKelas': 'Nama kelas', 'tingkat': 'Tingkat', 'namaMapel': 'Nama mapel',
    'jenisKelamin': 'Jenis kelamin', 'tahunMasuk': 'Tahun masuk', 'jenis': 'Jenis'};

  /// Buang field di luar DTO, cek field wajib dan tipe/rentang nilainya.
  Map<String, dynamic> _clean(String kind, Map<String, dynamic> data, bool create) {
    final key = (!create && kind == 'santri') ? 'santriUpdate' : kind;
    final out = <String, dynamic>{
      for (final k in _allowed[key]!) if (data.containsKey(k)) k: data[k],
    };
    if (create) {
      for (final k in _required[kind] ?? const <String>[]) {
        final v = out[k];
        if (v == null || (v is String && v.trim().isEmpty)) {
          throw ApiException(400, '${_pesan[k] ?? k} wajib diisi');
        }
      }
    }
    for (final k in out.keys.toList()) {
      final v = out[k];
      if (v == null) continue;
      if (k == 'jenisKelamin' && v != 'L' && v != 'P') throw ApiException(400, 'Jenis kelamin harus L atau P');
      if (k == 'tanggalLahir' && (v is! String || DateTime.tryParse(v) == null)) {
        throw ApiException(400, 'Tanggal lahir tidak valid');
      }
      if (k == 'tahunMasuk') {
        if (v is! num || v != v.toInt()) throw ApiException(400, 'Tahun masuk harus angka');
        out[k] = v.toInt();
      }
      if (kind == 'ustadz' && k == 'jenis' && v != 'GURU' && v != 'MUSYRIF') {
        throw ApiException(400, 'Jenis harus GURU atau MUSYRIF');
      }
      if (k == 'kkm' && (v is! num || v < 0 || v > 100)) throw ApiException(400, 'KKM harus 0 sampai 100');
      if (k == 'aktif' && v is! bool) throw ApiException(400, 'Aktif harus true/false');
      if (k != 'tahunMasuk' && k != 'kkm' && k != 'aktif' && v is! String) {
        throw ApiException(400, '$k harus berupa teks');
      }
    }
    return out;
  }

  int _cmp(dynamic a, dynamic b) => (a ?? '').toString().toLowerCase().compareTo((b ?? '').toString().toLowerCase());

  // ---------- router ----------
  Future<dynamic> _route(String method, String path, {Map<String, String>? query, dynamic body}) async {
    final s = path.split('/').where((e) => e.isNotEmpty).toList();
    if (s.isEmpty) throw ApiException(404, 'Rute kosong.');
    final q = query ?? {};
    final id = s.length > 1 ? s[1] : null;

    try {
      switch (s[0]) {
        case 'santri':
          {
            final r = _routeSantri(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'kelas':
          {
            final r = _routeKelas(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'mapel':
          if (s.length == 1 && method == 'GET') {
            return (await _all('mapel'))..sort((a, b) => _cmp(a['namaMapel'], b['namaMapel']));
          }
          if (s.length == 1 && method == 'POST') return _create('mapel', _clean('mapel', _body(body), true));
          if (id != null && method == 'PATCH') return _update('mapel', id, _clean('mapel', _body(body), false), 'Mapel');
          if (id != null && method == 'DELETE') return _remove('mapel', id, 'Mapel');
          break;

        case 'tahun-ajaran':
          {
            final r = _routeTahunAjaran(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'ustadz':
          {
            final r = _routeUstadz(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'mengajar':
          {
            final r = _routeMengajar(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        // ===== A: USTADZ/MUDIR =====
        case 'absensi':
          {
            final r = _routeAbsensi(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'nilai':
          {
            final r = _routeNilai(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'tahfidz':
          {
            final r = _routeTahfidz(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'ujian':
          {
            final r = _routeUjian(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'remedial':
          {
            final r = _routeRemedial(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'rapor':
          {
            final r = _routeRapor(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'jurnal-mengajar':
          {
            final r = _routeJurnal(method, s, q, body);
            if (r != null) return await r;
          }
          break;  

        case 'kelulusan':
          {
            final r = _routeKelulusan(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'notifikasi':
          {
            final r = _routeNotifikasi(method, s, q, body);
            if (r != null) return await r;
          }
          break;

        case 'dashboard':
          {
            final r = _routeDashboard(method, s, q, body);
            if (r != null) return await r;
          }
          break;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw ApiException(403, 'Anda tidak punya akses untuk aksi ini.');
      throw ApiException(500, 'Firestore: ${e.message ?? e.code}');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('FirestoreApiClient error [$method $path]: $e');
      throw ApiException(500, 'Error: $e');
    }
    throw ApiException(501, 'Rute belum dipindah ke Firestore: $method $path');
  }

  // ---------- CRUD generik ----------
  Future<Map<String, dynamic>> _create(String col, Map<String, dynamic> data) async {
    final ref = await _ref(col);
    final doc = {...data, 'createdAt': _now()};
    await ref.set(doc);
    return {'id': ref.id, ...doc};
  }

  Future<Map<String, dynamic>> _update(String col, String id, Map<String, dynamic> data, String label) async {
    final ref = await _ref(col, id);
    if (!(await ref.get()).exists) throw ApiException(404, '$label tidak ditemukan.');
    await ref.update({...data, 'updatedAt': _now()});
    return _map(await ref.get());
  }

  Future<Map<String, dynamic>> _remove(String col, String id, String label) async {
    final ref = await _ref(col, id);
    if (!(await ref.get()).exists) throw ApiException(404, '$label tidak ditemukan.');
    await ref.delete();
    return {'message': '$label dihapus.'};
  }
}