part of '../firestore_api_client.dart';

// ===== A: USTADZ/MUDIR - ABSENSI =====
extension AbsensiRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeAbsensi(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _absensiList(q);
    if (s.length == 1 && method == 'POST') return _absensiCreate(_body(body));
    if (id == 'bulk' && method == 'POST') return _absensiBulk(_body(body));
    return null;
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
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'MUSYRIF']);

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

    if (!paged) return items;
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

    final items = <String, Map<String, dynamic>>{};
    for (final i in raw) {
      final m = Map<String, dynamic>.from(i as Map);
      final sid = _nn(m['santriId']);
      if (sid == null) throw ApiException(400, 'santriId wajib diisi');
      _cekStatus(m['status']);
      items[sid] = m;
    }
    if (items.length > 450) throw ApiException(400, 'Maksimal 450 santri sekali simpan.');

    if (me['role'] == 'USTADZ') {
      final diampu = List<String>.from(me['kelasIds'] ?? const []);
      if (!diampu.contains(kelasId)) throw ApiException(403, 'Ini bukan kelas yang Anda ampu.');
    }

    final santriDocs = await Future.wait(items.keys.map((id) async => (await _ref('santri', id)).get()));
    if (santriDocs.any((s) => !s.exists)) {
      throw ApiException(404, 'Ada santri yang tidak ditemukan di pondok ini.');
    }
    if (me['role'] == 'USTADZ' && santriDocs.any((s) => s.data()?['kelasId'] != kelasId)) {
      throw ApiException(403, 'Ada santri yang bukan anggota kelas ini.');
    }

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
}