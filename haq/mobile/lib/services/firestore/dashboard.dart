part of '../firestore_api_client.dart';

// ===== A: DASHBOARD =====
// Kerangka milik A(ustadz, mudir). Cabang role lain (B dan C) diisi di fungsi masing-masing.
extension DashboardRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeDashboard(String method, List<String> s, Map<String, String> q, dynamic body) {
    if (s.length == 1 && method == 'GET') return _dashboard();
    return null;
  }

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