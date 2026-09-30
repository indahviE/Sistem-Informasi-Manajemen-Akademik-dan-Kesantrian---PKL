import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'ujian_input_screen.dart';
import 'ujian_remedial_screen.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

// Halaman Detail Ujian (mandiri: tidak bergantung pada file ujian lain).

class _C {
  static const emerald = Color(0xFF0F3A2E);
  static const emeraldMid = Color(0xFF164E3D);
  static const gold = Color(0xFFC5A059);
  static const goldSoft = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const sage = Color(0xFFE2ECE9);
  static const ivory = Color(0xFFFAF9F5);
  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF475569);
  static const goldText = Color(0xFF775A19);
  static const chipGray = Color(0xFFEFEEEA);
  static const trackGray = Color(0xFFE3E2DF);
  static const fieldFill = Color(0xFFF5F4EE);

  static const okBg = Color(0xFFE8F5E9);
  static const okFg = Color(0xFF1B5E20);
  static const okBd = Color(0xFFC8E6C9);
  static const warnBg = Color(0xFFFFF8E1);
  static const warnFg = Color(0xFFB78103);
  static const warnBd = Color(0xFFFFE082);
  static const badBg = Color(0xFFFEE2E2);
  static const badFg = Color(0xFF991B1B);
  static const badBd = Color(0xFFFECACA);
}

/// Lebar maksimum kolom konten (dipakai konten, bar atas, dan bar bawah).
const double kMaxWidth = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double kKkmDefault = 75;

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    );

