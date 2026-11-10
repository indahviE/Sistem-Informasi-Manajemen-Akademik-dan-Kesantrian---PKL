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
          if (s.length == 1 && method == 'GET') return _santriList(q);
          if (s.length == 1 && method == 'POST') return _santriCreate(_clean('santri', _body(body), true));
          if (id != null && method == 'GET') return _santriOne(id);
          if (id != null && method == 'PATCH') return _update('santri', id, _clean('santri', _body(body), false), 'Santri');
          if (id != null && method == 'DELETE') return _santriRemove(id);
          break;

        case 'kelas':
          if (s.length == 1 && method == 'GET') return _kelasList(q['diampu'] == 'true');
          if (id != null && s.length == 2 && method == 'GET') return _kelasDetail(id);
          if (s.length == 1 && method == 'POST') return _kelasCreate(_clean('kelas', _body(body), true));
          if (id != null && method == 'PATCH') return _kelasUpdate(id, _clean('kelas', _body(body), false));
          if (id != null && method == 'DELETE') return _kelasRemove(id);
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
          if (s.length == 1 && method == 'GET') {
            return (await _all('tahunAjaran'))..sort((a, b) => _cmp(b['nama'], a['nama']));
          }
          if (s.length == 1 && method == 'POST') return _taCreate(_clean('tahunAjaran', _body(body), true));
          if (id == 'aktif' && method == 'GET') return _taAktif();
          if (id != null && s.length == 3 && s[2] == 'aktif' && method == 'POST') return _taSetAktif(id);
          break;

        case 'ustadz':
          if (s.length == 1 && method == 'GET') return _ustadzList(q['jenis']);
          if (s.length == 1 && method == 'POST') return _create('ustadz', _clean('ustadz', _body(body), true));
          if (id != null && s.length == 2 && method == 'PATCH') return _update('ustadz', id, _clean('ustadz', _body(body), false), 'Ustadz');
          if (id != null && s.length == 2 && method == 'DELETE') return _ustadzRemove(id);
          if (id != null && s.length == 3 && s[2] == 'mengajar') {
            if (method == 'GET') return _mengajarList(id);
            if (method == 'POST') return _mengajarAdd(id, _body(body));
          }
          break;

        case 'mengajar':
          if (id == 'saya' && method == 'GET') return _mengajarSaya();
          if (id != null && method == 'DELETE') return _mengajarRemove(id);
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
          if (s.length == 1 && method == 'GET') return _raporList(q);
          if (id == 'santri' && method == 'GET') return _raporSantri();
          if (id == 'generate' && method == 'POST') return _raporGenerate(_body(body));
          if (id != null && s.length == 3 && s[2] == 'terbit' && method == 'PATCH') return _raporTerbit(id);
          if (id != null && s.length == 2 && method == 'GET') return _raporOne(id);
          if (id != null && s.length == 2 && method == 'DELETE') return _raporRemove(id);
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
          if (s.length == 1 && method == 'GET') return _dashboard();
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

  // ---------- SANTRI ----------
  // Query sesuai QuerySantriDto: kelasId, search, binaan, page, perPage.
  Future<Map<String, dynamic>> _santriList(Map<String, String> q) async {
    final me = await _user();
    var list = await _all('santri');

    // Santri yang sudah KELUAR tidak ikut daftar biasa.
    list = list.where((x) => x['status'] != 'KELUAR').toList();

    // binaan=true: hanya santri di kelas yang diampu ustadz yang login.
    if (q['binaan'] == 'true' && (me['role'] == 'USTADZ' || me['role'] == 'MUSYRIF')) {
      final ids = List<String>.from(me['kelasIds'] ?? const []);
      list = list.where((x) => ids.contains(x['kelasId'])).toList();
    }
    final kelasId = q['kelasId'];
    if (kelasId != null && kelasId.isNotEmpty) list = list.where((x) => x['kelasId'] == kelasId).toList();
    final cari = (q['search'] ?? '').toLowerCase();
    if (cari.isNotEmpty) {
      list = list.where((x) => '${x['nama']} ${x['nis']}'.toLowerCase().contains(cari)).toList();
    }
    list.sort((a, b) => _cmp(a['nama'], b['nama']));

    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final perPage = int.tryParse(q['perPage'] ?? '') ?? 20;
    final start = (page - 1) * perPage;
    final pageRows = start >= list.length ? <Map<String, dynamic>>[] : list.skip(start).take(perPage).toList();
    final items = await _santriJoin(pageRows);
    return {'items': items, 'total': list.length, 'page': page, 'perPage': perPage};
  }

  /// Sertakan objek kelas & wali (seperti `include` Prisma) supaya layar lama tetap benar.
  Future<List<Map<String, dynamic>>> _santriJoin(List<Map<String, dynamic>> rows) async {
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final wali = {for (final w in await _all('wali')) w['id']: w};
    return rows.map((r) {
      final k = kelas[r['kelasId']];
      final w = wali[r['waliId']];
      return {
        ...r,
        'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas'], 'tingkat': k['tingkat']},
        'wali': w == null ? null : {'id': w['id'], 'nama': w['nama'], 'noHp': w['noHp']},
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _santriOne(String id) async =>
      (await _santriJoin([await _must('santri', id, 'Santri')])).first;

  Future<Map<String, dynamic>> _santriCreate(Map<String, dynamic> data) async {
    final tid = await _tid();
    final nis = (data['nis'] as String?)?.trim();
    final santriCol = _db.collection('tenants').doc(tid).collection('santri');

    return _db.runTransaction((tx) async {
      // Aturan Firestore: SEMUA baca dulu, baru tulis.
      String finalNis;
      DocumentReference<Map<String, dynamic>>? cRef;
      var n = 0;
      if (nis != null && nis.isNotEmpty) {
        finalNis = nis;
      } else {
        // NIS otomatis: 20260001, 20260002, ...
        final year = DateTime.now().year;
        cRef = _db.collection('tenants').doc(tid).collection('counters').doc('santri_$year');
        final c = await tx.get(cRef);
        n = ((c.data()?['n'] as num?)?.toInt() ?? 0) + 1;
        finalNis = '$year${n.toString().padLeft(4, '0')}';
      }
      final ref = santriCol.doc(finalNis); // ID = NIS -> duplikat otomatis terdeteksi
      if ((await tx.get(ref)).exists) throw ApiException(409, 'NIS $finalNis sudah terdaftar.');
      if (cRef != null) tx.set(cRef, {'n': n});
      final doc = {
        ...data,
        'nis': finalNis,
        'status': data['status'] ?? 'AKTIF',
        'createdAt': _now(),
      };
      tx.set(ref, doc);
      return {'id': finalNis, ...doc};
    });
  }

  // Tidak ada cascade di Firestore -> santri tidak dihapus, hanya status KELUAR.
  Future<Map<String, dynamic>> _santriRemove(String id) async {
    await _update('santri', id, {'status': 'KELUAR'}, 'Santri');
    return {'message': 'Santri dinonaktifkan (status KELUAR).'};
  }

  // ---------- KELAS ----------
  Future<List<Map<String, dynamic>>> _kelasList(bool diampu) async {
    final me = await _user();
    var list = await _all('kelas');
    if (diampu && me['role'] == 'USTADZ') {
      final ids = List<String>.from(me['kelasIds'] ?? const []);
      list = list.where((k) => ids.contains(k['id'])).toList();
    }

    // Ustadz/Musyrif hanya boleh membaca dokumen ustadz miliknya sendiri (lihat rules),
    // jadi seluruh koleksi hanya dibaca untuk ADMIN/PIMPINAN.
    final ustadz = <dynamic, Map<String, dynamic>>{};
    if (me['role'] == 'ADMIN' || me['role'] == 'PIMPINAN') {
      for (final u in await _all('ustadz')) {
        ustadz[u['id']] = u;
      }
    } else if (me['ustadzId'] != null) {
      final s = await (await _ref('ustadz', me['ustadzId'] as String)).get();
      if (s.exists) ustadz[s.id] = _map(s);
    }
    final ta = {for (final t in await _all('tahunAjaran')) t['id']: t};
    final santri = await _all('santri');
    final jumlah = <String, int>{};
    for (final s in santri) {
      final k = s['kelasId'];
      if (k != null) jumlah[k] = (jumlah[k] ?? 0) + 1;
    }

    final out = list.map((k) {
      final w = ustadz[k['waliKelasId']];
      final t = ta[k['tahunAjaranId']];
      return {
        ...k,
        'waliKelas': w == null ? null : {'id': w['id'], 'nama': w['nama']},
        'tahunAjaran': t == null ? null : {'id': t['id'], 'nama': t['nama']},
        '_count': {'santris': jumlah[k['id']] ?? 0},
      };
    }).toList();
    out.sort((a, b) => _cmp(a['tingkat'], b['tingkat']));
    return out;
  }

  Future<void> _cekWaliKelas(String? waliId) async {
    if (waliId == null || waliId.isEmpty) return;
    final s = await (await _ref('ustadz', waliId)).get();
    if (!s.exists) throw ApiException(404, 'Ustadz untuk wali kelas tidak ditemukan.');
  }

  Future<Map<String, dynamic>> _kelasCreate(Map<String, dynamic> data) async {
    await _cekWaliKelas(data['waliKelasId'] as String?);
    var taId = data['tahunAjaranId'];
    if (taId == null) taId = (await _taAktif())['id']; // default: tahun ajaran aktif
    final k = await _create('kelas', {...data, 'tahunAjaranId': taId});
    if (k['waliKelasId'] != null) await _syncKelasIds(k['waliKelasId']);
    return k;
  }

  Future<Map<String, dynamic>> _kelasUpdate(String id, Map<String, dynamic> data) async {
    final lama = await _must('kelas', id, 'Kelas');
    await _cekWaliKelas(data['waliKelasId'] as String?);
    final k = await _update('kelas', id, data, 'Kelas');
    for (final u in {lama['waliKelasId'], k['waliKelasId']}) {
      if (u != null) await _syncKelasIds(u as String);
    }
    return k;
  }

  Future<Map<String, dynamic>> _kelasRemove(String id) async {
    final k = await _must('kelas', id, 'Kelas');
    final masihAda = await (await _col('santri')).where('kelasId', isEqualTo: id).limit(1).get();
    if (masihAda.docs.isNotEmpty) {
      throw ApiException(400, 'Kelas masih punya santri. Pindahkan santri dulu.');
    }
    await (await _ref('kelas', id)).delete();
    if (k['waliKelasId'] != null) await _syncKelasIds(k['waliKelasId'] as String);
    return {'message': 'Kelas dihapus.'};
  }

  // ---------- TAHUN AJARAN ----------
  Future<Map<String, dynamic>> _taAktif() async {
    final list = (await _all('tahunAjaran')).where((t) => t['aktif'] == true).toList()
      ..sort((a, b) => _cmp(b['nama'], a['nama']));
    if (list.isEmpty) return {'id': null, 'nama': null};
    return {'id': list.first['id'], 'nama': list.first['nama']};
  }

  Future<Map<String, dynamic>> _taCreate(Map<String, dynamic> data) async {
    final aktif = data['aktif'] ?? true;
    final ref = await _ref('tahunAjaran');
    final col = await _col('tahunAjaran');
    final batch = _db.batch();
    if (aktif == true) {
      for (final d in (await col.where('aktif', isEqualTo: true).get()).docs) {
        batch.update(d.reference, {'aktif': false});
      }
    }
    final doc = {...data, 'aktif': aktif, 'createdAt': _now()};
    batch.set(ref, doc);
    await batch.commit();
    return {'id': ref.id, ...doc};
  }

  Future<Map<String, dynamic>> _taSetAktif(String id) async {
    await _must('tahunAjaran', id, 'Tahun ajaran');
    final col = await _col('tahunAjaran');
    final batch = _db.batch();
    for (final d in (await col.get()).docs) {
      batch.update(d.reference, {'aktif': d.id == id});
    }
    await batch.commit();
    return {'message': 'Tahun ajaran aktif diperbarui.'};
  }

  // ---------- USTADZ & MENGAJAR ----------
  Future<List<Map<String, dynamic>>> _ustadzList(String? jenis) async {
    var list = await _all('ustadz');
    if (jenis != null && jenis.isNotEmpty) list = list.where((u) => u['jenis'] == jenis).toList();
    final kelas = await _all('kelas');
    final out = list.map((u) => {
          ...u,
          'kelasDiampu': kelas
              .where((k) => k['waliKelasId'] == u['id'])
              .map((k) => {'id': k['id'], 'namaKelas': k['namaKelas']})
              .toList(),
          'akun': null, // TODO: isi dari users/{userId} bila layar butuh email/status
        }).toList();
    out.sort((a, b) => _cmp(a['nama'], b['nama']));
    return out;
  }

  Future<Map<String, dynamic>> _ustadzRemove(String id) async {
    await _remove('ustadz', id, 'Ustadz');
    final m = await (await _col('mengajar')).where('ustadzId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final d in m.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    return {'message': 'Ustadz dihapus.'};
  }

  Future<List<Map<String, dynamic>>> _mengajarList(String ustadzId) async {
    await _must('ustadz', ustadzId, 'Ustadz');
    final rows = (await (await _col('mengajar')).where('ustadzId', isEqualTo: ustadzId).get())
        .docs
        .map(_map)
        .toList();
    return _mengajarDetail(rows);
  }

  Future<List<Map<String, dynamic>>> _mengajarDetail(List<Map<String, dynamic>> rows) async {
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    return rows
        .map((r) => {
              ...r,
              'kelas': kelas[r['kelasId']] == null
                  ? null
                  : {'id': r['kelasId'], 'namaKelas': kelas[r['kelasId']]!['namaKelas']},
              'mapel': mapel[r['mapelId']] == null
                  ? null
                  : {'id': r['mapelId'], 'namaMapel': mapel[r['mapelId']]!['namaMapel']},
            })
        .toList()
      ..sort((a, b) => _cmp(a['createdAt'], b['createdAt']));
  }

  Future<Map<String, dynamic>> _mengajarAdd(String ustadzId, Map<String, dynamic> dto) async {
    final kelasId = dto['kelasId'] as String?;
    final mapelId = dto['mapelId'] as String?;
    if (kelasId == null || mapelId == null) throw ApiException(400, 'kelasId dan mapelId wajib diisi.');
    await _must('ustadz', ustadzId, 'Ustadz');
    await _must('kelas', kelasId, 'Kelas');
    await _must('mapel', mapelId, 'Mata pelajaran');

    // ID tetap = pengganti unique + upsert: menambah dua kali tetap satu dokumen
    final id = '${ustadzId}_${kelasId}_$mapelId';
    final ref = await _ref('mengajar', id);
    if (!(await ref.get()).exists) {
      await ref.set({'ustadzId': ustadzId, 'kelasId': kelasId, 'mapelId': mapelId, 'createdAt': _now()});
    }
    await _syncKelasIds(ustadzId);
    return (await _mengajarDetail([_map(await ref.get())])).first;
  }

  Future<Map<String, dynamic>> _mengajarRemove(String id) async {
    final row = await _must('mengajar', id, 'Penugasan');
    await (await _ref('mengajar', id)).delete();
    await _syncKelasIds(row['ustadzId'] as String);
    return {'message': 'Penugasan dihapus.'};
  }

  Future<List<Map<String, dynamic>>> _mengajarSaya() async {
    final me = await _user();
    final uid = me['ustadzId'];
    if (uid == null) return [];
    final rows = await (await _col('mengajar')).where('ustadzId', isEqualTo: uid).get();
    return rows.docs.map((d) => {'kelasId': d['kelasId'], 'mapelId': d['mapelId']}).toList();
  }

  /// Simpan daftar kelas yang diampu langsung di dokumen user ustadz
  /// (wali kelas + kelas dari penugasan mengajar), supaya rules & query tidak perlu join.
  Future<void> _syncKelasIds(String ustadzId) async {
    final u = await (await _ref('ustadz', ustadzId)).get();
    final userId = u.data()?['userId'] as String?;
    if (userId == null) return;
    final ids = <String>{};
    for (final d in (await (await _col('mengajar')).where('ustadzId', isEqualTo: ustadzId).get()).docs) {
      ids.add(d['kelasId'] as String);
    }
    for (final d in (await (await _col('kelas')).where('waliKelasId', isEqualTo: ustadzId).get()).docs) {
      ids.add(d.id);
    }
    await _db.collection('users').doc(userId).update({'kelasIds': ids.toList()});
  }

  // ===== RAPOR =====
  // Koleksi: tenants/{tid}/rapor, ID = {santriId}_{periode}
  static const _jenisRapor = ['HARIAN', 'ULANGAN', 'TAHFIDZ', 'BAHASA_ARAB'];
  static const _bobotHarian = 0.5;
  static const _bobotUjian = 0.5;

  String _raporId(String santriId, String periode) =>
      '${santriId}_${periode.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}';

  double _r1(double x) => double.parse(x.toStringAsFixed(1));

  /// "2026/2027 - Ganjil" -> (gte, lt) berupa 'YYYY-MM-DD'. Format lain = null (tidak menyaring).
  (String, String)? _rentang(String periode) {
    final m = RegExp(r'(\d{4})\s*/\s*(\d{4})\s*-\s*(Ganjil|Genap)', caseSensitive: false).firstMatch(periode);
    if (m == null) return null;
    final awal = m.group(1)!;
    final akhir = m.group(2)!;
    return m.group(3)!.toLowerCase() == 'ganjil'
        ? ('$awal-07-01', '$akhir-01-01')
        : ('$akhir-01-01', '$akhir-07-01');
  }

  bool _dalam(dynamic t, (String, String)? r) {
    if (r == null) return true;
    final s = t?.toString();
    if (s == null || s.length < 10) return false;
    final d = s.substring(0, 10);
    return d.compareTo(r.$1) >= 0 && d.compareTo(r.$2) < 0;
  }

  /// Kelas yang dijadikan wali kelas oleh ustadz yang login.
  Future<List<String>> _kelasWali(Map<String, dynamic> me) async {
    final uid = me['ustadzId'] as String?;
    if (uid == null) return [];
    final rows = await (await _col('kelas')).where('waliKelasId', isEqualTo: uid).get();
    return rows.docs.map((d) => d.id).toList();
  }

  /// Ustadz hanya boleh menyentuh rapor santri di kelas yang ia walikan.
  Future<void> _waliKelasSantri(Map<String, dynamic> me, Map<String, dynamic> santri) async {
    if (me['role'] != 'USTADZ') return;
    final kelas = await _kelasWali(me);
    if (santri['kelasId'] == null || !kelas.contains(santri['kelasId'])) {
      throw ApiException(403, 'Anda bukan wali kelas santri ini.');
    }
  }

  Future<List<Map<String, dynamic>>> _raporJoin(List<Map<String, dynamic>> rows) async {
    final me = await _user();
    Map<dynamic, Map<String, dynamic>> santri;
    Map<dynamic, Map<String, dynamic>> kelas = {};
    if (me['role'] == 'WALI_SANTRI') {
      // Wali hanya boleh membaca dokumen anaknya; koleksi kelas tidak dibaca (nama kelas kosong)
      final ids = {for (final r in rows) r['santriId'] as String};
      final docs = await Future.wait(ids.map((id) async => (await _ref('santri', id)).get()));
      santri = {for (final d in docs) if (d.exists) d.id: _map(d)};
    } else {
      santri = {for (final s in await _all('santri')) s['id']: s};
      kelas = {for (final k in await _all('kelas')) k['id']: k};
    }
    return rows.map((r) {
      final s = santri[r['santriId']];
      final k = s == null ? null : kelas[s['kelasId']];
      return {
        ...r,
        'santri': s == null
            ? null
            : {
                'id': s['id'],
                'nama': s['nama'],
                'nis': s['nis'],
                'kelasId': s['kelasId'],
                'kelas': k == null ? null : {'namaKelas': k['namaKelas']},
              },
      };
    }).toList();
  }

  // GET /rapor/santri
  Future<List<Map<String, dynamic>>> _raporSantri() async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ']);
    var list = (await _all('santri')).where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF').toList();
    if (me['role'] == 'USTADZ') {
      final kelasWali = await _kelasWali(me);
      list = list.where((s) => kelasWali.contains(s['kelasId'])).toList();
    }
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final out = list.map((s) {
      final k = kelas[s['kelasId']];
      return {
        'id': s['id'],
        'nama': s['nama'],
        'nis': s['nis'],
        'kelasId': s['kelasId'],
        'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
      };
    }).toList();
    out.sort((a, b) => _cmp(a['nama'], b['nama']));
    return out;
  }

  // GET /rapor?santriId&periode
  Future<List<Map<String, dynamic>>> _raporList(Map<String, String> q) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'WALI_SANTRI']);

    List<Map<String, dynamic>> rows;
    if (me['role'] == 'WALI_SANTRI') {
      // Wali: baca per anak, hanya yang TERBIT (rules tidak mengizinkan baca seluruh koleksi)
      final anak = List<String>.from(me['santriIds'] ?? const []);
      final target = _nn(q['santriId']) != null ? anak.where((a) => a == q['santriId']).toList() : anak;
      final col = await _col('rapor');
      final hasil = await Future.wait(target.map((id) async => (await col
              .where('santriId', isEqualTo: id)
              .where('status', isEqualTo: 'TERBIT')
              .get())
          .docs
          .map(_map)
          .toList()));
      rows = hasil.expand((e) => e).toList();
    } else {
      rows = await _all('rapor');
      if (_nn(q['santriId']) != null) rows = rows.where((r) => r['santriId'] == q['santriId']).toList();
    }
    if (_nn(q['periode']) != null) rows = rows.where((r) => r['periode'] == q['periode']).toList();

    if (me['role'] == 'USTADZ') {
      final kelasWali = await _kelasWali(me);
      final santri = {for (final s in await _all('santri')) s['id']: s};
      rows = rows.where((r) => kelasWali.contains(santri[r['santriId']]?['kelasId'])).toList();
    }
    rows.sort((a, b) => _cmp(b['periode'], a['periode']));
    return _raporJoin(rows);
  }

  // GET /rapor/:id
  Future<Map<String, dynamic>> _raporOne(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'WALI_SANTRI']);
    final r = await _must('rapor', id, 'Rapor');
    if (me['role'] == 'WALI_SANTRI') {
      final anak = List<String>.from(me['santriIds'] ?? const []);
      if (r['status'] != 'TERBIT' || !anak.contains(r['santriId'])) {
        throw ApiException(404, 'Rapor tidak ditemukan.');
      }
    }
    final santri = await _must('santri', r['santriId'] as String, 'Santri');
    await _waliKelasSantri(me, santri);
    return (await _raporJoin([r])).first;
  }

  // POST /rapor/generate { santriId, periode, status? }
  Future<Map<String, dynamic>> _raporGenerate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final santriId = _nn(d['santriId']);
    final periode = _nn(d['periode']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    if (periode == null) throw ApiException(400, 'Periode wajib diisi');
    final santri = await _must('santri', santriId, 'Santri');
    await _waliKelasSantri(me, santri);

    // Rapor yang sudah terbit tidak boleh tertimpa
    final ref = await _ref('rapor', _raporId(santriId, periode));
    final lama = (await ref.get()).data();
    if (lama?['status'] == 'TERBIT') {
      throw ApiException(409, 'Rapor periode ini sudah diterbitkan dan tidak dapat digenerate ulang.');
    }
    final r = _rentang(periode);

    // Nilai non-ujian: rata-rata per mapel dalam periode
    final nilaiRows = (await (await _col('nilai')).where('santriId', isEqualTo: santriId).get())
        .docs
        .map(_map)
        .where((n) => _jenisRapor.contains(n['jenis']) && n['nilai'] is num && _dalam(n['tanggal'], r));
    final harianList = <String, List<double>>{};
    for (final n in nilaiRows) {
      harianList.putIfAbsent(n['mapelId'] as String, () => []).add((n['nilai'] as num).toDouble());
    }

    // Ujian dalam periode (periode cocok, atau tanggal di rentang, atau tanpa tanggal tapi dibuat di rentang)
    final ujian = {for (final u in await _all('ujian')) u['id']: u};
    bool ujianDalam(Map<String, dynamic> u) =>
        r == null ||
        u['periode'] == periode ||
        (u['tanggal'] != null ? _dalam(u['tanggal'], r) : _dalam(u['createdAt'], r));

    // Nilai ujian santri (hanya yang hadir dan sudah bernilai)
    final nilaiUjian = (await (await _col('nilaiUjian')).where('santriId', isEqualTo: santriId).get())
        .docs
        .map(_map)
        .where((n) =>
            n['status'] == 'HADIR' &&
            n['nilai'] is num &&
            ujian[n['ujianId']] != null &&
            ujianDalam(ujian[n['ujianId']]!))
        .toList();

    // Remedial: nilai akhir menggantikan nilai awal
    final remedial = (await (await _col('remedial')).where('santriId', isEqualTo: santriId).get()).docs.map(_map);
    final akhirMap = <String, double>{
      for (final x in remedial)
        if (x['ujianId'] != null && x['nilaiAkhir'] is num)
          x['ujianId'] as String: (x['nilaiAkhir'] as num).toDouble(),
    };

    final ujianPerMapel = <String, List<double>>{};
    for (final n in nilaiUjian) {
      final mid = ujian[n['ujianId']]!['mapelId'] as String?;
      if (mid == null) continue;
      ujianPerMapel.putIfAbsent(mid, () => []).add(akhirMap[n['ujianId']] ?? (n['nilai'] as num).toDouble());
    }

    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    double rata(List<double> a) => a.reduce((x, y) => x + y) / a.length;
    final semuaMapel = {...harianList.keys, ...ujianPerMapel.keys};
    final mapelRingkas = <Map<String, dynamic>>[];
    for (final id in semuaMapel) {
      final m = mapel[id];
      if (m == null) continue;
      final h = harianList[id] == null ? null : rata(harianList[id]!);
      final u = (ujianPerMapel[id]?.isNotEmpty ?? false) ? rata(ujianPerMapel[id]!) : null;
      // Kalau hanya salah satu yang ada, pakai itu saja (tidak dibobot dengan nol)
      final akhir = (h != null && u != null) ? h * _bobotHarian + u * _bobotUjian : (h ?? u ?? 0.0);
      mapelRingkas.add({
        'mapel': m['namaMapel'],
        'kkm': (m['kkm'] as num?)?.toDouble() ?? 75.0,
        'harian': h == null ? null : _r1(h),
        'ujian': u == null ? null : _r1(u),
        'rataRata': _r1(akhir),
      });
    }

    // Kehadiran dalam periode
    final absensi = (await (await _col('absensi')).where('santriId', isEqualTo: santriId).get())
        .docs
        .map(_map)
        .where((a) => _dalam(a['tanggal'], r))
        .toList();
    int hitung(String st) => absensi.where((a) => '${a['status']}'.toUpperCase() == st).length;
    final hadir = hitung('HADIR');
    final sakit = hitung('SAKIT');
    final izin = hitung('IZIN');
    final alpa = hitung('ALPA');

    final ringkasan = {
      'mapel': mapelRingkas,
      'ujian': nilaiUjian.map((n) {
        final u = ujian[n['ujianId']]!;
        final awal = (n['nilai'] as num).toDouble();
        final akhir = akhirMap[n['ujianId']];
        final m = mapel[u['mapelId']];
        return {
          'ujian': m?['namaMapel'] ?? u['nama'],
          'kkm': (m?['kkm'] as num?)?.toDouble() ?? 75.0,
          'nilaiAwal': awal,
          'nilaiAkhir': akhir ?? awal,
          'remedial': akhir != null,
          'rataRata': _r1(akhir ?? awal),
        };
      }).toList(),
      'kehadiran': {'hadir': hadir, 'sakit': sakit, 'izin': izin, 'alpa': alpa, 'total': hadir + sakit + izin + alpa},
    };
    final rataRata = mapelRingkas.isEmpty
        ? null
        : _r1(mapelRingkas.fold<double>(0, (s, m) => s + (m['rataRata'] as double)) / mapelRingkas.length);

    final doc = {
      'santriId': santriId,
      'kelasId': santri['kelasId'],
      'periode': periode,
      'ringkasan': ringkasan,
      'rataRata': rataRata,
      'status': d['status'] == 'TERBIT' ? 'TERBIT' : 'DRAFT',
      'createdAt': lama?['createdAt'] ?? _now(),
      'updatedAt': _now(),
    };
    await ref.set(doc);
    return (await _raporJoin([{'id': ref.id, ...doc}])).first;
  }

  // PATCH /rapor/:id/terbit
  Future<Map<String, dynamic>> _raporTerbit(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final r = await _must('rapor', id, 'Rapor');
    final santri = await _must('santri', r['santriId'] as String, 'Santri');
    await _waliKelasSantri(me, santri);
    return _update('rapor', id, {'status': 'TERBIT'}, 'Rapor');
  }

  // DELETE /rapor/:id
  Future<Map<String, dynamic>> _raporRemove(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final r = await _must('rapor', id, 'Rapor');
    final santri = await _must('santri', r['santriId'] as String, 'Santri');
    await _waliKelasSantri(me, santri);
    return _remove('rapor', id, 'Rapor');
  }

  // GET /kelas/:id  (detail kelas + daftar santri)
  Future<Map<String, dynamic>> _kelasDetail(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);
    final k = await _must('kelas', id, 'Kelas');

    Map<String, dynamic>? wali;
    final wId = k['waliKelasId'] as String?;
    if (wId != null) {
      try {
        final s = await (await _ref('ustadz', wId)).get();
        if (s.exists) wali = {'id': s.id, 'nama': s.data()!['nama']};
      } on FirebaseException {
        wali = null; // akun ini tidak boleh membaca ustadz lain; nama wali dilewati
      }
    }
    final santris = (await (await _col('santri')).where('kelasId', isEqualTo: id).get())
        .docs
        .map(_map)
        .map((s) => {
              'id': s['id'],
              'nis': s['nis'],
              'nama': s['nama'],
              'jenisKelamin': s['jenisKelamin'],
              'status': s['status'],
            })
        .toList()
      ..sort((a, b) => _cmp(a['nama'], b['nama']));
    return {...k, 'waliKelas': wali, 'santris': santris, '_count': {'santris': santris.length}};
  }
    // ===== A: DASHBOARD =====
  // Kerangka milik A. Cabang role lain (B dan C) diisi di fungsi masing-masing.

  Future<List<Map<String, dynamic>>> _absensiHariIni() async {
    final ref = await _col('absensi');
    return (await ref.where('tanggal', isEqualTo: _hariIni()).get()).docs.map(_map).toList();
  }

  Map<String, int> _hitungHadir(List<Map<String, dynamic>> rows) {
    final r = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0};
    for (final a in rows) {
      final k = '${a['status']}'.toLowerCase();
      if (r.containsKey(k)) r[k] = r[k]! + 1;
    }
    return r;
  }

  Future<Map<String, dynamic>> _statistikLembaga() async {
    final santri = (await _all('santri')).where((x) => x['status'] != 'KELUAR').toList();
    return {
      'santriAktif': santri.length,
      'santriPutra': santri.where((x) => x['jenisKelamin'] == 'L').length,
      'santriPutri': santri.where((x) => x['jenisKelamin'] == 'P').length,
      'totalUstadz': (await _all('ustadz')).length,
      'totalKelas': (await _all('kelas')).length,
    };
  }

  Future<Map<String, dynamic>> _dashboard() async {
    final me = await _user();
    final role = me['role'] as String?;
    final base = <String, dynamic>{
      'role': role,
      'namaPengguna': me['nama'],
      'namaPondok': (me['tenant'] as Map?)?['namaPondok'],
    };
    switch (role) {
      case 'USTADZ':
        // Pengingat absensi & nilai dibuat setiap dashboard ustadz dibuka
        try {
          await _notifikasiCekPengingat();
        } catch (e) {
          debugPrint('cek-pengingat gagal: $e');
        }
        return {...base, ...await _dashboardUstadz(me)};
      case 'PIMPINAN':
        return {...base, ...await _dashboardPimpinan()};
      case 'ADMIN': // TODO B: tambah totalAkun, auditKelengkapan, logAktivitas, dst.
        return {...base, 'statistik': await _statistikLembaga()};
      case 'SUPER_ADMIN': // TODO B: isi statistik tenant (tanpa tenantId, jangan panggil _tid)
        return {...base, 'statistik': <String, dynamic>{}, 'tenantTerbaru': <dynamic>[]};
      case 'MUSYRIF': // TODO C: ringkasan musyrif
      case 'WALI_SANTRI': // TODO C: data anak untuk WaliHero & WaliBody
        return {...base, 'anak': <dynamic>[]};
    }
    return base;
  }

  Future<Map<String, dynamic>> _dashboardUstadz(Map<String, dynamic> me) async {
    final ustadzId = me['ustadzId'] as String?;
    final kelasIds = List<String>.from(me['kelasIds'] ?? const []);
    if (kelasIds.isEmpty) {
      return {'kelasDiampu': <dynamic>[], 'ringkasan': <String, dynamic>{}};
    }

    final kelas = (await _all('kelas')).where((k) => kelasIds.contains(k['id'])).toList()
      ..sort((a, b) => _cmp(a['namaKelas'], b['namaKelas']));
    final List<Map<String, dynamic>> mengajar = ustadzId == null
        ? []
        : (await (await _col('mengajar')).where('ustadzId', isEqualTo: ustadzId).get())
            .docs
            .map(_map)
            .toList();
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    final santri = (await _all('santri')).where((s) => s['status'] != 'KELUAR').toList();
    final absensi = (await _absensiHariIni()).where((a) => kelasIds.contains(a['kelasId'])).toList();

    final items = kelas.map((k) {
      final kid = k['id'];
      final mapelIds = {
        for (final m in mengajar)
          if (m['kelasId'] == kid) m['mapelId'] as String
      };
      final namaMapel = [
        for (final id in mapelIds)
          if (mapel[id] != null) mapel[id]!['namaMapel']
      ].join(', ');
      final terisiIds = {for (final a in absensi) if (a['kelasId'] == kid) a['mapelId']};
      final terisi = mapelIds.isEmpty ? terisiIds.length : terisiIds.where(mapelIds.contains).length;
      return {
        'namaKelas': k['namaKelas'],
        'tingkat': k['tingkat'],
        'mapel': namaMapel,
        'jumlahSantri': santri.where((s) => s['kelasId'] == kid).length,
        'jumlahMapel': mapelIds.length,
        'mapelTerisiHariIni': terisi,
        'absensiHariIniTerisi': terisi > 0,
      };
    }).toList();

    final h = _hitungHadir(absensi);
    final ringkasan = <String, dynamic>{};
    if (absensi.isNotEmpty) {
      ringkasan['kehadiranPersen'] = (h['hadir']! / absensi.length * 100).round();
      ringkasan['kehadiranKet'] = '${h['hadir']} dari ${absensi.length} data absensi hari ini';
    }
    return {'kelasDiampu': items, 'ringkasan': ringkasan};
  }

  Future<Map<String, dynamic>> _dashboardPimpinan() async {
    final stat = await _statistikLembaga();
    final absensi = await _absensiHariIni();
    final kelasTerisi = {for (final a in absensi) a['kelasId']}..remove(null);
    return {
      'statistik': stat,
      'kepatuhanAbsensi': {'terisi': kelasTerisi.length, 'total': stat['totalKelas']},
      'kehadiranHariIni': _hitungHadir(absensi),
    };
  }
}