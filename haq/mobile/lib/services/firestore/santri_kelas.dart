part of '../firestore_api_client.dart';

// ===== DATA INDUK: SANTRI, KELAS, TAHUN AJARAN, USTADZ, MENGAJAR =====
extension SantriKelasRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeSantri(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _santriList(q);
    if (s.length == 1 && method == 'POST') return _santriCreate(_clean('santri', _body(body), true));
    if (id != null && method == 'GET') return _santriOne(id);
    if (id != null && method == 'PATCH') {
      return _update('santri', id, _clean('santri', _body(body), false), 'Santri');
    }
    if (id != null && method == 'DELETE') return _santriRemove(id);
    return null;
  }

  Future<dynamic>? _routeKelas(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _kelasList(q['diampu'] == 'true');
    if (id != null && s.length == 2 && method == 'GET') return _kelasDetail(id);
    if (s.length == 1 && method == 'POST') return _kelasCreate(_clean('kelas', _body(body), true));
    if (id != null && method == 'PATCH') return _kelasUpdate(id, _clean('kelas', _body(body), false));
    if (id != null && method == 'DELETE') return _kelasRemove(id);
    return null;
  }

  Future<dynamic>? _routeTahunAjaran(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') {
      return _all('tahunAjaran').then((l) => l..sort((a, b) => _cmp(b['nama'], a['nama'])));
    }
    if (s.length == 1 && method == 'POST') return _taCreate(_clean('tahunAjaran', _body(body), true));
    if (id == 'aktif' && method == 'GET') return _taAktif();
    if (id != null && s.length == 3 && s[2] == 'aktif' && method == 'POST') return _taSetAktif(id);
    return null;
  }

  Future<dynamic>? _routeUstadz(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _ustadzList(q['jenis']);
    if (s.length == 1 && method == 'POST') return _create('ustadz', _clean('ustadz', _body(body), true));
    if (id != null && s.length == 2 && method == 'PATCH') {
      return _update('ustadz', id, _clean('ustadz', _body(body), false), 'Ustadz');
    }
    if (id != null && s.length == 2 && method == 'DELETE') return _ustadzRemove(id);
    if (id != null && s.length == 3 && s[2] == 'mengajar') {
      if (method == 'GET') return _mengajarList(id);
      if (method == 'POST') return _mengajarAdd(id, _body(body));
    }
    return null;
  }

  Future<dynamic>? _routeMengajar(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (id == 'saya' && method == 'GET') return _mengajarSaya();
    if (id != null && method == 'DELETE') return _mengajarRemove(id);
    return null;
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

  Future<Map<String, dynamic>> _santriOne(String id) async {
    final me = await _user();
    final s = await _must('santri', id, 'Santri');
    // Wali tidak boleh membaca koleksi kelas/wali, jadi tanpa objek bersarang
    if (me['role'] == 'WALI_SANTRI') return s;
    return (await _santriJoin([s])).first;
  }

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
        final year = (data['tahunMasuk'] as num?)?.toInt() ?? DateTime.now().year;
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