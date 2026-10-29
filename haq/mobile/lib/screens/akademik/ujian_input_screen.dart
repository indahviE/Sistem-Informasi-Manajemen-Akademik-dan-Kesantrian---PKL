import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

// Halaman Input Nilai (mandiri: tidak bergantung pada file ujian lain).
//
// Alur: Tahap 1 pilih santri -> Tahap 2 input nilai.
// Remedial dikerjakan di halaman tersendiri.
//
// Catatan kunci: saat ujian terkunci, layar TIDAK lagi memblokir input.
// Backend yang memutuskan boleh/tidaknya (mis. nilai susulan santri
// sakit/izin/alpa). Pesan penolakan dari backend ditampilkan apa adanya.
//
// Pimpinan/Mudir: tidak boleh menginput nilai. Halaman ini tidak dibuka dari
// layar mereka; penjagaan _readOnly di bawah hanya jaring pengaman.

const double _maxW = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double _kkmDefault = 75;

const _presets = <int>[70, 75, 80, 85, 90, 100];

// Warna status (hijau tidak ada di SC; merah ikut SC.errorBg/errorText)
const _kOkBg = Color(0xFFE8F5E9);
const _kOkFg = Color(0xFF1B5E20);
const _kOkBd = Color(0xFFC8E6C9);
const _kGoldChip = Color(0xFFFDEFD3);

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

