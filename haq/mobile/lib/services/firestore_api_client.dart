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
          if (s.length == 1 && method == 'GET') return _absensiList(q);
          if (s.length == 1 && method == 'POST') return _absensiCreate(_body(body));
          if (id == 'bulk' && method == 'POST') return _absensiBulk(_body(body));
          break;

          case 'nilai':
          if (s.length == 1 && method == 'GET') return _nilaiList(q);
          if (s.length == 1 && method == 'POST') return _nilaiCreate(_body(body));
          if (id == 'bulk' && method == 'POST') return _nilaiBulk(_body(body));
          break;

        case 'tahfidz':
          if (s.length == 1 && method == 'GET') return _tahfidzList(q);
          if (s.length == 1 && method == 'POST') return _tahfidzCreate(_body(body));
          break;

                case 'ujian':
          if (s.length == 1 && method == 'GET') return _ujianList(q);
          if (s.length == 1 && method == 'POST') return _ujianCreate(_body(body));
          if (id == 'penugasan-saya' && method == 'GET') return _penugasanSaya();
          if (id != null && s.length == 2) {
            if (method == 'GET') return _ujianDetail(id);
            if (method == 'PATCH') return _ujianUpdate(id, _body(body));
            if (method == 'DELETE') return _ujianRemove(id);
          }
          if (id != null && s.length == 3) {
            if (s[2] == 'kunci' && method == 'POST') return _ujianKunci(id);
            if (s[2] == 'buka-kunci' && method == 'POST') return _ujianBukaKunci(id, _body(body));
            if (s[2] == 'nilai' && method == 'GET') return _nilaiUjianList(id);
            if (s[2] == 'nilai' && method == 'POST') return _nilaiUjianSatu(id, _body(body));
            if (s[2] == 'remedial' && method == 'GET') return _remedialUjianList(id);
            if (s[2] == 'remedial' && method == 'POST') return _remedialSimpan(id, _body(body));
          }
          if (id != null && s.length == 4 && s[2] == 'nilai') {
            if (s[3] == 'bulk' && method == 'POST') return _nilaiUjianBulk(id, _body(body));
            if (method == 'DELETE') return _nilaiUjianRemove(id, s[3]);
          }
          break;

        case 'remedial':
          if (s.length == 1 && method == 'POST') return _remedialCreate(_body(body));
          if (id != null && method == 'PATCH') return _remedialUpdate(id, _body(body));
          if (id != null && method == 'DELETE') return _remedialRemove(id);
          break;  

        case 'notifikasi':
          if (s.length == 1 && method == 'GET') return _notifikasiList();
          if (id == 'unread-count' && method == 'GET') return _notifikasiUnread();
          if (id == 'read-all' && method == 'POST') return _notifikasiReadAll();
          if (id == 'cek-pengingat' && method == 'POST') return _notifikasiCekPengingat();
          if (id != null && s.length == 3 && s[2] == 'read' && method == 'PATCH') return _notifikasiRead(id);
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

    // ===== A: USTADZ/MUDIR =====

  void _roles(Map<String, dynamic> me, List<String> ok) {
    if (!ok.contains(me['role'])) {
      throw ApiException(403, 'Anda tidak punya akses untuk aksi ini.');
    }
  }

  /// Kosong -> null.
  String? _nn(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Ambil tanggalnya saja, simpan sebagai ISO tengah malam UTC.
  String _tgl(dynamic v) {
    final s = (v ?? '').toString();
    if (s.length < 10 || DateTime.tryParse(s.substring(0, 10)) == null) {
      throw ApiException(400, 'Tanggal tidak valid');
    }
    return '${s.substring(0, 10)}T00:00:00Z';
  }

  /// ID tetap: {tanggal}_{mapelId}_{santriId}
  String _absId(String tgl, String? mapelId, String santriId) =>
      '${tgl.substring(0, 10)}_${mapelId ?? '-'}_$santriId';

  void _cekStatus(dynamic st) {
    if (st is! String || st.trim().isEmpty) throw ApiException(400, 'Status absensi wajib diisi');
  }

  // GET /absensi?santriId&kelasId&mapelId&startDate&endDate&page&perPage
  Future<dynamic> _absensiList(Map<String, String> q) async {
    final me = await _user();
    // WALI_SANTRI sengaja belum didukung di sini, lihat catatan di bawah.
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);

    // Hanya rentang tanggal yang difilter di server (satu field, tidak butuh index).
    Query<Map<String, dynamic>> ref = await _col('absensi');
    if (_nn(q['startDate']) != null) {
      ref = ref.where('tanggal', isGreaterThanOrEqualTo: _tgl(q['startDate']));
    }
    if (_nn(q['endDate']) != null) {
      ref = ref.where('tanggal', isLessThanOrEqualTo: _tgl(q['endDate']));
    }
    var rows = (await ref.get()).docs.map(_map).toList();

    final santri = {for (final s in await _all('santri')) s['id']: s};
    if (_nn(q['santriId']) != null) rows = rows.where((r) => r['santriId'] == q['santriId']).toList();
    if (_nn(q['mapelId']) != null) rows = rows.where((r) => r['mapelId'] == q['mapelId']).toList();
    if (_nn(q['kelasId']) != null) {
      rows = rows.where((r) => santri[r['santriId']]?['kelasId'] == q['kelasId']).toList();
    }
    rows.sort((a, b) {
      final c = _cmp(b['tanggal'], a['tanggal']);
      return c != 0 ? c : _cmp(b['id'], a['id']);
    });

    final paged = q.containsKey('page') || q.containsKey('perPage');
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final perPage = int.tryParse(q['perPage'] ?? '') ?? 20;
    final slice = !paged
        ? rows
        : (((page - 1) * perPage) >= rows.length
            ? <Map<String, dynamic>>[]
            : rows.skip((page - 1) * perPage).take(perPage).toList());

    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    final items = slice.map((r) {
      final s = santri[r['santriId']];
      final k = s == null ? null : kelas[s['kelasId']];
      final m = mapel[r['mapelId']];
      return {
        ...r,
        'santri': s == null
            ? null
            : {
                'id': s['id'],
                'nama': s['nama'],
                'nis': s['nis'],
                'kelas': k == null ? null : {'namaKelas': k['namaKelas']},
              },
        'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel']},
      };
    }).toList();

    if (!paged) return items; // mode lama: array biasa
    return {'items': items, 'total': rows.length, 'page': page, 'perPage': perPage};
  }

  // POST /absensi (satu santri)
  Future<Map<String, dynamic>> _absensiCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ', 'MUSYRIF']);
    final santriId = _nn(d['santriId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    _cekStatus(d['status']);
    final tgl = _tgl(d['tanggal']);
    final mapelId = _nn(d['mapelId']);
    await _must('santri', santriId, 'Santri');

    final ref = await _ref('absensi', _absId(tgl, mapelId, santriId));
    if ((await ref.get()).exists && me['role'] != 'ADMIN') {
      throw ApiException(403, 'Absensi sudah direkap. Hanya admin yang dapat mengubahnya.');
    }
    final doc = {
      'santriId': santriId,
      'kelasId': _nn(d['kelasId']),
      'mapelId': mapelId,
      'tanggal': tgl,
      'status': d['status'],
      'catatan': d['catatan'],
      'inputOleh': me['userId'],
      'createdAt': _now(),
    };
    await ref.set(doc);
    return {'id': ref.id, ...doc};
  }

  // POST /absensi/bulk  { kelasId, mapelId?, tanggal, items: [{santriId, status, catatan}] }
  Future<Map<String, dynamic>> _absensiBulk(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final kelasId = _nn(d['kelasId']);
    if (kelasId == null) throw ApiException(400, 'kelasId wajib diisi');
    final tgl = _tgl(d['tanggal']);
    final mapelId = _nn(d['mapelId']);
    final raw = d['items'];
    if (raw is! List || raw.isEmpty) throw ApiException(400, 'Items absensi wajib diisi');

    // 1 santri = 1 entri (kalau dobel, yang terakhir dipakai)
    final items = <String, Map<String, dynamic>>{};
    for (final i in raw) {
      final m = Map<String, dynamic>.from(i as Map);
      final sid = _nn(m['santriId']);
      if (sid == null) throw ApiException(400, 'santriId wajib diisi');
      _cekStatus(m['status']);
      items[sid] = m;
    }
    if (items.length > 450) throw ApiException(400, 'Maksimal 450 santri sekali simpan.');

    // Ustadz hanya boleh mengabsen kelas yang ia ampu
    if (me['role'] == 'USTADZ') {
      final diampu = List<String>.from(me['kelasIds'] ?? const []);
      if (!diampu.contains(kelasId)) throw ApiException(403, 'Ini bukan kelas yang Anda ampu.');
    }

    // Semua santri harus ada (dan untuk ustadz: anggota kelas ini)
    final santriDocs = await Future.wait(items.keys.map((id) async => (await _ref('santri', id)).get()));
    if (santriDocs.any((s) => !s.exists)) {
      throw ApiException(404, 'Ada santri yang tidak ditemukan di pondok ini.');
    }
    if (me['role'] == 'USTADZ' && santriDocs.any((s) => s.data()?['kelasId'] != kelasId)) {
      throw ApiException(403, 'Ada santri yang bukan anggota kelas ini.');
    }

    // Sudah direkap = terkunci; hanya ADMIN yang boleh mengubah
    final col = await _col('absensi');
    final ids = {for (final sid in items.keys) sid: _absId(tgl, mapelId, sid)};
    final cek = await Future.wait(ids.values.map((i) => col.doc(i).get()));
    final lamaKelas = await col
        .where('kelasId', isEqualTo: kelasId)
        .where('tanggal', isEqualTo: tgl)
        .where('mapelId', isEqualTo: mapelId)
        .limit(1)
        .get();
    final adaLama = lamaKelas.docs.isNotEmpty || cek.any((e) => e.exists);
    if (adaLama && me['role'] != 'ADMIN') {
      throw ApiException(403, 'Absensi sudah direkap. Hanya admin yang dapat mengubahnya.');
    }

    final sudahAda = {for (final e in cek) if (e.exists) e.id};
    final batch = _db.batch();
    items.forEach((sid, m) {
      final ref = col.doc(ids[sid]);
      if (sudahAda.contains(ref.id)) {
        batch.update(ref, {
          'status': m['status'],
          'catatan': m['catatan'],
          'inputOleh': me['userId'],
          'updatedAt': _now(),
        });
      } else {
        batch.set(ref, {
          'santriId': sid,
          'kelasId': kelasId,
          'mapelId': mapelId,
          'tanggal': tgl,
          'status': m['status'],
          'catatan': m['catatan'],
          'inputOleh': me['userId'],
          'createdAt': _now(),
        });
      }
    });
    await batch.commit();
    return {'count': items.length, 'message': 'Absensi massal disimpan.'};
  }

    // ===== NILAI =====
  static const _jenisNilai = ['HARIAN', 'ULANGAN', 'TAHFIDZ', 'BAHASA_ARAB'];

  /// Tanggal hari ini menurut WIB (UTC+7), bukan zona perangkat.
  String _hariIniWib() =>
      _tgl(DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String());

  /// ID tetap = pengganti unique (santri, mapel, jenis, skill, tanggal) -> input ulang menimpa.
  String _nilaiId(String santriId, String mapelId, String jenis, String skill, String tgl) {
    final sk = skill.isEmpty ? '-' : skill.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    return '${santriId}_${mapelId}_${jenis}_${sk}_${tgl.substring(0, 10)}';
  }

  String _cekJenisNilai(dynamic v) {
    if (v is! String || !_jenisNilai.contains(v)) throw ApiException(400, 'Jenis nilai tidak valid');
    return v;
  }

  double _cekAngkaNilai(dynamic v) {
    if (v is! num) throw ApiException(400, 'Nilai harus angka');
    if (v < 0) throw ApiException(400, 'Nilai minimal 0');
    if (v > 100) throw ApiException(400, 'Nilai maksimal 100');
    return v.toDouble();
  }

  /// skill hanya dipakai untuk BAHASA_ARAB; selain itu disimpan "" (bukan null).
  String _cekSkill(String jenis, dynamic v) {
    if (jenis != 'BAHASA_ARAB') return '';
    final s = _nn(v) ?? '';
    if (s.length > 30) throw ApiException(400, 'Skill maksimal 30 karakter');
    return s;
  }

  /// Pasangan "kelasId|mapelId" yang diajar ustadz yang login.
  Future<Set<String>> _mengajarKeys(Map<String, dynamic> me) async {
    final uid = me['ustadzId'] as String?;
    if (uid == null) return {};
    final rows = await (await _col('mengajar')).where('ustadzId', isEqualTo: uid).get();
    return {for (final d in rows.docs) '${d['kelasId']}|${d['mapelId']}'};
  }

  // GET /nilai?santriId&kelasId&mapelId&jenis&startDate&endDate&page&perPage
  Future<dynamic> _nilaiList(Map<String, String> q) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);

    Query<Map<String, dynamic>> ref = await _col('nilai');
    if (_nn(q['startDate']) != null) {
      ref = ref.where('tanggal', isGreaterThanOrEqualTo: _tgl(q['startDate']));
    }
    if (_nn(q['endDate']) != null) {
      ref = ref.where('tanggal', isLessThanOrEqualTo: _tgl(q['endDate']));
    }
    var rows = (await ref.get()).docs.map(_map).toList();

    final santri = {for (final s in await _all('santri')) s['id']: s};
    if (_nn(q['santriId']) != null) rows = rows.where((r) => r['santriId'] == q['santriId']).toList();
    if (_nn(q['mapelId']) != null) rows = rows.where((r) => r['mapelId'] == q['mapelId']).toList();
    if (_nn(q['jenis']) != null) rows = rows.where((r) => r['jenis'] == q['jenis']).toList();
    if (_nn(q['kelasId']) != null) {
      rows = rows.where((r) => santri[r['santriId']]?['kelasId'] == q['kelasId']).toList();
    }
    if (me['role'] == 'USTADZ') {
      final diampu = List<String>.from(me['kelasIds'] ?? const []);
      rows = rows.where((r) => diampu.contains(santri[r['santriId']]?['kelasId'])).toList();
    }
    rows.sort((a, b) {
      final c = _cmp(b['tanggal'], a['tanggal']);
      return c != 0 ? c : _cmp(b['id'], a['id']);
    });

    final paged = q.containsKey('page') || q.containsKey('perPage');
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final perPage = int.tryParse(q['perPage'] ?? '') ?? 20;
    final slice = !paged
        ? rows
        : (((page - 1) * perPage) >= rows.length
            ? <Map<String, dynamic>>[]
            : rows.skip((page - 1) * perPage).take(perPage).toList());

    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    final items = slice.map((r) {
      final s = santri[r['santriId']];
      final k = s == null ? null : kelas[s['kelasId']];
      final m = mapel[r['mapelId']];
      return {
        ...r,
        'santri': s == null
            ? null
            : {
                'id': s['id'],
                'nama': s['nama'],
                'nis': s['nis'],
                'kelas': k == null ? null : {'namaKelas': k['namaKelas']},
              },
        'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel'], 'kkm': m['kkm']},
      };
    }).toList();

    if (!paged) return items;
    return {'items': items, 'total': rows.length, 'page': page, 'perPage': perPage};
  }

  // POST /nilai (satu santri) { santriId, mapelId, jenis, nilai, keterangan?, skill?, tanggal }
  Future<Map<String, dynamic>> _nilaiCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final santriId = _nn(d['santriId']);
    final mapelId = _nn(d['mapelId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    if (mapelId == null) throw ApiException(400, 'mapelId wajib diisi');
    final jenis = _cekJenisNilai(d['jenis']);
    final nilai = _cekAngkaNilai(d['nilai']);
    final skill = _cekSkill(jenis, d['skill']);
    final tgl = _tgl(d['tanggal']);

    final santri = await _must('santri', santriId, 'Santri');
    await _must('mapel', mapelId, 'Mata pelajaran');
    if (me['role'] == 'USTADZ') {
      final keys = await _mengajarKeys(me);
      if (!keys.contains('${santri['kelasId']}|$mapelId')) {
        throw ApiException(403, 'Anda tidak mengampu mapel ini di kelas santri tersebut.');
      }
    }

    final ref = await _ref('nilai', _nilaiId(santriId, mapelId, jenis, skill, tgl));
    final ada = (await ref.get()).exists;
    final ta = await _taAktif();
    if (ada) {
      await ref.update({
        'nilai': nilai,
        'keterangan': _nn(d['keterangan']),
        'inputOleh': me['userId'],
        'updatedAt': _now(),
      });
    } else {
      await ref.set({
        'santriId': santriId,
        'kelasId': santri['kelasId'],
        'mapelId': mapelId,
        'tahunAjaranId': ta['id'],
        'jenis': jenis,
        'nilai': nilai,
        'keterangan': _nn(d['keterangan']),
        'skill': skill,
        'tanggal': tgl,
        'inputOleh': me['userId'],
        'createdAt': _now(),
      });
    }
    return _map(await ref.get());
  }

  // POST /nilai/bulk { mapelId, jenis, skill?, tanggal? (diabaikan), items: [{santriId, nilai, catatan?}] }
  Future<Map<String, dynamic>> _nilaiBulk(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final mapelId = _nn(d['mapelId']);
    if (mapelId == null) throw ApiException(400, 'mapelId wajib diisi');
    final jenis = _cekJenisNilai(d['jenis']);
    final skill = _cekSkill(jenis, d['skill']);
    final tgl = _hariIniWib(); // tanggal dari aplikasi diabaikan
    final raw = d['items'];
    if (raw is! List || raw.isEmpty) throw ApiException(400, 'Daftar santri tidak boleh kosong');
    if (raw.length > 300) throw ApiException(400, 'Terlalu banyak santri dalam satu kiriman');

    // 1 santri = 1 entri (kalau dobel, yang terakhir dipakai)
    final items = <String, Map<String, dynamic>>{};
    for (final i in raw) {
      final m = Map<String, dynamic>.from(i as Map);
      final sid = _nn(m['santriId']);
      if (sid == null) throw ApiException(400, 'santriId wajib diisi');
      m['nilai'] = _cekAngkaNilai(m['nilai']);
      final cat = _nn(m['catatan']);
      if (cat != null && cat.length > 150) throw ApiException(400, 'Catatan maksimal 150 karakter');
      m['catatan'] = cat;
      items[sid] = m;
    }

    await _must('mapel', mapelId, 'Mata pelajaran');
    final santriDocs = await Future.wait(items.keys.map((id) async => (await _ref('santri', id)).get()));
    if (santriDocs.any((s) => !s.exists)) {
      throw ApiException(404, 'Ada santri yang tidak ditemukan di pondok ini.');
    }
    if (me['role'] == 'USTADZ') {
      final keys = await _mengajarKeys(me);
      if (santriDocs.any((s) => !keys.contains('${s.data()?['kelasId']}|$mapelId'))) {
        throw ApiException(403, 'Ada santri di kelas yang tidak Anda ajar untuk mapel ini.');
      }
    }

    final kelasBySantri = {for (final s in santriDocs) s.id: s.data()?['kelasId']};

    final col = await _col('nilai');
    final ids = {for (final sid in items.keys) sid: _nilaiId(sid, mapelId, jenis, skill, tgl)};
    final cek = await Future.wait(ids.values.map((i) => col.doc(i).get()));
    final sudahAda = {for (final e in cek) if (e.exists) e.id};
    final ta = await _taAktif();

    final batch = _db.batch();
    items.forEach((sid, m) {
      final ref = col.doc(ids[sid]);
      if (sudahAda.contains(ref.id)) {
        batch.update(ref, {
          'nilai': m['nilai'],
          'keterangan': m['catatan'],
          'inputOleh': me['userId'],
          'updatedAt': _now(),
        });
      } else {
        batch.set(ref, {
          'santriId': sid,
          'kelasId': kelasBySantri[sid],
          'mapelId': mapelId,
          'tahunAjaranId': ta['id'],
          'jenis': jenis,
          'nilai': m['nilai'],
          'keterangan': m['catatan'],
          'skill': skill,
          'tanggal': tgl,
          'inputOleh': me['userId'],
          'createdAt': _now(),
        });
      }
    });
    await batch.commit();
    return {'count': items.length, 'message': 'Nilai massal disimpan.'};
  }

  // ===== TAHFIDZ =====
  /// Jumlah ayat tiap surah (indeks 0 = surah 1). Total 6236.
  static const _ayatPerSurah = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  /// Nomor ayat urut 1..6236 dari (surah, ayat).
  int _ayatAbs(int surat, int ayat) {
    var n = 0;
    for (var i = 0; i < surat - 1; i++) {
      n += _ayatPerSurah[i];
    }
    return n + ayat;
  }

  /// Angka bulat opsional dalam rentang; null kalau tidak dikirim.
  int? _cekInt(dynamic v, String label, int min, int max) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    if (v is! num || v != v.toInt()) throw ApiException(400, '$label harus angka');
    final n = v.toInt();
    if (n < min || n > max) throw ApiException(400, '$label harus $min sampai $max');
    return n;
  }

  // GET /tahfidz?santriId&kelasId&jenis&startDate&endDate&page&perPage
  Future<dynamic> _tahfidzList(Map<String, String> q) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);

    Query<Map<String, dynamic>> ref = await _col('tahfidz');
    if (_nn(q['startDate']) != null) {
      ref = ref.where('tanggalSetor', isGreaterThanOrEqualTo: _tgl(q['startDate']));
    }
    if (_nn(q['endDate']) != null) {
      ref = ref.where('tanggalSetor', isLessThanOrEqualTo: _tgl(q['endDate']));
    }
    var rows = (await ref.get()).docs.map(_map).toList();

    final santri = {for (final s in await _all('santri')) s['id']: s};
    if (_nn(q['santriId']) != null) rows = rows.where((r) => r['santriId'] == q['santriId']).toList();
    if (_nn(q['jenis']) != null) rows = rows.where((r) => r['jenis'] == q['jenis']).toList();
    if (_nn(q['kelasId']) != null) {
      rows = rows.where((r) => santri[r['santriId']]?['kelasId'] == q['kelasId']).toList();
    }
    if (me['role'] == 'USTADZ') {
      final diampu = List<String>.from(me['kelasIds'] ?? const []);
      rows = rows.where((r) => diampu.contains(santri[r['santriId']]?['kelasId'])).toList();
    }
    rows.sort((a, b) {
      final c = _cmp(b['tanggalSetor'], a['tanggalSetor']);
      return c != 0 ? c : _cmp(b['createdAt'], a['createdAt']);
    });

    final paged = q.containsKey('page') || q.containsKey('perPage');
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final perPage = int.tryParse(q['perPage'] ?? '') ?? 20;
    final slice = !paged
        ? rows
        : (((page - 1) * perPage) >= rows.length
            ? <Map<String, dynamic>>[]
            : rows.skip((page - 1) * perPage).take(perPage).toList());

    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final items = slice.map((r) {
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
                'kelas': k == null ? null : {'namaKelas': k['namaKelas']},
              },
      };
    }).toList();

    if (!paged) return items;
    return {'items': items, 'total': rows.length, 'page': page, 'perPage': perPage};
  }

  // POST /tahfidz { santriId, juz, halaman?, halamanMulai?, halamanSelesai?,
  //   suratMulai?, ayatMulai?, suratSelesai?, ayatSelesai?, jenis?, kualitas?, catatanUstadz? }
  Future<Map<String, dynamic>> _tahfidzCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ', 'MUSYRIF']);
    final santriId = _nn(d['santriId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    final juz = _cekInt(d['juz'], 'Juz', 1, 30);
    if (juz == null) throw ApiException(400, 'Juz wajib diisi');
    final halaman = _cekInt(d['halaman'], 'Halaman', 1, 20);
    final halMulai = _cekInt(d['halamanMulai'], 'Halaman mulai', 1, 20);
    final halSelesai = _cekInt(d['halamanSelesai'], 'Halaman selesai', 1, 20);

    final sm = _cekInt(d['suratMulai'], 'Surat mulai', 1, 114);
    final am = _cekInt(d['ayatMulai'], 'Ayat mulai', 1, 286);
    final ss = _cekInt(d['suratSelesai'], 'Surat selesai', 1, 114);
    final asl = _cekInt(d['ayatSelesai'], 'Ayat selesai', 1, 286);

    // Surat & ayat: kalau dikirim, harus lengkap keempatnya.
    final adaAyat = [sm, am, ss, asl].where((e) => e != null).length;
    if (adaAyat != 0 && adaAyat != 4) {
      throw ApiException(400, 'Surat dan ayat mulai/selesai harus diisi lengkap');
    }
    int? absMulai;
    int? absSelesai;
    if (adaAyat == 4) {
      if (am! > _ayatPerSurah[sm! - 1]) {
        throw ApiException(400, 'Ayat mulai melebihi jumlah ayat surah tersebut');
      }
      if (asl! > _ayatPerSurah[ss! - 1]) {
        throw ApiException(400, 'Ayat selesai melebihi jumlah ayat surah tersebut');
      }
      absMulai = _ayatAbs(sm, am);
      absSelesai = _ayatAbs(ss, asl);
      if (absSelesai < absMulai) throw ApiException(400, 'Ayat selesai tidak boleh sebelum ayat mulai');
    }

    final jenis = _nn(d['jenis']) ?? 'ZIYADAH';
    if (jenis != 'ZIYADAH' && jenis != 'MURAJAAH') throw ApiException(400, 'Jenis setoran tidak valid');
    final kualitas = _nn(d['kualitas']);
    const kualitasOk = ['MUMTAZ', 'JAYYID_JIDDAN', 'JAYYID', 'MAQBUL', 'DHAIF'];
    if (kualitas != null && !kualitasOk.contains(kualitas)) {
      throw ApiException(400, 'Kualitas setoran tidak valid');
    }

    final santri = await _must('santri', santriId, 'Santri');
    if (me['role'] == 'USTADZ') {
      final diampu = List<String>.from(me['kelasIds'] ?? const []);
      if (!diampu.contains(santri['kelasId'])) {
        throw ApiException(403, 'Santri ini bukan di kelas yang Anda ampu.');
      }
    }

    // Tanggal setor diisi server (WIB); tanggalSetor dari aplikasi diabaikan.
    final ref = await _ref('tahfidz');
    final doc = {
      'santriId': santriId,
      'kelasId': santri['kelasId'],
      'juz': juz,
      'halaman': halaman ?? halMulai ?? 1,
      'halamanMulai': halMulai,
      'halamanSelesai': halSelesai,
      'suratMulai': sm,
      'ayatMulai': am,
      'suratSelesai': ss,
      'ayatSelesai': asl,
      'ayatAbsMulai': absMulai,
      'ayatAbsSelesai': absSelesai,
      'jenis': jenis,
      'kualitas': kualitas,
      'tanggalSetor': _hariIniWib(),
      'catatanUstadz': _nn(d['catatanUstadz']),
      'inputOleh': me['userId'],
      'createdAt': _now(),
    };
    await ref.set(doc);
    return {'id': ref.id, ...doc};
  }

    // ===== UJIAN & REMEDIAL =====
  static const _terpusat = ['UTS', 'UAS'];
  static const _statusUjian = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];

  String _periodeDariTanggal(DateTime d) {
    final u = d.toUtc();
    return u.month >= 7 ? '${u.year}/${u.year + 1} - Ganjil' : '${u.year - 1}/${u.year} - Genap';
  }

  DateTime? _parseTgl(dynamic v) {
    final s = _nn(v);
    if (s == null) return null;
    final t = DateTime.tryParse(s);
    if (t == null) throw ApiException(400, 'Tanggal tidak valid');
    return t;
  }

  /// Penugasan mengajar ustadz yang login: [{mapelId, kelasId}]
  Future<List<Map<String, dynamic>>> _tugas(Map<String, dynamic> me) async {
    final uid = me['ustadzId'] as String?;
    if (uid == null) return [];
    final rows = await (await _col('mengajar')).where('ustadzId', isEqualTo: uid).get();
    return rows.docs.map((d) => {'mapelId': d['mapelId'], 'kelasId': d['kelasId']}).toList();
  }

  Future<bool> _punyaPenugasan(Map<String, dynamic> me, String? mapelId, String? kelasId) async {
    if (mapelId == null || kelasId == null) return false;
    return (await _tugas(me)).any((t) => t['mapelId'] == mapelId && t['kelasId'] == kelasId);
  }

  /// KKM ikut mapel; cadangan: KKM di ujian.
  Future<double> _kkmUjian(Map<String, dynamic> u) async {
    final mid = u['mapelId'] as String?;
    if (mid != null) {
      final k = (await (await _ref('mapel', mid)).get()).data()?['kkm'];
      if (k is num) return k.toDouble();
    }
    return (u['kkm'] as num?)?.toDouble() ?? 75;
  }

  /// Nilai akhir = rata-rata (ujian + remedial), maksimal KKM.
  Map<String, dynamic> _hitungRemedial(double awal, double rem, double kkm) {
    final rata = (awal + rem) / 2;
    return {'nilaiAkhir': rata < kkm ? rata : kkm, 'status': rata >= kkm ? 'TUNTAS' : 'BELUM_TUNTAS'};
  }

  Future<void> _bolehKelola(Map<String, dynamic> me, Map<String, dynamic> u) async {
    if (me['role'] != 'USTADZ') return;
    final m = u['mapelId'] as String?;
    final k = u['kelasId'] as String?;
    if (m != null && k != null) {
      if (await _punyaPenugasan(me, m, k)) return;
      throw ApiException(403, 'Anda tidak mengajar mapel ini di kelas tersebut.');
    }
    if (m != null) {
      if ((await _tugas(me)).any((t) => t['mapelId'] == m)) return;
      throw ApiException(403, 'Anda tidak mengajar mapel ini.');
    }
    if (u['dibuatOleh'] != me['userId']) {
      throw ApiException(403, 'Ujian ini dibuat oleh pengguna lain. Anda tidak bisa mengubah nilainya.');
    }
  }

  /// Kelas yang dipegang ustadz pada ujian "Semua kelas". null = tanpa batas.
  Future<List<String>?> _kelasDipegang(Map<String, dynamic> me, Map<String, dynamic> u) async {
    if (me['role'] != 'USTADZ' || u['mapelId'] == null || u['kelasId'] != null) return null;
    return {
      for (final t in await _tugas(me))
        if (t['mapelId'] == u['mapelId']) t['kelasId'] as String
    }.toList();
  }

  Future<void> _santriDipegang(
      Map<String, dynamic> me, Map<String, dynamic> u, List<DocumentSnapshot<Map<String, dynamic>>> santri) async {
    final kelas = await _kelasDipegang(me, u);
    if (kelas == null) return;
    if (santri.any((s) => !kelas.contains(s.data()?['kelasId']))) {
      throw ApiException(403, 'Ada santri yang bukan di kelas yang Anda ajar untuk mapel ini.');
    }
  }

  void _bolehKunci(Map<String, dynamic> me, Map<String, dynamic> u) {
    if (me['role'] == 'USTADZ' && u['mapelId'] != null && u['kelasId'] == null) {
      throw ApiException(403, 'Ujian untuk semua kelas hanya bisa dikunci oleh Admin.');
    }
  }

  void _terbuka(Map<String, dynamic> u) {
    if (u['dikunciPada'] != null) {
      throw ApiException(409,
          'Nilai ujian ini sudah dikunci. Buka kunci terlebih dahulu (alasan wajib diisi) jika perlu perbaikan.');
    }
  }

  /// Santri yang sebelumnya sakit/izin/alpa (nilai kosong), sekarang hadir dan diisi nilainya.
  bool _susulan(Map<String, dynamic>? lama, Map<String, dynamic> n) =>
      lama != null && lama['status'] != 'HADIR' && lama['nilai'] == null && n['status'] == 'HADIR' && n['nilai'] != null;

  Map<String, dynamic> _normalNilai(Map<String, dynamic> i, String p) {
    final status = _nn(i['status']) ?? 'HADIR';
    if (!_statusUjian.contains(status)) {
      throw ApiException(400, '${p}Status kehadiran harus HADIR, SAKIT, IZIN, atau ALPA');
    }
    if (status != 'HADIR') return {'status': status, 'nilai': null}; // susulan, bukan "di bawah KKM"
    final v = i['nilai'];
    if (v == null) throw ApiException(400, '${p}Nilai wajib diisi untuk santri yang hadir.');
    if (v is! num) throw ApiException(400, '${p}Nilai harus angka');
    if (v < 0 || v > 100) throw ApiException(400, '${p}Nilai harus antara 0 sampai 100');
    return {'status': status, 'nilai': v.toDouble()};
  }

  Future<void> _audit(WriteBatch b, Map<String, dynamic> me, String action, String ujianId, String judul,
      String desk, [Map<String, dynamic>? data, String tingkat = 'INFO']) async {
    b.set(await _ref('auditLog'), {
      'userId': me['userId'],
      'userNama': me['nama'],
      'userRole': me['role'],
      'action': action,
      'entity': 'Ujian',
      'entityId': ujianId,
      'kategori': 'DATA',
      'tingkat': tingkat,
      'judul': judul,
      'deskripsi': desk,
      'data': data,
      'createdAt': _now(),
    });
  }

  Future<Map<String, dynamic>> _joinUjian(Map<String, dynamic> u) async {
    final m = u['mapelId'] == null ? null : (await _all('mapel')).where((x) => x['id'] == u['mapelId']).firstOrNull;
    final k = u['kelasId'] == null ? null : (await _all('kelas')).where((x) => x['id'] == u['kelasId']).firstOrNull;
    return {
      'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel'], 'kkm': m['kkm']},
      'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
    };
  }

  // GET /ujian?kelasId&saya
  Future<dynamic> _ujianList(Map<String, String> q) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);
    final ustadz = me['role'] == 'USTADZ';
    final tugas = ustadz ? await _tugas(me) : <Map<String, dynamic>>[];

    var list = await _all('ujian');
    if (ustadz) {
      list = list
          .where((u) =>
              u['dibuatOleh'] == me['userId'] ||
              (u['mapelId'] != null &&
                  tugas.any((t) =>
                      t['mapelId'] == u['mapelId'] && (u['kelasId'] == null || t['kelasId'] == u['kelasId']))))
          .toList();
    } else if (q['saya'] == 'true') {
      list = list.where((u) => u['dibuatOleh'] == me['userId'] || u['dibuatOleh'] == null).toList();
    }
    if (_nn(q['kelasId']) != null) list = list.where((u) => u['kelasId'] == q['kelasId']).toList();

    // Ustadz pada ujian "Semua kelas": hanya kelas yang ia ajar
    final batas = <String, List<String>?>{
      for (final u in list)
        u['id'] as String: (ustadz && u['mapelId'] != null && u['kelasId'] == null)
            ? {for (final t in tugas) if (t['mapelId'] == u['mapelId']) t['kelasId'] as String}.toList()
            : null,
    };

    final santri = (await _all('santri')).where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF').toList();
    final perKelas = <String, int>{};
    for (final s in santri) {
      final k = s['kelasId'];
      if (k != null) perKelas[k] = (perKelas[k] ?? 0) + 1;
    }

    // "Sudah dinilai" = hadir dan nilainya terisi
    final dinilai = <String, int>{};
    for (final n in await _all('nilaiUjian')) {
      final uid = n['ujianId'];
      if (!batas.containsKey(uid) || n['status'] != 'HADIR' || n['nilai'] == null) continue;
      final b = batas[uid];
      if (b != null && !b.contains(n['kelasId'])) continue;
      dinilai[uid] = (dinilai[uid] ?? 0) + 1;
    }

    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final out = list.map((u) {
      final m = mapel[u['mapelId']];
      final k = kelas[u['kelasId']];
      final b = batas[u['id']];
      final total = u['kelasId'] != null
          ? (perKelas[u['kelasId']] ?? 0)
          : b != null
              ? b.fold<int>(0, (a, x) => a + (perKelas[x] ?? 0))
              : santri.length;
      return {
        ...u,
        'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel'], 'kkm': m['kkm']},
        'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
        '_count': {'nilais': dinilai[u['id']] ?? 0},
        'kkm': m?['kkm'] ?? u['kkm'],
        'terkunci': u['dikunciPada'] != null,
        'totalSantri': total,
      };
    }).toList();
    out.sort((a, b) => _cmp(b['createdAt'], a['createdAt']));
    return out;
  }

  // GET /ujian/penugasan-saya
  Future<Map<String, dynamic>> _penugasanSaya() async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    if (me['role'] != 'USTADZ') return {'dibatasi': false, 'items': <dynamic>[]};
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final items = (await _tugas(me)).map((t) {
      final m = mapel[t['mapelId']];
      final k = kelas[t['kelasId']];
      return {
        'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel'], 'kkm': m['kkm']},
        'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
      };
    }).toList();
    return {'dibatasi': true, 'items': items};
  }

  // GET /ujian/:id
  Future<Map<String, dynamic>> _ujianDetail(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    final kelasIds = await _kelasDipegang(me, u);
    final join = await _joinUjian(u);

    final santriAll = await _all('santri');
    final santri = {for (final s in santriAll) s['id']: s};
    var nilais = (await (await _col('nilaiUjian')).where('ujianId', isEqualTo: id).get()).docs.map(_map).toList();
    if (kelasIds != null) nilais = nilais.where((n) => kelasIds.contains(n['kelasId'])).toList();
    nilais.sort((a, b) => _cmp(a['createdAt'], b['createdAt']));
    final nilaisOut = nilais.map((n) {
      final s = santri[n['santriId']];
      return {
        ...n,
        'santri': s == null ? null : {'id': s['id'], 'nama': s['nama'], 'nis': s['nis'], 'kelasId': s['kelasId']},
      };
    }).toList();

    List<Map<String, dynamic>>? santris;
    if (kelasIds != null) {
      final kelas = {for (final k in await _all('kelas')) k['id']: k};
      santris = santriAll
          .where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF' && kelasIds.contains(s['kelasId']))
          .map((s) => {
                'id': s['id'],
                'nama': s['nama'],
                'nis': s['nis'],
                'status': s['status'],
                'kelasId': s['kelasId'],
                'kelas': kelas[s['kelasId']] == null
                    ? null
                    : {'id': s['kelasId'], 'namaKelas': kelas[s['kelasId']]!['namaKelas']},
              })
          .toList()
        ..sort((a, b) => _cmp(a['nama'], b['nama']));
    }

    return {
      ...u,
      ...join,
      'nilais': nilaisOut,
      if (santris != null) 'santris': santris,
      'kkm': join['mapel']?['kkm'] ?? u['kkm'],
      'terkunci': u['dikunciPada'] != null,
      'bolehKunci': !(me['role'] == 'USTADZ' && u['mapelId'] != null && u['kelasId'] == null),
    };
  }

  // POST /ujian
  Future<Map<String, dynamic>> _ujianCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final nama = _nn(d['nama']);
    if (nama == null) throw ApiException(400, 'Nama ujian wajib diisi');
    final jenis = _nn(d['jenis']) ?? 'ULANGAN';
    final mapelId = _nn(d['mapelId']);
    final kelasId = _nn(d['kelasId']);
    final tgl = _parseTgl(d['tanggal']);
    final dur = _cekInt(d['durasiMenit'], 'Durasi', 1, 100000);
    final kkmIn = d['kkm'];
    if (kkmIn != null && (kkmIn is! num || kkmIn < 0 || kkmIn > 100)) {
      throw ApiException(400, 'KKM harus 0 sampai 100');
    }
    if (mapelId != null) await _must('mapel', mapelId, 'Mata pelajaran');
    if (kelasId != null) await _must('kelas', kelasId, 'Kelas');

    final terpusat = _terpusat.contains(jenis.toUpperCase());
    if (terpusat && me['role'] == 'USTADZ') {
      if (mapelId == null || kelasId == null) {
        throw ApiException(400, 'Untuk UTS/UAS, mapel dan kelas wajib dipilih.');
      }
      if (!await _punyaPenugasan(me, mapelId, kelasId)) {
        throw ApiException(403, 'Anda tidak mengajar mapel ini di kelas tersebut.');
      }
    }
    if (terpusat && mapelId != null && kelasId != null) {
      final ada = (await _all('ujian'))
          .any((u) => u['jenis'] == jenis && u['mapelId'] == mapelId && u['kelasId'] == kelasId);
      if (ada) throw ApiException(409, '$jenis sudah ada untuk mapel dan kelas ini.');
    }

    final ref = await _ref('ujian');
    final doc = {
      'nama': nama,
      'jenis': jenis,
      'mapelId': mapelId,
      'kelasId': kelasId,
      'tanggal': tgl?.toUtc().toIso8601String(),
      'periode': _periodeDariTanggal(tgl ?? DateTime.now()),
      'durasiMenit': dur,
      'kkm': kkmIn == null ? 75.0 : (kkmIn as num).toDouble(),
      'dibuatOleh': me['userId'],
      'dibuatOlehNama': me['nama'],
      'dikunciPada': null,
      'dikunciOleh': null,
      'createdAt': _now(),
      'updatedAt': _now(),
    };
    await ref.set(doc);
    return {'id': ref.id, ...doc, ...await _joinUjian(doc)};
  }

  // PATCH /ujian/:id
  Future<Map<String, dynamic>> _ujianUpdate(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    _terbuka(u);

    final mapelBaru = _nn(d['mapelId']) ?? u['mapelId'] as String?;
    final kelasBaru = _nn(d['kelasId']) ?? u['kelasId'] as String?;
    final jenisBaru = _nn(d['jenis']) ?? u['jenis'] as String;
    final terpusat = _terpusat.contains(jenisBaru.toUpperCase());
    if (terpusat && me['role'] == 'USTADZ' && (d['mapelId'] != null || d['kelasId'] != null || d['jenis'] != null)) {
      if (!await _punyaPenugasan(me, mapelBaru, kelasBaru)) {
        throw ApiException(403, 'Anda tidak mengajar mapel ini di kelas tersebut.');
      }
    }
    if (terpusat && mapelBaru != null && kelasBaru != null) {
      final ada = (await _all('ujian')).any((x) =>
          x['id'] != id && x['jenis'] == jenisBaru && x['mapelId'] == mapelBaru && x['kelasId'] == kelasBaru);
      if (ada) throw ApiException(409, '$jenisBaru sudah ada untuk mapel dan kelas ini.');
    }

    final upd = <String, dynamic>{};
    if (_nn(d['nama']) != null) upd['nama'] = _nn(d['nama']);
    if (_nn(d['jenis']) != null) upd['jenis'] = _nn(d['jenis']);
    if (_nn(d['mapelId']) != null) upd['mapelId'] = _nn(d['mapelId']);
    if (_nn(d['kelasId']) != null) upd['kelasId'] = _nn(d['kelasId']);
    final tgl = _parseTgl(d['tanggal']);
    if (tgl != null) {
      upd['tanggal'] = tgl.toUtc().toIso8601String();
      upd['periode'] = _periodeDariTanggal(tgl);
    }
    if (d['durasiMenit'] != null) upd['durasiMenit'] = _cekInt(d['durasiMenit'], 'Durasi', 1, 100000);
    if (d['kkm'] != null) {
      final k = d['kkm'];
      if (k is! num || k < 0 || k > 100) throw ApiException(400, 'KKM harus 0 sampai 100');
      upd['kkm'] = k.toDouble();
    }
    return _update('ujian', id, upd, 'Ujian');
  }

  // DELETE /ujian/:id  (nilai ikut terhapus, remedial dilepas dari ujian)
  Future<Map<String, dynamic>> _ujianRemove(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    _terbuka(u);
    final nilai = await (await _col('nilaiUjian')).where('ujianId', isEqualTo: id).get();
    final rem = await (await _col('remedial')).where('ujianId', isEqualTo: id).get();
    if (nilai.docs.length + rem.docs.length > 480) {
      throw ApiException(400, 'Data ujian terlalu banyak untuk dihapus sekaligus.');
    }
    final batch = _db.batch();
    for (final d in nilai.docs) {
      batch.delete(d.reference);
    }
    for (final d in rem.docs) {
      batch.update(d.reference, {'ujianId': null});
    }
    batch.delete((await _ref('ujian', id)));
    await batch.commit();
    return {'message': 'Ujian dihapus.'};
  }

  // POST /ujian/:id/kunci
  Future<Map<String, dynamic>> _ujianKunci(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    _bolehKunci(me, u);
    if (u['dikunciPada'] != null) throw ApiException(409, 'Nilai ujian ini sudah dikunci.');

    final nilais = (await (await _col('nilaiUjian')).where('ujianId', isEqualTo: id).get()).docs.map(_map).toList();
    if (nilais.isEmpty) throw ApiException(400, 'Belum ada nilai yang diinput untuk ujian ini.');

    // Semua santri aktif peserta harus punya nilai atau keterangan kehadiran
    final aktif = (await _all('santri'))
        .where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF' && (u['kelasId'] == null || s['kelasId'] == u['kelasId']))
        .toList();
    final sudah = {for (final n in nilais) n['santriId']};
    final kosong = aktif.where((s) => !sudah.contains(s['id'])).toList();
    if (kosong.isNotEmpty) {
      final contoh = kosong.take(5).map((s) => s['nama']).join(', ');
      throw ApiException(400,
          '${kosong.length} santri belum punya nilai atau keterangan kehadiran: $contoh${kosong.length > 5 ? ', dst.' : ''}.');
    }

    final remedials = (await (await _col('remedial')).where('ujianId', isEqualTo: id).get()).docs.map(_map).toList();
    final belum = remedials.where((r) => r['nilaiRemedial'] == null).length;
    if (belum > 0) {
      throw ApiException(400,
          '$belum remedial belum diisi nilai perbaikannya. Isi nilainya, atau hapus remedial yang tidak jadi dilaksanakan.');
    }

    final kkm = await _kkmUjian(u);
    final hadir = nilais.where((n) => n['status'] == 'HADIR' && n['nilai'] != null).toList();
    final bawah = hadir.where((n) => (n['nilai'] as num) < kkm).toList();
    final idRem = {for (final r in remedials) r['santriId']};
    final ringkasan = {
      'kkm': kkm,
      'totalPeserta': nilais.length,
      'tuntasLangsung': hadir.length - bawah.length,
      'dibawahKkm': bawah.length,
      'ikutRemedial': bawah.where((n) => idRem.contains(n['santriId'])).length,
      'tanpaRemedial': bawah.where((n) => !idRem.contains(n['santriId'])).length,
      'perluSusulan': nilais.length - hadir.length,
    };

    final batch = _db.batch();
    batch.update((await _ref('ujian', id)), {
      'dikunciPada': _now(),
      'dikunciOleh': me['userId'],
      'updatedAt': _now(),
    });
    await _audit(batch, me, 'UJIAN_KUNCI', id, 'Nilai ujian dikunci', 'Nilai ujian "${u['nama']}" dikunci.', ringkasan);
    await batch.commit();
    return {..._map(await (await _ref('ujian', id)).get()), 'terkunci': true, 'ringkasan': ringkasan};
  }

  // POST /ujian/:id/buka-kunci { alasan }
  Future<Map<String, dynamic>> _ujianBukaKunci(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    _bolehKunci(me, u);
    if (u['dikunciPada'] == null) throw ApiException(409, 'Nilai ujian ini belum dikunci.');
    final alasan = _nn(d['alasan']);
    if (alasan == null) throw ApiException(400, 'Alasan buka kunci wajib diisi');
    if (alasan.length < 10) throw ApiException(400, 'Alasan buka kunci minimal 10 karakter.');
    if (alasan.length > 500) throw ApiException(400, 'Alasan buka kunci maksimal 500 karakter.');
    // TODO: cek rapor TERBIT (hanya Admin/Pimpinan) setelah modul rapor dipindah.

    final batch = _db.batch();
    batch.update((await _ref('ujian', id)), {'dikunciPada': null, 'dikunciOleh': null, 'updatedAt': _now()});
    await _audit(batch, me, 'UJIAN_BUKA_KUNCI', id, 'Kunci nilai ujian dibuka',
        'Kunci nilai ujian "${u['nama']}" dibuka. Alasan: $alasan',
        {'alasan': alasan, 'dikunciPadaSebelumnya': u['dikunciPada'], 'dikunciOlehSebelumnya': u['dikunciOleh']},
        'WARNING');
    await batch.commit();
    return {..._map(await (await _ref('ujian', id)).get()), 'terkunci': false};
  }

  // ---------- nilai ujian ----------
  // GET /ujian/:id/nilai
  Future<List<Map<String, dynamic>>> _nilaiUjianList(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    final kelasIds = await _kelasDipegang(me, u);
    var rows = (await (await _col('nilaiUjian')).where('ujianId', isEqualTo: id).get()).docs.map(_map).toList();
    if (kelasIds != null) rows = rows.where((n) => kelasIds.contains(n['kelasId'])).toList();
    final santri = {for (final s in await _all('santri')) s['id']: s};
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final out = rows.map((n) {
      final s = santri[n['santriId']];
      final k = s == null ? null : kelas[s['kelasId']];
      return {
        ...n,
        'santri': s == null
            ? null
            : {
                'id': s['id'],
                'nama': s['nama'],
                'nis': s['nis'],
                'kelas': k == null ? null : {'namaKelas': k['namaKelas']},
              },
      };
    }).toList();
    out.sort((a, b) => _cmp(a['santri']?['nama'], b['santri']?['nama']));
    return out;
  }

  /// Dipakai simpan satu dan bulk. ID dokumen = {ujianId}_{santriId} (pengganti unique + upsert).
  Future<List<Map<String, dynamic>>> _nilaiUjianTulis(
      Map<String, dynamic> me, Map<String, dynamic> u, List raw) async {
    if (raw.isEmpty) throw ApiException(400, 'Daftar santri tidak boleh kosong');
    if (raw.length > 150) throw ApiException(400, 'Maksimal 150 santri sekali simpan.');

    // Validasi semua dulu supaya tidak ada yang tersimpan separuh jalan
    final items = <String, Map<String, dynamic>>{};
    for (var i = 0; i < raw.length; i++) {
      final p = raw.length > 1 ? 'Baris ${i + 1}: ' : '';
      final m = Map<String, dynamic>.from(raw[i] as Map);
      final sid = _nn(m['santriId']);
      if (sid == null) throw ApiException(400, '${p}santriId wajib diisi');
      items[sid] = {..._normalNilai(m, p), 'catatan': _nn(m['catatan'])};
    }

    final santriDocs = await Future.wait(items.keys.map((id) async => (await _ref('santri', id)).get()));
    if (santriDocs.any((s) => !s.exists)) throw ApiException(404, 'Ada santri yang tidak ditemukan di pondok ini.');
    await _santriDipegang(me, u, santriDocs);

    final uid = u['id'] as String;
    final col = await _col('nilaiUjian');
    final lamaDocs = await Future.wait(items.keys.map((sid) => col.doc('${uid}_$sid').get()));
    final lama = {for (final d in lamaDocs) if (d.exists) d.id: d.data()!};

    // Terkunci: hanya nilai susulan yang boleh; satu saja yang bukan, semuanya ditolak
    if (u['dikunciPada'] != null && items.entries.any((e) => !_susulan(lama['${uid}_${e.key}'], e.value))) {
      throw ApiException(409,
          'Nilai ujian ini sudah dikunci. Saat terkunci hanya nilai susulan (santri yang sebelumnya sakit/izin/alpa) yang boleh diisi. Untuk mengubah nilai lain, buka kunci terlebih dahulu (alasan wajib diisi).');
    }

    final kkm = await _kkmUjian(u);
    final santri = {for (final s in santriDocs) s.id: s.data()!};
    final batch = _db.batch();
    final hasil = <Map<String, dynamic>>[];

    for (final e in items.entries) {
      final sid = e.key;
      final n = e.value;
      final id = '${uid}_$sid';
      final l = lama[id];
      final now = _now();
      final data = {
        'nilai': n['nilai'],
        'status': n['status'],
        'catatan': n['catatan'],
        'inputOleh': me['userId'],
        'updatedAt': now,
      };
      if (l == null) {
        batch.set(col.doc(id), {
          'ujianId': uid,
          'santriId': sid,
          'kelasId': santri[sid]!['kelasId'],
          'createdAt': now,
          ...data,
        });
      } else {
        batch.update(col.doc(id), data);
      }
      hasil.add({
        'id': id,
        'ujianId': uid,
        'santriId': sid,
        ...data,
        'santri': {'id': sid, 'nama': santri[sid]!['nama'], 'nis': santri[sid]!['nis']},
      });

      if (l != null && (l['nilai'] != n['nilai'] || l['status'] != n['status'])) {
        final sus = _susulan(l, n);
        final nama = santri[sid]!['nama'];
        await _audit(
          batch,
          me,
          sus ? 'NILAI_SUSULAN_MASUK' : 'NILAI_UJIAN_UBAH',
          uid,
          sus ? 'Nilai susulan diinput' : 'Nilai ujian diubah',
          sus
              ? 'Nilai susulan $nama pada ujian "${u['nama']}" diinput${u['dikunciPada'] != null ? ' (saat nilai terkunci)' : ''}.'
              : 'Nilai $nama pada ujian "${u['nama']}" diubah.',
          {
            'santriId': sid,
            'lama': {'nilai': l['nilai'], 'status': l['status']},
            'baru': {'nilai': n['nilai'], 'status': n['status']},
            'terkunci': u['dikunciPada'] != null,
          },
        );

        // Remedial santri ini ikut disesuaikan dengan nilai ujian terbaru
        if (n['nilai'] != null) {
          final rs = await (await _ref('remedial', id)).get();
          if (rs.exists) {
            final r = rs.data()!;
            final nv = n['nilai'] as double;
            if (r['nilaiRemedial'] == null) {
              batch.update(rs.reference, {'nilaiAwal': nv, 'updatedAt': now});
            } else if (nv < kkm) {
              final h = _hitungRemedial(nv, (r['nilaiRemedial'] as num).toDouble(), kkm);
              batch.update(rs.reference, {
                'nilaiAwal': nv,
                'nilaiAkhir': h['nilaiAkhir'],
                'status': h['status'],
                'hasil': h['status'],
                'updatedAt': now,
              });
            }
          }
        }
      }
    }
    await batch.commit();
    return hasil;
  }

  // POST /ujian/:id/nilai
  Future<Map<String, dynamic>> _nilaiUjianSatu(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    return (await _nilaiUjianTulis(me, u, [d])).first;
  }

  // POST /ujian/:id/nilai/bulk { items: [{santriId, nilai?, status?, catatan?}] }
  Future<List<Map<String, dynamic>>> _nilaiUjianBulk(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    final raw = d['items'];
    return _nilaiUjianTulis(me, u, raw is List ? raw : const []);
  }

  // DELETE /ujian/:id/nilai/:nilaiId
  Future<Map<String, dynamic>> _nilaiUjianRemove(String id, String nilaiId) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    _terbuka(u);
    final n = await _must('nilaiUjian', nilaiId, 'Nilai');
    if (n['ujianId'] != id) throw ApiException(404, 'Nilai tidak ditemukan.');
    final sDoc = await (await _ref('santri', n['santriId'] as String)).get();
    await _santriDipegang(me, u, [sDoc]);
    final batch = _db.batch();
    batch.delete((await _ref('nilaiUjian', nilaiId)));
    await _audit(batch, me, 'NILAI_UJIAN_HAPUS', id, 'Nilai ujian dihapus',
        'Nilai ${sDoc.data()?['nama']} pada ujian "${u['nama']}" dihapus.',
        {'santriId': n['santriId'], 'lama': {'nilai': n['nilai'], 'status': n['status']}});
    await batch.commit();
    return {'message': 'Nilai dihapus.'};
  }

  // ---------- remedial ----------
  // GET /ujian/:id/remedial
  Future<List<Map<String, dynamic>>> _remedialUjianList(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);
    final u = await _must('ujian', id, 'Ujian');
    await _bolehKelola(me, u);
    final kelasIds = await _kelasDipegang(me, u);
    var rows = (await (await _col('remedial')).where('ujianId', isEqualTo: id).get()).docs.map(_map).toList();
    if (kelasIds != null) rows = rows.where((r) => kelasIds.contains(r['kelasId'])).toList();
    final santri = {for (final s in await _all('santri')) s['id']: s};
    final out = rows.map((r) {
      final s = santri[r['santriId']];
      return {...r, 'santri': s == null ? null : {'id': s['id'], 'nama': s['nama'], 'nis': s['nis']}};
    }).toList();
    out.sort((a, b) => _cmp(b['createdAt'], a['createdAt']));
    return out;
  }

  // POST /ujian/:id/remedial { santriId, keterangan, status?, catatan?, nilaiRemedial?, jadwal?, ruang?, tenggat? }
  Future<Map<String, dynamic>> _remedialSimpan(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final u = await _must('ujian', id, 'Ujian');
    final santriId = _nn(d['santriId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    final keterangan = _nn(d['keterangan']);
    if (keterangan == null) throw ApiException(400, 'Keterangan remedial wajib diisi');
    final sDoc = await (await _ref('santri', santriId)).get();
    if (!sDoc.exists) throw ApiException(404, 'Santri tidak ditemukan');
    await _bolehKelola(me, u);
    await _santriDipegang(me, u, [sDoc]);

    final kkm = await _kkmUjian(u);
    final docId = '${id}_$santriId'; // sama dengan ID nilaiUjian
    final utama = (await (await _ref('nilaiUjian', docId)).get()).data();

    // Terkunci: remedial hanya untuk santri hasil susulan (nilai masuk setelah dikunci)
    final kunci = u['dikunciPada'] as String?;
    if (kunci != null && !(utama != null && (utama['updatedAt'] as String).compareTo(kunci) > 0)) _terbuka(u);

    if (utama == null || utama['status'] != 'HADIR' || utama['nilai'] == null) {
      throw ApiException(400,
          'Santri ini belum punya nilai ujian. Santri yang sakit/izin/alpa harus mengikuti ujian susulan dulu; remedial bisa dibuat setelah nilai susulannya masuk.');
    }
    final awal = (utama['nilai'] as num).toDouble();
    if (awal >= kkm) {
      throw ApiException(400, 'Nilai santri ($awal) sudah mencapai KKM $kkm, tidak perlu remedial.');
    }

    final remRef = await _ref('remedial', docId);
    final lama = (await remRef.get()).data();
    double? nilaiRem;
    if (_nn(d['nilaiRemedial']) != null) {
      nilaiRem = double.tryParse(_nn(d['nilaiRemedial'])!);
      if (nilaiRem == null || nilaiRem < 0 || nilaiRem > 100) {
        throw ApiException(400, 'Nilai perbaikan harus antara 0 sampai 100.');
      }
    } else {
      nilaiRem = (lama?['nilaiRemedial'] as num?)?.toDouble();
    }

    // Status dan nilai akhir ditentukan sistem
    String statusFinal;
    double? akhir;
    if (nilaiRem != null) {
      final h = _hitungRemedial(awal, nilaiRem, kkm);
      akhir = h['nilaiAkhir'];
      statusFinal = h['status'];
    } else {
      final inp = (_nn(d['status']) ?? 'BELUM_TES').toUpperCase();
      if (inp == 'TUNTAS' || inp == 'BELUM_TUNTAS') {
        throw ApiException(400, 'Status Tuntas / Belum Tuntas ditentukan otomatis setelah nilai remedial diisi.');
      }
      statusFinal = inp == 'PROSES' ? 'PROSES' : 'BELUM_TES';
    }

    final data = <String, dynamic>{
      'keterangan': keterangan,
      'status': statusFinal,
      'hasil': statusFinal,
      'nilaiAwal': awal,
      'nilaiRemedial': nilaiRem,
      'nilaiAkhir': akhir,
      if (d.containsKey('catatan')) 'catatan': _nn(d['catatan']),
      if (_nn(d['jadwal']) != null) 'jadwal': _nn(d['jadwal']),
      if (_nn(d['tenggat']) != null) 'tenggat': _nn(d['tenggat']),
      if (d.containsKey('ruang')) 'ruang': _nn(d['ruang']),
      'updatedAt': _now(),
    };
    if (lama == null) {
      await remRef.set({
        'ujianId': id,
        'santriId': santriId,
        'mapelId': u['mapelId'],
        'kelasId': sDoc.data()?['kelasId'],
        'tanggal': _now(),
        'createdAt': _now(),
        ...data,
      });
    } else {
      await remRef.update(data);
    }
    return _map(await remRef.get());
  }

  Future<void> _remedialGuard(Map<String, dynamic> me, Map<String, dynamic> r) async {
    final uid = r['ujianId'] as String?;
    if (uid == null) return;
    final s = await (await _ref('ujian', uid)).get();
    if (!s.exists) return;
    final u = _map(s);
    await _bolehKelola(me, u);
    _terbuka(u);
  }

  // POST /remedial { santriId, ujianId?, mapelId?, keterangan, hasil?, tanggal? }
  Future<Map<String, dynamic>> _remedialCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final santriId = _nn(d['santriId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    final keterangan = _nn(d['keterangan']);
    if (keterangan == null) throw ApiException(400, 'Keterangan remedial wajib diisi');
    final sDoc = await (await _ref('santri', santriId)).get();
    if (!sDoc.exists) throw ApiException(404, 'Santri tidak ditemukan di pondok ini.');
    final ujianId = _nn(d['ujianId']);
    if (ujianId != null) {
      final u = await _must('ujian', ujianId, 'Ujian');
      await _bolehKelola(me, u);
      await _santriDipegang(me, u, [sDoc]);
      _terbuka(u);
    }
    final ref = ujianId != null ? await _ref('remedial', '${ujianId}_$santriId') : await _ref('remedial');
    if (ujianId != null && (await ref.get()).exists) {
      throw ApiException(409, 'Remedial santri ini untuk ujian tersebut sudah ada.');
    }
    final tgl = _parseTgl(d['tanggal']);
    final doc = {
      'santriId': santriId,
      'kelasId': sDoc.data()?['kelasId'],
      'ujianId': ujianId,
      'mapelId': _nn(d['mapelId']),
      'keterangan': keterangan,
      'hasil': _nn(d['hasil']) ?? 'PROSES',
      'status': 'BELUM_TES',
      'tanggal': (tgl ?? DateTime.now()).toUtc().toIso8601String(),
      'createdAt': _now(),
    };
    await ref.set(doc);
    return {'id': ref.id, ...doc};
  }

  // PATCH /remedial/:id { keterangan?, hasil?, tanggal? }
  Future<Map<String, dynamic>> _remedialUpdate(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final r = await _must('remedial', id, 'Remedial');
    await _remedialGuard(me, r);
    final tgl = _parseTgl(d['tanggal']);
    return _update('remedial', id, {
      if (_nn(d['keterangan']) != null) 'keterangan': _nn(d['keterangan']),
      if (_nn(d['hasil']) != null) 'hasil': _nn(d['hasil']),
      if (tgl != null) 'tanggal': tgl.toUtc().toIso8601String(),
    }, 'Remedial');
  }

  // DELETE /remedial/:id
  Future<Map<String, dynamic>> _remedialRemove(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final r = await _must('remedial', id, 'Remedial');
    await _remedialGuard(me, r);
    return _remove('remedial', id, 'Remedial');
  }

  // ===== NOTIFIKASI =====
  // Koleksi: tenants/{tid}/notifikasi
  // Field: userId, jenis, pesan, tanggal (ISO string), statusBaca (bool)

  /// Notifikasi milik user yang login. Super admin tidak punya tenant -> null (kosong).
  Future<Query<Map<String, dynamic>>?> _notifQuery(Map<String, dynamic> me) async {
    if (me['tenantId'] == null) return null;
    return (await _col('notifikasi')).where('userId', isEqualTo: me['userId']);
  }

  // GET /notifikasi
  Future<List<Map<String, dynamic>>> _notifikasiList() async {
    final me = await _user();
    final q = await _notifQuery(me);
    if (q == null) return [];
    final rows = (await q.get()).docs.map(_map).toList()
      ..sort((a, b) => _cmp(b['tanggal'], a['tanggal']));
    return rows.take(100).map((n) => {...n, 'statusBaca': n['statusBaca'] == true}).toList();
  }

  // GET /notifikasi/unread-count  (backend lama mengembalikan angka saja)
  Future<int> _notifikasiUnread() async {
    final me = await _user();
    final q = await _notifQuery(me);
    if (q == null) return 0;
    return (await q.where('statusBaca', isEqualTo: false).get()).docs.length;
  }

  // PATCH /notifikasi/:id/read
  Future<Map<String, dynamic>> _notifikasiRead(String id) async {
    final me = await _user();
    final n = await _must('notifikasi', id, 'Notifikasi');
    if (n['userId'] != me['userId']) throw ApiException(404, 'Notifikasi tidak ditemukan.');
    if (n['statusBaca'] != true) {
      await (await _ref('notifikasi', id)).update({'statusBaca': true});
    }
    return {...n, 'statusBaca': true};
  }

  // POST /notifikasi/read-all
  Future<Map<String, dynamic>> _notifikasiReadAll() async {
    final me = await _user();
    final q = await _notifQuery(me);
    if (q == null) return {'count': 0};
    final docs = (await q.where('statusBaca', isEqualTo: false).get()).docs;
    for (var i = 0; i < docs.length; i += 400) {
      final batch = _db.batch();
      for (final d in docs.skip(i).take(400)) {
        batch.update(d.reference, {'statusBaca': true});
      }
      await batch.commit();
    }
    return {'count': docs.length, 'message': 'Semua notifikasi ditandai dibaca.'};
  }

  // ---------- pengingat ustadz (pengganti NotifikasiScheduler mode on-open) ----------
  static const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  /// Buat notifikasi untuk diri sendiri. ID tetap = tidak dobel di hari yang sama.
  Future<void> _notifSendiri(
      Map<String, dynamic> me, Set<String> ada, String id, String jenis, String pesan) async {
    if (ada.contains(id)) return;
    await (await _ref('notifikasi', id)).set({
      'userId': me['userId'],
      'jenis': jenis,
      'pesan': pesan,
      'tanggal': _now(),
      'statusBaca': false,
    });
    ada.add(id);
  }

  // POST /notifikasi/cek-pengingat  (dipanggil dashboard ustadz saat dibuka)
  // TODO: hormati toggle "Pengingat Absensi" / "Pengingat Input Nilai" setelah /pengaturan dipindah.
  Future<Map<String, dynamic>> _notifikasiCekPengingat() async {
    final me = await _user();
    if (me['role'] != 'USTADZ' || me['tenantId'] == null || me['ustadzId'] == null) return {'ok': true};
    final q = await _notifQuery(me);
    final ada = <String>{...(await q!.get()).docs.map((d) => d.id)};
    // Gagal di satu pengingat tidak boleh mengganggu dashboard.
    try {
      await _pengingatAbsensi(me, ada);
    } catch (e) {
      debugPrint('Pengingat absensi gagal: $e');
    }
    try {
      await _pengingatNilai(me, ada);
    } catch (e) {
      debugPrint('Pengingat nilai gagal: $e');
    }
    return {'ok': true};
  }

  /// Senin-Sabtu: ingatkan wali kelas yang absensi kelasnya hari ini belum diisi.
  Future<void> _pengingatAbsensi(Map<String, dynamic> me, Set<String> ada) async {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    if (wib.weekday == DateTime.sunday) return;
    final tgl = _hariIniWib();
    final hari = tgl.substring(0, 10);

    final kelas = await (await _col('kelas')).where('waliKelasId', isEqualTo: me['ustadzId']).get();
    if (kelas.docs.isEmpty) return;
    final santri = (await _all('santri')).where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF').toList();
    final absensi = (await (await _col('absensi')).where('tanggal', isEqualTo: tgl).get()).docs.map(_map).toList();

    for (final d in kelas.docs) {
      final k = _map(d);
      final ids = {for (final s in santri) if (s['kelasId'] == k['id']) s['id']};
      if (ids.isEmpty) continue;
      final sudah = absensi.any((a) => a['kelasId'] == k['id'] || ids.contains(a['santriId']));
      if (sudah) continue;
      await _notifSendiri(me, ada, 'abs_${k['id']}_$hari', 'ABSENSI',
          'Absensi kelas ${k['namaKelas']} hari ini belum diisi.');
    }
  }

  /// Ujian milik ustadz (1-7 hari lalu, belum dikunci) yang nilainya belum lengkap.
  /// Catatan: hanya untuk pembuat ujian. Pengingat ke wali kelas untuk ujian buatan admin belum ada.
  Future<void> _pengingatNilai(Map<String, dynamic> me, Set<String> ada) async {
    const geser = 7 * 3600 * 1000;
    final hariIni = (DateTime.now().toUtc().millisecondsSinceEpoch + geser) ~/ Duration.millisecondsPerDay;
    final hari = _hariIniWib().substring(0, 10);

    final ujians = (await _all('ujian')).where((u) => u['dikunciPada'] == null && u['dibuatOleh'] == me['userId']);
    if (ujians.isEmpty) return;
    final semuaSantri = (await _all('santri')).where((s) => (s['status'] ?? 'AKTIF') == 'AKTIF').toList();
    final kelasMap = {for (final k in await _all('kelas')) k['id']: k};

    for (final u in ujians) {
      final t = DateTime.tryParse('${u['tanggal']}');
      if (t == null) continue;
      final selisih = hariIni - ((t.toUtc().millisecondsSinceEpoch + geser) ~/ Duration.millisecondsPerDay);
      if (selisih < 1 || selisih > 7) continue;

      final batas = await _kelasDipegang(me, u);
      final peserta = semuaSantri
          .where((s) =>
              (u['kelasId'] == null || s['kelasId'] == u['kelasId']) &&
              (batas == null || batas.contains(s['kelasId'])))
          .toList();
      if (peserta.isEmpty) continue;

      final nilai = (await (await _col('nilaiUjian')).where('ujianId', isEqualTo: u['id']).get()).docs.map(_map);
      final nMap = {for (final n in nilai) n['santriId']: n};
      var belum = 0;
      var susulan = 0;
      for (final s in peserta) {
        final n = nMap[s['id']];
        if (n == null) {
          belum++;
        } else if (n['nilai'] == null) {
          if (n['status'] == 'HADIR') {
            belum++;
          } else if (n['status'] != 'ALPA') {
            susulan++;
          }
        }
      }
      if (belum + susulan == 0) continue;

      final wt = t.toUtc().add(const Duration(hours: 7));
      final labelKelas = u['kelasId'] == null ? 'semua kelas' : 'kelas ${kelasMap[u['kelasId']]?['namaKelas'] ?? '-'}';
      final rincian = [
        if (belum > 0) '$belum belum diinput',
        if (susulan > 0) '$susulan menunggu susulan',
      ].join(', ');
      final dinilai = peserta.length - belum - susulan;
      await _notifSendiri(me, ada, 'nilai_${u['id']}_$hari', 'NILAI',
          'Nilai ${u['nama']} (${wt.day} ${_bln[wt.month - 1]}) $labelKelas: $dinilai dari ${peserta.length} santri sudah dinilai, $rincian.');
    }
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

  /// Tanggal hari ini (jam perangkat) dalam format yang sama dengan absensi.
  String _hariIni() => _tgl(DateTime.now().toIso8601String());

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