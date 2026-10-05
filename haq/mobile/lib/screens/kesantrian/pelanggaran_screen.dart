import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;

// ============================================================================
// Catatan field yang diasumsikan dikirim/diterima backend untuk Pelanggaran:
// Field inti (id, santriId, jenisPelanggaran, poin, tanggal, pelaporId,
// tindakLanjut, status) sudah ada di schema. Field berikut masih ASUMSI
// opsional — kalau backend belum punya kolomnya, nilainya cukup diabaikan
// tanpa bikin request gagal, dan baris terkait di UI otomatis disembunyikan:
//   - keterangan     : String  (deskripsi detail pelanggaran, textarea)
//   - santri (nested): { id, nama, nis, asrama, kelas: { namaKelas } }
//     -> kalau endpoint GET /api/pelanggaran belum nge-include relasi ini,
//        kode akan fallback cari dari daftar /api/santri berdasarkan santriId.
// ============================================================================

const List<Map<String, Object>> _jenisPelanggaranPresets = [
  {'label': 'Keluar Tanpa Izin', 'poin': 3},
  {'label': 'Tidak Jamaah', 'poin': 2},
  {'label': 'Tidak Disiplin', 'poin': 1},
  {'label': 'Terlambat Masuk Jam Belajar', 'poin': 1},
  {'label': 'Membawa Barang Terlarang / HP', 'poin': 5},
];

const List<String> _tindakLanjutOptions = [
  'Tidak ada',
  'Peringatan Lisan',
  'Peringatan Tertulis (SP 1)',
  'Panggilan Orang Tua / Wali',
  'Skorsing Asrama',
];

const _hariIndo = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'];
const _bulanPendekPelanggaran = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

String _initialsOf(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

String _fmtTanggalLengkap(DateTime t) {
  final hari = _hariIndo[t.weekday];
  final jam = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  return '$hari, ${t.day} ${_bulanPendekPelanggaran[t.month - 1]} ${t.year} • $jam WIB';
}

Color _poinBg(int poin) {
  if (poin >= 4) return const Color(0xFFFFE0E0);
  if (poin >= 2) return const Color(0xFFFDEEC9);
  return const Color(0xFFDDF0E3);
}

Color _poinFg(int poin) {
  if (poin >= 4) return const Color(0xFF9F1239);
  if (poin >= 2) return const Color(0xFF92650C);
  return PColors.primary;
}

String _kategoriPoin(int poin) {
  if (poin >= 4) return 'Kategori Berat';
  if (poin >= 2) return 'Kategori Sedang';
  return 'Kategori Ringan';
}

class PelanggaranScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String subtitle;
  const PelanggaranScreen({super.key, this.onBack, this.subtitle = 'Musyrif • Riwayat Pelanggaran'});

  @override
  State<PelanggaranScreen> createState() => _PelanggaranScreenState();
}