Widget _pill(String text, Color bg, Color fg, {Color? bd, double fs = 10.5}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: bd == null ? null : Border.all(color: bd),
      ),
      child: Text(text,
          style: TextStyle(color: fg, fontSize: fs, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );

class _JenisStyle {
  final Color bg;
  final Color fg;
  final String label;
  final String judul;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  const _JenisStyle(this.bg, this.fg, this.label, this.judul, this.icon, this.iconBg, this.iconFg);
}

_JenisStyle _jenisStyle(String j) {
  const goldIconBg = Color(0xFFFDEFD3);
  switch (j) {
    case 'UAS':
      return const _JenisStyle(_C.emerald, Colors.white, 'UAS', 'UJIAN AKHIR SEMESTER',
          Icons.menu_book_outlined, _C.chipGray, _C.ink);
    case 'UTS':
      return const _JenisStyle(Color(0xFFFED488), _C.goldText, 'UTS', 'UJIAN TENGAH SEMESTER',
          Icons.auto_stories_outlined, goldIconBg, _C.goldText);
    case 'TES_TAHFIDZ':
      return const _JenisStyle(Color(0xFFFFE6B0), _C.goldText, 'TES TAHFIDZ', 'TES TAHFIDZ',
          Icons.menu_book, goldIconBg, _C.goldText);
    case 'LAINNYA':
      return const _JenisStyle(_C.trackGray, Color(0xFF414845), 'LAINNYA', 'PENILAIAN LAINNYA',
          Icons.record_voice_over_outlined, _C.chipGray, _C.ink);
    default:
      return const _JenisStyle(_C.trackGray, Color(0xFF414845), 'ULANGAN', 'ULANGAN HARIAN',
          Icons.assignment_outlined, _C.chipGray, _C.ink);
  }
}

String _jenisOf(Map<String, dynamic> u) => (u['jenis'] ?? 'ULANGAN') as String;

String _grade(double n, double kkm) {
  if (n >= 90) return 'A';
  if (n >= 80) return 'B+';
  if (n >= kkm) return 'B';
  return '';
}

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Pola bintang 8 titik (Rub el Hizb) untuk watermark header.
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (final scale in [1.0, 0.72, 0.44]) {
      for (final rot in [0.0, math.pi / 4]) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = rot + i * math.pi / 2 + math.pi / 4;
          final pt = Offset(c.dx + r * scale * math.cos(a), c.dy + r * scale * math.sin(a));
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Warna tambahan khusus hero halaman detail.
const _heroGold = Color(0xFFE9C176);
const _heroGoldLight = Color(0xFFFED488);
const _heroMint = Color(0xFFA4D0BF);

String _fmtTgl(dynamic raw) {
  final d = DateTime.tryParse('$raw');
  if (d == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

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
  String? _error;
  String _tab = 'ALL'; // ALL | OK | BAD
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.ujian}/${widget.ujian['id']}');

      // Data remedial (opsional): dipakai supaya angka Remedial sama dengan halaman Remedial.
      var rem = <Map<String, dynamic>>[];
      try {
        final rr = await api.get('${ApiUrl.ujian}/${widget.ujian['id']}/remedial');
        final raw = rr is Map ? (rr['data'] ?? rr['remedials'] ?? rr['items']) : rr;
        rem = ((raw as List?) ?? []).whereType<Map<String, dynamic>>().toList();
      } on ApiException {
        // Endpoint belum ada / gagal: anggap kosong.
      }

      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _remedials = rem;
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

  /// Data ujian dari daftar digabung dengan data dari endpoint detail,
  /// supaya field yang tidak dikirim endpoint detail tetap terisi.
  Map<String, dynamic> get _ujian => {...widget.ujian, ...?_data};

  /// KKM milik ujian ini (jatuh ke bawaan bila belum ada).
  double get _kkm =>
      (_ujian['kkm'] is num) ? (_ujian['kkm'] as num).toDouble() : kKkmDefault;

  String get _kkmText =>
      _kkm == _kkm.roundToDouble() ? _kkm.toStringAsFixed(0) : _kkm.toStringAsFixed(1);

  // Buka halaman Input Nilai, lalu muat ulang data setelah kembali.
  Future<void> _openInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UjianInputScreen(ujian: _ujian)),
    );
    if (mounted) _load();
  }

  // Buka halaman Remedial, lalu muat ulang data setelah kembali.
  Future<void> _openRemedial() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UjianRemedialScreen(ujian: _ujian)),
    );
    if (mounted) _load();
  }

  List<Map<String, dynamic>> get _nilais =>
      ((_data?['nilais'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();

  /// Santri di bawah KKM yang remedialnya belum tuntas (sama dengan hitungan halaman Remedial).
  int get _remedialAktif {
    final tuntas = _remedials
        .where((r) => '${r['status']}'.toUpperCase() == 'TUNTAS')
        .map((r) => r['santriId'] ?? (r['santri'] as Map?)?['id'])
        .toSet();
    return _nilais
        .where((n) =>
            (n['nilai'] as num) < _kkm &&
            !tuntas.contains(n['santriId'] ?? (n['santri'] as Map?)?['id']))
        .length;
  }

  // ───────────────────────────── BUILD ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.ivory,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxWidth),
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : RefreshIndicator(onRefresh: _load, child: _buildContent()),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ── Baris atas: kembali + bagikan + menu ──
  Widget _topBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: _C.border),
          right: BorderSide(color: _C.border),
          bottom: BorderSide(color: _C.border),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
              color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: _C.ink),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('Kembali ke Daftar Ujian',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.ink)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _snack(context, 'Bagikan hasil segera hadir.'),
              child: _iconBox(Icons.ios_share),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'muat') _load();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'muat', child: Text('Muat ulang')),
              ],
              child: _iconBox(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _C.chipGray, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: _C.ink),
      );

  // ── Isi halaman ──
  Widget _buildContent() {
    final u = _ujian;
    final all = _nilais;
    final tuntas = all.where((n) => (n['nilai'] as num) >= _kkm).length;
    final belum = all.length - tuntas;
    final remedial = _remedialAktif;

    Map<String, dynamic>? top;
    if (all.isNotEmpty) {
      top = all.reduce((a, b) => (a['nilai'] as num) >= (b['nilai'] as num) ? a : b);
    }

    final q = _query.trim().toLowerCase();
    final list = all.where((n) {
      final v = (n['nilai'] as num).toDouble();
      if (_tab == 'OK' && v < _kkm) return false;
      if (_tab == 'BAD' && v >= _kkm) return false;
      if (q.isEmpty) return true;
      final s = n['santri'] as Map<String, dynamic>;
      return '${s['nama']} ${s['nis']}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => (b['nilai'] as num).compareTo(a['nilai'] as num));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        _hero(u, all),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Daftar Nilai',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
            const SizedBox(width: 8),
            _pill('${all.length} nilai', _C.chipGray, _C.ink2, fs: 10.5),
            const Spacer(),
            if (remedial > 0)
              _pill('● $remedial Remedial', _C.badBg, _C.badFg, bd: _C.badBd, fs: 10.5),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 13, color: _C.ink),
          decoration: InputDecoration(
            hintText: 'Cari santri atau NIS…',
            hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
            prefixIcon: const Icon(Icons.search, size: 20, color: _C.ink2),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.emerald, width: 2)),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tabChip('Semua', all.length, 'ALL'),
              _tabChip('Tuntas', tuntas, 'OK'),
              _tabChip('Belum Tuntas', belum, 'BAD', countColor: _C.badFg),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('Belum ada nilai diinput.',
                    style: TextStyle(fontSize: 12.5, color: _C.ink2))),
          )
        else if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('Santri tidak ditemukan.',
                    style: TextStyle(fontSize: 12.5, color: _C.ink2))),
          )
        else
          for (final n in list) _nilaiTile(n, isTop: identical(n, top)),
      ],
    );
  }

  Widget _tabChip(String label, int count, String value, {Color? countColor}) {
    final sel = _tab == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? _C.emerald : _C.chipGray,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : _C.ink2)),
              const SizedBox(width: 4),
              Text('($count)',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: countColor != null && !sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white70 : (countColor ?? _C.ink2.withOpacity(0.7)))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero ──
  Widget _hero(Map<String, dynamic> u, List<Map<String, dynamic>> all) {
    final st = _jenisStyle(_jenisOf(u));

    double? avg;
    Map<String, dynamic>? top, low;
    if (all.isNotEmpty) {
      avg = all.fold<double>(0, (a, n) => a + (n['nilai'] as num).toDouble()) / all.length;
      top = all.reduce((a, b) => (a['nilai'] as num) >= (b['nilai'] as num) ? a : b);
      low = all.reduce((a, b) => (a['nilai'] as num) <= (b['nilai'] as num) ? a : b);
    }
    String nm(Map<String, dynamic>? n) =>
        n == null ? '-' : ((n['santri'] as Map<String, dynamic>)['nama'] as String);

    final kelasNama = u['kelas']?['namaKelas'];
    final totalSantri =
        u['totalSantri'] ?? u['kelas']?['jumlahSantri'] ?? u['kelas']?['_count']?['santris'];
    final kelasLabel = kelasNama == null
        ? 'Semua kelas'
        : (totalSantri is int && totalSantri > 0 ? '$kelasNama ($totalSantri)' : '$kelasNama');
    final tgl = _fmtTgl(u['tanggal']);

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_C.emerald, _C.emeraldMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -34,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: _StarPainter(Colors.white.withOpacity(0.07)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(st.judul,
                          style: const TextStyle(
                              color: _heroGold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _C.gold.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                    child: Text(st.label,
                        style: const TextStyle(
                            color: _heroGold,
                            fontSize: 11,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(u['nama'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _heroInfo(Icons.menu_book_outlined, 'Mapel: ${u['mapel']?['namaMapel'] ?? 'Umum'}'),
                  _heroInfo(Icons.groups_2_outlined, kelasLabel),
                  if (tgl.isNotEmpty) _heroInfo(Icons.event_outlined, tgl),
                  if (u['durasiMenit'] != null)
                    _heroInfo(Icons.schedule, '${u['durasiMenit']} Menit'),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),
              Row(
                children: [
                  _heroStat('Rata-rata', avg == null ? '-' : avg.toStringAsFixed(1),
                      'KKM $_kkmText',
                      subColor: _heroMint),
                  const SizedBox(width: 8),
                  _heroStat('Tertinggi',
                      top == null ? '-' : (top['nilai'] as num).toStringAsFixed(0), nm(top),
                      gold: true),
                  const SizedBox(width: 8),
                  _heroStat('Terendah',
                      low == null ? '-' : (low['nilai'] as num).toStringAsFixed(0), nm(low)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );

  Widget _heroStat(String label, String value, String sub,
      {bool gold = false, Color subColor = Colors.white70}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: gold ? _C.gold.withOpacity(0.28) : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: gold ? _heroGold : Colors.white70, fontSize: 10.5)),
                ),
                if (gold) const Icon(Icons.star_border, size: 13, color: _heroGold),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: gold ? _heroGoldLight : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: gold ? Colors.white : subColor, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  // ── Kartu nilai santri ──
  Widget _nilaiTile(Map<String, dynamic> n, {required bool isTop}) {
    final santri = n['santri'] as Map<String, dynamic>;
    final v = (n['nilai'] as num).toDouble();
    final ok = v >= _kkm;
    final cat = '${n['catatan'] ?? ''}'.trim();

    // Warna kotak nilai: emas (tertinggi), hijau (>=90), abu (tuntas), merah (belum tuntas)
    final Color bg;
    final Color fg;
    if (!ok) {
      bg = _C.badBg;
      fg = _C.badFg;
    } else if (isTop) {
      bg = const Color(0xFFFDEFD3);
      fg = _C.goldText;
    } else if (v >= 90) {
      bg = _C.okBg;
      fg = _C.okFg;
    } else {
      bg = _C.chipGray;
      fg = _C.ink;
    }

    final subColor = ok ? _C.ink2 : _C.badFg;
    final spans = <InlineSpan>[TextSpan(text: 'NIS: ${santri['nis']}')];
    if (cat.isNotEmpty) {
      spans.add(const TextSpan(text: ' • '));
      if (isTop) {
        final first = RegExp(r'^[^\s,]+').firstMatch(cat)?.group(0) ?? '';
        spans.add(TextSpan(
            text: first,
            style: const TextStyle(color: _C.goldText, fontWeight: FontWeight.w700)));
        spans.add(TextSpan(text: cat.substring(first.length)));
      } else {
        spans.add(TextSpan(text: cat));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: _cardDeco(),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Text(v.toStringAsFixed(0),
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              if (isTop)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _C.goldText,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.star_rounded, size: 9, color: _heroGoldLight),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(santri['nama'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5, color: _C.ink)),
                    ),
                    const SizedBox(width: 6),
                    ok
                        ? _pill('Tuntas (${_grade(v, _kkm)})', _C.okBg, _C.okFg,
                            bd: _C.okBd, fs: 10)
                        : _pill('Belum Tuntas', _C.badBg, _C.badFg, bd: _C.badBd, fs: 10),
                  ],
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(style: TextStyle(fontSize: 11.5, color: subColor), children: spans),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar tombol bawah ──
  Widget _bottomBar() {
    final remedial = _remedialAktif;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: _C.border),
              left: BorderSide(color: _C.border),
              right: BorderSide(color: _C.border),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                  color: _C.emerald.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.chipGray,
                        foregroundColor: _C.ink,
                        minimumSize: const Size.fromHeight(44),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: _openRemedial,
                      icon: const Icon(Icons.replay, size: 18),
                      label: Text(remedial > 0 ? 'Remedial ($remedial)' : 'Remedial'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.emerald,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: _openInput,
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Input Nilai'),
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