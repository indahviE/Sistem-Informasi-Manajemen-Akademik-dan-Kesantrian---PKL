import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'ujian_input_screen.dart';
import 'ujian_remedial_screen.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

// Halaman Detail Ujian (mandiri: tidak bergantung pada file ujian lain).
//
// Status akhir santri ditentukan dari nilai awal + data remedial dari backend
// (status & nilaiAkhir), sama dengan halaman Remedial:
//   - nilai awal >= KKM                  -> Tuntas langsung
//   - di bawah KKM, remedial TUNTAS      -> Tuntas (remedial)
//   - di bawah KKM, remedial BELUM_TUNTAS-> Belum Tuntas (final)
//   - di bawah KKM, remedial belum ada/selesai -> Belum Tuntas (menunggu remedial)
//   - tanpa nilai (sakit/izin/alpa)      -> Susulan
//
// Kalau ujian mencakup beberapa kelas (mis. "Semua kelas"), daftar dikelompokkan
// per kelas. Pengelompokan butuh backend mengirim santri.kelas.namaKelas di setiap
// nilai; kalau tidak ada, daftar tampil datar seperti biasa.
//
// Pimpinan/Mudir: mode baca saja (tanpa input nilai, kunci, atau remedial).

/// Lebar maksimum kolom konten.
const double kMaxWidth = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double kKkmDefault = 75;

// Warna status (hijau & kuning tidak ada di SC; merah ikut SC.errorBg/errorText)
const _kOkBg = Color(0xFFE8F5E9);
const _kOkFg = Color(0xFF1B5E20);
const _kOkBd = Color(0xFFC8E6C9);
const _kWarnBg = Color(0xFFFFF8E1);
const _kWarnFg = Color(0xFFB78103);
const _kWarnBd = Color(0xFFFFE082);
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

String _jenisLabel(String j) {
  switch (j) {
    case 'UAS':
      return 'Ujian Akhir Semester';
    case 'UTS':
      return 'Ujian Tengah Semester';
    case 'TES_TAHFIDZ':
      return 'Tes Tahfidz';
    case 'LAINNYA':
      return 'Penilaian Lainnya';
    default:
      return 'Ulangan Harian';
  }
}

IconData _jenisIcon(String j) {
  switch (j) {
    case 'UAS':
      return Icons.menu_book_rounded;
    case 'UTS':
      return Icons.auto_stories_rounded;
    case 'TES_TAHFIDZ':
      return Icons.menu_book;
    case 'LAINNYA':
      return Icons.record_voice_over_outlined;
    default:
      return Icons.assignment_rounded;
  }
}

String _jenisOf(Map<String, dynamic> u) => (u['jenis'] ?? 'ULANGAN') as String;

String _grade(double n, double kkm) {
  if (n >= 90) return 'A';
  if (n >= 80) return 'B+';
  if (n >= kkm) return 'B';
  return '';
}

double? _nilaiNum(Map<String, dynamic> n) =>
    n['nilai'] is num ? (n['nilai'] as num).toDouble() : null;

String _kehadiranOf(Map<String, dynamic> n) => '${n['status'] ?? 'HADIR'}'.toUpperCase();

String _fmtNum(dynamic v) {
  if (v is! num) return '';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

String _fmtTgl(dynamic raw) {
  final d = DateTime.tryParse('$raw');
  if (d == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Status akhir santri pada ujian ini.
enum _Akhir { tuntasLangsung, tuntasRemedial, belumFinal, belumMenunggu, susulan }

// Dialog bertema (sama dengan halaman Ustadz)
RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

Widget _dialogIcon(IconData icon, Color bg, Color fg) => Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 26, color: fg),
    );

Widget _btnBatal(VoidCallback onTap, {String label = 'Batal'}) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: SC.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, SC.inkSecondary)),
    );

Widget _btnUtama(String label, VoidCallback onTap, {Color? warna}) => FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: warna ?? SC.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, Colors.white)),
    );

/// Halaman Detail Ujian & Daftar Nilai.
class UjianDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ujian;
  const UjianDetailScreen({super.key, required this.ujian});

  @override
  State<UjianDetailScreen> createState() => _UjianDetailScreenState();
}