class _PelanggaranScreenState extends State<PelanggaranScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _santris = [];

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _timeFilter = 'Semua';
  String _roomFilter = 'Semua Kamar';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final results = await Future.wait([
        api.get(ApiUrl.pelanggaran),
        api.get(ApiUrl.santri, query: {'perPage': '100'}),
      ]);
      final pelanggaranRaw = results[0];
      final santriRaw = results[1];
      final list = (pelanggaranRaw is List ? pelanggaranRaw : (pelanggaranRaw['items'] as List? ?? []))
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final santris = (santriRaw is List ? santriRaw : (santriRaw['items'] as List? ?? []))
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      list.sort((a, b) {
        final ta = DateTime.tryParse(a['tanggal']?.toString() ?? '') ?? DateTime(2000);
        final tb = DateTime.tryParse(b['tanggal']?.toString() ?? '') ?? DateTime(2000);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _all = list;
        _santris = santris;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data pelanggaran: $e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _santriOf(Map<String, dynamic> p) {
    final nested = p['santri'];
    if (nested is Map) return nested.cast<String, dynamic>();
    final id = p['santriId'];
    for (final s in _santris) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  String _kelasLabel(Map<String, dynamic>? santri) {
    final kelasRaw = santri?['kelas'];
    if (kelasRaw is Map) return (kelasRaw['namaKelas'] ?? kelasRaw['nama'] ?? '-').toString();
    return kelasRaw?.toString() ?? '-';
  }

  List<String> get _rooms {
    final set = <String>{};
    for (final p in _all) {
      final asrama = _santriOf(p)?['asrama']?.toString();
      if (asrama != null && asrama.isNotEmpty) set.add(asrama);
    }
    final sorted = set.toList()..sort();
    return ['Semua Kamar', ...sorted];
  }

  bool _matchesTime(DateTime t, String filter) {
    final now = DateTime.now();
    if (filter == 'Minggu Ini') return now.difference(t).inDays <= 7;
    if (filter == 'Bulan Ini') return t.year == now.year && t.month == now.month;
    return true;
  }

  int _countTime(String filter) {
    return _all.where((p) {
      final t = DateTime.tryParse(p['tanggal']?.toString() ?? '');
      return t != null && _matchesTime(t, filter);
    }).length;
  }

  List<Map<String, dynamic>> get _filtered {
    return _all.where((p) {
      final santri = _santriOf(p);
      final nama = (santri?['nama'] ?? '').toString().toLowerCase();
      final nis = (santri?['nis'] ?? '').toString().toLowerCase();
      final jenis = (p['jenisPelanggaran'] ?? '').toString().toLowerCase();
      final matchQuery = _query.isEmpty || nama.contains(_query) || nis.contains(_query) || jenis.contains(_query);

      final matchRoom = _roomFilter == 'Semua Kamar' || (santri?['asrama']?.toString() == _roomFilter);

      final t = DateTime.tryParse(p['tanggal']?.toString() ?? '');
      final matchTime = t == null || _matchesTime(t, _timeFilter);

      return matchQuery && matchRoom && matchTime;
    }).toList();
  }

  Future<void> _tandaiSelesai(Map<String, dynamic> p) async {
    try {
      final api = AppScope.of(context).api;
      await api.patch('${ApiUrl.pelanggaran}/${p['id']}', {'status': 'SELESAI'});
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openInput() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InputPelanggaranDialog(santris: _santris, allPelanggaran: _all),
    );
    if (result == null) return;
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.pelanggaran, result);
      _load(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE8F5E9),
          content: Text('Pelanggaran berhasil dicatat. Wali santri telah dikirim notifikasi.',
              style: TextStyle(color: Color(0xFF1B5E20))),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWali = AppScope.of(context).user?.isWali == true;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildFilterBar(),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : RefreshIndicator(
                              onRefresh: () => _load(showSpinner: false),
                              child: filtered.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                      children: [emptyView(_all.isEmpty ? 'Belum ada catatan pelanggaran.' : 'Tidak ada hasil yang cocok.')],
                                    )
                                  : ListView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) => _pelanggaranCard(filtered[i]),
                                    ),
                            ),
                ),
              ],
            ),
                // Tombol berada di dalam kotak konten (maxWidth 480), tetap di bawah.
                if (!isWali)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _openInput,
                      backgroundColor: PColors.primary,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text('Catat Pelanggaran',
                          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: PColors.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              onPressed: widget.onBack,
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: PColors.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Riwayat Pelanggaran', style: TextStyle(fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1B1C1A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: PColors.primary, borderRadius: BorderRadius.circular(999)),
                    child: Text('${_all.length} Catatan', style: const TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 1),
                Text(widget.subtitle, style: PText.bodySm),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Filter Lanjutan',
            icon: const Icon(Icons.tune, color: PColors.inkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: PColors.background,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: PText.bodyMd.copyWith(color: PColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: 'Cari nama santri, NIS, atau pelanggaran...',
                hintStyle: PText.bodySm,
                prefixIcon: const Icon(Icons.search, size: 20, color: PColors.inkSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _searchCtrl.clear()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in ['Semua', 'Minggu Ini', 'Bulan Ini']) ...[
                  _chip(label: f, count: f == 'Semua' ? null : _countTime(f), selected: _timeFilter == f, onTap: () => setState(() => _timeFilter = f)),
                  const SizedBox(width: 8),
                ],
                Container(width: 1, height: 22, color: PColors.inkSecondary.withOpacity(0.25), margin: const EdgeInsets.symmetric(horizontal: 2)),
                const SizedBox(width: 8),
                for (final r in _rooms) ...[
                  _chip(label: r, selected: _roomFilter == r, onTap: () => setState(() => _roomFilter = r)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, int? count, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : PColors.inkSecondary)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.25) : PColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : PColors.ink)),
            ),
          ],
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------
  Widget _pelanggaranCard(Map<String, dynamic> p) {
    final santri = _santriOf(p);
    final nama = (santri?['nama'] ?? 'Santri').toString();
    final nis = (santri?['nis'] ?? '-').toString();
    final kelas = _kelasLabel(santri);
    final jenis = (p['jenisPelanggaran'] ?? '-').toString();
    final keterangan = p['keterangan']?.toString().trim();
    final poin = (p['poin'] as num?)?.toInt() ?? 0;
    final status = (p['status'] ?? 'DICATAT').toString();
    final selesai = status != 'DICATAT';
    final tindakLanjut = p['tindakLanjut']?.toString().trim();
    final tanggal = DateTime.tryParse(p['tanggal']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: PColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initialsOf(nama), style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: PColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 1),
                    Text('NIS $nis • Kelas $kelas', maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: selesai ? const Color(0xFFDDF0E3) : const Color(0xFFFDEEC9), borderRadius: BorderRadius.circular(999)),
                child: Text(selesai ? 'Selesai' : 'Pending',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: selesai ? PColors.primary : const Color(0xFF92650C))),
              ),
              if (!selesai)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: PColors.inkSecondary),
                  onSelected: (v) {
                    if (v == 'selesai') _tandaiSelesai(p);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'selesai', child: Text('Tandai Selesai')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jenis, style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700)),
                      if (keterangan != null && keterangan.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(keterangan, maxLines: 2, overflow: TextOverflow.ellipsis, style: PText.bodySm.copyWith(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _poinBg(poin), borderRadius: BorderRadius.circular(999)),
                  child: Text('+$poin Poin', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: _poinFg(poin))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (tanggal != null)
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: PColors.inkSecondary),
              const SizedBox(width: 5),
              Text(_fmtTanggalLengkap(tanggal), style: PText.bodySm.copyWith(fontSize: 11.5)),
            ]),
          if (tindakLanjut != null && tindakLanjut.isNotEmpty && tindakLanjut != 'Tidak ada') ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.fact_check_outlined, size: 12, color: PColors.inkSecondary),
                const SizedBox(width: 4),
                Text('Tindak Lanjut: $tindakLanjut', style: PText.bodySm.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Dialog "Input Pelanggaran" — replikasi tampilan mockup HTML.
// ===========================================================================
class _InputPelanggaranDialog extends StatefulWidget {
  const _InputPelanggaranDialog({required this.santris, required this.allPelanggaran});
  final List<Map<String, dynamic>> santris;
  final List<Map<String, dynamic>> allPelanggaran;

  @override
  State<_InputPelanggaranDialog> createState() => _InputPelanggaranDialogState();
}

class _InputPelanggaranDialogState extends State<_InputPelanggaranDialog> {
  Map<String, dynamic>? _santri;
  Map<String, Object>? _jenisTerpilih;
  final _keteranganCtrl = TextEditingController();
  String _tindakLanjut = _tindakLanjutOptions[1];
  bool _submitting = false;
  String? _errorSantri;
  String? _errorJenis;

  @override
  void initState() {
    super.initState();
    _santri = widget.santris.isEmpty ? null : widget.santris.first;
    _keteranganCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  int _countPelanggaranFor(String santriId) {
    return widget.allPelanggaran.where((p) => p['santriId'] == santriId).length;
  }

  String _kelasKamarLabel(Map<String, dynamic> s) {
    final kelasRaw = s['kelas'];
    final kelas = kelasRaw is Map ? (kelasRaw['namaKelas'] ?? kelasRaw['nama'])?.toString() : kelasRaw?.toString();
    final kamar = s['asrama']?.toString();
    final parts = [if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas', if (kamar != null && kamar.isNotEmpty) 'Kamar $kamar'];
    return parts.isEmpty ? '-' : parts.join(' • ');
  }

  void _pilihSantri() {
    if (widget.santris.isEmpty) return;
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
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final s in widget.santris)
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(_initialsOf(s['nama']?.toString() ?? '-'),
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      title: Text(s['nama']?.toString() ?? '-', style: PText.bodyMd),
                      subtitle: Text('NIS: ${s['nis'] ?? '-'} • ${_kelasKamarLabel(s)}', style: PText.bodySm),
                      trailing: Text(
                        _countPelanggaranFor(s['id'].toString()) == 0 ? 'Disiplin' : '${_countPelanggaranFor(s['id'].toString())} Pelanggaran',
                        style: PText.bodySm.copyWith(
                          color: _countPelanggaranFor(s['id'].toString()) == 0 ? PColors.primary : const Color(0xFF92650C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _santri = s;
                          _errorSantri = null;
                        });
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

  void _submit() {
    bool valid = true;
    setState(() {
      _errorSantri = _santri == null ? 'Silakan pilih santri terlebih dahulu.' : null;
      _errorJenis = _jenisTerpilih == null ? 'Jenis pelanggaran wajib dipilih.' : null;
    });
    if (_errorSantri != null || _errorJenis != null) valid = false;
    if (!valid) return;

    setState(() => _submitting = true);
    Navigator.pop(context, {
      'santriId': _santri!['id'],
      'jenisPelanggaran': _jenisTerpilih!['label'],
      'poin': _jenisTerpilih!['poin'],
      'tanggal': DateTime.now().toIso8601String(),
      'tindakLanjut': _tindakLanjut == 'Tidak ada' ? null : _tindakLanjut,
      // NOTE: 'keterangan' belum tentu punya kolom di schema saat ini — lihat
      // komentar di atas file. Dikirim tetap, aman diabaikan kalau belum ada.
      'keterangan': _keteranganCtrl.text.trim().isEmpty ? null : _keteranganCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final nama = _santri?['nama']?.toString() ?? 'Belum ada data santri';
    final nis = _santri?['nis']?.toString() ?? '-';
    final poin = (_jenisTerpilih?['poin'] as int?) ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
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
                      decoration: BoxDecoration(color: PColors.primary.withOpacity(0.10), shape: BoxShape.circle),
                      child: const Icon(Icons.gavel, color: PColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Input Pelanggaran', style: PText.headlineSm),
                          const SizedBox(height: 1),
                          Text('Form Pencatatan Resmi', style: PText.bodySm),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20), tooltip: 'Tutup'),
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
                        onTap: _pilihSantri,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: _errorSantri != null ? Border.all(color: Colors.red, width: 1.4) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(_initialsOf(nama), style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('NIS: $nis${_santri != null ? ' • ${_kelasKamarLabel(_santri!)}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm),
                                  ],
                                ),
                              ),
                              if (widget.santris.length > 1) const Icon(Icons.unfold_more, size: 18, color: PColors.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (_errorSantri != null) ...[
                        const SizedBox(height: 4),
                        Text(_errorSantri!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),
                      _requiredLabel('Jenis Pelanggaran'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: PColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: _errorJenis != null ? Border.all(color: Colors.red, width: 1.4) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, Object>>(
                            value: _jenisTerpilih,
                            isExpanded: true,
                            hint: Text('Pilih jenis pelanggaran...', style: PText.bodySm),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            style: PText.bodyMd.copyWith(color: PColors.ink),
                            items: [
                              for (final j in _jenisPelanggaranPresets)
                                DropdownMenuItem(value: j, child: Text('${j['label']} (${j['poin']} poin)')),
                            ],
                            onChanged: (v) => setState(() {
                              _jenisTerpilih = v;
                              _errorJenis = null;
                            }),
                          ),
                        ),
                      ),
                      if (_errorJenis != null) ...[
                        const SizedBox(height: 4),
                        Text(_errorJenis!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Poin', style: PText.labelMd.copyWith(color: PColors.ink)),
                          Text('Otomatis terisi berdasarkan jenis', style: PText.bodySm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(color: PColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.stars, size: 18, color: PColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('$poin Poin Pelanggaran', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: PColors.primary)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _poinBg(poin), borderRadius: BorderRadius.circular(999)),
                              child: Text(_kategoriPoin(poin), style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: _poinFg(poin))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text.rich(TextSpan(text: 'Keterangan ', style: PText.labelMd.copyWith(color: PColors.ink), children: [
                            TextSpan(text: '(Opsional)', style: PText.bodySm),
                          ])),
                          const Spacer(),
                          Text('${_keteranganCtrl.text.length}/500', style: PText.bodySm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _keteranganCtrl,
                        maxLength: 500,
                        maxLines: 3,
                        style: PText.bodyMd.copyWith(color: PColors.ink),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: PColors.background,
                          hintText: 'Jelaskan detail pelanggaran...',
                          hintStyle: PText.bodySm,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(TextSpan(text: 'Tindak Lanjut ', style: PText.labelMd.copyWith(color: PColors.ink), children: [
                        TextSpan(text: '(Opsional)', style: PText.bodySm),
                      ])),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _tindakLanjut,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            style: PText.bodyMd.copyWith(color: PColors.ink),
                            items: [for (final t in _tindakLanjutOptions) DropdownMenuItem(value: t, child: Text(t))],
                            onChanged: (v) => setState(() => _tindakLanjut = v ?? _tindakLanjut),
                          ),
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
                          backgroundColor: PColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 17),
                        label: const Text('Simpan Pelanggaran', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
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
    return Text.rich(TextSpan(text: text, style: PText.labelMd.copyWith(color: PColors.ink), children: const [
      TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
    ]));
  }
}