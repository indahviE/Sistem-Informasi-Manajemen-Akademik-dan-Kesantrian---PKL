part of '../firestore_api_client.dart';

// ===== A: UJIAN, NILAI UJIAN & REMEDIAL =====
// ujian: auto-ID. nilaiUjian & remedial: ID = {ujianId}_{santriId}
extension UjianRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeUjian(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
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
    return null;
  }

  /// Rute /remedial (di luar /ujian/:id/remedial)
  Future<dynamic>? _routeRemedial(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'POST') return _remedialCreate(_body(body));
    if (id != null && method == 'PATCH') return _remedialUpdate(id, _body(body));
    if (id != null && method == 'DELETE') return _remedialRemove(id);
    return null;
  }

  static const _terpusat = ['UTS', 'UAS'];
  static const _statusUjian = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];

  String _periodeDariTanggal(DateTime d) {
    final u = d.toUtc();
    return u.month >= 7 ? '${u.year}/${u.year + 1} - Ganjil' : '${u.year - 1}/${u.year} - Genap';
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
    // Nilai yang sudah masuk rapor terbit: hanya Admin/Pimpinan yang boleh membuka kunci
    final periodeUjian = u['periode'] as String?;
    if (periodeUjian != null && me['role'] != 'ADMIN' && me['role'] != 'PIMPINAN') {
      final peserta = (await (await _col('nilaiUjian')).where('ujianId', isEqualTo: id).get())
          .docs
          .map((d) => d['santriId'])
          .toSet();
      final terbit = (await (await _col('rapor')).where('periode', isEqualTo: periodeUjian).get())
          .docs
          .any((d) => d['status'] == 'TERBIT' && peserta.contains(d['santriId']));
      if (terbit) {
        throw ApiException(403, 'Nilai sudah masuk rapor yang terbit. Hanya Admin atau Pimpinan yang bisa membuka kunci.');
      }
    }

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
}