import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;

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
    final alasan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;
    String jenis = 'KELUAR';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Ajukan Perizinan',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TwSelect(
              value: jenis,
              label: 'Jenis',
              options: const [
                DropdownOption('KELUAR', 'Izin Keluar'),
                DropdownOption('PULANG', 'Pulang'),
              ],
              onChanged: (v) => setLocal(() => jenis = v!),
            ),
            _PDialogField(controller: alasan, label: 'Alasan'),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: PColors.inkSecondary),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: PColors.primary,
                foregroundColor: PColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text('Ajukan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.perizinan, {
        'santriId': santriId,
        'jenis': jenis,
        'alasan': alasan.text.trim(),
        'tanggalKeluar': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.primary, content: const Text('Perizinan diajukan.')),
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
                    ? const Icon(Icons.check_circle_rounded, color: PColors.primary)
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
          Expanded(child: Text('Portal Wali Santri', style: PText.labelMd.copyWith(color: PColors.primary))),
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

  @override
  Widget build(BuildContext context) {
    final isWali = AppScope.of(context).user?.isWali == true;
    final riwayat = _riwayatTerfilter;

    return Scaffold(
      backgroundColor: PColors.background,
      floatingActionButton: isWali
          ? null
          : FloatingActionButton(
              onPressed: _add,
              tooltip: 'Ajukan Izin',
              backgroundColor: PColors.primary,
              foregroundColor: PColors.gold,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: _loading
                ? loadingView()
                : _error != null
                    ? errorView(_error!, _load)
                    : RefreshIndicator(
                        color: PColors.primary,
                        onRefresh: _load,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, isWali ? 24 : 96),
                          children: [
                            if (isWali) ..._buildWaliHeader(),
                            _buildRiwayatHeader(),
                            const SizedBox(height: 10),
                            _buildFilterChips(),
                            const SizedBox(height: 12),
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
                gradient: const LinearGradient(colors: [PColors.primary, PColors.primaryGradientEnd]),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PColors.primary, PColors.primaryGradientEnd],
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
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: PColors.primary),
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
            decoration: BoxDecoration(color: PColors.sage, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, size: 16, color: PColors.primary),
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
          color: selected ? PColors.primary : PColors.surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: selected ? PColors.primary : PColors.border),
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
                  color: status == 'DITOLAK' ? PColors.errorBg : PColors.sage,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_iconForJenis(p), size: 15, color: status == 'DITOLAK' ? PColors.errorText : PColors.primary),
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
                  Expanded(child: _POutlinedButton(label: 'Tandai Kembali', color: PColors.primary, onPressed: onReturn!)),
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
    return [
      _PairRow(
        left: _KV('Tanggal Diajukan', _fmtTanggal((p['tanggalDiajukan'] ?? p['tanggalKeluar'])?.toString(), withJam: false)),
        right: const _KV('Status', 'Menunggu persetujuan'),
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
            style: PText.bodySm.copyWith(fontStyle: FontStyle.italic, color: PColors.primary, fontWeight: FontWeight.w700),
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

class _PDialogField extends StatelessWidget {
  const _PDialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: PText.bodyMd.copyWith(color: PColors.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: PText.bodyMd,
          filled: true,
          fillColor: PColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}