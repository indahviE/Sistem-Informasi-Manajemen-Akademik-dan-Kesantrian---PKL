import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;
import '../p_theme.dart';

// ============================================================================
// Catatan field yang diasumsikan dikirim backend (selain yang sudah ada):
// Semua bersifat OPSIONAL — kalau belum ada, baris terkait di UI otomatis
// disembunyikan, tidak akan error.
//   - nomorRegistrasi        : String   (mis. "IIP-202502-019")
//   - kategori               : String   (mis. "Keluarga")
//   - penjemput              : String
//   - disahkanOleh           : String   (nama + jabatan musyrif)
//   - adabSantri             : String   (override teks adab; ada default statis)
//   - rencanaKembali/tenggatKembali : String ISO datetime
//   - checkInPosko           : String ISO datetime
//   - diprosesOleh           : String
//   - pendamping, divisi     : String   (khusus Izin Keluar)
//   - jadwalKembaliBatas, waktuTiba : String ISO datetime (status TELAT)
//   - menitTelat             : num
//   - catatanKeterlambatan   : String
//   - alasanPenolakan        : String
//   - tanggalDiajukan        : String ISO date
//   - pihakProses            : String
// ============================================================================

/// Notifikasi melayang bertema.
void _showPerizinanToast(BuildContext context, String title, {String? subtitle, bool error = false}) {
  const gold = Color(0xFFC5A059);
  const errorBg = Color(0xFFFEE2E2);
  const errorText = Color(0xFF991B1B);
  final w = MediaQuery.of(context).size.width;
  final side = w > 472 ? (w - 440) / 2 : 16.0;
  final fg = error ? errorText : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? errorBg : PTheme.primary,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: Duration(seconds: error ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: error ? errorText.withOpacity(0.25) : gold.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: error ? Colors.white : gold.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error ? Icons.error_outline : Icons.check_rounded,
                size: 18,
                color: error ? errorText : gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

class PerizinanScreen extends StatefulWidget {
  const PerizinanScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PerizinanScreen> createState() => _PerizinanScreenState();
}

class _PerizinanScreenState extends State<PerizinanScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
  bool _loading = true;
  String? _error;

  // Filter riwayat & anak yang sedang dipantau (khusus wali, multi-anak)
  String _filter = 'SEMUA'; // SEMUA | PULANG | KELUAR
  String? _selectedSantriId;

  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Refresh tiap menit supaya countdown terasa real-time.
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      // Filter "hanya anak sendiri" untuk Wali sudah ditangani di backend.
      final res = await api.get(ApiUrl.perizinan);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    if (_santris.isEmpty) {
      try {
        final api = AppScope.of(context).api;
        final byId = <String, Map<String, dynamic>>{};
        for (var page = 1; page <= 50; page++) {
          dynamic s;
          try {
            s = await api.get(ApiUrl.santri, query: {'perPage': '100', 'page': '$page'});
          } catch (_) {
            if (page == 1) rethrow;
            break;
          }
          final raw = s is List ? s : (s is Map ? (s['items'] ?? s['data']) : null);
          final items = (raw is List ? raw : const [])
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          var baru = 0;
          for (final it in items) {
            final id = it['id']?.toString();
            if (id != null && !byId.containsKey(id)) {
              byId[id] = it;
              baru++;
            }
          }
          if (baru == 0 || items.length < 100) break;
        }
        if (mounted) setState(() => _santris = byId.values.toList());
      } catch (_) {}
    }

    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AjukanIzinDialog(santris: _santris),
    );
    if (result == null) return;

    try {
      final api = AppScope.of(context).api;
      final res = await api.post(ApiUrl.perizinan, result);
      // Musyrif yang mencatat = musyrif yang mengesahkan, jadi langsung DISETUJUI.
      final row = res is Map ? (res['data'] is Map ? res['data'] : res) : null;
      final id = row?['id'];
      if (id != null && row?['statusApproval'] != 'DISETUJUI') {
        await api.patch('${ApiUrl.perizinan}/$id', {'statusApproval': 'DISETUJUI'});
      }
      _load();
      if (!mounted) return;
      _showPerizinanToast(context, 'Izin berhasil dicatat', subtitle: 'Wali santri mendapat notifikasi');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showPerizinanToast(context, 'Gagal memproses perizinan', subtitle: e.message, error: true);
    }
  }

  Future<void> _action(Map<String, dynamic> p, String status) async {
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.patch('${ApiUrl.perizinan}/${p['id']}', {
        'statusApproval': status,
        if (status == 'KEMBALI' || status == 'TELAT')
          'tanggalKembali':
              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showPerizinanToast(context, 'Gagal memproses perizinan', subtitle: e.message, error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Helper data
  // ---------------------------------------------------------------------

  List<Map<String, dynamic>> get _itemsUntukAnak {
    final list = _items.cast<Map<String, dynamic>>();
    if (_selectedSantriId == null) return list;
    return list.where((p) => p['santriId']?.toString() == _selectedSantriId).toList();
  }

  Map<String, dynamic>? get _anakAktif {
    final list = _itemsUntukAnak;
    if (list.isEmpty) return null;
    final santri = list.first['santri'];
    return santri is Map<String, dynamic> ? santri : null;
  }

  bool get _adaLebihDariSatuAnak {
    final ids = _items
        .cast<Map<String, dynamic>>()
        .map((p) => p['santriId']?.toString())
        .where((id) => id != null)
        .toSet();
    return ids.length > 1;
  }

  /// Semua izin yang sedang berjalan: sudah DISETUJUI tapi belum tercatat kembali.
  /// Diurutkan dari yang paling dulu jatuh tempo (paling mendesak di atas).
  List<Map<String, dynamic>> get _perizinanBerjalan {
    final list = _itemsUntukAnak
        .where((p) => p['statusApproval'] == 'DISETUJUI' && p['tanggalKembali'] == null)
        .toList();
    list.sort((a, b) {
      final ta = _dt(a['rencanaKembali'] ?? a['tanggalKembaliRencana']);
      final tb = _dt(b['rencanaKembali'] ?? b['tanggalKembaliRencana']);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    return list;
  }

  List<Map<String, dynamic>> get _riwayatSemua {
    // Hanya Wali yang punya kartu "izin aktif" terpisah di atas.
    // Role lain melihat izin yang sedang berjalan di daftar.
    if (AppScope.of(context).user?.isWali != true) return _itemsUntukAnak;
    final berjalan = _perizinanBerjalan.toSet();
    return _itemsUntukAnak.where((p) => !berjalan.contains(p)).toList();
  }

  int get _countPulang => _riwayatSemua.where((p) => p['jenis'] == 'PULANG').length;
  int get _countKeluar => _riwayatSemua.where((p) => p['jenis'] == 'KELUAR').length;

  List<Map<String, dynamic>> get _riwayatTerfilter {
    switch (_filter) {
      case 'PULANG':
        return _riwayatSemua.where((p) => p['jenis'] == 'PULANG').toList();
      case 'KELUAR':
        return _riwayatSemua.where((p) => p['jenis'] == 'KELUAR').toList();
      default:
        return _riwayatSemua;
    }
  }

  void _pilihAnak() {
    final map = <String, String>{};
    for (final p in _items.cast<Map<String, dynamic>>()) {
      final id = p['santriId']?.toString();
      final nama = (p['santri'] as Map?)?['nama']?.toString();
      if (id != null && nama != null) map[id] = nama;
    }
    if (map.length < 2) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: PColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PColors.inkSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text('Pilih Anak', style: PText.headlineSm),
            const SizedBox(height: 6),
            for (final e in map.entries)
              ListTile(
                leading: _InitialAvatar(nama: e.value, size: 38),
                title: Text(e.value, style: PText.bodyMd),
                trailing: _selectedSantriId == e.key
                    ? Icon(Icons.check_circle_rounded, color: PTheme.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedSantriId = e.key);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HERO (statistik + identitas anak untuk wali)
  // ---------------------------------------------------------------------

  Widget _buildHero(bool isWali) {
    final semua = _itemsUntukAnak;
    int hitung(bool Function(Map<String, dynamic>) t) => semua.where(t).length;
    final berjalan = hitung((p) => p['statusApproval'] == 'DISETUJUI' && p['tanggalKembali'] == null);

    final List<_Stat> stats = isWali
        ? [
            _Stat('Total', '${semua.length}'),
            _Stat('Pulang', '${hitung((p) => p['jenis'] == 'PULANG')}'),
            _Stat('Keluar', '${hitung((p) => p['jenis'] == 'KELUAR')}'),
            _Stat('Berjalan', '$berjalan'),
          ]
        : [
            _Stat('Total', '${semua.length}'),
            _Stat('Menunggu', '${hitung((p) => p['statusApproval'] == 'DIAJUKAN')}'),
            _Stat('Berjalan', '$berjalan'),
            _Stat(
              'Selesai',
              '${hitung((p) => p['statusApproval'] == 'KEMBALI' || (p['statusApproval'] == 'DISETUJUI' && p['tanggalKembali'] != null))}',
            ),
          ];

    final anak = isWali ? _anakAktif : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PTheme.primary, PTheme.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: PTheme.primary.withOpacity(0.26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.09), width: 1.5),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -56,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: PColors.gold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: PColors.gold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: PColors.gold.withOpacity(0.5)),
                      ),
                      child: Text(
                        isWali ? 'PORTAL WALI SANTRI' : 'PENGASUHAN SANTRI',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: PColors.gold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isWali)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'Mode Pantau',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Perizinan Santri',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWali
                      ? 'Pantau izin keluar dan pulang ananda secara real-time. Izin diterbitkan terpusat oleh Pengasuhan dan Musyrif.'
                      : 'Kelola pengajuan, pengesahan, dan kepulangan santri dalam satu tempat.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                if (anak != null) ...[
                  const SizedBox(height: 14),
                  _HeroChildRow(
                    anak: anak,
                    bisaGanti: _adaLebihDariSatuAnak,
                    onTap: _pilihAnak,
                  ),
                ],
                const SizedBox(height: 14),
                _StatStrip(stats: stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBerjalanHeader(int jumlah) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: PColors.gold, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text('Sedang Berjalan', style: PText.headlineSm)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: PTheme.primary, borderRadius: BorderRadius.circular(999)),
            child: Text(
              '$jumlah',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol kembali hanya untuk role musyrif.
  bool get _showBack {
    final isMusyrif = AppScope.of(context).user?.isMusyrif == true;
    return isMusyrif && (widget.onBack != null || Navigator.of(context).canPop());
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _buildRiwayatHeader() {
    return Row(
      children: [
        if (_showBack) ...[
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAE6DC)),
            ),
            child: IconButton(
              onPressed: _handleBack,
              tooltip: 'Kembali',
              icon: Icon(Icons.arrow_back_rounded, color: PColors.primary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),
          ),
        ],
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: PColors.gold, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat Perizinan', style: PText.headlineSm),
              const SizedBox(height: 2),
              Text('Tahun Ajaran ${_tahunAjaranFallback()}', style: PText.bodySm),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return _Segmented(
      options: [
        _SegOption('SEMUA', 'Semua', _riwayatSemua.length),
        _SegOption('PULANG', 'Pulang', _countPulang),
        _SegOption('KELUAR', 'Keluar', _countKeluar),
      ],
      value: _filter,
      onChanged: (v) => setState(() => _filter = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    final isWali = user?.isWali == true;
    final bisaKelola = user?.role == 'ADMIN' || user?.role == 'MUSYRIF';
    final riwayat = _riwayatTerfilter;
    final adaData = _items.isNotEmpty;
    final berjalanList = isWali ? _perizinanBerjalan : const <Map<String, dynamic>>[];
    // Wali: satu-satunya izin yang ada sedang tampil di kartu aktif,
    // jadi riwayat memang belum punya isi. Jangan tampilkan filter kosong.
    final belumAdaRiwayat = isWali && berjalanList.isNotEmpty && _riwayatSemua.isEmpty;

    return Scaffold(
      backgroundColor: PColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : RefreshIndicator(
                              color: PTheme.primary,
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                                children: [
                                  _buildHero(isWali),
                                  const SizedBox(height: 16),
                                  if (isWali && berjalanList.isNotEmpty) ...[
                                    _buildBerjalanHeader(berjalanList.length),
                                    for (final b in berjalanList)
                                      _ActivePerizinanCard(
                                        p: b,
                                        showNama: _adaLebihDariSatuAnak && _selectedSantriId == null,
                                      ),
                                    const SizedBox(height: 10),
                                  ],
                                  if (!adaData)
                                    _EmptyState(
                                      isWali: isWali,
                                      bisaKelola: bisaKelola,
                                      onAdd: _add,
                                    )
                                  else ...[
                                    _buildRiwayatHeader(),
                                    const SizedBox(height: 12),
                                    if (belumAdaRiwayat)
                                      const _NoHistoryYet()
                                    else ...[
                                      _buildFilter(),
                                      const SizedBox(height: 14),
                                      if (riwayat.isEmpty)
                                        _FilterEmpty(
                                          label: _filter == 'PULANG'
                                              ? 'izin pulang'
                                              : (_filter == 'KELUAR' ? 'izin keluar' : 'riwayat izin'),
                                        )
                                      else
                                        for (final p in riwayat)
                                          _RiwayatTile(
                                            p: p,
                                            showActions: bisaKelola,
                                            showNama: !isWali,
                                            onApprove: p['statusApproval'] == 'DIAJUKAN'
                                                ? () => _action(p, 'DISETUJUI')
                                                : null,
                                            onReject: p['statusApproval'] == 'DIAJUKAN'
                                                ? () => _action(p, 'DITOLAK')
                                                : null,
                                            onReturn: p['statusApproval'] == 'DISETUJUI'
                                                ? () => _action(p, 'KEMBALI')
                                                : null,
                                          ),
                                    ],
                                  ],
                                  if (isWali) ...[
                                    const SizedBox(height: 6),
                                    _DisciplineGuideCard(
                                      batas: berjalanList.length == 1
                                          ? _dt(berjalanList.first['rencanaKembali'] ??
                                              berjalanList.first['tanggalKembaliRencana'])
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    const _ClosingCard(),
                                  ],
                                ],
                              ),
                            ),
                ),
              ),
              if (bisaKelola)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _add,
                    tooltip: 'Catat Perizinan',
                    backgroundColor: PTheme.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Catat Perizinan',
                      style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Format & helper murni (tanggal, durasi, tahun ajaran)
// ===========================================================================

const _bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toLocal();
}

String _fmtTanggal(String? iso, {bool withHari = false, bool withJam = true}) {
  if (iso == null || iso.isEmpty) return '-';
  DateTime dt;
  try {
    dt = DateTime.parse(iso).toLocal();
  } catch (_) {
    return iso;
  }
  final tgl = '${dt.day} ${_bulanPendek[dt.month - 1]} ${dt.year}';
  final jam = withJam ? ' (${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB)' : '';
  if (withHari) return '${_namaHari[dt.weekday - 1]}, $tgl$jam';
  return '$tgl$jam';
}

String _fmtJamSaja(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  } catch (_) {
    return iso;
  }
}

/// Durasi singkat (maksimal dua satuan): "1 hr 4 j", "16 j 10 m", "25 m".
String _fmtDurasi(Duration d) {
  if (d.inDays > 0) return '${d.inDays} hr ${d.inHours % 24} j';
  if (d.inHours > 0) return '${d.inHours} j ${d.inMinutes % 60} m';
  return '${d.inMinutes} m';
}

/// Tanggal + jam ringkas: "26 Okt, 11:07".
String _fmtRingkas(DateTime? d) {
  if (d == null) return '-';
  return '${d.day} ${_bulanPendek[d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _tahunAjaranFallback([DateTime? now]) {
  final n = now ?? DateTime.now();
  final y = n.year;
  return (n.month >= 7) ? '$y/${y + 1}' : '${y - 1}/$y';
}

IconData _iconForJenis(Map<String, dynamic> p) {
  if (p['statusApproval'] == 'DITOLAK') return Icons.block_rounded;
  return (p['jenis'] == 'PULANG') ? Icons.home_rounded : Icons.directions_walk_rounded;
}

// ===========================================================================
// Resolusi status -> label + warna badge
// ===========================================================================

class _StatusStyle {
  const _StatusStyle(this.bg, this.fg, this.border);
  final Color bg;
  final Color fg;
  final Color border;
}

class _ResolvedStatus {
  const _ResolvedStatus(this.label, this.style);
  final String label;
  final _StatusStyle style;
}

_ResolvedStatus _resolveStatus(Map<String, dynamic> p) {
  final status = p['statusApproval'] as String? ?? '';
  switch (status) {
    case 'DIAJUKAN':
      return const _ResolvedStatus(
        'Diajukan',
        _StatusStyle(PColors.pendingBg, PColors.pendingText, PColors.pendingBorder),
      );
    case 'DISETUJUI':
      if (p['tanggalKembali'] != null) {
        return const _ResolvedStatus(
          'Kembali',
          _StatusStyle(PColors.successBg, PColors.successText, PColors.successBorder),
        );
      }
      // Belum kembali dan sudah lewat Rencana Kembali -> merah otomatis.
      final rencana = DateTime.tryParse('${p['rencanaKembali'] ?? ''}')?.toLocal();
      if (rencana != null && DateTime.now().isAfter(rencana)) {
        final menit = DateTime.now().difference(rencana).inMinutes;
        return _ResolvedStatus(
          'Terlambat $menit Menit',
          const _StatusStyle(PColors.errorBg, PColors.errorText, PColors.errorBorder),
        );
      }
      return const _ResolvedStatus(
        'Sedang Berjalan',
        _StatusStyle(PColors.infoBg, PColors.infoText, PColors.infoBorder),
      );
    case 'KEMBALI':
      return const _ResolvedStatus(
        'Kembali Tepat Waktu',
        _StatusStyle(PColors.successBg, PColors.successText, PColors.successBorder),
      );
    case 'TELAT':
      final menit = p['menitTelat'];
      final label = menit != null ? 'Telat $menit Menit' : 'Telat';
      return _ResolvedStatus(label, const _StatusStyle(PColors.errorBg, PColors.errorText, PColors.errorBorder));
    case 'DITOLAK':
      final pihak = (p['pihakProses'] as String?)?.trim();
      final label = (pihak != null && pihak.isNotEmpty) ? 'Ditolak $pihak' : 'Ditolak';
      return _ResolvedStatus(label, const _StatusStyle(PColors.errorBg, PColors.errorText, PColors.errorBorder));
    default:
      return _ResolvedStatus(
        status.isEmpty ? '-' : status,
        const _StatusStyle(PColors.infoBg, PColors.infoText, PColors.infoBorder),
      );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.resolved});
  final _ResolvedStatus resolved;

  @override
  Widget build(BuildContext context) {
    final s = resolved.style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: s.fg, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              resolved.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: s.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Potongan UI umum
// ===========================================================================

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.nama, this.size = 40});
  final String nama;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase()
            : (parts[0][0] + parts[1][0]).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PTheme.primary, PTheme.primaryEnd],
        ),
        border: Border.all(color: PColors.gold.withOpacity(0.7), width: 1.2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, height: 28, color: Colors.white.withOpacity(0.16)));
      }
      children.add(
        Expanded(
          child: Column(
            children: [
              Text(
                stats[i].value,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stats[i].label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(children: children),
    );
  }
}

class _HeroChildRow extends StatelessWidget {
  const _HeroChildRow({required this.anak, required this.bisaGanti, required this.onTap});

  final Map<String, dynamic> anak;
  final bool bisaGanti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nama = anak['nama']?.toString() ?? '-';
    final kelasMap = anak['kelas'];
    final kelas = kelasMap is Map ? kelasMap['namaKelas']?.toString() : null;
    final nis = anak['nis']?.toString();
    final asrama = anak['asrama']?.toString();
    final info = [
      if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas',
      if (nis != null && nis.isNotEmpty) 'NIS $nis',
      if (asrama != null && asrama.isNotEmpty) asrama,
    ].join(' • ');

    return Material(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: bisaGanti ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _InitialAvatar(nama: nama, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (info.isNotEmpty)
                      Text(
                        info,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                  ],
                ),
              ),
              if (bisaGanti)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ganti',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.unfold_more_rounded, size: 14, color: Colors.white),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Segmented filter ----
class _SegOption {
  const _SegOption(this.value, this.label, this.count);
  final String value;
  final String label;
  final int count;
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.value, required this.onChanged});
  final List<_SegOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: value == o.value ? PTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        o.label,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: value == o.value ? Colors.white : PColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: value == o.value ? PColors.gold : PColors.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${o.count}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: value == o.value ? PTheme.primary : PColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EMPTY STATE
// ===========================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isWali, required this.bisaKelola, required this.onAdd});
  final bool isWali;
  final bool bisaKelola;
  final VoidCallback onAdd;

  Widget _step(IconData icon, String title, String sub, Color bg, Color fg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: PColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10.5,
              height: 1.3,
              color: PColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrow() {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Icon(Icons.chevron_right_rounded, size: 18, color: PColors.inkSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: PColors.goldSurface, shape: BoxShape.circle),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [PTheme.primary, PTheme.primaryEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PTheme.primary.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.assignment_turned_in_outlined, size: 32, color: PColors.gold),
                ),
                Positioned(
                  right: 6,
                  top: 4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: PColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: PColors.border),
                    ),
                    child: const Icon(Icons.home_rounded, size: 16, color: PColors.gold),
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: PColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: PColors.border),
                    ),
                    child: const Icon(Icons.directions_walk_rounded, size: 16, color: PColors.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Perizinan', style: PText.headlineSm, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            isWali
                ? 'Alhamdulillah, ananda sedang tidak memiliki catatan izin. Setiap izin pulang atau izin keluar akan tampil di sini secara otomatis.'
                : 'Belum ada catatan izin keluar maupun izin pulang. Catat izin pertama untuk mulai memantau pergerakan santri.',
            textAlign: TextAlign.center,
            style: PText.bodySm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: PColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _step(Icons.edit_note_rounded, 'Diajukan', 'Dicatat\nPengasuhan', PTheme.sage, PTheme.primary),
                _arrow(),
                _step(Icons.verified_rounded, 'Disetujui', 'Disahkan\nMusyrif', PColors.goldSurface, PColors.gold),
                _arrow(),
                _step(Icons.how_to_reg_rounded, 'Kembali', 'Check-in\nPosko', PColors.successBg, PColors.successText),
              ],
            ),
          ),
          if (bisaKelola) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: PTheme.primary,
                  foregroundColor: PColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Catat Izin Pertama',
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wali punya izin aktif, tapi belum ada izin lain yang selesai.
/// Menggantikan filter + daftar kosong supaya halaman tidak terasa "rusak".
class _NoHistoryYet extends StatelessWidget {
  const _NoHistoryYet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: PColors.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.history_rounded, size: 22, color: PColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Belum ada izin yang selesai', style: PText.labelLg),
                const SizedBox(height: 3),
                Text(
                  'Izin yang saat ini berjalan ada di kartu di atas. Setelah ananda tercatat kembali, izin tersebut otomatis pindah ke riwayat ini.',
                  style: PText.bodySm.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kosong hanya karena filter (data ada, tapi tidak ada yang cocok).
class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: PColors.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_outlined, size: 26, color: PColors.gold),
          ),
          const SizedBox(height: 12),
          Text('Tidak ada $label', style: PText.labelLg),
          const SizedBox(height: 4),
          Text(
            'Belum ada data pada kategori ini. Coba pilih kategori lain.',
            textAlign: TextAlign.center,
            style: PText.bodySm,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// KARTU IZIN AKTIF (Wali) — ringkas by default, tap untuk membuka detail.
// Aman untuk banyak izin sekaligus (satu kartu ± 95px saat tertutup).
// Otomatis berubah merah saat terlambat.
// ===========================================================================

class _ActivePerizinanCard extends StatefulWidget {
  const _ActivePerizinanCard({required this.p, this.showNama = false});

  final Map<String, dynamic> p;
  final bool showNama;

  @override
  State<_ActivePerizinanCard> createState() => _ActivePerizinanCardState();
}

class _ActivePerizinanCardState extends State<_ActivePerizinanCard> {
  bool _open = false;

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PTheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w700, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCol(String label, String value, {bool right = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: PText.bodySm.copyWith(fontSize: 10.5, color: PColors.inkSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 3,
            style: PText.bodySm.copyWith(
              color: PColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final resolved = _resolveStatus(p);
    final telat = resolved.label.startsWith('Terlambat') || p['statusApproval'] == 'TELAT';
    final isPulang = p['jenis'] == 'PULANG';
    final jenis = isPulang ? 'Izin Pulang' : 'Izin Keluar';
    final kategori = (p['kategori'] as String?)?.trim();
    final judul = (kategori != null && kategori.isNotEmpty) ? '$jenis • $kategori' : jenis;
    final alasan = p['alasan']?.toString() ?? '-';
    final penjemput = p['penjemput']?.toString();
    final disahkan = (p['disahkanOleh'] ?? p['disetujuiOlehNama'])?.toString();
    final adabOverride = (p['adabSantri'] as String?)?.trim();
    final adab = (adabOverride != null && adabOverride.isNotEmpty)
        ? adabOverride
        : 'Wajib melapor ke pos piket keamanan gerbang utama dan konfirmasi kehadiran ke musyrif saat tiba di asrama.';
    final santriMap = p['santri'];
    final namaSantri = santriMap is Map ? santriMap['nama']?.toString() : null;
    final sub = (widget.showNama && namaSantri != null && namaSantri.isNotEmpty) ? '$namaSantri • $alasan' : alasan;

    final keluar = _dt(p['tanggalKeluar']);
    final rencana = _dt(p['rencanaKembali'] ?? p['tanggalKembaliRencana']);
    final target = _dt(p['tenggatKembali'] ?? p['rencanaKembali'] ?? p['tanggalKembaliRencana']);

    double? progress;
    if (keluar != null && rencana != null && rencana.isAfter(keluar)) {
      final total = rencana.difference(keluar).inMinutes;
      final lewat = DateTime.now().difference(keluar).inMinutes;
      if (total > 0) progress = (lewat / total).clamp(0.0, 1.0).toDouble();
    }
    if (telat && progress != null) progress = 1.0;

    String chipText = '—';
    if (target != null) {
      final diff = target.difference(DateTime.now());
      chipText = diff.isNegative ? 'Telat ${_fmtDurasi(diff.abs())}' : 'Sisa ${_fmtDurasi(diff)}';
    }

    final accent = telat ? PColors.errorText : PTheme.primary;
    final bg = telat ? const Color(0xFFFFF6F5) : PColors.surface;

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: telat ? PColors.errorBg : PColors.goldSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPulang ? Icons.home_rounded : Icons.directions_walk_rounded,
                  size: 18,
                  color: telat ? PColors.errorText : PColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PText.labelLg.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PText.bodySm.copyWith(color: PColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: telat ? PColors.errorBg : PColors.goldSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: telat ? PColors.errorBorder : PColors.gold.withOpacity(0.4)),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: telat ? PColors.errorText : PTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: PColors.inkSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: PColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            )
          else
            Container(height: 2, color: PColors.border),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Keluar ${_fmtRingkas(keluar)}', style: PText.bodySm.copyWith(fontSize: 10.5)),
              Text('Kembali ${_fmtRingkas(rencana)}', style: PText.bodySm.copyWith(fontSize: 10.5)),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: PColors.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateCol('Tanggal Keluar', _fmtTanggal(p['tanggalKeluar']?.toString(), withHari: true)),
                const SizedBox(width: 12),
                _dateCol(
                  'Rencana Kembali',
                  _fmtTanggal((p['rencanaKembali'] ?? p['tanggalKembaliRencana'])?.toString(), withHari: true),
                  right: true,
                ),
              ],
            ),
            if ((penjemput != null && penjemput.isNotEmpty) || (disahkan != null && disahkan.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (penjemput != null && penjemput.isNotEmpty)
                    _chip(Icons.family_restroom_rounded, 'Penjemput: $penjemput'),
                  if (disahkan != null && disahkan.isNotEmpty) _chip(Icons.verified_rounded, 'Disahkan: $disahkan'),
                ],
              ),
            ],
            if (telat) ...[
              const SizedBox(height: 12),
              const _NoteBox(
                title: 'Perhatian',
                text: 'Ananda melewati batas rencana kembali. Silakan hubungi musyrif pembina bila ada kendala.',
                icon: Icons.warning_amber_rounded,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PColors.goldSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PColors.gold.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 15, color: PColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Adab Santri: ',
                        style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w800, height: 1.4),
                        children: [
                          TextSpan(text: adab, style: PText.bodySm.copyWith(height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: telat ? PColors.errorBorder : PColors.border),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: bg,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Panduan disiplin & kartu penutup
// ===========================================================================

class _DisciplineGuideCard extends StatelessWidget {
  /// [batas] diisi hanya kalau ada tepat satu izin berjalan, supaya jamnya
  /// pasti benar. Kalau tidak, teks memakai kalimat umum tanpa jam.
  const _DisciplineGuideCard({this.batas});
  final DateTime? batas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.goldSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: PColors.gold.withOpacity(0.35)),
            ),
            child: const Icon(Icons.schedule_rounded, size: 18, color: PColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panduan Disiplin & Keterlambatan', style: PText.labelLg),
                const SizedBox(height: 4),
                Text(
                  'Apabila santri belum check-in di posko keamanan setelah melewati batas rencana kembali pada izin${batas != null ? ' (${_fmtRingkas(batas)} WIB)' : ''}, sistem otomatis menerbitkan status "Telat" disertai notifikasi resmi kepada wali santri dan musyrif pembina.',
                  style: PText.bodySm.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingCard extends StatelessWidget {
  const _ClosingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: PColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.auto_awesome, size: 14, color: PColors.gold),
            ),
            Expanded(child: Divider(color: PColors.border)),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'وَأَوْفُوا بِالْعَهْدِ إِنَّ الْعَهْدَ كَانَ مَسْئُولًا',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 17, height: 1.6, color: PColors.gold),
        ),
        const SizedBox(height: 6),
        Text(
          '"Dan penuhilah janji; sesungguhnya janji itu pasti diminta pertanggungjawabannya." (QS. Al-Isra\': 34)',
          textAlign: TextAlign.center,
          style: PText.bodySm.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        Text(
          'Semoga Allah menjaga keistiqamahan santri',
          textAlign: TextAlign.center,
          style: PText.bodySm.copyWith(
            fontStyle: FontStyle.italic,
            color: PTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Tile riwayat (dipakai untuk Wali & Musyrif/Admin)
// ===========================================================================

class _KV {
  const _KV(this.label, this.value);
  final String label;
  final String value;
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.left, required this.right});
  final _KV left;
  final _KV right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _KVText(kv: left)),
        const SizedBox(width: 10),
        Expanded(child: _KVText(kv: right)),
      ],
    );
  }
}

