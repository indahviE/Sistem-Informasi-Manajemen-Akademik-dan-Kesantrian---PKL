import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../p_theme.dart';
import '../signup_screen.dart' show PText;

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
const _bulanPanjangPelanggaran = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember'
];

const Color _kBorder = Color(0xFFE9E8E2);

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
  if (poin >= 4) return const Color(0xFFFFE4E6);
  if (poin >= 2) return const Color(0xFFFEF0CC);
  return const Color(0xFFDDF0E3);
}

Color _poinFg(int poin) {
  if (poin >= 4) return const Color(0xFFBE123C);
  if (poin >= 2) return const Color(0xFF92650C);
  return PTheme.primary;
}

String _kategoriPoin(int poin) {
  if (poin >= 4) return 'Berat';
  if (poin >= 2) return 'Sedang';
  return 'Ringan';
}

/// Ambil SEMUA santri (bukan hanya halaman pertama). Loop per halaman sampai
/// habis; kalau backend mengabaikan parameter `page`, loop berhenti sendiri
/// karena tidak ada santri baru.
Future<List<Map<String, dynamic>>> _fetchSemuaSantri(dynamic api) async {
  const perPage = 100;
  final byId = <String, Map<String, dynamic>>{};
  for (var page = 1; page <= 50; page++) {
    dynamic res;
    try {
      res = await api.get(ApiUrl.santri, query: {'perPage': '$perPage', 'page': '$page'});
    } catch (_) {
      if (page == 1) rethrow;
      break;
    }
    final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
    final items = (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    var baru = 0;
    for (final s in items) {
      final id = s['id']?.toString();
      if (id != null && !byId.containsKey(id)) {
        byId[id] = s;
        baru++;
      }
    }
    if (baru == 0 || items.length < perPage) break;
  }
  return byId.values.toList();
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

  bool get _isWali => AppScope.of(context).user?.isWali == true;
  bool get _isPimpinan => AppScope.of(context).user?.isPimpinan == true;

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
      final isWali = _isWali;
      final results = await Future.wait<dynamic>([
        api.get(ApiUrl.pelanggaran),
        isWali ? api.get(ApiUrl.waliMe) : _fetchSemuaSantri(api),
      ]);
      final pelanggaranRaw = results[0];
      final santriRaw = isWali ? (results[1] is Map ? (results[1] as Map)['santris'] : null) : results[1];
      final list = (pelanggaranRaw is List ? pelanggaranRaw : (pelanggaranRaw['items'] as List? ?? []))
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final santris = (santriRaw is List ? santriRaw : (santriRaw is Map ? (santriRaw['items'] as List? ?? []) : []))
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      list.sort((a, b) {
        final ta = DateTime.tryParse(a['tanggal']?.toString() ?? '')?.toLocal() ?? DateTime(2000);
        final tb = DateTime.tryParse(b['tanggal']?.toString() ?? '')?.toLocal() ?? DateTime(2000);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _all = list;
        _santris = santris;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data pelanggaran: $e';
          _loading = false;
        });
      }
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
      final t = DateTime.tryParse(p['tanggal']?.toString() ?? '')?.toLocal();
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

      final t = DateTime.tryParse(p['tanggal']?.toString() ?? '')?.toLocal();
      final matchTime = t == null || _matchesTime(t, _timeFilter);

      return matchQuery && matchRoom && matchTime;
    }).toList();
  }

  /// Notifikasi melayang bertema (sama dengan `_toast` di absensi_screen.dart).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
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
            side: BorderSide(
              color: error ? errorText.withOpacity(0.25) : gold.withOpacity(0.5),
            ),
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
                    Text(title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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
      String? nama;
      for (final s in _santris) {
        if (s['id'] == result['santriId']) nama = s['nama']?.toString();
      }
      _toast('Pelanggaran berhasil dicatat',
          subtitle: '${nama ?? 'Santri'} • +${result['poin']} poin • Wali telah dinotifikasi');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, error: true);
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWali = _isWali;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: PTheme.background,
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
                                          children: [
                                            _buildFilterBar(),
                                            emptyView(_all.isEmpty
                                                ? 'Belum ada catatan pelanggaran.'
                                                : 'Tidak ada hasil yang cocok.'),
                                          ],
                                        )
                                      : ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          padding: EdgeInsets.fromLTRB(16, 4, 16, (isWali || _isPimpinan) ? 24 : 100),
                                          children: _buildListChildren(filtered, isWali),
                                        ),
                                ),
                    ),
                  ],
                ),
                if (!isWali && !_isPimpinan)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _openInput,
                      tooltip: 'Catat Pelanggaran',
                      elevation: 3,
                      backgroundColor: PTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Catat Pelanggaran',
                          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildListChildren(List<Map<String, dynamic>> filtered, bool isWali) {
    final children = <Widget>[_buildFilterBar(), _buildRingkasan(filtered)];
    String? lastKey;
    for (final p in filtered) {
      final t = DateTime.tryParse(p['tanggal']?.toString() ?? '')?.toLocal();
      final key = t == null ? '-' : '${t.year}-${t.month}';
      if (key != lastKey) {
        children.add(_groupHeader(t == null ? 'Tanpa Tanggal' : '${_bulanPanjangPelanggaran[t.month - 1]} ${t.year}'));
        lastKey = key;
      }
      children.add(_pelanggaranCard(p));
    }
    if (isWali) children.add(_waliPanduan());
    return children;
  }

  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
      decoration: BoxDecoration(
        color: PTheme.background,
        border: Border(bottom: BorderSide(color: _kBorder.withOpacity(0.0))),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: IconButton(
                onPressed: widget.onBack,
                tooltip: 'Kembali',
                icon: Icon(Icons.arrow_back_rounded, color: PTheme.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            )
          else
            const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Riwayat Pelanggaran',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Color(0xFF1B1C1A))),
                const SizedBox(height: 2),
                Text(_isWali ? 'Riwayat pelanggaran anak Anda' : widget.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: PTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${_all.length} Catatan',
                style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: PTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isWali = _isWali;
    const waktu = ['Semua', 'Minggu Ini', 'Bulan Ini'];

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: PText.bodyMd.copyWith(color: PTheme.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintText: 'Cari nama santri, NIS, atau pelanggaran...',
                hintStyle: PText.bodySm,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: PTheme.inkSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _searchCtrl.clear()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isWali)
            Row(
              children: [
                for (int i = 0; i < waktu.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _chip(
                      label: waktu[i],
                      count: waktu[i] == 'Semua' ? _all.length : _countTime(waktu[i]),
                      selected: _timeFilter == waktu[i],
                      onTap: () => setState(() => _timeFilter = waktu[i]),
                      expand: true,
                    ),
                  ),
                ],
              ],
            )
          else
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in waktu) ...[
                    _chip(
                      label: f,
                      count: f == 'Semua' ? _all.length : _countTime(f),
                      selected: _timeFilter == f,
                      onTap: () => setState(() => _timeFilter = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 1,
                    height: 22,
                    color: PTheme.inkSecondary.withOpacity(0.25),
                    margin: const EdgeInsets.only(left: 2, right: 10, top: 7, bottom: 7),
                  ),
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

  Widget _chip({
    required String label,
    int? count,
    required bool selected,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    final isi = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : PTheme.inkSecondary,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.22) : PTheme.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : PTheme.ink,
              ),
            ),
          ),
        ],
      ],
    );

    return Material(
      color: selected ? PTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: expand ? Alignment.center : null,
          padding: EdgeInsets.symmetric(horizontal: expand ? 8 : 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? PTheme.primary : _kBorder),
          ),
          child: isi,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Ringkasan (mengikuti filter yang sedang aktif)
  // ---------------------------------------------------------------------
  Widget _buildRingkasan(List<Map<String, dynamic>> data) {
    var totalPoin = 0;
    var berat = 0;
    for (final p in data) {
      final poin = (p['poin'] as num?)?.toInt() ?? 0;
      totalPoin += poin;
      if (poin >= 4) berat++;
    }

    Widget stat(String value, String label, IconData icon) => Expanded(
          child: Column(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.75)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 1),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8))),
            ],
          ),
        );

    Widget divider() => Container(width: 1, height: 44, color: Colors.white.withOpacity(0.2));

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PTheme.primary, PTheme.primary.withOpacity(0.82)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: PTheme.primary.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          stat('${data.length}', 'Catatan', Icons.description_outlined),
          divider(),
          stat('$totalPoin', 'Total Poin', Icons.stars_rounded),
          divider(),
          stat('$berat', 'Kategori Berat', Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _groupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: PTheme.inkSecondary)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _kBorder)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Khusus wali: panduan membaca poin
  // ---------------------------------------------------------------------
  Widget _waliPanduan() {
    Widget baris(String judul, String ket, int contohPoin) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _poinBg(contohPoin), shape: BoxShape.circle),
                child: Icon(Icons.stars_rounded, size: 16, color: _poinFg(contohPoin)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(ket, style: PText.bodySm.copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: PTheme.primary),
              const SizedBox(width: 6),
              Text('Cara membaca poin', style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Poin pelanggaran bersifat akumulatif. Semakin besar poin, semakin berat kategorinya.',
              style: PText.bodySm.copyWith(fontSize: 11.5, height: 1.4)),
          baris('Ringan', '1 poin', 1),
          baris('Sedang', '2 - 3 poin', 2),
          baris('Berat', '4 poin ke atas', 5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PTheme.background, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Ada pertanyaan tentang catatan ini? Silakan hubungi musyrif atau pihak pondok.',
              style: PText.bodySm.copyWith(fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  Widget _pelanggaranCard(Map<String, dynamic> p) {
    final isWali = _isWali;
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
    final tanggal = DateTime.tryParse(p['tanggal']?.toString() ?? '')?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: _poinFg(poin)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration:
                              BoxDecoration(color: PTheme.primary.withOpacity(0.10), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(_initialsOf(nama),
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: PTheme.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PText.bodyMd
                                      .copyWith(color: PTheme.ink, fontWeight: FontWeight.w800, fontSize: 14.5)),
                              const SizedBox(height: 1),
                              Text('NIS $nis • Kelas $kelas',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PText.bodySm.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: selesai ? const Color(0xFFDDF0E3) : PTheme.background,
                              borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(selesai ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                                size: 12, color: selesai ? PTheme.primary : PTheme.inkSecondary),
                            const SizedBox(width: 4),
                            Text(selesai ? 'Selesai' : 'Tercatat',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: selesai ? PTheme.primary : PTheme.inkSecondary)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: PTheme.background, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(jenis,
                                    style: PText.bodyMd.copyWith(
                                        color: PTheme.ink, fontWeight: FontWeight.w800, fontSize: 13.5)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration:
                                    BoxDecoration(color: _poinBg(poin), borderRadius: BorderRadius.circular(999)),
                                child: Text(
                                  isWali ? '$poin Poin' : '+$poin Poin',
                                  style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _poinFg(poin)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Kategori ${_kategoriPoin(poin)}',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _poinFg(poin))),
                          if (keterangan != null && keterangan.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(keterangan,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: PText.bodySm.copyWith(fontSize: 12, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (tanggal != null)
                      Row(children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: PTheme.inkSecondary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(_fmtTanggalLengkap(tanggal),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm.copyWith(fontSize: 11.5)),
                        ),
                      ]),
                    if (tindakLanjut != null && tindakLanjut.isNotEmpty && tindakLanjut != 'Tidak ada') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: PTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.fact_check_outlined, size: 13, color: PTheme.primary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text('Tindak Lanjut: $tindakLanjut',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PTheme.primary)),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Dialog "Input Pelanggaran"
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
    final asramaRaw = s['asrama'];
    final kamar = asramaRaw is Map ? (asramaRaw['nama'])?.toString() : asramaRaw?.toString();
    final parts = [
      if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas',
      if (kamar != null && kamar.isNotEmpty) 'Kamar $kamar'
    ];
    return parts.isEmpty ? '-' : parts.join(' • ');
  }

  /// Bottom sheet pilih santri. `isScrollControlled: true` + tinggi tetap
  /// (75% layar) supaya tidak overflow; daftar scroll di dalamnya + ada pencarian.
  void _pilihSantri() {
    if (widget.santris.isEmpty) return;
    String q = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PTheme.surface,
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
                            color: PTheme.inkSecondary.withOpacity(0.25), borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: Text('Pilih Santri', style: PText.headlineSm)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: PTheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                            child: Text('${list.length} santri',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: PTheme.primary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (v) => setSheet(() => q = v),
                        style: PText.bodyMd.copyWith(color: PTheme.ink),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: PTheme.background,
                          hintText: 'Cari nama / NIS...',
                          hintStyle: PText.bodySm,
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: PTheme.inkSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                                final jml = _countPelanggaranFor(s['id'].toString());
                                final dipilih = _santri != null && _santri!['id'] == s['id'];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                  selected: dipilih,
                                  selectedTileColor: PTheme.primary.withOpacity(0.06),
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(color: PTheme.primary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(_initialsOf(s['nama']?.toString() ?? '-'),
                                        style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ),
                                  title: Text(s['nama']?.toString() ?? '-',
                                      style: PText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                                  subtitle:
                                      Text('NIS: ${s['nis'] ?? '-'} • ${_kelasKamarLabel(s)}', style: PText.bodySm),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: jml == 0 ? const Color(0xFFDDF0E3) : const Color(0xFFFEF0CC),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      jml == 0 ? 'Disiplin' : '$jml Pelanggaran',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 10.5,
                                        color: jml == 0 ? PTheme.primary : const Color(0xFF92650C),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _santri = s;
                                      _errorSantri = null;
                                    });
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

  Widget _jenisTile(Map<String, Object> j) {
    final label = j['label'] as String;
    final p = j['poin'] as int;
    final selected = _jenisTerpilih != null && _jenisTerpilih!['label'] == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _jenisTerpilih = j;
          _errorJenis = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? PTheme.primary.withOpacity(0.07) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? PTheme.primary : _kBorder, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 20, color: selected ? PTheme.primary : PTheme.inkSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: PText.bodyMd.copyWith(
                        color: PTheme.ink, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 13.5)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _poinBg(p), borderRadius: BorderRadius.circular(999)),
                child: Text('$p poin',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: _poinFg(p))),
              ),
            ],
          ),
        ),
      ),
    );
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
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        child: Container(
          decoration: BoxDecoration(color: PTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: PTheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.gavel_rounded, color: PTheme.primary, size: 21),
                    ),
                    const SizedBox(width: 12),
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
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 21),
                        tooltip: 'Tutup'),
                  ],
                ),
              ),
              Container(height: 1, color: _kBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Pilih Santri'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pilihSantri,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _errorSantri != null ? Colors.red : _kBorder,
                                width: _errorSantri != null ? 1.4 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: PTheme.primary, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(_initialsOf(nama),
                                    style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text('NIS: $nis${_santri != null ? ' • ${_kelasKamarLabel(_santri!)}' : ''}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm),
                                  ],
                                ),
                              ),
                              if (widget.santris.length > 1)
                                const Icon(Icons.unfold_more_rounded, size: 20, color: PTheme.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (_errorSantri != null) ...[
                        const SizedBox(height: 4),
                        Text(_errorSantri!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 18),
                      _requiredLabel('Jenis Pelanggaran'),
                      const SizedBox(height: 8),
                      for (final j in _jenisPelanggaranPresets) _jenisTile(j),
                      if (_errorJenis != null) ...[
                        const SizedBox(height: 2),
                        Text(_errorJenis!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                            color: PTheme.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 19, color: PTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$poin Poin Pelanggaran',
                                      style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: PTheme.primary)),
                                  Text('Otomatis terisi berdasarkan jenis', style: PText.bodySm.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            if (_jenisTerpilih != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration:
                                    BoxDecoration(color: _poinBg(poin), borderRadius: BorderRadius.circular(999)),
                                child: Text(_kategoriPoin(poin),
                                    style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _poinFg(poin))),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text.rich(TextSpan(
                              text: 'Keterangan ',
                              style: PText.labelMd.copyWith(color: PTheme.ink),
                              children: [
                                TextSpan(text: '(Opsional)', style: PText.bodySm),
                              ])),
                          const Spacer(),
                          Text('${_keteranganCtrl.text.length}/500', style: PText.bodySm),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keteranganCtrl,
                        maxLength: 500,
                        maxLines: 3,
                        style: PText.bodyMd.copyWith(color: PTheme.ink),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Jelaskan detail pelanggaran...',
                          hintStyle: PText.bodySm,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: PTheme.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text.rich(TextSpan(
                          text: 'Tindak Lanjut ',
                          style: PText.labelMd.copyWith(color: PTheme.ink),
                          children: [
                            TextSpan(text: '(Opsional)', style: PText.bodySm),
                          ])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _tindakLanjut,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            style: PText.bodyMd.copyWith(color: PTheme.ink),
                            items: [for (final t in _tindakLanjutOptions) DropdownMenuItem(value: t, child: Text(t))],
                            onChanged: (v) => setState(() => _tindakLanjut = v ?? _tindakLanjut),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: _kBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text('Batal',
                              style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: PTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 17),
                          label: const Text('Simpan',
                              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
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
    return Text.rich(TextSpan(text: text, style: PText.labelMd.copyWith(color: PTheme.ink), children: const [
      TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
    ]));
  }
}