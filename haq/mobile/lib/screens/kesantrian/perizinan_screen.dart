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
// disembunyikan, tidak akan error. Tandai di PRD/endpoint kalau mau dipakai:
//   - nomorRegistrasi        : String   (mis. "IIP-202502-019")
//   - kategori               : String   (mis. "Keluarga" -> "Izin Pulang (Keluarga)")
//   - penjemput              : String
//   - disahkanOleh           : String   (nama + jabatan musyrif)
//   - adabSantri             : String   (override teks adab; ada default statis)
//   - rencanaKembali/tenggatKembali : String ISO datetime (untuk hero + countdown)
//   - checkInPosko           : String ISO datetime
//   - diprosesOleh           : String   (nama petugas posko/musyrif)
//   - pendamping, divisi     : String   (khusus Izin Keluar)
//   - jadwalKembaliBatas, waktuTiba : String ISO datetime (khusus status TELAT)
//   - menitTelat             : num
//   - catatanKeterlambatan   : String
//   - alasanPenolakan        : String
//   - tanggalDiajukan        : String ISO date
//   - pihakProses            : String   (mis. "Pengasuhan" -> badge "Ditolak Pengasuhan")
// ============================================================================

class PerizinanScreen extends StatefulWidget {
  const PerizinanScreen({super.key});

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
    // Refresh tiap menit supaya countdown "Sisa X Jam Y Menit" di kartu
    // izin aktif terasa real-time, sesuai narasi di banner info wali.
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
      // Catatan: filter "hanya anak sendiri" untuk Wali sudah ditangani
      // di backend (KesantrianService.findAllPerizinan), jadi di sini
      // tidak perlu filter tambahan di sisi klien.
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
        final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
        if (mounted) setState(() => _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AjukanIzinDialog(santris: _santris),
    );
    if (result == null) return;

    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.perizinan, result);
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PTheme.primary, content: const Text('Izin berhasil diajukan.')),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.errorText, content: Text(e.message)),
      );
    }
  }

  Future<void> _action(Map<String, dynamic> p, String status) async {
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.patch('${ApiUrl.perizinan}/${p['id']}', {
        'statusApproval': status,
        if (status == 'KEMBALI' || status == 'TELAT')
          'tanggalKembali': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.errorText, content: Text(e.message)),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Helper data khusus tampilan Wali
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

  /// Izin yang sedang berjalan: sudah DISETUJUI tapi belum tercatat kembali.
  Map<String, dynamic>? get _perizinanBerjalan {
    for (final p in _itemsUntukAnak) {
      if (p['statusApproval'] == 'DISETUJUI' && p['tanggalKembali'] == null) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> get _riwayatSemua {
    final berjalan = _perizinanBerjalan;
    return _itemsUntukAnak.where((p) => p != berjalan).toList();
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

  String _hitungSisaWaktu(Map<String, dynamic> p) {
    final iso = (p['tenggatKembali'] ?? p['rencanaKembali'] ?? p['tanggalKembaliRencana'])?.toString();
    if (iso == null || iso.isEmpty) return '—';
    DateTime target;
    try {
      target = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '—';
    }
    return _fmtSisaWaktu(target);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Pilih Anak', style: PText.headlineSm),
            const SizedBox(height: 4),
            for (final e in map.entries)
              ListTile(
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
  // Bagian header khusus Wali (identitas anak, banner, kartu izin aktif)
  // ---------------------------------------------------------------------

  List<Widget> _buildWaliHeader() {
    final anak = _anakAktif;
    final berjalan = _perizinanBerjalan;
    return [
      Row(
        children: [
          Expanded(child: Text('Portal Wali Santri', style: PText.labelMd.copyWith(color: PTheme.primary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: PColors.infoBg,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: PColors.infoBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined, size: 12, color: PColors.infoText),
                const SizedBox(width: 4),
                Text(
                  'Mode Pantau (Read-Only)',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: PColors.infoText),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (anak != null) _AnakCard(anak: anak, bisaGanti: _adaLebihDariSatuAnak, onTapGanti: _pilihAnak),
      const SizedBox(height: 12),
      const _InfoBanner(
        text:
            'Pencatatan izin diterbitkan secara terpusat oleh Biro Pengasuhan Santri dan Musyrif Asrama. Wali santri dapat memantau pergerakan jadwal secara real-time.',
      ),
      const SizedBox(height: 16),
      if (berjalan != null) ...[
        _ActivePerizinanCard(p: berjalan, sisaWaktuText: _hitungSisaWaktu(berjalan)),
        const SizedBox(height: 16),
      ],
      const _DisciplineGuideCard(),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildRiwayatHeader() {
    return Row(
      children: [
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Semua Riwayat (${_riwayatSemua.length})',
            selected: _filter == 'SEMUA',
            onTap: () => setState(() => _filter = 'SEMUA'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Izin Pulang ($_countPulang)',
            selected: _filter == 'PULANG',
            onTap: () => setState(() => _filter = 'PULANG'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Izin Keluar ($_countKeluar)',
            selected: _filter == 'KELUAR',
            onTap: () => setState(() => _filter = 'KELUAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildAjukanButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: _add,
        style: FilledButton.styleFrom(
          backgroundColor: PTheme.primary,
          foregroundColor: PColors.gold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text(
          'Ajukan Perizinan',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWali = AppScope.of(context).user?.isWali == true;
    final riwayat = _riwayatTerfilter;

    return Scaffold(
      backgroundColor: PColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: _loading
                ? loadingView()
                : _error != null
                    ? errorView(_error!, _load)
                    : RefreshIndicator(
                        color: PTheme.primary,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (isWali) ..._buildWaliHeader(),
                            _buildRiwayatHeader(),
                            const SizedBox(height: 10),
                            _buildFilterChips(),
                            const SizedBox(height: 12),
                            if (!isWali) ...[
                              _buildAjukanButton(),
                              const SizedBox(height: 14),
                            ],
                            if (riwayat.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: emptyView('Belum ada perizinan.'),
                              )
                            else
                              for (final p in riwayat)
                                _RiwayatTile(
                                  p: p,
                                  showActions: !isWali,
                                  onApprove: p['statusApproval'] == 'DIAJUKAN' ? () => _action(p, 'DISETUJUI') : null,
                                  onReject: p['statusApproval'] == 'DIAJUKAN' ? () => _action(p, 'DITOLAK') : null,
                                  onReturn: p['statusApproval'] == 'DISETUJUI' ? () => _action(p, 'KEMBALI') : null,
                                ),
                            if (isWali) ...[
                              const SizedBox(height: 20),
                              const _ClosingCard(),
                            ],
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Format & helper murni (tanggal, sisa waktu, tahun ajaran)
// ===========================================================================

const _bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

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

String _fmtSisaWaktu(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.isNegative) {
    final d = diff.abs();
    return 'Lewat ${d.inHours} Jam ${d.inMinutes % 60} Menit';
  }
  return 'Sisa ${diff.inHours} Jam ${diff.inMinutes % 60} Menit';
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
      final sudahKembali = p['tanggalKembali'] != null;
      return sudahKembali
          ? const _ResolvedStatus(
              'Kembali',
              _StatusStyle(PColors.successBg, PColors.successText, PColors.successBorder),
            )
          : const _ResolvedStatus(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: s.border),
      ),
      child: Text(
        resolved.label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: s.fg,
        ),
      ),
    );
  }
}

// ===========================================================================
// Header khusus Wali: banner info, kartu anak, kartu izin aktif, panduan
// ===========================================================================

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: PColors.infoText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: PText.bodySm.copyWith(color: PColors.infoText, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _AnakCard extends StatelessWidget {
  const _AnakCard({required this.anak, required this.bisaGanti, required this.onTapGanti});

  final Map<String, dynamic> anak;
  final bool bisaGanti;
  final VoidCallback onTapGanti;

  @override
  Widget build(BuildContext context) {
    final nama = anak['nama']?.toString() ?? '-';
    final kelasMap = anak['kelas'];
    final kelas = kelasMap is Map ? kelasMap['namaKelas']?.toString() : null;
    final nis = anak['nis']?.toString();
    final asrama = anak['asrama']?.toString();
    final inisial = nama.trim().isEmpty
        ? '?'
        : nama.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    return GestureDetector(
      onTap: bisaGanti ? onTapGanti : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [PTheme.primary, PTheme.primaryEnd]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                inisial,
                style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: PText.headlineSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas',
                      if (nis != null && nis.isNotEmpty) 'NIS $nis',
                      if (asrama != null && asrama.isNotEmpty) asrama,
                    ].join(' • '),
                    style: PText.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (bisaGanti) const Icon(Icons.unfold_more_rounded, color: PColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _ActivePerizinanCard extends StatelessWidget {
  const _ActivePerizinanCard({required this.p, required this.sisaWaktuText});

  final Map<String, dynamic> p;
  final String sisaWaktuText;

  @override
  Widget build(BuildContext context) {
    final jenis = p['jenis'] == 'PULANG' ? 'Izin Pulang' : 'Izin Keluar';
    final kategori = (p['kategori'] as String?)?.trim();
    final judul = (kategori != null && kategori.isNotEmpty) ? '$jenis ($kategori)' : jenis;
    final penjemput = p['penjemput']?.toString();
    final disahkan = (p['disahkanOleh'] ?? p['disetujuiOlehNama'])?.toString();
    final adabOverride = (p['adabSantri'] as String?)?.trim();
    final adab = (adabOverride != null && adabOverride.isNotEmpty)
        ? adabOverride
        : 'Wajib melapor langsung ke pos piket keamanan gerbang utama & konfirmasi kehadiran ke musyrif saat tiba di asrama.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PTheme.primary, PTheme.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9999)),
                child: Text(
                  judul,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: PColors.gold.withOpacity(0.18), borderRadius: BorderRadius.circular(9999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: PColors.gold, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text(
                      'Sedang Berjalan',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: PColors.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'KEPERLUAN & ALASAN IZIN',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: PColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            p['alasan']?.toString() ?? '-',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
          ),
          if (penjemput != null && penjemput.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.family_restroom_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Penjemput: $penjemput', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroDateCol(label: 'Tanggal Keluar', value: _fmtTanggal(p['tanggalKeluar']?.toString(), withHari: true)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white54),
              ),
              Expanded(
                child: _HeroDateCol(
                  label: 'Rencana Kembali',
                  value: _fmtTanggal((p['rencanaKembali'] ?? p['tanggalKembaliRencana'])?.toString(), withHari: true),
                  footnote: '(Batas Masuk)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Tenggat Kembali', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: PColors.gold, borderRadius: BorderRadius.circular(9999)),
                  child: Text(
                    sisaWaktuText,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: PTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          if (disahkan != null && disahkan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Disahkan: $disahkan', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Adab Santri: $adab',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroDateCol extends StatelessWidget {
  const _HeroDateCol({required this.label, required this.value, this.footnote});
  final String label;
  final String value;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
          maxLines: 2,
        ),
        if (footnote != null) Text(footnote!, style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}

class _DisciplineGuideCard extends StatelessWidget {
  const _DisciplineGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.shield_outlined, size: 16, color: PTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panduan Disiplin & Keterlambatan', style: PText.labelLg),
                const SizedBox(height: 4),
                Text(
                  'Apabila santri belum check-in di posko keamanan setelah pukul 17:00 WIB, sistem secara otomatis menerbitkan status "Telat" dengan notifikasi resmi kepada wali santri dan musyrif pembina.',
                  style: PText.bodySm.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : PColors.surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: selected ? PTheme.primary : PColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? PColors.gold : PColors.inkSecondary,
          ),
        ),
      ),
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
          style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w600),
          maxLines: 2,
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
        borderRadius: BorderRadius.circular(10),
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
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: PColors.errorText),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: PColors.errorText, height: 1.4),
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

class _RiwayatTile extends StatelessWidget {
  const _RiwayatTile({
    required this.p,
    required this.showActions,
    this.onApprove,
    this.onReject,
    this.onReturn,
  });

  final Map<String, dynamic> p;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveStatus(p);
    final status = p['statusApproval'] as String?;
    final jenisLabel = p['jenis'] == 'PULANG' ? 'Izin Pulang' : 'Izin Keluar';
    final alasan = p['alasan']?.toString() ?? '-';
    final nomor = p['nomorRegistrasi']?.toString();
    final santriMap = p['santri'];
    final namaSantri = santriMap is Map ? santriMap['nama']?.toString() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 1, right: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status == 'DITOLAK' ? PColors.errorBg : PTheme.sage,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_iconForJenis(p), size: 15, color: status == 'DITOLAK' ? PColors.errorText : PTheme.primary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showActions && namaSantri != null && namaSantri.isNotEmpty)
                      Text(
                        namaSantri,
                        style: PText.bodySm.copyWith(color: PColors.inkSecondary, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '$jenisLabel ${_ringkasanSingkat(alasan)}',
                      style: PText.labelLg.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(resolved: resolved),
            ],
          ),
          if (nomor != null && nomor.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Nomor Registrasi: $nomor', style: PText.bodySm.copyWith(fontFamily: 'monospace', letterSpacing: 0.2)),
          ],
          const SizedBox(height: 6),
          Text(alasan, style: PText.bodyMd.copyWith(color: PColors.ink)),
          const SizedBox(height: 10),
          ..._buildDetailRows(),
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
          if (showActions && (onApprove != null || onReject != null || onReturn != null)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(child: _POutlinedButton(label: 'Setujui', color: PColors.successText, onPressed: onApprove!)),
                if (onApprove != null && onReject != null) const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(child: _POutlinedButton(label: 'Tolak', color: PColors.errorText, onPressed: onReject!)),
                if (onReturn != null)
                  Expanded(child: _POutlinedButton(label: 'Tandai Kembali', color: PTheme.primary, onPressed: onReturn!)),
              ],
            ),
          ],
        ],
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
          const SizedBox(height: 6),
          _PairRow(
            left: _KV('Check-in Posko', _fmtTanggal((p['checkInPosko'] ?? p['tanggalKembali'])?.toString())),
            right: _KV('Petugas', (p['diprosesOleh'] ?? p['disetujuiOlehNama'])?.toString() ?? '-'),
          ),
        ],
      ];
    }

    // Sedang berjalan (jaga-jaga kalau muncul juga di riwayat)
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
          left: _KV('Jadwal', '${_fmtTanggal(p['tanggalKeluar']?.toString())} – ${_fmtJamSaja(p['jadwalKembaliBatas']?.toString())}'),
          right: _KV('Tiba', _fmtJamSaja((p['waktuTiba'] ?? p['tanggalKembali'])?.toString())),
        ),
      ];
    }

    // Ditolak
    if (status == 'DITOLAK') {
      return [
        _PairRow(
          left: _KV('Tanggal Diajukan', _fmtTanggal((p['tanggalDiajukan'] ?? p['createdAt'] ?? p['tanggalKeluar'])?.toString(), withJam: false)),
          right: _KV('Pihak Proses', p['pihakProses']?.toString() ?? '-'),
        ),
      ];
    }

    // Diajukan / status lain
    final estKembali = (p['rencanaKembali'] ?? p['tenggatKembali'])?.toString();
    final pendamping = p['pendamping']?.toString().trim();
    return [
      _PairRow(
        left: _KV('Tanggal Diajukan', _fmtTanggal((p['tanggalDiajukan'] ?? p['tanggalKeluar'])?.toString(), withJam: false)),
        right: _KV('Est. Kembali', (estKembali != null && estKembali.isNotEmpty) ? _fmtTanggal(estKembali) : '-'),
      ),
      const SizedBox(height: 6),
      _PairRow(
        left: const _KV('Status', 'Menunggu persetujuan'),
        right: _KV('Diantar / Didampingi Oleh', (pendamping != null && pendamping.isNotEmpty) ? pendamping : '-'),
      ),
    ];
  }

  String _ringkasanSingkat(String alasan) {
    final t = alasan.trim();
    if (t.isEmpty) return '';
    return '(${t.length > 18 ? '${t.substring(0, 18)}…' : t})';
  }
}

class _POutlinedButton extends StatelessWidget {
  const _POutlinedButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ===========================================================================
// Kartu penutup (Wali) — status "aman", tidak ada pelanggaran izin aktif
// ===========================================================================

class _ClosingCard extends StatelessWidget {
  const _ClosingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: PColors.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, color: PColors.gold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'Alhamdulillah, Tidak Ada\nPelanggaran Izin Aktif',
            textAlign: TextAlign.center,
            style: PText.headlineSm,
          ),
          const SizedBox(height: 8),
          Text(
            'Santri fokus mengikuti seluruh rangkaian ta\'lim, halaqah tahfidz, dan program mutaba\'ah harian asrama dengan tertib dan tenang.',
            textAlign: TextAlign.center,
            style: PText.bodySm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Semoga Allah Menjaga Keistiqamahan Santri',
            textAlign: TextAlign.center,
            style: PText.bodySm.copyWith(fontStyle: FontStyle.italic, color: PTheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'وَأَوْفُوا بِالْعَهْدِ إِنَّ الْعَهْدَ كَانَ مَسْئُولًا',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 16, height: 1.6, color: PColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            '"Dan penuhilah janji; sesungguhnya janji itu pasti diminta pertanggungjawabannya." (QS. Al-Isra\': 34)',
            textAlign: TextAlign.center,
            style: PText.bodySm.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}


// ===========================================================================
// Dialog "Ajukan Izin Santri" — replikasi tampilan mockup: kartu santri
// terpilih, toggle jenis izin, input alasan, tanggal/jam keluar & est.
// kembali, tujuan (dengan counter karakter), pendamping opsional, dan
// banner info verifikasi.
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
        _tanggalKeluar.year, _tanggalKeluar.month, _tanggalKeluar.day, _jamKeluar.hour, _jamKeluar.minute,
      );

  DateTime get _estKembaliLengkap => DateTime(
        _tanggalKeluar.year, _tanggalKeluar.month, _tanggalKeluar.day, _estKembali.hour, _estKembali.minute,
      );

  String _fmtJam(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB';

  Future<void> _pilihTanggalKeluar() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggalKeluar,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null) return;
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
    showModalBottomSheet(
      context: context,
      backgroundColor: PColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Pilih Santri', style: PText.headlineSm),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final s in widget.santris)
                    ListTile(
                      leading: _initialsAvatar(s['nama']?.toString() ?? '-', size: 36),
                      title: Text(s['nama']?.toString() ?? '-', style: PText.bodyMd),
                      subtitle: Text('NIS: ${s['nis'] ?? '-'}', style: PText.bodySm),
                      trailing: _santri?['id'] == s['id'] ? Icon(Icons.check_circle_rounded, color: PTheme.primary) : null,
                      onTap: () {
                        setState(() => _santri = s);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _initialsAvatar(String nama, {double size = 40}) {
    final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase()
            : (parts[0][0] + parts[1][0]).toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: PTheme.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(fontFamily: 'Nunito', fontSize: size * 0.36, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  void _submit() {
    if (_santri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih santri terlebih dahulu.')));
      return;
    }
    if (_alasanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan izin wajib diisi.')));
      return;
    }
    if (_tujuanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tujuan izin wajib diisi.')));
      return;
    }
    setState(() => _submitting = true);
    Navigator.pop(context, {
      'santriId': _santri!['id'],
      'jenis': _jenis,
      'alasan': _alasanCtrl.text.trim(),
      'tanggalKeluar': _tanggalKeluarLengkap.toIso8601String(),
      // NOTE: 'rencanaKembali' & 'pendamping' mengikuti nama field opsional
      // yang sudah diasumsikan di komentar atas file ini. Kalau backend
      // belum punya kolom ini, nilainya cukup diabaikan Prisma/DTO tanpa
      // bikin request gagal — begitu kolomnya ditambahkan, langsung kepakai.
      'rencanaKembali': _estKembaliLengkap.toIso8601String(),
      'pendamping': _pendampingCtrl.text.trim().isEmpty ? null : _pendampingCtrl.text.trim(),
      'catatan': 'Tujuan: ${_tujuanCtrl.text.trim()}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final nama = _santri?['nama']?.toString() ?? 'Belum ada data santri';
    final nis = _santri?['nis']?.toString() ?? '-';
    final kamar = _santri?['asrama']?.toString();
    // 'kelas' dari backend berupa Map {id, namaKelas}; ambil namanya saja.
    final kelasRaw = _santri?['kelas'];
    final kelas = kelasRaw is Map ? kelasRaw['namaKelas']?.toString() : kelasRaw?.toString();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(color: PColors.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: PTheme.primary.withOpacity(0.10), shape: BoxShape.circle),
                      child: Icon(Icons.assignment_turned_in_rounded, color: PTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ajukan Izin Santri', style: PText.headlineSm),
                          const SizedBox(height: 1),
                          Text('Form Perizinan Resmi', style: PText.bodySm),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Pilih Santri'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _gantiSantri,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              _initialsAvatar(nama, size: 38),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Wrap(spacing: 6, runSpacing: 4, children: [
                                      Text('NIS: $nis', style: PText.bodySm),
                                      if ((kelas ?? kamar) != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: PColors.surface, borderRadius: BorderRadius.circular(999)),
                                          child: Text(
                                            [if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas', if (kamar != null && kamar.isNotEmpty) 'Kamar $kamar']
                                                .join(' • '),
                                            style: PText.bodySm.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ]),
                                  ],
                                ),
                              ),
                              if (widget.santris.length > 1)
                                const Icon(Icons.unfold_more, size: 18, color: PColors.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _requiredLabel('Jenis Izin'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _jenisToggle('KELUAR', Icons.directions_walk, 'Izin Keluar')),
                          const SizedBox(width: 8),
                          Expanded(child: _jenisToggle('PULANG', Icons.home_outlined, 'Izin Pulang')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _requiredLabel('Alasan Izin'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _alasanCtrl,
                        maxLength: 100,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: PColors.background,
                          hintText: 'Contoh: Kepentingan keluarga, berobat, dll.',
                          hintStyle: PText.bodySm,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  text: '${_tanggalKeluar.day} ${_bulanPendek[_tanggalKeluar.month - 1]} ${_tanggalKeluar.year}, ${_fmtJam(_jamKeluar)}',
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
                                _pickerField(text: _fmtJam(_estKembali), icon: Icons.access_time, onTap: _pilihEstKembali),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: PColors.background,
                          hintText: 'Contoh: Toko Buku & Apotek',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(text: 'Diantar / Didampingi Oleh ', style: PText.labelMd.copyWith(color: PColors.ink), children: [
                          TextSpan(text: '(Opsional)', style: PText.bodySm),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pendampingCtrl,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: PColors.background,
                          hintText: 'Nama penjemput / pendamping (misal: Ayah/Wali)',
                          hintStyle: PText.bodySm,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: PColors.goldSurface, borderRadius: BorderRadius.circular(999)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.hourglass_bottom, size: 11, color: PColors.gold),
                                const SizedBox(width: 3),
                                Text('Diajukan', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: PColors.gold)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Izin akan diverifikasi oleh Kepala Pengasuhan / Kesantrian.', style: PText.bodySm.copyWith(fontSize: 11)),
                            ),
                            const Icon(Icons.verified_user_outlined, size: 16, color: PColors.inkSecondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: PTheme.primary,
                          foregroundColor: PColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Ajukan Izin', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal', style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700)),
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
      TextSpan(text: text, style: PText.labelMd.copyWith(color: PColors.ink), children: [
        TextSpan(text: ' *', style: TextStyle(color: PColors.errorText, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _jenisToggle(String value, IconData icon, String label) {
    final selected = _jenis == value;
    return InkWell(
      onTap: () => setState(() => _jenis = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : PColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : PColors.inkSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : PColors.inkSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _pickerField({required String text, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Text(text, style: PText.bodySm.copyWith(color: PColors.ink, fontWeight: FontWeight.w600))),
            Icon(icon, size: 16, color: PColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}