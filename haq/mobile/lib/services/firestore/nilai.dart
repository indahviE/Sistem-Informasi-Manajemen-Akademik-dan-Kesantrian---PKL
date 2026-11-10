part of '../firestore_api_client.dart';

// ===== A: NILAI =====
// ID dokumen: {santriId}_{mapelId}_{jenis}_{skill}_{tanggal}
extension NilaiRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeNilai(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _nilaiList(q);
    if (s.length == 1 && method == 'POST') return _nilaiCreate(_body(body));
    if (id == 'bulk' && method == 'POST') return _nilaiBulk(_body(body));
    return null;
  }

  static const _jenisNilai = ['HARIAN', 'ULANGAN', 'TAHFIDZ', 'BAHASA_ARAB'];

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
}