class _UjianDetailScreenState extends State<UjianDetailScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _remedials = [];
  bool _loading = true;
  bool _busyKunci = false;
  String? _error;
  String _tab = 'ALL'; // ALL | OK | BAD | SUS
  String _query = '';
  final _searchC = TextEditingController();
  final _scroll = ScrollController();

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  /// Nama kelas yang sedang dibuka (kartu kelas bisa dibuka/tutup).
  final Set<String> _terbuka = {};
  bool _kelasAwalDiatur = false;

  /// santriId -> nama kelas, diambil dari daftar santri (sama seperti halaman Input Nilai).
  Map<dynamic, String> _kelasBySantri = {};
  static const _tanpaKelas = 'Belum ada kelas';

  /// Pimpinan/Mudir hanya memantau: tidak bisa input nilai, kunci, atau remedial.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

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
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.ujian}/${widget.ujian['id']}');

      // Data remedial (opsional): dipakai supaya status & nilai akhir sama dengan halaman Remedial.
      var rem = <Map<String, dynamic>>[];
      try {
        final rr = await api.get('${ApiUrl.ujian}/${widget.ujian['id']}/remedial');
        final raw = rr is Map ? (rr['data'] ?? rr['remedials'] ?? rr['items']) : rr;
        rem = ((raw as List?) ?? []).whereType<Map<String, dynamic>>().toList();
      } on ApiException {
        // Endpoint belum ada / gagal: anggap kosong.
      }

      // Peta santri -> kelas (sekali saja). Dipakai kalau nilai dari backend
      // tidak membawa santri.kelas.namaKelas.
      var peta = _kelasBySantri;
      if (peta.isEmpty) {
        try {
          final sr = await api.get(ApiUrl.santri);
          final raw = sr is Map ? (sr['data'] ?? sr['santris'] ?? sr['items']) : sr;
          final m = <dynamic, String>{};
          for (final s in ((raw as List?) ?? []).whereType<Map>()) {
            final k = s['kelas'];
            final nama = k is Map ? '${k['namaKelas'] ?? ''}'.trim() : '';
            if (nama.isNotEmpty) m[s['id']] = nama;
          }
          peta = m;
        } on ApiException {
          // Gagal: daftar tetap tampil datar.
        }
      }

      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _remedials = rem;
        _kelasBySantri = peta;
        _loading = false;
        _error = null;
        _aturKelasAwal();
      });
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

  /// Data ujian dari daftar digabung dengan data dari endpoint detail,
  /// supaya field yang tidak dikirim endpoint detail tetap terisi.
  Map<String, dynamic> get _ujian => {...widget.ujian, ...?_data};

  /// KKM ujian ini. Backend mengirim KKM mapel di field `kkm`
  /// (jatuh ke bawaan bila belum ada).
  double get _kkm => (_ujian['kkm'] is num) ? (_ujian['kkm'] as num).toDouble() : kKkmDefault;

  String get _kkmText =>
      _kkm == _kkm.roundToDouble() ? _kkm.toStringAsFixed(0) : _kkm.toStringAsFixed(1);

  bool get _terkunci => _ujian['dikunciPada'] != null;

  /// Ujian "Semua kelas": kunci hanya oleh Admin (backend mengirim bolehKunci=false untuk ustadz).
  bool get _bolehKunci => _ujian['bolehKunci'] != false;

  // Ujian dianggap belum tiba kalau tanggalnya masih setelah hari ini.
  bool get _belumTiba {
    final d = DateTime.tryParse('${_ujian['tanggal'] ?? ''}')?.toLocal();
    if (d == null) return false;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day).isAfter(DateTime(now.year, now.month, now.day));
  }

  List<Map<String, dynamic>> get _nilais =>
      ((_data?['nilais'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();

  dynamic _sidOf(Map<String, dynamic> m) => m['santriId'] ?? (m['santri'] as Map?)?['id'];

  /// Nama kelas santri pada nilai [n] (null bila backend tidak mengirimnya).
  String? _kelasOfNilai(Map<String, dynamic> n) {
    final s = n['santri'];
    dynamic v;
    if (s is Map && s['kelas'] is Map) v = (s['kelas'] as Map)['namaKelas'];
    if (v == null && n['kelas'] is Map) v = (n['kelas'] as Map)['namaKelas'];
    final t = v?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    return _kelasBySantri[_sidOf(n)];
  }

  /// Data remedial milik santri pada nilai [n] (null bila belum ada).
  Map<String, dynamic>? _remedialOf(Map<String, dynamic> n) {
    final id = _sidOf(n);
    if (id == null) return null;
    for (final r in _remedials) {
      if (_sidOf(r) == id) return r;
    }
    return null;
  }

  /// Status akhir santri berdasarkan nilai awal + remedial dari backend.
  _Akhir _akhirOf(Map<String, dynamic> n) {
    final v = _nilaiNum(n);
    if (v == null) return _Akhir.susulan;
    if (v >= _kkm) return _Akhir.tuntasLangsung;
    final st = '${_remedialOf(n)?['status'] ?? ''}'.toUpperCase();
    if (st == 'TUNTAS') return _Akhir.tuntasRemedial;
    if (st == 'BELUM_TUNTAS') return _Akhir.belumFinal;
    return _Akhir.belumMenunggu;
  }

  /// Kunci grup kelas untuk nilai [n].
  String _kelasKey(Map<String, dynamic> n) => _kelasOfNilai(n) ?? _tanpaKelas;

  /// Buka otomatis kelas yang masih punya santri belum tuntas atau susulan.
  /// Hanya dijalankan sekali, supaya pilihan buka/tutup tidak berubah saat muat ulang.
  void _aturKelasAwal() {
    if (_kelasAwalDiatur) return;
    _kelasAwalDiatur = true;
    for (final n in _nilais) {
      if (!_isTuntas(_akhirOf(n))) _terbuka.add(_kelasKey(n));
    }
  }

  bool _isTuntas(_Akhir a) => a == _Akhir.tuntasLangsung || a == _Akhir.tuntasRemedial;

  /// Santri di bawah KKM yang remedialnya masih menunggu
  /// (BELUM_TUNTAS sudah final, jadi tidak dihitung). Sama dengan halaman Remedial.
  int get _remedialAktif => _nilais.where((n) => _akhirOf(n) == _Akhir.belumMenunggu).length;

  /// Ada santri tanpa nilai (sakit/izin/alpa) yang masih bisa diisi susulan.
  bool get _adaSusulan => _nilais.any((n) => _nilaiNum(n) == null);

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  // Buka halaman Input Nilai, lalu muat ulang data setelah kembali.
  Future<void> _openInput() async {
    if (_readOnly) return;

    if (_belumTiba) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: SC.surface,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape,
          icon: _dialogIcon(Icons.event_outlined, SC.goldSurface, SC.goldDark),
          title: Text('Ujian belum berlangsung',
              textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
          content: Text(
            'Ujian ini dijadwalkan ${_fmtTgl(_ujian['tanggal'])}. Tetap input nilai sekarang?',
            textAlign: TextAlign.center,
            style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            _btnBatal(() => Navigator.pop(c, false)),
            _btnUtama('Lanjut', () => Navigator.pop(c, true)),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UjianInputScreen(ujian: _ujian)),
    );
    if (mounted) _load(spinner: false);
  }

  // Buka halaman Remedial, lalu muat ulang data setelah kembali.
  Future<void> _openRemedial() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UjianRemedialScreen(ujian: _ujian)),
    );
    if (mounted) _load(spinner: false);
  }

  Future<void> _kunci() async {
    if (_busyKunci || _readOnly) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: _dialogIcon(Icons.lock_outline_rounded, SC.goldSurface, SC.goldDark),
        title: Text('Kunci nilai ujian?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          'Setelah dikunci, nilai dan remedial tidak bisa diubah (kecuali ujian susulan santri sakit/izin/alpa). Untuk mengubahnya, kunci harus dibuka dengan alasan yang dicatat.',
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(c, false)),
          _btnUtama('Kunci', () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busyKunci = true);
    try {
      final res = await AppScope.of(context)
          .api
          .post('${ApiUrl.ujian}/${widget.ujian['id']}/kunci');
      await _load(spinner: false);
      if (!mounted) return;
      final r = res is Map ? res['ringkasan'] : null;
      if (r is Map) {
        await _tampilRingkasan(Map<String, dynamic>.from(r));
      } else {
        _toast('Nilai ujian dikunci', subtitle: '${_ujian['nama'] ?? 'Ujian'}');
      }
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal mengunci nilai.', error: true);
    } finally {
      if (mounted) setState(() => _busyKunci = false);
    }
  }

  Future<void> _bukaKunci() async {
    if (_busyKunci || _readOnly) return;
    final alasan = await showDialog<String>(
      context: context,
      builder: (_) => const _AlasanDialog(),
    );
    if (alasan == null || !mounted) return;

    setState(() => _busyKunci = true);
    try {
      await AppScope.of(context)
          .api
          .post('${ApiUrl.ujian}/${widget.ujian['id']}/buka-kunci', {'alasan': alasan});
      await _load(spinner: false);
      if (mounted) {
        _toast('Kunci dibuka', subtitle: 'Setiap perubahan nilai akan tercatat');
      }
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal membuka kunci.', error: true);
    } finally {
      if (mounted) setState(() => _busyKunci = false);
    }
  }

  Future<void> _tampilRingkasan(Map<String, dynamic> r) {
    Widget row(String l, dynamic v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(l, style: sty(13, FontWeight.w500, SC.inkSecondary))),
            Text('$v', style: sty(13, FontWeight.w800, SC.ink)),
          ]),
        );
    return showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: _dialogIcon(Icons.lock_rounded, SC.sage, SC.primary),
        title: Text('Nilai dikunci',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('Tuntas langsung', r['tuntasLangsung']),
            row('Di bawah KKM', r['dibawahKkm']),
            row('   • Ikut remedial', r['ikutRemedial']),
            row('   • Tanpa remedial', r['tanpaRemedial']),
            row('Perlu ujian susulan', r['perluSusulan']),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [_btnUtama('Tutup', () => Navigator.pop(c))],
      ),
    );
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
    final showControls = !_loading && _error == null && _nilais.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxWidth),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: () => _load(spinner: false),
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _banner()),
                if (!_loading && _error == null)
                  SliverToBoxAdapter(child: _kunciBanner()),
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
    final u = _ujian;
    final jenis = _jenisOf(u);
    final all = _nilais;
    final loaded = !_loading && _error == null;

    double? avg;
    Map<String, dynamic>? top, low;
    final dinilai = all.where((n) => _nilaiNum(n) != null).toList();
    if (dinilai.isNotEmpty) {
      avg = dinilai.fold<double>(0, (a, n) => a + _nilaiNum(n)!) / dinilai.length;
      top = dinilai.reduce((a, b) => _nilaiNum(a)! >= _nilaiNum(b)! ? a : b);
      low = dinilai.reduce((a, b) => _nilaiNum(a)! <= _nilaiNum(b)! ? a : b);
    }

    String nm(Map<String, dynamic>? n) {
      final s = n?['santri'];
      return s is Map ? '${s['nama'] ?? '-'}' : '-';
    }

    final kelasNama = u['kelas']?['namaKelas'];
    final totalSantri =
        u['totalSantri'] ?? u['kelas']?['jumlahSantri'] ?? u['kelas']?['_count']?['santris'];
    final kelasLabel = kelasNama == null
        ? 'Semua kelas'
        : (totalSantri is int && totalSantri > 0 ? '$kelasNama ($totalSantri)' : '$kelasNama');
    final tgl = _fmtTgl(u['tanggal']);
    final mapel = u['mapel']?['namaMapel'] ?? 'Umum';

    String v(double? n, {int digits = 0}) =>
        !loaded || n == null ? '–' : n.toStringAsFixed(digits);

    Widget stat(IconData icon, String value, String label, String? sub, {bool gold = false}) =>
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: gold ? SC.gold : Colors.white.withOpacity(0.7)),
              const SizedBox(height: 5),
              Text(value, style: sty(20, FontWeight.w800, gold ? SC.gold : Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72))),
              if (sub != null && sub != '-')
                Padding(
                  padding: const EdgeInsets.only(top: 1, left: 4, right: 4),
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(10, FontWeight.w500, Colors.white.withOpacity(0.55))),
                ),
            ],
          ),
        );

    Widget garis() => Container(width: 1, height: 52, color: Colors.white.withOpacity(0.18));

    Widget info(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12, FontWeight.w500, Colors.white.withOpacity(0.9))),
            ),
          ],
        );

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
                child: Icon(_jenisIcon(jenis), size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u['nama'] ?? 'Ujian'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(19, FontWeight.w800, Colors.white, h: 1.2)),
                    const SizedBox(height: 3),
                    Text(
                      _jenisLabel(jenis),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              info(Icons.menu_book_outlined, '$mapel'),
              info(Icons.groups_2_outlined, kelasLabel),
              if (tgl.isNotEmpty) info(Icons.event_outlined, tgl),
              if (u['durasiMenit'] != null) info(Icons.schedule, '${u['durasiMenit']} menit'),
              info(Icons.flag_outlined, 'KKM $_kkmText'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                stat(Icons.functions_rounded, v(avg, digits: 1), 'Rata-rata', null),
                garis(),
                stat(Icons.trending_up_rounded, v(_nilaiNum(top ?? {})), 'Tertinggi',
                    top == null ? null : nm(top),
                    gold: true),
                garis(),
                stat(Icons.trending_down_rounded, v(_nilaiNum(low ?? {})), 'Terendah',
                    low == null ? null : nm(low)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Banner kunci
  // ---------------------------------------------------------------------
  Widget _kunciBanner() {
    final locked = _terkunci;
    final tgl = _fmtTgl(_ujian['dikunciPada']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: locked ? SC.goldSurface : SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: locked ? SC.gold.withOpacity(0.45) : SC.border),
          boxShadow: softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: locked ? Colors.white : SC.surfaceDim,
                shape: BoxShape.circle,
                border: Border.all(color: locked ? SC.gold.withOpacity(0.45) : SC.border),
              ),
              child: Icon(locked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  size: 18, color: locked ? SC.goldDark : SC.inkSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locked ? 'Nilai dikunci' : 'Nilai masih terbuka',
                      style: sty(13, FontWeight.w800, locked ? SC.goldDark : SC.ink)),
                  const SizedBox(height: 2),
                  Text(
                    locked
                        ? (tgl.isEmpty
                            ? 'Tidak bisa diubah kecuali kunci dibuka (ujian susulan tetap bisa diisi).'
                            : 'Dikunci $tgl. Tidak bisa diubah kecuali kunci dibuka (ujian susulan tetap bisa diisi).')
                        : (_bolehKunci
                            ? 'Kunci setelah semua nilai dan remedial selesai.'
                            : 'Ujian semua kelas dikunci oleh Admin setelah semua ustadz selesai input.'),
                    style: sty(11.5, FontWeight.w500,
                        locked ? SC.goldDark.withOpacity(0.85) : SC.inkSecondary,
                        h: 1.3),
                  ),
                ],
              ),
            ),
            if (!_readOnly && _bolehKunci) ...[
              const SizedBox(width: 8),
              _busyKunci
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: locked ? SC.surface : SC.primary,
                        foregroundColor: locked ? SC.ink : Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: locked ? const BorderSide(color: SC.border) : BorderSide.none,
                        ),
                      ),
                      onPressed: locked ? _bukaKunci : _kunci,
                      child: Text(locked ? 'Buka Kunci' : 'Kunci',
                          style: sty(12, FontWeight.w800, locked ? SC.ink : Colors.white)),
                    ),
            ],
          ],
        ),
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
            hintText: 'Cari santri atau NIS',
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

  /// Kontrol segmen Semua / Tuntas / Belum / Susulan.
  Widget _segmented() {
    final all = _nilais;
    final dinilai = all.where((n) => _nilaiNum(n) != null).toList();
    final susulan = all.length - dinilai.length;
    final tuntas = dinilai.where((n) => _isTuntas(_akhirOf(n))).length;
    final belum = dinilai.length - tuntas;

    Widget seg(String value, String label, int n, {bool merahBilaAda = false}) {
      final active = _tab == value;
      final Color warna = active
          ? Colors.white
          : (merahBilaAda && n > 0 ? SC.errorText : SC.inkSecondary);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = value),
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
                style: sty(11.5, FontWeight.w700, warna)),
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
            seg('OK', 'Tuntas', tuntas),
            seg('BAD', 'Belum', belum, merahBilaAda: true),
            if (susulan > 0) seg('SUS', 'Susulan', susulan),
          ],
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

    final all = _nilais;
    if (all.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.assignment_outlined,
            judul: 'Belum ada nilai',
            pesan: _readOnly
                ? 'Belum ada nilai yang diinput untuk ujian ini.'
                : 'Mulai dengan tombol "Input Nilai" di bawah.',
          ),
        ),
      ];
    }

    Map<String, dynamic>? top;
    final dinilai = all.where((n) => _nilaiNum(n) != null).toList();
    if (dinilai.isNotEmpty) {
      top = dinilai.reduce((a, b) => _nilaiNum(a)! >= _nilaiNum(b)! ? a : b);
    }

    final q = _query.trim().toLowerCase();
    final list = all.where((n) {
      final a = _akhirOf(n);
      if (_tab == 'OK' && !_isTuntas(a)) return false;
      if (_tab == 'BAD' && (a == _Akhir.susulan || _isTuntas(a))) return false;
      if (_tab == 'SUS' && a != _Akhir.susulan) return false;
      if (q.isEmpty) return true;
      final s = (n['santri'] as Map?) ?? const {};
      return '${s['nama']} ${s['nis']}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => (_nilaiNum(b) ?? -1).compareTo(_nilaiNum(a) ?? -1));

    final remedial = _remedialAktif;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
          child: Row(
            children: [
              Text('Daftar Nilai', style: sty(15, FontWeight.w800, SC.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('${all.length}', style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
              const Spacer(),
              if (remedial > 0)
                _pill('$remedial remedial',
                    bg: SC.errorBg, fg: SC.errorText, bd: _badBd, icon: Icons.replay_rounded),
            ],
          ),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada santri yang cocok dengan pencarian atau filter ini.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          sliver: SliverList(delegate: SliverChildListDelegate(_daftarNilai(list, top))),
        ),
    ];
  }

  /// Susun daftar kartu. Kalau ujian mencakup beberapa kelas, kelompokkan per
  /// kelas (urut nama kelas, di dalamnya tetap urut nilai tertinggi).
  List<Widget> _daftarNilai(List<Map<String, dynamic>> list, Map<String, dynamic>? top) {
    final kelasSet = list.map(_kelasOfNilai).whereType<String>().toSet();
    final semuaKelas = _ujian['kelas'] == null;
    final grouped = kelasSet.length > 1 || (semuaKelas && kelasSet.isNotEmpty);

    if (!grouped) {
      return [for (final n in list) _nilaiTile(n, isTop: identical(n, top))];
    }

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final n in list) {
      groups.putIfAbsent(_kelasKey(n), () => []).add(n);
    }
    final names = groups.keys.toList()
      ..sort((a, b) {
        if (a == _tanpaKelas) return 1;
        if (b == _tanpaKelas) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    // Saat mencari atau memfilter, semua kelas yang punya hasil dibuka paksa.
    final menyaring = _query.trim().isNotEmpty || _tab != 'ALL';
    return [
      for (final k in names) _kelasCard(k, groups[k]!, top, paksaBuka: menyaring),
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

  // ---------------------------------------------------------------------
  // Kartu kelas
  // ---------------------------------------------------------------------
  Widget _kelasCard(String nama, List<Map<String, dynamic>> items, Map<String, dynamic>? top,
      {required bool paksaBuka}) {
    // Angka di judul dihitung dari semua santri di kelas ini, bukan hasil filter.
    final semua = _nilais.where((n) => _kelasKey(n) == nama).toList();
    final tuntas = semua.where((n) => _isTuntas(_akhirOf(n))).length;
    final susulan = semua.where((n) => _nilaiNum(n) == null).length;
    final belum = semua.length - tuntas - susulan;
    final buka = paksaBuka || _terbuka.contains(nama);
    final tanpaKelas = nama == _tanpaKelas;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: paksaBuka
                ? null
                : () => setState(() {
                      if (!_terbuka.remove(nama)) _terbuka.add(nama);
                    }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tanpaKelas ? SC.surfaceDim : SC.sage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tanpaKelas ? Icons.help_outline_rounded : Icons.class_rounded,
                      size: 20,
                      color: tanpaKelas ? SC.inkSecondary : SC.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                  style: sty(15, FontWeight.w800, SC.ink)),
                            ),
                            const SizedBox(width: 8),
                            _pill('${semua.length} santri',
                                bg: SC.goldSurface, fg: SC.goldDark, bd: SC.gold.withOpacity(0.4)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (tuntas > 0)
                              _pill('$tuntas tuntas', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd),
                            if (belum > 0)
                              _pill('$belum belum tuntas',
                                  bg: SC.errorBg, fg: SC.errorText, bd: _badBd),
                            if (susulan > 0)
                              _pill('$susulan susulan', bg: _kWarnBg, fg: _kWarnFg, bd: _kWarnBd),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(buka ? Icons.expand_less : Icons.expand_more,
                      size: 24, color: SC.inkSecondary),
                ],
              ),
            ),
          ),
          if (buka) ...[
            const Divider(height: 1, thickness: 1, color: SC.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
              child: Column(
                children: [
                  for (final n in items) _nilaiTile(n, isTop: identical(n, top)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu santri
  // ---------------------------------------------------------------------
  Widget _kartu({required Widget child, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
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

  Widget _nilaiTile(Map<String, dynamic> n, {required bool isTop}) {
    final santri = (n['santri'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final nv = _nilaiNum(n);
    if (nv == null) return _susulanTile(n, santri);
    final v = nv;
    final akhir = _akhirOf(n);
    final ok = _isTuntas(akhir);
    final rem = _remedialOf(n);
    final nilaiAkhir = rem?['nilaiAkhir'];
    final cat = '${n['catatan'] ?? ''}'.trim();

    // Warna kotak nilai: emas (tertinggi), hijau (>=90), abu (tuntas), merah (belum tuntas)
    final Color bg;
    final Color fg;
    if (!ok) {
      bg = SC.errorBg;
      fg = SC.errorText;
    } else if (isTop) {
      bg = _kGoldChip;
      fg = SC.goldDark;
    } else if (v >= 90) {
      bg = _kOkBg;
      fg = _kOkFg;
    } else {
      bg = SC.surfaceDim;
      fg = SC.ink;
    }

    // Pill status
    final Widget pill;
    switch (akhir) {
      case _Akhir.tuntasLangsung:
        pill = _pill('Tuntas (${_grade(v, _kkm)})', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd);
        break;
      case _Akhir.tuntasRemedial:
        pill = _pill('Tuntas (Remedial)', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd);
        break;
      default:
        pill = _pill('Belum Tuntas', bg: SC.errorBg, fg: SC.errorText, bd: _badBd);
    }

    // Info remedial sebagai pill tambahan
    String? info;
    if (akhir == _Akhir.tuntasRemedial || akhir == _Akhir.belumFinal) {
      final t = _fmtNum(nilaiAkhir);
      info = t.isEmpty ? 'Setelah remedial' : 'Nilai akhir $t (remedial)';
    } else if (akhir == _Akhir.belumMenunggu) {
      info = 'Menunggu remedial';
    }

    return _kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Text(v.toStringAsFixed(0), style: sty(17, FontWeight.w800, fg)),
                  ),
                  if (isTop)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: SC.goldDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: SC.surface, width: 1.5),
                        ),
                        child: Icon(Icons.star_rounded, size: 10, color: SC.gold),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${santri['nama'] ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(14.5, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 5),
                    _meta(Icons.tag_rounded, '${santri['nis'] ?? '-'}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              pill,
              if (info != null)
                _pill(info,
                    bg: ok ? _kOkBg : SC.errorBg,
                    fg: ok ? _kOkFg : SC.errorText,
                    bd: ok ? _kOkBd : _badBd,
                    icon: Icons.replay_rounded),
            ],
          ),
          if (cat.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(cat,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _susulanTile(Map<String, dynamic> n, Map<String, dynamic> santri) {
    final label = switch (_kehadiranOf(n)) {
      'SAKIT' => 'Sakit',
      'IZIN' => 'Izin',
      'ALPA' => 'Alpa',
      _ => 'Belum ada nilai',
    };
    // Ketuk untuk mengisi nilai susulan di halaman Input Nilai (tidak untuk Mudir).
    return _kartu(
      onTap: _readOnly ? null : _openInput,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: _kWarnBg, shape: BoxShape.circle),
                child: const Icon(Icons.event_busy_outlined, size: 21, color: _kWarnFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${santri['nama'] ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(14.5, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 5),
                    _meta(Icons.tag_rounded, '${santri['nis'] ?? '-'}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill('Susulan • $label', bg: _kWarnBg, fg: _kWarnFg, bd: _kWarnBd),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    _readOnly ? 'Menunggu ujian susulan' : 'Ketuk untuk isi nilai susulan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(11, FontWeight.w500, SC.inkSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bar tombol bawah
  // ---------------------------------------------------------------------
  Widget _bottomBar() {
    final remedial = _remedialAktif;

    final labelRemedial = _readOnly
        ? (remedial > 0 ? 'Lihat Remedial ($remedial)' : 'Lihat Remedial')
        : (remedial > 0
            ? 'Remedial ($remedial)'
            : (_remedials.isNotEmpty ? 'Riwayat Remedial' : 'Remedial'));

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: SC.surface,
            border: const Border(top: BorderSide(color: SC.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _readOnly
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: SC.primary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: _openRemedial,
                            icon: const Icon(Icons.visibility_outlined,
                                size: 18, color: Colors.white),
                            label: Text(labelRemedial,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sty(13, FontWeight.w700, Colors.white)),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: SC.border),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: _openRemedial,
                            icon: Icon(Icons.replay_rounded, size: 18, color: SC.primary),
                            label: Text(labelRemedial,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sty(13, FontWeight.w700, SC.primary)),
                          ),
                  ),
                  if (!_readOnly) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: SC.primary,
                          disabledBackgroundColor: SC.primary.withOpacity(0.5),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: (_terkunci && !_adaSusulan) ? null : _openInput,
                        icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
                        label: Text('Input Nilai', style: sty(13, FontWeight.w700, Colors.white)),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Dialog alasan buka kunci
// ---------------------------------------------------------------------------
class _AlasanDialog extends StatefulWidget {
  const _AlasanDialog();

  @override
  State<_AlasanDialog> createState() => _AlasanDialogState();
}

class _AlasanDialogState extends State<_AlasanDialog> {
  final _c = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() {
    final t = _c.text.trim();
    if (t.length < 10) {
      setState(() => _err = 'Alasan minimal 10 karakter.');
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SC.goldSurface,
              shape: BoxShape.circle,
              border: Border.all(color: SC.gold.withOpacity(0.45)),
            ),
            child: Icon(Icons.lock_open_rounded, size: 20, color: SC.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buka kunci nilai', style: sty(16, FontWeight.w800, SC.ink)),
                const SizedBox(height: 1),
                Text('Alasan dicatat di log aktivitas beserta nama Anda',
                    style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _c,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          style: sty(14, FontWeight.w600, SC.ink),
          onChanged: (_) {
            if (_err != null) setState(() => _err = null);
          },
          decoration: InputDecoration(
            hintText: 'Contoh: Salah ketik nilai santri B',
            hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
            errorText: _err,
            errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
            filled: true,
            fillColor: SC.surfaceDim,
            contentPadding: const EdgeInsets.all(14),
            border: b(Colors.transparent),
            enabledBorder: b(Colors.transparent),
            focusedBorder: b(SC.primary, 1.4),
            errorBorder: b(SC.errorText, 1.4),
            focusedErrorBorder: b(SC.errorText, 1.4),
          ),
        ),
      ),
      actions: [
        _btnBatal(() => Navigator.pop(context)),
        _btnUtama('Buka Kunci', _ok),
      ],
    );
  }
}