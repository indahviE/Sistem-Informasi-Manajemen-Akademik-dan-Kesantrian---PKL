part of '../firestore_api_client.dart';

// ===== A: RAPOR =====
// Koleksi: tenants/{tid}/rapor, ID = {santriId}_{periode}
extension RaporRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeRapor(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _raporList(q);
    if (id == 'santri' && method == 'GET') return _raporSantri();
    if (id == 'generate' && method == 'POST') return _raporGenerate(_body(body));
    if (id != null && s.length == 3 && s[2] == 'terbit' && method == 'PATCH') return _raporTerbit(id);
    if (id != null && s.length == 2 && method == 'GET') return _raporOne(id);
    if (id != null && s.length == 2 && method == 'DELETE') return _raporRemove(id);
    return null;
  }

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
}