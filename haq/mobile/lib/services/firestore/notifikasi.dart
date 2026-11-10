part of '../firestore_api_client.dart';

// ===== A: NOTIFIKASI =====
// Koleksi: tenants/{tid}/notifikasi
// Field: userId, jenis, pesan, tanggal (ISO string), statusBaca (bool)
extension NotifikasiRoutes on FirestoreApiClient {
  /// null = tidak ada rute cocok -> jatuh ke 501
  Future<dynamic>? _routeNotifikasi(String method, List<String> s, Map<String, String> q, dynamic body) {
    final id = s.length > 1 ? s[1] : null;
    if (s.length == 1 && method == 'GET') return _notifikasiList();
    if (id == 'unread-count' && method == 'GET') return _notifikasiUnread();
    if (id == 'read-all' && method == 'POST') return _notifikasiReadAll();
    if (id == 'cek-pengingat' && method == 'POST') return _notifikasiCekPengingat();
    if (id != null && s.length == 3 && s[2] == 'read' && method == 'PATCH') return _notifikasiRead(id);
    return null;
  }

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
}