part of '../firestore_api_client.dart';

// ===== A: TAHFIDZ =====
// ID dokumen: acak (satu santri boleh setor lebih dari sekali per hari)
extension TahfidzRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeTahfidz(String method, List<String> s, Map<String, String> q, dynamic body) {
    if (s.length == 1 && method == 'GET') return _tahfidzList(q);
    if (s.length == 1 && method == 'POST') return _tahfidzCreate(_body(body));
    return null;
  }

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
}