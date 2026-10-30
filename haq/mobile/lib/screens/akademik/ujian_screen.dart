import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'ujian_detail_screen.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Kirim kelasId, tanggal, dan field tambahan lain saat membuat ujian.
/// KKM selalu dikirim (tidak bergantung flag ini).
const bool kKirimFieldTambahan = true;

// ---------------------------------------------------------------------------
// Warna status (hijau & kuning tidak ada di SC; merah ikut SC.errorBg/errorText)
// ---------------------------------------------------------------------------
const _kOkBg = Color(0xFFE8F5E9);
const _kOkFg = Color(0xFF1B5E20);
const _kOkBd = Color(0xFFC8E6C9);
const _kWarnBg = Color(0xFFFFF8E1);
const _kWarnFg = Color(0xFFB78103);
const _kWarnBd = Color(0xFFFFE082);
const _kGoldChip = Color(0xFFFCEBC4);

Color get _badBd => SC.errorText.withOpacity(0.25);

/// Bar pencarian + filter yang menempel di atas saat digulir.
class _PinnedBar extends SliverPersistentHeaderDelegate {
  _PinnedBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: SC.background,
      height: height,
      alignment: Alignment.topCenter,
      child: ClipRect(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
Widget _pill(String text, {required Color bg, required Color fg, Color? bd, IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: bd == null ? null : Border.all(color: bd),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(10.5, FontWeight.w800, fg)),
        ),
      ],
    ),
  );
}

class _JenisStyle {
  final Color pillBg;
  final Color pillFg;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  const _JenisStyle(this.pillBg, this.pillFg, this.label, this.icon, this.iconBg, this.iconFg);
}

_JenisStyle _jenisStyle(String j) {
  switch (j) {
    case 'UAS':
      return _JenisStyle(SC.primary, Colors.white, 'UAS', Icons.menu_book_outlined, SC.sage, SC.primary);
    case 'UTS':
      return _JenisStyle(_kGoldChip, SC.goldDark, 'UTS', Icons.auto_stories_outlined, SC.goldSurface, SC.goldDark);
    case 'TES_TAHFIDZ':
      return _JenisStyle(SC.goldSurface, SC.goldDark, 'TES TAHFIDZ', Icons.menu_book, SC.goldSurface, SC.goldDark);
    case 'LAINNYA':
      return _JenisStyle(
          SC.surfaceDim, SC.inkSecondary, 'LAINNYA', Icons.record_voice_over_outlined, SC.surfaceDim, SC.inkSecondary);
    default:
      return _JenisStyle(SC.surfaceDim, SC.inkSecondary, 'ULANGAN', Icons.assignment_outlined, SC.mint, SC.primary);
  }
}

/// Nama pembuat ujian. Kosong kalau backend belum mengirimnya.
String _pembuatOf(Map<String, dynamic> u) {
  final nama = u['dibuatOlehNama'];
  if (nama is String && nama.trim().isNotEmpty) return nama.trim();
  return '';
}

