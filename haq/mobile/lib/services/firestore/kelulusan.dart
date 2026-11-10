part of '../firestore_api_client.dart';

// ===== A: KELULUSAN =====
// Koleksi: tenants/{tid}/kelulusan, ID = santriId (1 santri = 1 data, pengganti unique + upsert)
extension KelulusanRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeKelulusan(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _kelulusanList();
    if (s.length == 1 && method == 'POST') return _kelulusanSimpan(_body(body));
    if (id != null && method == 'PATCH') return _kelulusanUpdate(id, _body(body));
    if (id != null && method == 'DELETE') return _kelulusanRemove(id);
    return null;
  }

  Future<List<Map<String, dynamic>>> _kelulusanJoin(List<Map<String, dynamic>> rows) async {
    final santri = {for (final s in await _all('santri')) s['id']: s};
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
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
                'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
              },
      };
    }).toList();
  }

  // GET /kelulusan
  Future<List<Map<String, dynamic>>> _kelulusanList() async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ', 'WALI_SANTRI']);
    List<Map<String, dynamic>> rows;
    if (me['role'] == 'WALI_SANTRI') {
      // Wali hanya boleh membaca dokumen anaknya (ID dokumen = santriId)
      final anak = List<String>.from(me['santriIds'] ?? const []);
      final docs = await Future.wait(anak.map((id) async => (await _ref('kelulusan', id)).get()));
      rows = docs.where((d) => d.exists).map(_map).toList();
    } else {
      rows = await _all('kelulusan');
    }
    rows.sort((a, b) => _cmp(b['tanggalKelulusan'], a['tanggalKelulusan']));
    return _kelulusanJoin(rows);
  }

  // POST /kelulusan { santriId, status?, tanggalKelulusan?, predikat?, juzYangDiHafal?, catatan? }
  Future<Map<String, dynamic>> _kelulusanSimpan(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final santriId = _nn(d['santriId']);
    if (santriId == null) throw ApiException(400, 'santriId wajib diisi');
    await _must('santri', santriId, 'Santri');

    final ref = await _ref('kelulusan', santriId);
    final ada = (await ref.get()).exists;
    final tgl = _parseTgl(d['tanggalKelulusan']);

    if (ada) {
      // Sudah ada: hanya field yang dikirim yang diubah
      await ref.update({
        if (_nn(d['status']) != null) 'status': _nn(d['status']),
        if (tgl != null) 'tanggalKelulusan': tgl.toUtc().toIso8601String(),
        if (_nn(d['predikat']) != null) 'predikat': _nn(d['predikat']),
        if (d.containsKey('juzYangDiHafal')) 'juzYangDiHafal': d['juzYangDiHafal'],
        if (d.containsKey('catatan')) 'catatan': _nn(d['catatan']),
        'updatedAt': _now(),
      });
    } else {
      await ref.set({
        'santriId': santriId,
        'status': _nn(d['status']) ?? 'LULUS',
        'tanggalKelulusan': (tgl ?? DateTime.now()).toUtc().toIso8601String(),
        'predikat': _nn(d['predikat']),
        'juzYangDiHafal': d['juzYangDiHafal'],
        'catatan': _nn(d['catatan']),
        'createdAt': _now(),
      });
    }
    return (await _kelulusanJoin([_map(await ref.get())])).first;
  }

  // PATCH /kelulusan/:id
  Future<Map<String, dynamic>> _kelulusanUpdate(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    await _must('kelulusan', id, 'Data kelulusan');
    final tgl = _parseTgl(d['tanggalKelulusan']);
    final r = await _update('kelulusan', id, {
      if (_nn(d['status']) != null) 'status': _nn(d['status']),
      if (tgl != null) 'tanggalKelulusan': tgl.toUtc().toIso8601String(),
      if (_nn(d['predikat']) != null) 'predikat': _nn(d['predikat']),
      if (d.containsKey('juzYangDiHafal')) 'juzYangDiHafal': d['juzYangDiHafal'],
      if (d.containsKey('catatan')) 'catatan': _nn(d['catatan']),
    }, 'Data kelulusan');
    return (await _kelulusanJoin([r])).first;
  }

  // DELETE /kelulusan/:id  (hanya Admin, sama seperti backend lama)
  Future<Map<String, dynamic>> _kelulusanRemove(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN']);
    return _remove('kelulusan', id, 'Data kelulusan');
  }
}