String _fmtNum(dynamic v) {
  if (v is! num) return '';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

String _grade(double n, double kkm) {
  if (n >= 90) return 'A';
  if (n >= 80) return 'B+';
  if (n >= kkm) return 'B';
  return '';
}

String _labelKehadiran(String s) {
  switch (s.toUpperCase()) {
    case 'SAKIT':
      return 'Sakit';
    case 'IZIN':
      return 'Izin';
    case 'ALPA':
      return 'Alpa';
    default:
      return 'Susulan';
  }
}

List<Map<String, dynamic>> _listOf(dynamic v) =>
    ((v as List?) ?? []).whereType<Map<String, dynamic>>().toList();

InputDecoration _dec(String hint, {Color? fill, bool error = false}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    filled: true,
    fillColor: fill ?? SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: b(Colors.transparent),
    enabledBorder: b(error ? _badBd : Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
}

/// Halaman Input Nilai.
class UjianInputScreen extends StatefulWidget {
  final Map<String, dynamic> ujian;
  const UjianInputScreen({super.key, required this.ujian});

  @override
  State<UjianInputScreen> createState() => _UjianInputScreenState();
}

class _UjianInputScreenState extends State<UjianInputScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _santriAll = [];
  List<Map<String, dynamic>> _remedials = [];
  bool _loading = true;
  String? _error;

  // Tahap 1
  String _query = '';
  String _filter = 'ALL'; // ALL | BELUM | SUDAH
  bool _showAll = false;
  Map<String, dynamic>? _selected;
  final _searchC = TextEditingController();
  final _scroll = ScrollController();

  // Tahap 2
  final _nilaiCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  bool _savingNilai = false;
  String _kehadiran = 'HADIR';

  final _step2Key = GlobalKey();

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  static const _initialCount = 6;

  /// Pimpinan/Mudir hanya memantau: tidak bisa menginput nilai.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  dynamic get _id => widget.ujian['id'];

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
    _nilaiCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.ujian}/$_id');

      // Data remedial (opsional): untuk badge status akhir.
      var rem = <Map<String, dynamic>>[];
      try {
        final rr = await api.get('${ApiUrl.ujian}/$_id/remedial');
        rem = _listOf(rr is Map ? (rr['data'] ?? rr['remedials'] ?? rr['items']) : rr);
      } on ApiException {
        // endpoint remedial belum ada: anggap kosong
      }

      // Ambil daftar santri sekali saja (kalau sebelumnya masih kosong).
      var santri = _santriAll;
      if (santri.isEmpty) {
        try {
          final sr = await api.get(ApiUrl.santri);
          santri = _listOf(sr is Map ? (sr['data'] ?? sr['santris'] ?? sr['items']) : sr);
        } on ApiException {
          // biarkan kosong; ditangani di tampilan
        }
      }

      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _remedials = rem;
        _santriAll = santri;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// Data ujian dari daftar digabung dengan data endpoint detail.
  Map<String, dynamic> get _ujian => {...widget.ujian, ...?_data};

  /// KKM ujian ini. Backend mengirim KKM mapel di field `kkm`
  /// (jatuh ke bawaan bila belum ada).
  double get _kkm => (_ujian['kkm'] is num) ? (_ujian['kkm'] as num).toDouble() : _kkmDefault;

  String get _kkmText =>
      _kkm == _kkm.roundToDouble() ? _kkm.toStringAsFixed(0) : _kkm.toStringAsFixed(1);

  /// Hanya untuk menampilkan banner; TIDAK dipakai untuk memblokir input.
  bool get _terkunci => _ujian['dikunciPada'] != null;

  bool _aktif(Map<String, dynamic> s) {
    final st = s['status'];
    return st == null || '$st'.toUpperCase() == 'AKTIF';
  }

  List<Map<String, dynamic>> get _santris {
    // Kalau backend sudah mengirim santri di detail ujian, pakai itu.
    if (_data?['santris'] is List) return _listOf(_data!['santris']).where(_aktif).toList();
    final embedded = _listOf(_data?['kelas']?['santris']);
    if (embedded.isNotEmpty) return embedded.where(_aktif).toList();

    // Kalau tidak, saring dari daftar semua santri berdasarkan kelas ujian.
    final kelasId = _ujian['kelasId'] ?? _ujian['kelas']?['id'];
    if (kelasId == null) return _santriAll.where(_aktif).toList(); // "Semua kelas"
    return _santriAll
        .where((s) => _aktif(s) && (s['kelasId'] ?? s['kelas']?['id']) == kelasId)
        .toList();
  }

  List<Map<String, dynamic>> get _nilais => _listOf(_data?['nilais']);

  dynamic _sidOf(Map<String, dynamic> n) => n['santriId'] ?? (n['santri'] as Map?)?['id'];

  Map<String, dynamic>? _nilaiOf(dynamic santriId) {
    for (final n in _nilais) {
      if (_sidOf(n) == santriId) return n;
    }
    return null;
  }

  Map<String, dynamic>? _remedialOf(dynamic santriId) {
    for (final r in _remedials) {
      final id = r['santriId'] ?? (r['santri'] as Map?)?['id'];
      if (id == santriId) return r;
    }
    return null;
  }

  /// Sudah punya angka nilai. Santri sakit/izin/alpa belum dihitung.
  bool _sudahDinilai(Map<String, dynamic> s) => _nilaiOf(s['id'])?['nilai'] is num;

  String get _kelasNama => '${_ujian['kelas']?['namaKelas'] ?? ''}';

  double? get _nilaiVal {
    final v = double.tryParse(_nilaiCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) return null;
    return v;
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
  // Aksi
  // ---------------------------------------------------------------------
  void _select(Map<String, dynamic> s) {
    if (_readOnly) return;
    final existing = _nilaiOf(s['id']);
    var status = '${existing?['status'] ?? 'HADIR'}'.toUpperCase();

    // Ujian terkunci + santri tercatat sakit/izin/alpa: kemungkinan besar
    // yang ingin diisi adalah nilai susulan, jadi mulai dari "Hadir".
    if (_terkunci && status != 'HADIR') status = 'HADIR';

    setState(() {
      _selected = s;
      _kehadiran = status;
      _nilaiCtrl.text = existing == null ? '' : _fmtNum(existing['nilai']);
      _catCtrl.text = '${existing?['catatan'] ?? ''}';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _step2Key.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(c,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.05);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _kehadiran = 'HADIR';
      _nilaiCtrl.clear();
      _catCtrl.clear();
    });
  }

  Future<void> _saveNilai() async {
    if (_readOnly) return;
    final s = _selected;
    if (s == null) return;

    final hadir = _kehadiran == 'HADIR';
    final v = _nilaiVal;
    if (hadir && v == null) {
      _toast('Nilai belum valid', subtitle: 'Masukkan nilai antara 0 – 100.', error: true);
      return;
    }
    setState(() => _savingNilai = true);
    try {
      // Tidak ada pemblokiran di sini: kalau ujian terkunci dan backend
      // menolak, ApiException berisi alasannya dan ditampilkan di banner.
      // Santri yang tadinya Sakit/Izin/Alpa lalu ikut susulan: alasan lamanya
      // dicatat di catatan, karena status akan tertimpa jadi Hadir.
      var catatan = _catCtrl.text.trim();
      final sebelum = '${_nilaiOf(s['id'])?['status'] ?? 'HADIR'}'.toUpperCase();
      if (hadir &&
          const ['SAKIT', 'IZIN', 'ALPA'].contains(sebelum) &&
          !catatan.contains('Ikut susulan')) {
        final tanda = 'Ikut susulan (sebelumnya: ${_labelKehadiran(sebelum)})';
        catatan = catatan.isEmpty ? tanda : '$catatan\n$tanda';
      }

      await AppScope.of(context).api.post('${ApiUrl.ujian}/$_id/nilai', {
        'santriId': s['id'],
        'status': _kehadiran,
        if (hadir) 'nilai': v,
        'catatan': catatan,
      });
      await _load(silent: true);
      if (!mounted) return;
      final nama = '${s['nama']}';
      if (!hadir) {
        _toast('$nama dicatat ${_labelKehadiran(_kehadiran).toLowerCase()}',
            subtitle: 'Masuk jalur susulan');
      } else if ((v ?? 0) >= _kkm) {
        _toast('Nilai $nama tersimpan', subtitle: 'Nilai ${_fmtNum(v)} • Tuntas');
      } else {
        _toast('Nilai $nama tersimpan',
            subtitle: 'Nilai ${_fmtNum(v)} • Belum tuntas, masuk remedial');
      }
      _clearSelection();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _savingNilai = false);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _santris.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxW),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: () => _load(silent: true),
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _banner()),
                ..._infoSlivers(),
                if (_selected != null && !_loading && _error == null)
                  SliverToBoxAdapter(child: _step2()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    height: showControls ? 118 : 0.0,
                    child: showControls
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [_searchBar(), _segmented()],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                ..._bodySlivers(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    final total = _santris.length;
    final sudah = _santris.where(_sudahDinilai).length;
    final belum = total - sudah;
    final nama = '${_ujian['nama'] ?? 'Ujian'}';

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
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.edit_note_rounded, size: 26, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Input Nilai', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      _kelasNama.isEmpty ? nama : '$nama • $_kelasNama',
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
                stat(Icons.groups_rounded, loaded ? '$total' : '–', 'Santri'),
                garis(),
                stat(Icons.task_alt_rounded, loaded ? '$sudah' : '–', 'Sudah dinilai'),
                garis(),
                stat(Icons.pending_actions_rounded, loaded ? '$belum' : '–', 'Belum dinilai',
                    warn: loaded && belum > 0),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('KKM $_kkmText',
                  style: sty(11.5, FontWeight.w600, Colors.white.withOpacity(0.85))),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Info kunci / semua dinilai
  // ---------------------------------------------------------------------
  Widget _infoBox(IconData icon, String text,
      {required Color bg, required Color fg, required Color bd}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: sty(12, FontWeight.w600, fg, h: 1.35))),
          ],
        ),
      ),
    );
  }

  List<Widget> _infoSlivers() {
    if (_loading || _error != null) return const [];
    return [
      if (_terkunci)
        SliverToBoxAdapter(
          child: _infoBox(
            Icons.lock_outline_rounded,
            'Nilai ujian ini sudah dikunci. Santri susulan (sakit/izin/alpa) tetap bisa diisi nilainya. Untuk koreksi nilai lain, buka kunci di halaman Detail Ujian (alasan wajib diisi).',
            bg: SC.goldSurface,
            fg: SC.goldDark,
            bd: SC.gold.withOpacity(0.45),
          ),
        ),
      if (!_terkunci && _santris.isNotEmpty && _santris.every(_sudahDinilai))
        SliverToBoxAdapter(
          child: _infoBox(
            Icons.check_circle_outline_rounded,
            'Semua santri sudah dinilai. Ketuk santri untuk koreksi, lalu kunci nilai di halaman Detail Ujian.',
            bg: _kOkBg,
            fg: _kOkFg,
            bd: _kOkBd,
          ),
        ),
    ];
  }

  // ---------------------------------------------------------------------
  // Pencarian & filter (Tahap 1)
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
            hintText: 'Cari nama atau NIS santri',
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

  /// Kontrol segmen Semua / Belum / Sudah.
  Widget _segmented() {
    final all = _santris;
    final nSudah = all.where(_sudahDinilai).length;

    Widget seg(String value, String label, int n) {
      final active = _filter == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _filter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? SC.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$label ($n)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, FontWeight.w700, active ? Colors.white : SC.inkSecondary)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: SC.surfaceDim,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.border),
        ),
        child: Row(
          children: [
            seg('ALL', 'Semua', all.length),
            seg('BELUM', 'Belum', all.length - nSudah),
            seg('SUDAH', 'Sudah', nSudah),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Isi daftar santri (Tahap 1)
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

    final q = _query.trim().toLowerCase();
    final all = _santris;
    if (all.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.groups_outlined,
            judul: 'Belum ada santri',
            pesan: 'Belum ada data santri di kelas ini.',
          ),
        ),
      ];
    }

    final filtered = all.where((s) {
      if (q.isNotEmpty && !'${s['nama']} ${s['nis']}'.toLowerCase().contains(q)) return false;
      if (_filter == 'BELUM') return !_sudahDinilai(s);
      if (_filter == 'SUDAH') return _sudahDinilai(s);
      return true;
    }).toList()
      ..sort((a, b) {
        // belum dinilai di atas, lalu urut nama
        final c = (_sudahDinilai(a) ? 1 : 0).compareTo(_sudahDinilai(b) ? 1 : 0);
        return c != 0 ? c : '${a['nama']}'.toLowerCase().compareTo('${b['nama']}'.toLowerCase());
      });

    // Kalau santri berasal dari beberapa kelas, tampilkan per kelas (tanpa potong "tampilkan semua").
    final kelasSet = filtered.map(_kelasOfSantri).whereType<String>().toSet();
    final grouped = kelasSet.length > 1 || (_ujian['kelas'] == null && kelasSet.isNotEmpty);
    final visible = (grouped ||
            _showAll ||
            q.isNotEmpty ||
            _filter != 'ALL' ||
            filtered.length <= _initialCount)
        ? filtered
        : filtered.take(_initialCount).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: SC.goldDark, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('TAHAP 1', style: sty(10, FontWeight.w800, SC.goldDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pilih santri untuk dinilai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(15, FontWeight.w800, SC.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('${filtered.length}', style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Santri tidak ditemukan',
            pesan: 'Pastikan kata kunci sesuai nama lengkap atau NIS santri.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ..._santriWidgets(visible, grouped),
              if (!grouped && !_showAll && q.isEmpty && filtered.length > _initialCount)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    child: Text('Tampilkan semua (${filtered.length})',
                        style: sty(12.5, FontWeight.w800, SC.primary)),
                  ),
                ),
            ]),
          ),
        ),
    ];
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
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
                  child: Icon(icon, size: 38, color: SC.primary),
                ),
                Positioned(top: 8, right: 14, child: Icon(Icons.star_rounded, size: 17, color: SC.gold)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(judul, textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(pesan,
              textAlign: TextAlign.center, style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }

  /// Nama kelas santri (null bila tidak ada).
  String? _kelasOfSantri(Map<String, dynamic> s) {
    final k = s['kelas'];
    final v = k is Map ? k['namaKelas'] : null;
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Daftar kartu santri; kalau [grouped], dipecah per kelas dengan judul seksi.
  List<Widget> _santriWidgets(List<Map<String, dynamic>> list, bool grouped) {
    if (!grouped) return [for (final s in list) _santriTile(s)];

    final groups = <String, List<Map<String, dynamic>>>{};
    final tanpa = <Map<String, dynamic>>[];
    for (final s in list) {
      final k = _kelasOfSantri(s);
      if (k == null) {
        tanpa.add(s);
      } else {
        groups.putIfAbsent(k, () => []).add(s);
      }
    }
    final names = groups.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final out = <Widget>[];
    var first = true;
    for (final k in names) {
      out.add(_sectionHeader(k, groups[k]!.length, first: first));
      first = false;
      out.addAll(groups[k]!.map(_santriTile));
    }
    if (tanpa.isNotEmpty) {
      out.add(_sectionHeader('Belum ada kelas', tanpa.length, unassigned: true, first: first));
      out.addAll(tanpa.map(_santriTile));
    }
    return out;
  }

  Widget _sectionHeader(String title, int count, {bool unassigned = false, bool first = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, first ? 2 : 14, 2, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: unassigned ? SC.surfaceDim : SC.sage,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(unassigned ? Icons.help_outline_rounded : Icons.class_rounded,
                size: 15, color: unassigned ? SC.inkSecondary : SC.primary),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, FontWeight.w800, SC.inkSecondary, h: 1.1)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
            child: Text('$count', style: sty(10.5, FontWeight.w800, SC.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: SC.border)),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SC.inkMuted),
          const SizedBox(width: 3),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
          ),
        ],
      );

  Widget _santriTile(Map<String, dynamic> s) {
    final sel = _selected != null && _selected!['id'] == s['id'];
    final n = _nilaiOf(s['id']);
    final nama = '${s['nama']}';
    final jk = s['jenisKelamin']?.toString().toUpperCase();

    Widget status;
    if (n != null) {
      final v = n['nilai'] is num ? (n['nilai'] as num).toDouble() : null;
      if (v == null) {
        status = _pill(_labelKehadiran('${n['status']}'),
            bg: SC.goldSurface, fg: SC.goldDark, bd: SC.gold.withOpacity(0.4));
      } else if (v >= _kkm) {
        status = _pill('Dinilai ${_fmtNum(v)}', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd);
      } else {
        final rem = _remedialOf(s['id']);
        final st = '${rem?['status'] ?? ''}'.toUpperCase();
        final ak = _fmtNum(rem?['nilaiAkhir']);
        final alur = '${_fmtNum(v)}${ak.isEmpty ? '' : ' → $ak'}';
        if (st == 'TUNTAS') {
          status = _pill('$alur Remedial', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd);
        } else if (st == 'BELUM_TUNTAS') {
          status = _pill('$alur Belum tuntas', bg: SC.errorBg, fg: SC.errorText, bd: _badBd);
        } else {
          status = _pill('Dinilai ${_fmtNum(v)} • Remedial',
              bg: SC.errorBg, fg: SC.errorText, bd: _badBd);
        }
      }
    } else if (sel) {
      status = _pill('Belum Dinilai', bg: _kGoldChip, fg: SC.goldDark);
    } else {
      status = _pill('Siap Dinilai', bg: SC.surfaceDim, fg: SC.inkSecondary);
    }

    final terkunciRapi = _terkunci && _sudahDinilai(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? SC.goldSurface : SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? SC.gold.withOpacity(0.6) : SC.border),
          boxShadow: softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: terkunciRapi ? null : () => _select(s),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SantriAvatar(name: nama, gender: jk, size: 50, badge: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: sty(14.5, FontWeight.w800, SC.ink)),
                            ),
                            if (sel) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified_outlined, size: 15, color: SC.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _meta(Icons.tag_rounded, '${s['nis']}'),
                            status,
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (terkunciRapi)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock_outline, size: 16, color: SC.inkSecondary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tahap 2: input nilai
  // ---------------------------------------------------------------------
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary)),
      );

  Widget _step2() {
    final s = _selected!;
    final v = _nilaiVal;
    final hasText = _nilaiCtrl.text.trim().isNotEmpty;
    final below = v != null && v < _kkm;
    final ok = v != null && v >= _kkm;
    final hadir = _kehadiran == 'HADIR';

    return Padding(
      key: _step2Key,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: SC.goldDark, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('TAHAP 2', style: sty(10, FontWeight.w800, SC.goldDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Input nilai ujian',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(15, FontWeight.w800, SC.ink)),
                ),
                InkWell(
                  onTap: _savingNilai ? null : _clearSelection,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SC.surfaceDim,
                      shape: BoxShape.circle,
                      border: Border.all(color: SC.border),
                    ),
                    child: const Icon(Icons.close_rounded, size: 17, color: SC.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _pill('${s['nama']}',
                bg: SC.surfaceDim, fg: SC.inkSecondary, icon: Icons.person_outline),
            const SizedBox(height: 16),
            _label('Kehadiran saat ujian'),
            _kehadiranPicker(),
            const SizedBox(height: 14),
            if (!hadir)
              _infoSusulan()
            else ...[
              Row(
                children: [
                  Expanded(child: _label('Nilai capaian santri (skala 0-100)')),
                  if (below)
                    _pill('Belum Tuntas', bg: SC.errorBg, fg: SC.errorText, bd: _badBd),
                  if (ok)
                    _pill('Tuntas (${_grade(v, _kkm)})', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: below ? SC.errorBg.withOpacity(0.45) : SC.surfaceDim,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: below ? _badBd : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nilaiCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        style: sty(22, FontWeight.w800,
                            below ? SC.errorText : (ok ? _kOkFg : SC.ink)),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: sty(22, FontWeight.w800, SC.inkMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    Text('KKM: $_kkmText',
                        style: sty(12, FontWeight.w700, below ? SC.errorText : SC.inkSecondary)),
                    if (below) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded, size: 18, color: SC.errorText),
                    ],
                    if (ok) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle_outline, size: 18, color: _kOkFg),
                    ],
                  ],
                ),
              ),
              if (hasText && v == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text('Nilai harus antara 0 sampai 100.',
                      style: sty(11.5, FontWeight.w600, SC.errorText)),
                ),
              if (below) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SC.errorBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _badBd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: SC.errorText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nilai ${_fmtNum(v)} di bawah batas KKM ($_kkmText). Santri akan masuk daftar remedial.',
                          style: sty(12, FontWeight.w600, SC.errorText, h: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _label('Pilihan cepat nilai preset'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in (<int>{..._presets, _kkm.round()}.toList()..sort()))
                    _presetChip(p, v),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _label('Catatan penguji / evaluasi (opsional)'),
            TextField(
              controller: _catCtrl,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 5,
              style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
              decoration: _dec('Tulis catatan evaluasi santri…'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _savingNilai ? null : _clearSelection,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SC.border),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _savingNilai ? null : _saveNilai,
                    style: FilledButton.styleFrom(
                      backgroundColor: SC.primary,
                      disabledBackgroundColor: SC.primary.withOpacity(0.5),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: _savingNilai
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                    label: Text(_savingNilai ? 'Menyimpan...' : 'Simpan Nilai',
                        style: sty(13, FontWeight.w700, Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kehadiranPicker() {
    const opsi = [
      ['HADIR', 'Hadir'],
      ['SAKIT', 'Sakit'],
      ['IZIN', 'Izin'],
      ['ALPA', 'Alpa'],
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in opsi)
          GestureDetector(
            onTap: _savingNilai ? null : () => setState(() => _kehadiran = o[0]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _kehadiran == o[0] ? SC.primary : SC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _kehadiran == o[0] ? SC.primary : SC.border),
              ),
              child: Text(o[1],
                  style: sty(12, FontWeight.w700,
                      _kehadiran == o[0] ? Colors.white : SC.inkSecondary)),
            ),
          ),
      ],
    );
  }

  Widget _infoSusulan() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SC.goldSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SC.gold.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: SC.goldDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Santri tidak ikut ujian. Nilai dikosongkan dan santri masuk jalur ujian susulan, bukan remedial. Setelah ikut susulan, pilih "Hadir" lalu isi nilainya.',
                style: sty(12, FontWeight.w600, SC.goldDark, h: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _presetChip(int p, double? current) {
    final sel = current != null && current == p.toDouble();
    final isKkm = p == _kkm.round();
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _nilaiCtrl.text = '$p'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel || isKkm ? _kGoldChip : SC.surfaceDim,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? SC.gold : Colors.transparent, width: 1.2),
        ),
        child: Text(isKkm ? '$p (KKM)' : '$p',
            style: sty(12.5, sel || isKkm ? FontWeight.w800 : FontWeight.w600,
                sel || isKkm ? SC.goldDark : SC.ink)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bar bawah: progres
  // ---------------------------------------------------------------------
  Widget _bottomBar() {
    final total = _santris.length;
    final done = _santris.where((s) => _nilaiOf(s['id']) != null).length;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0).toDouble();

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
        child: Container(
          decoration: BoxDecoration(
            color: SC.surface,
            border: const Border(top: BorderSide(color: SC.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Progres penilaian',
                            style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                      ),
                      Text('${(progress * 100).round()}%',
                          style: sty(13, FontWeight.w800, SC.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$done dari $total santri selesai',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(13.5, FontWeight.w800, SC.ink)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: SC.border,
                      valueColor: AlwaysStoppedAnimation(SC.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}