String _jenisOf(Map<String, dynamic> u) => (u['jenis'] ?? 'ULANGAN') as String;
double? _numOf(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

List<Map<String, dynamic>> _maps(dynamic v) => ((v as List?) ?? [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

String _fmtTanggal(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _fmtJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

InputDecoration _dec(String? hint,
    {Widget? suffix, Widget? prefix, String? error, Color? fill}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    suffixIcon: suffix,
    prefixIcon: prefix,
    errorText: error,
    errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
    filled: true,
    fillColor: fill ?? SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
    errorBorder: b(SC.errorText, 1.4),
    focusedErrorBorder: b(SC.errorText, 1.4),
  );
}

ButtonStyle _primaryBtn({double h = 46}) => FilledButton.styleFrom(
      backgroundColor: SC.primary,
      foregroundColor: Colors.white,
      minimumSize: Size(0, h),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );

Future<T?> _showSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 480),
      backgroundColor: SC.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => child,
    );

// ---------------------------------------------------------------------------
// 1. DAFTAR UJIAN
// ---------------------------------------------------------------------------
class UjianScreen extends StatefulWidget {
  const UjianScreen({super.key});

  @override
  State<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends State<UjianScreen> {
  List<dynamic> _ujian = [];
  int? _remedialCount;
  Map<dynamic, int> _remedialById = {}; // id ujian -> santri remedial aktif
  bool _filterRemedial = false; // ketuk pengingat remedial untuk menyaring
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA';
  String _sort = 'TERBARU';
  String _query = '';
  final _searchC = TextEditingController();
  final _scroll = ScrollController();

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  /// Pimpinan/Mudir hanya memantau: tidak bisa membuat ujian atau menginput nilai.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  static const _filters = [
    ['SEMUA', 'Semua'],
    ['ULANGAN', 'Ulangan'],
    ['UTS', 'UTS'],
    ['UAS', 'UAS'],
    ['TES_TAHFIDZ', 'Tes Tahfidz'],
    ['LAINNYA', 'Lainnya'],
  ];

  static const _sorts = <String, String>{
    'TERBARU': 'Terbaru',
    'TERLAMA': 'Terlama',
    'NAMA': 'Nama A–Z',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchC.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ujian);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _ujian = items;
        _loading = false;
        _error = null;
      });

      _hitungRemedial();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      } else {
        _toast(e.message, error: true);
      }
    }
  }

  /// Hitung remedial yang masih aktif per ujian. Aturannya sama dengan layar Remedial:
  /// nilai < KKM (KKM mapel), kecuali yang sudah final (TUNTAS / BELUM_TUNTAS).
  /// Santri izin yang nilainya belum diinput TIDAK dihitung.
  Future<void> _hitungRemedial() async {
    final list = _all;
    final hasil = <dynamic, int>{};

    await Future.wait(list.map((u) async {
      final dariApi = u['remedialAktif'];
      if (dariApi is int) {
        hasil[u['id']] = dariApi;
        return;
      }
      if (_countNilai(u) == 0) {
        hasil[u['id']] = 0;
        return;
      }
      try {
        hasil[u['id']] = await _remedialUjian(u);
      } catch (_) {}
    }));

    if (!mounted) return;
    setState(() {
      _remedialById = hasil;
      _remedialCount = (hasil.isEmpty && list.isNotEmpty)
          ? null
          : hasil.values.fold<int>(0, (a, b) => a + b);
      // Kalau tidak ada lagi remedial, matikan filter supaya daftar tidak kosong.
      if ((_remedialCount ?? 0) == 0) _filterRemedial = false;
    });
  }

  Future<int> _remedialUjian(Map<String, dynamic> u) async {
    final api = AppScope.of(context).api;
    final res = await api.get('${ApiUrl.ujian}/${u['id']}');
    final d = <String, dynamic>{...u, ...(res as Map).cast<String, dynamic>()};
    final kkm = _numOf(d['kkm']) ?? _numOf(d['mapel']?['kkm']) ?? 75;

    // santriId -> status
    final status = <dynamic, String>{};
    for (final n in _maps(d['nilais'])) {
      final v = _numOf(n['nilai']);
      if (v == null || v >= kkm) continue;
      final s = n['santri'] is Map ? n['santri'] as Map : const {};
      status[n['santriId'] ?? s['id']] = 'BELUM_TES';
    }

    try {
      final rr = await api.get('${ApiUrl.ujian}/${u['id']}/remedial');
      final raw = rr is Map ? (rr['data'] ?? rr['remedials'] ?? rr['items']) : rr;
      for (final r in _maps(raw)) {
        final s = r['santri'] is Map ? r['santri'] as Map : const {};
        status[r['santriId'] ?? s['id']] = '${r['status'] ?? ''}'.toUpperCase();
      }
    } on ApiException {
      // endpoint remedial belum ada: pakai hasil dari nilai saja
    }

    return status.values.where((s) => s != 'TUNTAS' && s != 'BELUM_TUNTAS').length;
  }

  Future<void> _addUjian() async {
    final result = await _showSheet<Map<String, dynamic>>(context, const _FormUjianSheet());
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.ujian, result);
      if (!mounted) return;
      _toast(
        'Ujian berhasil dibuat',
        subtitle: '${result['nama']} • ${_jenisStyle('${result['jenis']}').label}',
      );
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal membuat ujian.', error: true);
    }
  }

  List<Map<String, dynamic>> get _all => _ujian.whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> get _shown {
    final q = _query.trim().toLowerCase();
    final list = _all.where((u) {
      if (_filter != 'SEMUA' && _jenisOf(u) != _filter) return false;
      if (_filterRemedial && (_remedialById[u['id']] ?? 0) == 0) return false;
      if (q.isEmpty) return true;
      final s =
          '${u['nama']} ${u['mapel']?['namaMapel'] ?? ''} ${u['kelas']?['namaKelas'] ?? ''} ${_pembuatOf(u)}'
              .toLowerCase();
      return s.contains(q);
    }).toList();

    DateTime? d(Map<String, dynamic> u) =>
        DateTime.tryParse('${u['tanggal'] ?? u['createdAt'] ?? ''}');
    int idx(Map<String, dynamic> u) => _ujian.indexOf(u);

    list.sort((a, b) {
      if (_sort == 'NAMA') {
        return '${a['nama']}'.toLowerCase().compareTo('${b['nama']}'.toLowerCase());
      }
      final da = d(a), db = d(b);
      if (da != null && db != null) {
        final c = da.compareTo(db);
        if (c != 0) return _sort == 'TERBARU' ? -c : c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return idx(a).compareTo(idx(b));
    });
    return list;
  }

  int _countNilai(Map<String, dynamic> u) => (u['_count']?['nilais'] as int? ?? 0);

  /// Total santri di kelas (opsional, hanya jika backend mengirimnya).
  int? _totalSantri(Map<String, dynamic> u) {
    final v = u['totalSantri'] ?? u['kelas']?['jumlahSantri'] ?? u['kelas']?['_count']?['santris'];
    return v is int && v > 0 ? v : null;
  }

  String? _tenggat(Map<String, dynamic> u) {
    final d = DateTime.tryParse('${u['tanggal'] ?? ''}');
    if (d == null) return null;
    final now = DateTime.now();
    final diff = DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff > 0) return 'Tenggat: $diff Hari Lagi';
    if (diff == 0) return 'Tenggat: Hari ini';
    return null;
  }

  // ---------------------------------------------------------------------
  // Banner inline (sama dengan halaman Ustadz)
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _bannerTimer = Timer(Duration(seconds: error ? 5 : 3), _closeBanner);
  }

  void _closeBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerTitle = null);
  }

  Widget _banner() {
    final title = _bannerTitle;
    final error = _bannerError;
    final fg = error ? SC.errorText : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: title == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: error ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: error ? Colors.white : SC.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      error ? Icons.error_outline : Icons.check_rounded,
                      size: 18,
                      color: error ? SC.errorText : SC.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: sty(13.5, FontWeight.w800, fg)),
                        if (_bannerSub != null && _bannerSub!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!, style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75))),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, size: 18, color: fg.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _all.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              RefreshIndicator(
                color: SC.primary,
                onRefresh: () => _load(spinner: false),
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedBar(
                        height: showControls ? 118 : 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _searchBar(),
                            if (showControls) _filterChips(),
                          ],
                        ),
                      ),
                    ),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (!_readOnly)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: _addUjian,
                    tooltip: 'Buat ujian',
                    backgroundColor: SC.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: SC.gold.withOpacity(0.6)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20, color: SC.gold),
                    label: Text('Buat Ujian', style: sty(13, FontWeight.w700, Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    final all = _all;
    final totalNilai = all.fold<int>(0, (a, u) => a + _countNilai(u));

    int? kapasitas;
    if (all.isNotEmpty && all.every((u) => _totalSantri(u) != null)) {
      kapasitas = all.fold<int>(0, (a, u) => a + _totalSantri(u)!);
    }
    final pct = kapasitas == null ? null : ((totalNilai / kapasitas) * 100).round();
    final remedial = _remedialCount;

    String ringkasan;
    if (_error != null) {
      ringkasan = 'Data tidak dapat dimuat';
    } else if (!loaded) {
      ringkasan = 'Memuat data...';
    } else if (all.isEmpty) {
      ringkasan = 'Belum ada ujian dibuat';
    } else {
      ringkasan = '${all.length} agenda ujian & penilaian';
    }

    Widget stat(IconData icon, String value, String label, {bool warn = false}) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: warn ? SC.gold : Colors.white.withOpacity(0.7)),
              const SizedBox(height: 5),
              Text(value, style: sty(20, FontWeight.w800, warn ? SC.gold : Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72))),
            ],
          ),
        );

    Widget garis() => Container(width: 1, height: 44, color: Colors.white.withOpacity(0.18));

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.fact_check_rounded, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ujian & Remedial', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      ringkasan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                stat(Icons.event_note_outlined, loaded ? '${all.length}' : '–', 'Ujian'),
                garis(),
                stat(Icons.done_all_rounded,
                    !loaded ? '–' : (pct == null ? '$totalNilai' : '$pct%'),
                    pct == null ? 'Nilai masuk' : 'Progres nilai'),
                garis(),
                stat(Icons.replay_rounded, !loaded || remedial == null ? '–' : '$remedial',
                    'Perlu remedial',
                    warn: loaded && (remedial ?? 0) > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pencarian & filter
  // ---------------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _searchC,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari ujian, mapel, atau kelas',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () {
                      _searchC.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: SC.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: SC.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: SC.primary, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  /// Filter jenis ujian: pill yang bisa digeser ke samping.
  Widget _filterChips() {
    Widget chip(String value, String label, {int? count}) {
      final active = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _filter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? SC.primary : SC.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? SC.primary : SC.border),
            ),
            child: Text(
              count == null ? label : '$label ($count)',
              style: sty(12, FontWeight.w700, active ? Colors.white : SC.inkSecondary),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final f in _filters)
              chip(f[0], f[1], count: f[0] == 'SEMUA' ? _all.length : null),
          ],
        ),
      ),
    );
  }

  /// Pengingat remedial: muncul hanya kalau ada santri yang perlu remedial.
  Widget _noticeRemedial() {
    final n = _remedialCount ?? 0;
    if (n == 0) return const SizedBox.shrink();
    final jumlahUjian = _remedialById.values.where((v) => v > 0).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Material(
        color: SC.goldSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SC.gold.withOpacity(0.4)),
        ),
        child: InkWell(
          onTap: () => setState(() => _filterRemedial = !_filterRemedial),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.gold.withOpacity(0.45)),
                  ),
                  child: Icon(Icons.replay_rounded, size: 17, color: SC.goldDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _filterRemedial
                            ? 'Menampilkan $jumlahUjian ujian dengan remedial'
                            : '$n santri perlu remedial di $jumlahUjian ujian',
                        style: sty(12.5, FontWeight.w800, SC.goldDark),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _filterRemedial ? 'Ketuk untuk kembali ke semua' : 'Ketuk untuk menyaring daftar',
                        style: sty(11, FontWeight.w500, SC.goldDark.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                Icon(_filterRemedial ? Icons.close_rounded : Icons.chevron_right_rounded,
                    size: 20, color: SC.goldDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Isi daftar
  // ---------------------------------------------------------------------
  List<Widget> _bodySlivers() {
    if (_loading) {
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: loadingView()))];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }
    final all = _all;
    if (all.isEmpty) {
      return [SliverToBoxAdapter(child: _kosong())];
    }

    final list = _shown;
    return [
      SliverToBoxAdapter(child: _noticeRemedial()),
      SliverToBoxAdapter(child: _listHeader(list.length)),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 40, color: SC.inkMuted),
                const SizedBox(height: 10),
                Text('Tidak ada hasil', style: sty(16, FontWeight.w800, SC.ink)),
                const SizedBox(height: 6),
                Text('Tidak ada ujian yang cocok dengan pencarian atau filter ini.',
                    textAlign: TextAlign.center,
                    style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([for (final u in list) _ujianCard(u)]),
          ),
        ),
    ];
  }

  Widget _listHeader(int n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
      child: Row(
        children: [
          Text('Daftar Agenda Ujian', style: sty(15, FontWeight.w800, SC.ink)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
            child: Text('$n', style: sty(10.5, FontWeight.w800, SC.primary)),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Urutkan',
            color: SC.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              for (final e in _sorts.entries)
                PopupMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: sty(13, _sort == e.key ? FontWeight.w800 : FontWeight.w600,
                          _sort == e.key ? SC.primary : SC.inkSecondary)),
                ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_sorts[_sort]!, style: sty(12, FontWeight.w700, SC.goldDark)),
                const SizedBox(width: 4),
                Icon(Icons.swap_vert_rounded, size: 16, color: SC.goldDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kosong() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 96),
      child: Column(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: SC.sage.withOpacity(0.55)),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: SC.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(Icons.assignment_outlined, size: 38, color: SC.primary),
                ),
                Positioned(top: 8, right: 14, child: Icon(Icons.star_rounded, size: 17, color: SC.gold)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Belum ada ujian',
              textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(
            _readOnly
                ? 'Belum ada ujian yang dibuat oleh ustadz.'
                : 'Buat ujian pertama untuk mulai menilai santri, mengunci nilai, dan menjadwalkan remedial.',
            textAlign: TextAlign.center,
            style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu ujian
  // ---------------------------------------------------------------------
  Widget _ujianCard(Map<String, dynamic> u) {
    final st = _jenisStyle(_jenisOf(u));
    final count = _countNilai(u);
    final total = _totalSantri(u);
    final complete = total != null && count >= total;
    final double? progress = total == null ? null : (count / total).clamp(0.0, 1.0).toDouble();
    // Hanya remedial yang masih menunggu (belum final).
    final remed = _remedialById[u['id']] ?? (u['remedialAktif'] as int?) ?? 0;
    final mapel = u['mapel']?['namaMapel'] ?? 'Umum';
    final kelas = u['kelas']?['namaKelas'] ?? 'Semua kelas';
    final pembuat = _pembuatOf(u);

    final String panelText;
    if (total == null) {
      panelText = '$count santri telah dinilai';
    } else if (complete) {
      panelText = 'Semua santri sudah dinilai: $count / $total';
    } else {
      panelText = '$count / $total santri telah dinilai';
    }

    final Widget footLeft;
    if (remed > 0) {
      footLeft = _pill('$remed santri perlu remedial',
          bg: SC.errorBg, fg: SC.errorText, bd: _badBd, icon: Icons.warning_amber_rounded);
    } else if (count == 0) {
      footLeft = _pill('Belum ada nilai',
          bg: _kWarnBg, fg: _kWarnFg, bd: _kWarnBd, icon: Icons.hourglass_empty_rounded);
    } else if (complete) {
      footLeft = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: SC.gold),
          const SizedBox(width: 5),
          Text('Nilai lengkap', style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
        ],
      );
    } else {
      footLeft = Text(
        _tenggat(u) ??
            (total != null
                ? '${total - count} santri belum dinilai / menunggu susulan'
                : 'Nilai sedang diinput'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: sty(11.5, FontWeight.w500, SC.inkSecondary),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: remed > 0 ? SC.errorText.withOpacity(0.3) : SC.border),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => UjianDetailScreen(ujian: u)))
              .then((_) {
            if (mounted) _load(spinner: false);
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: st.iconBg, shape: BoxShape.circle),
                      child: Icon(st.icon, color: st.iconFg, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${u['nama']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sty(15, FontWeight.w800, SC.ink)),
                          const SizedBox(height: 2),
                          Text('$mapel • $kelas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sty(12, FontWeight.w500, SC.inkSecondary)),
                          if (pembuat.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 12, color: SC.inkMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('Oleh $pembuat',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(11, FontWeight.w600, SC.inkMuted)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (u['dikunciPada'] != null) ...[
                      Icon(Icons.lock_outline, size: 16, color: SC.goldDark),
                      const SizedBox(width: 6),
                    ],
                    _pill(st.label, bg: st.pillBg, fg: st.pillFg),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SC.surfaceDim,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                              count == 0
                                  ? Icons.hourglass_empty_rounded
                                  : (complete
                                      ? Icons.check_circle_outline
                                      : Icons.assignment_turned_in_outlined),
                              size: 15,
                              color: SC.ink),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(panelText,
                                style: sty(12, FontWeight.w600, SC.inkSecondary)),
                          ),
                          if (progress != null)
                            Text('${(progress * 100).round()}%',
                                style: sty(16, FontWeight.w800, SC.ink)),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: SC.border,
                            valueColor: AlwaysStoppedAnimation(
                                complete ? SC.primary : SC.primary.withOpacity(0.75)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: footLeft),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            _readOnly
                                ? 'Lihat Nilai'
                                : count == 0
                                    ? 'Input Nilai'
                                    : (complete ? 'Detail Nilai' : 'Lanjutkan Nilai'),
                            style: sty(12, FontWeight.w800, SC.primary)),
                        Icon(Icons.chevron_right_rounded, size: 18, color: SC.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. BUAT UJIAN BARU (bottom sheet)
// ---------------------------------------------------------------------------
class _FormUjianSheet extends StatefulWidget {
  const _FormUjianSheet();

  @override
  State<_FormUjianSheet> createState() => _FormUjianSheetState();
}

class _FormUjianSheetState extends State<_FormUjianSheet> {
  final _nama = TextEditingController();
  final _kkm = TextEditingController(text: '75');
  String _jenis = 'UAS';
  final _lainnyaNama = TextEditingController();
  final _lainnyaKet = TextEditingController();
  List<dynamic> _mapel = []; // mapel terdaftar (untuk dropdown)
  // Dua alur: ujian mapel (pilih dari daftar, KKM ikut mapel) atau non-mapel/umum (KKM manual).
  bool _pakaiMapel = true;
  dynamic _mapelId;
  bool _mapelLoading = true;
  bool _mapelGagal = false;
  bool _mapelError = false;
  List<Map<String, dynamic>> _kelasList = [];
  Map<String, dynamic>? _kelas;
  // Ustadz: mapel & kelas dibatasi penugasan (endpoint ujian/penugasan-saya).
  bool _dibatasi = false;
  List<Map<String, dynamic>> _tugas = [];
  bool _kelasError = false;
  DateTime _jadwal = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 0);
  bool _namaError = false;
  bool _kkmError = false;

  static const jenisOptions = ['ULANGAN', 'UTS', 'UAS', 'TES_TAHFIDZ', 'LAINNYA'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPenugasan();
    });
  }

  /// Ustadz: dropdown mapel/kelas hanya berisi penugasannya.
  /// Admin (dibatasi=false) atau endpoint gagal: alur lama (semua mapel & kelas).
  /// Catatan: kalau endpoint gagal, backend tetap menolak pilihan di luar penugasan.
  Future<void> _loadPenugasan() async {
    try {
      final res = await AppScope.of(context).api.get('${ApiUrl.ujian}/penugasan-saya');
      final raw = res is Map ? res.cast<String, dynamic>() : <String, dynamic>{};
      final data = raw['data'] is Map ? (raw['data'] as Map).cast<String, dynamic>() : raw;
      if (data['dibatasi'] == true) {
        final tugas = _maps(data['items']);
        final seen = <dynamic>{};
        final mapel = <Map<String, dynamic>>[];
        for (final t in tugas) {
          final mp = t['mapel'];
          if (mp is Map && seen.add(mp['id'])) mapel.add(mp.cast<String, dynamic>());
        }
        if (!mounted) return;
        setState(() {
          _dibatasi = true;
          _tugas = tugas;
          _mapel = mapel;
          _mapelLoading = false;
          _mapelGagal = false;
          _kelasList = _kelasDariTugas(null);
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    _loadMapel();
    _loadKelas();
  }

  /// Kelas dari penugasan. mapelId null = semua kelas yang diajar.
  List<Map<String, dynamic>> _kelasDariTugas(dynamic mapelId) {
    final seen = <dynamic>{};
    final out = <Map<String, dynamic>>[];
    for (final t in _tugas) {
      final k = t['kelas'];
      if (k is! Map) continue;
      if (mapelId != null && t['mapel']?['id'] != mapelId) continue;
      if (seen.add(k['id'])) out.add({'id': k['id'], 'nama': k['namaKelas'], 'count': null});
    }
    return out;
  }

  void _pilihMapel(dynamic v) => setState(() {
        _mapelId = v;
        _mapelError = false;
        _syncKkm();
        if (_dibatasi) {
          _kelasList = _kelasDariTugas(v);
          _kelas = _kelasList.length == 1 ? _kelasList.first : null;
          _kelasError = false;
        }
      });

  Future<void> _loadMapel() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.mapel);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (mounted) {
        setState(() {
          _mapel = items;
          _mapelLoading = false;
          _mapelGagal = false;
        });
      }
    } catch (_) {
      // Mis. role tidak boleh membaca daftar mapel: tampilkan pesan, jangan diam-diam kosong.
      if (mounted) {
        setState(() {
          _mapelLoading = false;
          _mapelGagal = true;
        });
      }
    }
  }

  /// Mapel yang dipilih di dropdown (null bila alur non-mapel atau belum memilih).
  Map<String, dynamic>? get _mapelTerpilih {
    if (!_pakaiMapel || _mapelId == null) return null;
    for (final m in _mapel) {
      if (m is Map && m['id'] == _mapelId) return Map<String, dynamic>.from(m);
    }
    return null;
  }

  /// KKM milik mapel terpilih (null bila non-mapel, belum memilih, atau mapel belum punya KKM).
  double? get _kkmMapel {
    final v = _mapelTerpilih?['kkm'];
    return v is num ? v.toDouble() : null;
  }

  /// Pada alur mapel, KKM ditentukan mapel (backend mengabaikan isian lain).
  bool get _kkmTerkunci => _kkmMapel != null;

  String _fmtKkm(num v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Samakan isian KKM dengan KKM mapel terpilih. Dipanggil di dalam setState.
  void _syncKkm() {
    final k = _kkmMapel;
    if (k != null) {
      _kkm.text = _fmtKkm(k);
      _kkmError = false;
    }
  }

  /// Daftar kelas diturunkan dari data santri (belum ada endpoint kelas di layar ini).
  Future<void> _loadKelas() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.santri);
      final items = res is List ? res : ((res as Map<String, dynamic>)['items'] as List? ?? []);
      final map = <String, Map<String, dynamic>>{};
      for (final s in items) {
        if (s is! Map) continue;
        final k = s['kelas'];
        if (k is! Map) continue;
        final name = k['namaKelas']?.toString();
        if (name == null) continue;
        final e = map.putIfAbsent(
            name, () => <String, dynamic>{'id': k['id'] ?? s['kelasId'], 'nama': name, 'count': 0});
        e['count'] = (e['count'] as int) + 1;
      }
      if (mounted) setState(() => _kelasList = map.values.toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _nama.dispose();
    _kkm.dispose();
    _lainnyaNama.dispose();
    _lainnyaKet.dispose();
    super.dispose();
  }

  Future<void> _pickJadwal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _jadwal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_jadwal));
    if (!mounted) return;
    final tt = t ?? TimeOfDay.fromDateTime(_jadwal);
    setState(() => _jadwal = DateTime(d.year, d.month, d.day, tt.hour, tt.minute));
  }

  Future<void> _pilihKelasLain() async {
    final res = await _showSheet<Map<String, dynamic>>(
        context, _KelasChooser(list: _kelasList, selected: _kelas, bolehSemua: !_dibatasi));
    if (res == null || !mounted) return;
    setState(() => _kelas = res['nama'] == '__ALL__' ? null : res);
  }

  void _submit() {
    final nama = _nama.text.trim();
    // Ujian mapel memakai KKM mapel; non-mapel (atau mapel tanpa KKM) pakai isian.
    final kkm = _kkmMapel ?? double.tryParse(_kkm.text.replaceAll(',', '.'));
    final namaBad = nama.isEmpty;
    final kkmBad = kkm == null || kkm < 0 || kkm > 100;
    // Ustadz: UTS/UAS wajib lewat mapel + kelas penugasan (sama dengan aturan backend).
    final terpusat = _jenis == 'UTS' || _jenis == 'UAS';
    if (_dibatasi && terpusat && !_pakaiMapel) {
      setState(() {
        _pakaiMapel = true;
        _mapelError = true;
        _kelasList = _kelasDariTugas(_mapelId);
      });
      return;
    }
    final mapelBad = _pakaiMapel && _mapelId == null;
    final kelasBad = _dibatasi && _pakaiMapel && terpusat && _kelas == null;
    if (namaBad || kkmBad || mapelBad || kelasBad) {
      setState(() {
        _namaError = namaBad;
        _kkmError = kkmBad;
        _mapelError = mapelBad;
        _kelasError = kelasBad;
      });
      return;
    }

    final payload = <String, dynamic>{
      'nama': nama,
      'jenis': _jenis,
      'mapelId': _pakaiMapel ? _mapelId : null,
      'kkm': kkm,
    };
    if (kKirimFieldTambahan) {
      if (_kelas?['id'] != null) payload['kelasId'] = _kelas!['id'];
      payload['tanggal'] = _jadwal.toIso8601String();
    }
    Navigator.of(context).pop(payload);
  }

  Widget _label(String text, {bool req = false, Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Row(
          children: [
            Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary)),
            if (req) Text(' *', style: sty(12, FontWeight.w800, SC.errorText)),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _goldChip({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SC.goldSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.gold.withOpacity(0.5)),
        ),
        child: child,
      );

  Widget _grayChip({required Widget child, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: SC.surfaceDim,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SC.border),
          ),
          child: child,
        ),
      );

  String _kelasText(Map<String, dynamic> k) {
    final n = '${k['nama']}';
    final base = n.toLowerCase().startsWith('kelas') ? n : 'Kelas $n';
    final c = k['count'];
    return c == null ? base : '$base ($c Santri)';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final saran = _kelasList.where((k) => k['nama'] != _kelas?['nama']).take(1).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SC.sage,
                      shape: BoxShape.circle,
                      border: Border.all(color: SC.gold.withOpacity(0.45)),
                    ),
                    child: Icon(Icons.fact_check_rounded, size: 20, color: SC.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buat Ujian Baru', style: sty(16, FontWeight.w800, SC.ink)),
                        const SizedBox(height: 1),
                        Text('Atur identitas ujian dan parameter penilaian',
                            style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: SC.surfaceDim,
                        shape: BoxShape.circle,
                        border: Border.all(color: SC.border),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: SC.ink),
                    ),
                  ),
                ],
              ),
            ),
            // Isi form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nama Ujian', req: true),
                    TextField(
                      controller: _nama,
                      onChanged: (_) {
                        if (_namaError) setState(() => _namaError = false);
                      },
                      style: sty(14, FontWeight.w600, SC.ink),
                      decoration: _dec(
                        'Contoh: UAS Bahasa Arab Semester Ganjil',
                        prefix: Icon(Icons.menu_book_outlined, size: 19, color: SC.inkSecondary),
                        error: _namaError ? 'Nama ujian wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _label('Jenis Evaluasi',
                        req: true,
                        trailing: Text('Akademik & Diniyah',
                            style: sty(11, FontWeight.w700, SC.goldDark))),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final j in jenisOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _jenis = j),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _jenis == j ? SC.primary : SC.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: _jenis == j ? SC.primary : SC.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_jenis == j) ...[
                                        const Icon(Icons.check, size: 14, color: Colors.white),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(_jenisTitle(j),
                                          style: sty(12, FontWeight.w700,
                                              _jenis == j ? Colors.white : SC.inkSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _jenis == 'LAINNYA'
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _lainnyaForm(),
                            )
                          : const SizedBox(width: double.infinity),
                    ),

                    _label('Mata Pelajaran', req: true),
                    _mapelSection(),
                    const SizedBox(height: 14),

                    _label('Kelas / Rombel Sasaran'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _goldChip(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_outlined, size: 16, color: SC.goldDark),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                    _kelas == null
                                        ? (_dibatasi && _pakaiMapel ? 'Pilih kelas' : 'Semua kelas')
                                        : _kelasText(_kelas!),
                                    style: sty(12, FontWeight.w700, SC.goldDark)),
                              ),
                              if (_kelas != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _kelas = null),
                                  child: Icon(Icons.close, size: 14, color: SC.goldDark),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_kelasList.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in saran)
                            _grayChip(
                              onTap: () => setState(() => _kelas = k),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 14, color: SC.ink),
                                  const SizedBox(width: 5),
                                  Text('${k['nama']}', style: sty(12, FontWeight.w600, SC.ink)),
                                ],
                              ),
                            ),
                          _grayChip(
                            onTap: _pilihKelasLain,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.apartment_outlined, size: 14, color: SC.ink),
                                const SizedBox(width: 5),
                                Text('Pilih Kelas Lain', style: sty(12, FontWeight.w600, SC.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_kelasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 2),
                        child: Text('Pilih kelas yang Anda ajar untuk mapel ini',
                            style: sty(11.5, FontWeight.w600, SC.errorText)),
                      ),

                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('KKM Kelulusan', req: true),
                              TextField(
                                controller: _kkm,
                                readOnly: _kkmTerkunci,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) {
                                  if (_kkmError) setState(() => _kkmError = false);
                                },
                                style: sty(14, FontWeight.w700,
                                    _kkmTerkunci ? SC.inkSecondary : SC.ink),
                                decoration: _dec(
                                  null,
                                  error: _kkmError ? '0–100' : null,
                                  suffix: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: _kkmTerkunci
                                        ? Icon(Icons.lock_outline, size: 18, color: SC.goldDark)
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: SC.surface,
                                                borderRadius: BorderRadius.circular(8)),
                                            child: Text('Poin',
                                                style: sty(11, FontWeight.w600, SC.inkSecondary)),
                                          ),
                                  ),
                                  fill: _kkmTerkunci ? SC.border : SC.surfaceDim,
                                ),
                              ),
                              if (_kkmTerkunci)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 2),
                                  child: Text('Mengikuti KKM mata pelajaran',
                                      style: sty(10.5, FontWeight.w600, SC.goldDark)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Jadwal Pelaksanaan', req: true),
                              GestureDetector(
                                onTap: _pickJadwal,
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                      color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_available_outlined,
                                          size: 18, color: SC.goldDark),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_fmtTanggal(_jadwal),
                                                style: sty(12.5, FontWeight.w800, SC.ink)),
                                            Text(_fmtJam(_jadwal),
                                                style: sty(10.5, FontWeight.w500, SC.inkSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SC.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: SC.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_user_outlined,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Integritas & Khidmah',
                                    style: sty(13, FontWeight.w800, SC.ink)),
                                const SizedBox(height: 2),
                                Text(
                                    'Hasil evaluasi akan otomatis terhubung ke Buku Raport Santri & Rekap Wali Asrama.',
                                    style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bar aksi bawah
            Container(
              decoration: BoxDecoration(
                color: SC.surface,
                border: Border(top: BorderSide(color: SC.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: SC.border),
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: _primaryBtn(h: 46),
                          onPressed: _submit,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text('Simpan & Terbitkan',
                              style: sty(13.5, FontWeight.w700, Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pilihan alur: "Mapel Terdaftar" (dropdown, KKM ikut mapel) atau "Non-Mapel" (umum, KKM manual).
  Widget _alurChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? SC.primary : SC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? SC.primary : SC.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : SC.inkSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: sty(12, FontWeight.w700, selected ? Colors.white : SC.inkSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _alurChip('Mapel Terdaftar', Icons.menu_book_outlined, _pakaiMapel,
                () => setState(() {
                      _pakaiMapel = true;
                      _mapelError = false;
                      if (_dibatasi) {
                        _kelasList = _kelasDariTugas(_mapelId);
                        _kelas = _kelasList.length == 1 ? _kelasList.first : null;
                      }
                    })),
            const SizedBox(width: 8),
            _alurChip('Non-Mapel (Umum)', Icons.edit_note_outlined, !_pakaiMapel,
                () => setState(() {
                      _pakaiMapel = false;
                      _mapelError = false;
                      _kelasError = false;
                      if (_dibatasi) _kelasList = _kelasDariTugas(null);
                    })),
          ],
        ),
        const SizedBox(height: 10),
        if (_pakaiMapel) _mapelDropdown() else _infoNonMapel(),
      ],
    );
  }

  Widget _mapelDropdown() {
    final items = _mapel.whereType<Map>().toList();
    final String? helper;
    if (_mapelLoading) {
      helper = 'Memuat daftar mapel...';
    } else if (_mapelGagal) {
      helper = 'Daftar mapel tidak dapat dimuat. Periksa izin akses, atau pilih Non-Mapel.';
    } else if (items.isEmpty) {
      helper = 'Belum ada mapel terdaftar. Hubungi admin, atau pilih Non-Mapel.';
    } else if (_mapelTerpilih != null && _kkmMapel == null) {
      helper = 'Mapel ini belum punya KKM. Isi KKM di bawah.';
    } else if (_kkmTerkunci) {
      helper = 'KKM mengikuti mapel (${_fmtKkm(_kkmMapel!)}).';
    } else {
      helper = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<dynamic>(
          value: items.any((m) => m['id'] == _mapelId) ? _mapelId : null,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 20, color: SC.primary),
          style: sty(14, FontWeight.w600, SC.ink),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: SC.surface,
          decoration: _dec(
            'Pilih mata pelajaran',
            error: _mapelError ? 'Pilih mapel, atau ganti ke Non-Mapel' : null,
            prefix: Icon(Icons.translate, size: 19, color: SC.primary),
          ),
          items: [
            for (final m in items)
              DropdownMenuItem<dynamic>(
                value: m['id'],
                child: Text(
                  m['kkm'] is num
                      ? '${m['namaMapel']} (KKM ${_fmtKkm(m['kkm'] as num)})'
                      : '${m['namaMapel']}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: items.isEmpty ? null : _pilihMapel,
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                    _mapelGagal || (!_mapelLoading && items.isEmpty)
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    size: 14,
                    color: SC.goldDark),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(helper, style: sty(11.5, FontWeight.w600, SC.goldDark))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoNonMapel() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle_outline, size: 14, color: SC.goldDark),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Ujian umum tanpa mapel khusus. KKM diisi manual di bawah.',
                style: sty(11.5, FontWeight.w600, SC.goldDark)),
          ),
        ],
      );

  /// Form tambahan (opsional) yang muncul saat Jenis Evaluasi = Lainnya.
  Widget _lainnyaForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SC.goldSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.gold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: SC.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Detail Penilaian Lainnya', style: sty(13, FontWeight.w800, SC.ink)),
              ),
              _pill('Opsional', bg: _kGoldChip, fg: SC.goldDark),
            ],
          ),
          const SizedBox(height: 12),
          _label('Nama Jenis Penilaian'),
          TextField(
            controller: _lainnyaNama,
            textCapitalization: TextCapitalization.sentences,
            style: sty(14, FontWeight.w600, SC.ink),
            decoration: _dec('Contoh: Praktik Khithabah, Muhadharah', fill: Colors.white),
          ),
          const SizedBox(height: 12),
          _label('Keterangan'),
          TextField(
            controller: _lainnyaKet,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: sty(14, FontWeight.w600, SC.ink),
            decoration: _dec('Deskripsi singkat atau ketentuan penilaian', fill: Colors.white),
          ),
        ],
      ),
    );
  }

  String _jenisTitle(String j) {
    switch (j) {
      case 'TES_TAHFIDZ':
        return 'Tes Tahfidz';
      case 'LAINNYA':
        return 'Lainnya';
      case 'ULANGAN':
        return 'Ulangan';
      default:
        return j; // UTS, UAS
    }
  }
}

class _KelasChooser extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final Map<String, dynamic>? selected;
  final bool bolehSemua;
  const _KelasChooser({required this.list, required this.selected, this.bolehSemua = true});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text('Pilih Kelas / Rombel', style: sty(15, FontWeight.w800, SC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (bolehSemua)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.groups_2_outlined, size: 20, color: SC.primary),
                      title: Text('Semua kelas', style: sty(14, FontWeight.w700, SC.ink)),
                      trailing: selected == null
                          ? Icon(Icons.check_circle, size: 18, color: SC.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(<String, dynamic>{'nama': '__ALL__'}),
                    ),
                  for (final k in list)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.apartment_outlined, size: 20, color: SC.primary),
                      title: Text('${k['nama']}', style: sty(14, FontWeight.w700, SC.ink)),
                      subtitle: k['count'] == null
                          ? null
                          : Text('${k['count']} Santri',
                              style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                      trailing: selected?['nama'] == k['nama']
                          ? Icon(Icons.check_circle, size: 18, color: SC.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(k),
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
}