import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'api_client.dart' show ApiClient, ApiException;

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

    final ustadz = {for (final u in await _all('ustadz')) u['id']: u};
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
}