part of '../firestore_api_client.dart';

// ===== A: JURNAL MENGAJAR =====
// Koleksi: tenants/{tid}/jurnalMengajar, ID otomatis
extension JurnalRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeJurnal(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _jurnalList(q);
    if (s.length == 1 && method == 'POST') return _jurnalCreate(_body(body));
    if (id != null && s.length == 2 && method == 'PATCH') return _jurnalUpdate(id, _body(body));
    if (id != null && s.length == 2 && method == 'DELETE') return _jurnalRemove(id);
    return null;
  }

  /// Lampirkan kelas, mapel, dan penulis (nama disimpan di dokumen karena akun lain tidak bisa dibaca).
  Future<List<Map<String, dynamic>>> _jurnalJoin(List<Map<String, dynamic>> rows) async {
    final kelas = {for (final k in await _all('kelas')) k['id']: k};
    final mapel = {for (final m in await _all('mapel')) m['id']: m};
    return rows.map((r) {
      final k = kelas[r['kelasId']];
      final m = mapel[r['mapelId']];
      return {
        ...r,
        'kelas': k == null ? null : {'id': k['id'], 'namaKelas': k['namaKelas']},
        'mapel': m == null ? null : {'id': m['id'], 'namaMapel': m['namaMapel']},
        'penulis': r['inputOleh'] == null ? null : {'id': r['inputOleh'], 'nama': r['inputOlehNama']},
      };
    }).toList();
  }

  /// Ustadz hanya boleh mengubah/menghapus jurnal miliknya, admin bebas.
  Future<Map<String, dynamic>> _jurnalEditable(Map<String, dynamic> me, String id) async {
    final j = await _must('jurnalMengajar', id, 'Jurnal');
    if (me['role'] != 'ADMIN' && j['inputOleh'] != me['userId']) {
      throw ApiException(403, 'Anda hanya dapat mengubah jurnal milik sendiri.');
    }
    return j;
  }

  // GET /jurnal-mengajar?kelasId&startDate&endDate
  Future<List<Map<String, dynamic>>> _jurnalList(Map<String, String> q) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'PIMPINAN', 'USTADZ']);

    List<Map<String, dynamic>> rows;
    if (me['role'] == 'USTADZ') {
      // Ustadz hanya melihat miliknya (rules juga mensyaratkan filter ini)
      rows = (await (await _col('jurnalMengajar')).where('inputOleh', isEqualTo: me['userId']).get())
          .docs
          .map(_map)
          .toList();
    } else {
      rows = await _all('jurnalMengajar');
    }
    if (_nn(q['kelasId']) != null) rows = rows.where((r) => r['kelasId'] == q['kelasId']).toList();

    String? tgl(String? v) => (v == null || v.length < 10) ? null : v.substring(0, 10);
    final mulai = tgl(_nn(q['startDate']));
    final akhir = tgl(_nn(q['endDate']));
    if (mulai != null || akhir != null) {
      rows = rows.where((r) {
        final t = tgl(r['tanggal']?.toString());
        if (t == null) return false;
        if (mulai != null && t.compareTo(mulai) < 0) return false;
        if (akhir != null && t.compareTo(akhir) > 0) return false;
        return true;
      }).toList();
    }

    rows.sort((a, b) {
      final c = _cmp(b['tanggal'], a['tanggal']);
      return c != 0 ? c : _cmp(b['createdAt'], a['createdAt']);
    });
    return _jurnalJoin(rows);
  }

  // POST /jurnal-mengajar { kelasId, mapelId?, tanggal, materi, catatan? }
  Future<Map<String, dynamic>> _jurnalCreate(Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    final kelasId = _nn(d['kelasId']);
    final mapelId = _nn(d['mapelId']);
    final materi = _nn(d['materi']);
    final tgl = _parseTgl(d['tanggal']);
    if (kelasId == null) throw ApiException(400, 'Kelas wajib diisi');
    if (tgl == null) throw ApiException(400, 'Tanggal wajib diisi');
    if (materi == null) throw ApiException(400, 'Materi wajib diisi');
    await _must('kelas', kelasId, 'Kelas');
    if (mapelId != null) await _must('mapel', mapelId, 'Mata pelajaran');

    final ref = await _ref('jurnalMengajar');
    final doc = {
      'kelasId': kelasId,
      'mapelId': mapelId,
      'tanggal': tgl.toUtc().toIso8601String(),
      'materi': materi,
      'catatan': _nn(d['catatan']),
      'inputOleh': me['userId'],
      'inputOlehNama': me['nama'],
      'createdAt': _now(),
      'updatedAt': _now(),
    };
    await ref.set(doc);
    return (await _jurnalJoin([{'id': ref.id, ...doc}])).first;
  }

  // PATCH /jurnal-mengajar/:id
  Future<Map<String, dynamic>> _jurnalUpdate(String id, Map<String, dynamic> d) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    await _jurnalEditable(me, id);

    final upd = <String, dynamic>{};
    if (d.containsKey('tanggal')) {
      final tgl = _parseTgl(d['tanggal']);
      if (tgl == null) throw ApiException(400, 'Tanggal tidak valid');
      upd['tanggal'] = tgl.toUtc().toIso8601String();
    }
    if (d.containsKey('kelasId')) {
      final k = _nn(d['kelasId']);
      if (k == null) throw ApiException(400, 'Kelas wajib diisi');
      await _must('kelas', k, 'Kelas');
      upd['kelasId'] = k;
    }
    if (d.containsKey('mapelId')) {
      final m = _nn(d['mapelId']);
      if (m != null) await _must('mapel', m, 'Mata pelajaran');
      upd['mapelId'] = m; // kosong = lepas mapel
    }
    if (d.containsKey('materi')) {
      final m = _nn(d['materi']);
      if (m == null) throw ApiException(400, 'Materi wajib diisi');
      upd['materi'] = m;
    }
    if (d.containsKey('catatan')) upd['catatan'] = _nn(d['catatan']);

    final hasil = await _update('jurnalMengajar', id, upd, 'Jurnal');
    return (await _jurnalJoin([hasil])).first;
  }

  // DELETE /jurnal-mengajar/:id
  Future<Map<String, dynamic>> _jurnalRemove(String id) async {
    final me = await _user();
    _roles(me, ['ADMIN', 'USTADZ']);
    await _jurnalEditable(me, id);
    await _remove('jurnalMengajar', id, 'Jurnal');
    return {'success': true};
  }
}