class _KVText extends StatelessWidget {
  const _KVText({required this.kv});
  final _KV kv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kv.label, style: PText.bodySm.copyWith(fontSize: 10, color: PColors.inkSecondary)),
        const SizedBox(height: 2),
        Text(
          kv.value,
          style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w700),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.title, required this.text, this.icon = Icons.error_outline_rounded});
  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PColors.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: PColors.errorText),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PColors.errorText,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: PColors.errorText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.dt, required this.style, required this.icon});
  final DateTime? dt;
  final _StatusStyle style;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border),
      ),
      child: dt == null
          ? Icon(icon, size: 20, color: style.fg)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${dt!.day}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: style.fg,
                  ),
                ),
                Text(
                  _bulanPendek[dt!.month - 1].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: style.fg,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RiwayatTile extends StatefulWidget {
  const _RiwayatTile({
    required this.p,
    required this.showActions,
    this.showNama = true,
    this.onApprove,
    this.onReject,
    this.onReturn,
  });

  final Map<String, dynamic> p;
  final bool showActions;
  final bool showNama;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReturn;

  @override
  State<_RiwayatTile> createState() => _RiwayatTileState();
}

class _RiwayatTileState extends State<_RiwayatTile> {
  bool _open = false;

  Map<String, dynamic> get p => widget.p;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveStatus(p);
    final status = p['statusApproval'] as String?;
    final jenisLabel = p['jenis'] == 'PULANG' ? 'Izin Pulang' : 'Izin Keluar';
    final kategori = (p['kategori'] as String?)?.trim();
    final judul = (kategori != null && kategori.isNotEmpty) ? '$jenisLabel • $kategori' : jenisLabel;
    final alasan = p['alasan']?.toString() ?? '-';
    final nomor = p['nomorRegistrasi']?.toString();
    final santriMap = p['santri'];
    final namaSantri = santriMap is Map ? santriMap['nama']?.toString() : null;
    final detail = _buildDetailRows();
    final onApprove = widget.onApprove;
    final onReject = widget.onReject;
    final onReturn = widget.onReturn;

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(
                dt: _dt(p['tanggalKeluar']),
                style: resolved.style,
                icon: _iconForJenis(p),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showNama && namaSantri != null && namaSantri.isNotEmpty)
                      Text(
                        namaSantri,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PText.bodySm.copyWith(
                          color: PColors.inkSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Row(
                      children: [
                        Icon(_iconForJenis(p), size: 14, color: PTheme.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            judul,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PText.labelLg.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alasan,
                      maxLines: _open ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: PText.bodySm.copyWith(color: PColors.ink, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(resolved: resolved),
              const Spacer(),
              if (nomor != null && nomor.isNotEmpty)
                Flexible(
                  child: Text(
                    nomor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PText.bodySm.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: PColors.inkSecondary,
              ),
            ],
          ),
          if (_open) ...[
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: detail),
              ),
            ],
            if (status == 'DITOLAK' && (p['alasanPenolakan'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _NoteBox(title: 'Alasan Penolakan', text: p['alasanPenolakan'] as String),
            ],
            if (status == 'TELAT' && (p['catatanKeterlambatan'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _NoteBox(
                title: 'Catatan Kedisiplinan',
                text: p['catatanKeterlambatan'] as String,
                icon: Icons.report_gmailerrorred_rounded,
              ),
            ],
          ],
          if (widget.showActions && (onApprove != null || onReject != null || onReturn != null)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: _PButton(
                      label: 'Setujui',
                      icon: Icons.check_rounded,
                      color: PColors.successText,
                      filled: true,
                      onPressed: onApprove,
                    ),
                  ),
                if (onApprove != null && onReject != null) const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(
                    child: _PButton(
                      label: 'Tolak',
                      icon: Icons.close_rounded,
                      color: PColors.errorText,
                      onPressed: onReject,
                    ),
                  ),
                if (onReturn != null)
                  Expanded(
                    child: _PButton(
                      label: 'Tandai Kembali',
                      icon: Icons.how_to_reg_rounded,
                      color: PTheme.primary,
                      filled: true,
                      onPressed: onReturn,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: PColors.surface,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: resolved.style.fg),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailRows() {
    final status = p['statusApproval'] as String?;

    // Sudah kembali (tepat waktu maupun via DISETUJUI+tanggalKembali)
    if (status == 'KEMBALI' || (status == 'DISETUJUI' && p['tanggalKembali'] != null)) {
      return [
        _PairRow(
          left: _KV('Periode', _fmtTanggal(p['tanggalKeluar']?.toString())),
          right: _KV('s/d', _fmtTanggal(p['tanggalKembali']?.toString())),
        ),
        if (p['checkInPosko'] != null || p['diprosesOleh'] != null || p['tanggalKembali'] != null) ...[
          const SizedBox(height: 8),
          _PairRow(
            left: _KV('Check-in Posko', _fmtTanggal((p['checkInPosko'] ?? p['tanggalKembali'])?.toString())),
            right: _KV('Petugas', (p['diprosesOleh'] ?? p['disetujuiOlehNama'])?.toString() ?? '-'),
          ),
        ],
      ];
    }

    // Sedang berjalan
    if (status == 'DISETUJUI') {
      return [
        _PairRow(
          left: _KV('Tanggal Keluar', _fmtTanggal(p['tanggalKeluar']?.toString())),
          right: _KV(
            'Rencana Kembali',
            _fmtTanggal((p['rencanaKembali'] ?? p['tanggalKembaliRencana'])?.toString()),
          ),
        ),
      ];
    }

    // Telat
    if (status == 'TELAT') {
      return [
        _PairRow(
          left: _KV(
            'Jadwal',
            '${_fmtTanggal(p['tanggalKeluar']?.toString())} – ${_fmtJamSaja(p['jadwalKembaliBatas']?.toString())}',
          ),
          right: _KV('Tiba', _fmtJamSaja((p['waktuTiba'] ?? p['tanggalKembali'])?.toString())),
        ),
      ];
    }

    // Ditolak
    if (status == 'DITOLAK') {
      return [
        _PairRow(
          left: _KV(
            'Tanggal Diajukan',
            _fmtTanggal((p['tanggalDiajukan'] ?? p['createdAt'] ?? p['tanggalKeluar'])?.toString(), withJam: false),
          ),
          right: _KV('Pihak Proses', p['pihakProses']?.toString() ?? '-'),
        ),
      ];
    }

    // Diajukan / status lain
    final estKembali = (p['rencanaKembali'] ?? p['tenggatKembali'])?.toString();
    final pendamping = p['pendamping']?.toString().trim();
    return [
      _PairRow(
        left: _KV(
          'Tanggal Diajukan',
          _fmtTanggal((p['tanggalDiajukan'] ?? p['tanggalKeluar'])?.toString(), withJam: false),
        ),
        right: _KV('Est. Kembali', (estKembali != null && estKembali.isNotEmpty) ? _fmtTanggal(estKembali) : '-'),
      ),
      const SizedBox(height: 8),
      _PairRow(
        left: const _KV('Status', 'Menunggu persetujuan'),
        right: _KV('Diantar / Didampingi', (pendamping != null && pendamping.isNotEmpty) ? pendamping : '-'),
      ),
    ];
  }
}

class _PButton extends StatelessWidget {
  const _PButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: filled ? Colors.white : color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color,
            ),
          ),
        ),
      ],
    );

    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: filled ? null : Border.all(color: color.withOpacity(0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ===========================================================================
// Dialog "Catat Izin Santri"
// ===========================================================================
class _AjukanIzinDialog extends StatefulWidget {
  const _AjukanIzinDialog({required this.santris});
  final List<Map<String, dynamic>> santris;

  @override
  State<_AjukanIzinDialog> createState() => _AjukanIzinDialogState();
}

class _AjukanIzinDialogState extends State<_AjukanIzinDialog> {
  Map<String, dynamic>? _santri;
  String _jenis = 'KELUAR';
  final _alasanCtrl = TextEditingController();
  DateTime _tanggalKeluar = DateTime.now();
  TimeOfDay _jamKeluar = TimeOfDay.now();
  TimeOfDay _estKembali = TimeOfDay(hour: (TimeOfDay.now().hour + 3) % 24, minute: TimeOfDay.now().minute);
  final _tujuanCtrl = TextEditingController();
  final _pendampingCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _santri = widget.santris.isEmpty ? null : widget.santris.first;
    _tujuanCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _alasanCtrl.dispose();
    _tujuanCtrl.dispose();
    _pendampingCtrl.dispose();
    super.dispose();
  }

  DateTime get _tanggalKeluarLengkap => DateTime(
        _tanggalKeluar.year,
        _tanggalKeluar.month,
        _tanggalKeluar.day,
        _jamKeluar.hour,
        _jamKeluar.minute,
      );

  DateTime get _estKembaliLengkap => DateTime(
        _tanggalKeluar.year,
        _tanggalKeluar.month,
        _tanggalKeluar.day,
        _estKembali.hour,
        _estKembali.minute,
      );

  String _fmtJam(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB';

  Future<void> _pilihTanggalKeluar() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggalKeluar,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: _jamKeluar);
    if (t == null) return;
    setState(() {
      _tanggalKeluar = d;
      _jamKeluar = t;
    });
  }

  Future<void> _pilihEstKembali() async {
    final t = await showTimePicker(context: context, initialTime: _estKembali);
    if (t == null) return;
    setState(() => _estKembali = t);
  }

  void _gantiSantri() {
    if (widget.santris.length <= 1) return;
    String q = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PColors.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final query = q.trim().toLowerCase();
          final list = query.isEmpty
              ? widget.santris
              : widget.santris.where((s) {
                  final nama = (s['nama'] ?? '').toString().toLowerCase();
                  final nis = (s['nis'] ?? '').toString().toLowerCase();
                  return nama.contains(query) || nis.contains(query);
                }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PColors.inkSecondary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: Text('Pilih Santri', style: PText.headlineSm)),
                          Text('${list.length} santri', style: PText.bodySm),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (v) => setSheet(() => q = v),
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: PColors.background,
                          hintText: 'Cari nama / NIS...',
                          hintStyle: PText.bodySm,
                          prefixIcon: const Icon(Icons.search, size: 20, color: PColors.inkSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: list.isEmpty
                          ? Center(child: Text('Santri tidak ditemukan.', style: PText.bodySm))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final s = list[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                  leading: _InitialAvatar(nama: s['nama']?.toString() ?? '-', size: 38),
                                  title: Text(s['nama']?.toString() ?? '-', style: PText.bodyMd),
                                  subtitle: Text('NIS: ${s['nis'] ?? '-'}', style: PText.bodySm),
                                  trailing: _santri?['id'] == s['id']
                                      ? Icon(Icons.check_circle_rounded, color: PTheme.primary)
                                      : null,
                                  onTap: () {
                                    setState(() => _santri = s);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (_santri == null) {
      _showPerizinanToast(context, 'Pilih santri terlebih dahulu', error: true);
      return;
    }
    if (_alasanCtrl.text.trim().isEmpty) {
      _showPerizinanToast(context, 'Alasan izin wajib diisi', error: true);
      return;
    }
    if (_tujuanCtrl.text.trim().isEmpty) {
      _showPerizinanToast(context, 'Tujuan izin wajib diisi', error: true);
      return;
    }
    setState(() => _submitting = true);
    Navigator.pop(context, {
      'santriId': _santri!['id'],
      'jenis': _jenis,
      'alasan': _alasanCtrl.text.trim(),
      'tanggalKeluar': _tanggalKeluarLengkap.toIso8601String(),
      // 'rencanaKembali' & 'pendamping' mengikuti nama field opsional di
      // komentar atas file ini. Kalau backend belum punya kolomnya, nilainya
      // diabaikan tanpa membuat request gagal.
      'rencanaKembali': _estKembaliLengkap.toIso8601String(),
      'pendamping': _pendampingCtrl.text.trim().isEmpty ? null : _pendampingCtrl.text.trim(),
      'catatan': 'Tujuan: ${_tujuanCtrl.text.trim()}',
    });
  }

  InputDecoration _dec(String hint) => InputDecoration(
        counterText: '',
        filled: true,
        fillColor: PColors.background,
        hintText: hint,
        hintStyle: PText.bodySm,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final nama = _santri?['nama']?.toString() ?? 'Belum ada data santri';
    final nis = _santri?['nis']?.toString() ?? '-';
    final kamar = _santri?['asrama']?.toString();
    final kelasRaw = _santri?['kelas'];
    final kelas = kelasRaw is Map ? kelasRaw['namaKelas']?.toString() : kelasRaw?.toString();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 660),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: PColors.surface, borderRadius: BorderRadius.circular(26)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header gradien
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PTheme.primary, PTheme.primaryEnd],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: PColors.gold.withOpacity(0.7)),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: PColors.gold),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catat Izin Santri',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Form Perizinan Resmi',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: Colors.white),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Pilih Santri'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _gantiSantri,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _InitialAvatar(nama: nama, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PText.bodyMd.copyWith(
                                        color: PColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text('NIS: $nis', style: PText.bodySm),
                                        if ((kelas != null && kelas.isNotEmpty) || (kamar != null && kamar.isNotEmpty))
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: PColors.surface,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              [
                                                if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas',
                                                if (kamar != null && kamar.isNotEmpty) 'Kamar $kamar',
                                              ].join(' • '),
                                              style: PText.bodySm.copyWith(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.santris.length > 1)
                                const Icon(Icons.unfold_more, size: 18, color: PColors.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _requiredLabel('Jenis Izin'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _jenisToggle('KELUAR', Icons.directions_walk, 'Izin Keluar')),
                          const SizedBox(width: 8),
                          Expanded(child: _jenisToggle('PULANG', Icons.home_outlined, 'Izin Pulang')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _requiredLabel('Alasan Izin'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _alasanCtrl,
                        maxLength: 100,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: _dec('Contoh: Kepentingan keluarga, berobat, dll.'),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _requiredLabel('Tanggal & Jam Keluar'),
                                const SizedBox(height: 6),
                                _pickerField(
                                  text:
                                      '${_tanggalKeluar.day} ${_bulanPendek[_tanggalKeluar.month - 1]} ${_tanggalKeluar.year}, ${_fmtJam(_jamKeluar)}',
                                  icon: Icons.calendar_today_outlined,
                                  onTap: _pilihTanggalKeluar,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _requiredLabel('Est. Kembali'),
                                const SizedBox(height: 6),
                                _pickerField(
                                  text: _fmtJam(_estKembali),
                                  icon: Icons.access_time,
                                  onTap: _pilihEstKembali,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _requiredLabel('Tujuan'),
                          const Spacer(),
                          Text('${_tujuanCtrl.text.length}/100', style: PText.bodySm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _tujuanCtrl,
                        maxLength: 100,
                        maxLines: 2,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: _dec('Contoh: Toko Buku & Apotek'),
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          text: 'Diantar / Didampingi Oleh ',
                          style: PText.labelMd.copyWith(color: PColors.ink),
                          children: [TextSpan(text: '(Opsional)', style: PText.bodySm)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pendampingCtrl,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: _dec('Nama penjemput / pendamping (misal: Ayah/Wali)'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: const BoxDecoration(
                  color: PColors.surface,
                  border: Border(top: BorderSide(color: PColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text(
                          'Batal',
                          style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: PTheme.primary,
                            foregroundColor: PColors.gold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text(
                            'Simpan Izin',
                            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Text.rich(
      TextSpan(
        text: text,
        style: PText.labelMd.copyWith(color: PColors.ink),
        children: [
          TextSpan(text: ' *', style: TextStyle(color: PColors.errorText, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _jenisToggle(String value, IconData icon, String label) {
    final selected = _jenis == value;
    return InkWell(
      onTap: () => setState(() => _jenis = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : PColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? PColors.gold.withOpacity(0.6) : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? PColors.gold : PColors.inkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : PColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerField({required String text, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(icon, size: 16, color: PColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}