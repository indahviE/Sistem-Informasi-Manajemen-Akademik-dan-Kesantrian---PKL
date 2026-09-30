import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'ujian_detail_screen.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

// ─────────────────────────────────────────────────────────────
// Palet & helper (mengikuti DESIGN.md SIM Pesantren)
// Ukuran dibuat kompak, mengikuti dashboard_screen.dart
// ─────────────────────────────────────────────────────────────
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

/// Kirim kelasId, tanggal, dan field tambahan lain saat membuat ujian.
/// KKM selalu dikirim (tidak bergantung flag ini).
const bool kKirimFieldTambahan = true;

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

ButtonStyle _primaryBtn({double h = 44}) => FilledButton.styleFrom(
      backgroundColor: _C.emerald,
      foregroundColor: Colors.white,
      minimumSize: Size.fromHeight(h),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );

Future<T?> _showSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 480),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => child,
    );

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// ─────────────────────────────────────────────────────────────
// 1. DAFTAR UJIAN
// ─────────────────────────────────────────────────────────────
String _fmtTanggal(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _fmtJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

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

class UjianScreen extends StatefulWidget {
  const UjianScreen({super.key});

  @override
  State<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends State<UjianScreen> {
  List<dynamic> _ujian = [];
  int? _remedialCount;
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA';
  String _sort = 'TERBARU';
  String _query = '';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ujian);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _ujian = items;
        _loading = false;
      });

      // Kalau backend mengirim remedialAktif untuk semua ujian, jumlahkan langsung.
      // Kalau tidak, pakai cara lama (GET /remedial) sebagai cadangan.
      final maps = _ujian.whereType<Map>().toList();
      if (maps.isNotEmpty && maps.every((u) => u['remedialAktif'] is int)) {
        setState(() => _remedialCount =
            maps.fold<int>(0, (a, u) => a + (u['remedialAktif'] as int)));
      } else {
        _loadRemedial();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  /// Cadangan: hitung remedial yang belum tuntas. Diam-diam diabaikan kalau endpoint GET belum ada.
  Future<void> _loadRemedial() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.remedial);
      final raw =
          res is List ? res : (res is Map<String, dynamic> ? (res['data'] ?? res['items']) : null);
      if (raw is! List || !mounted) return;
      final n = raw.where((r) {
        if (r is! Map) return false;
        final h = '${r['status'] ?? r['hasil'] ?? 'PROSES'}'.toUpperCase();
        return h != 'TUNTAS';
      }).length;
      setState(() => _remedialCount = n);
    } catch (_) {}
  }

  Future<void> _addUjian() async {
    final result = await _showSheet<Map<String, dynamic>>(context, const _FormUjianSheet());
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.ujian, result);
      if (!mounted) return;
      _snack(context, 'Ujian berhasil dibuat');
      _load();
    } on ApiException catch (e) {
      if (mounted) _snack(context, e.message);
    }
  }

  List<Map<String, dynamic>> get _all => _ujian.whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> get _shown {
    final q = _query.trim().toLowerCase();
    final list = _all.where((u) {
      if (_filter != 'SEMUA' && _jenisOf(u) != _filter) return false;
      if (q.isEmpty) return true;
      final s =
          '${u['nama']} ${u['mapel']?['namaMapel'] ?? ''} ${u['kelas']?['namaKelas'] ?? ''}'
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

  /// Total santri di kelas (opsional — hanya jika backend mengirimnya).
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.ivory,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(
                child: _loading
                    ? loadingView()
                    : _error != null
                        ? errorView(_error!, _load)
                        : _ujian.isEmpty
                            ? emptyView('Belum ada ujian. Buat ujian untuk mulai menilai.')
                            : RefreshIndicator(onRefresh: _load, child: _buildList()),
              ),
              Positioned(
                right: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
                child: FloatingActionButton.extended(
                  onPressed: _addUjian,
                  backgroundColor: _C.emerald,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: const StadiumBorder(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Buat Ujian',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final all = _all;
    final list = _shown;
    final totalNilai = all.fold<int>(0, (a, u) => a + _countNilai(u));

    int? kapasitas;
    if (all.isNotEmpty && all.every((u) => _totalSantri(u) != null)) {
      kapasitas = all.fold<int>(0, (a, u) => a + _totalSantri(u)!);
    }
    final pct = kapasitas == null ? null : ((totalNilai / kapasitas) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        _hero(),
        const SizedBox(height: 12),

        // Filter jenis
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _filters)
                _listChip(f[1], _filter == f[0], () => setState(() => _filter = f[0]),
                    count: f[0] == 'SEMUA' ? all.length : null),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ringkasan
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statCard(
                label: 'Total',
                value: '${all.length}',
                sub: 'Ujian Aktif',
                icon: Icons.event_note_outlined,
              ),
              const SizedBox(width: 8),
              _statCard(
                label: 'Progres',
                value: pct == null ? '$totalNilai' : '$pct%',
                sub: kapasitas == null ? 'Nilai masuk' : '$totalNilai/$kapasitas Nilai',
                icon: Icons.done_all_rounded,
                iconBg: const Color(0xFFFCEBC4),
                iconFg: _C.goldText,
              ),
              const SizedBox(width: 8),
              _statCard(
                label: 'Remedial',
                value: _remedialCount == null ? '–' : '$_remedialCount',
                sub: 'Perlu Bimbingan',
                icon: Icons.priority_high_rounded,
                iconBg: _C.badBg,
                iconFg: _C.badFg,
                valueColor: _C.badFg,
                subColor: _C.badFg,
                subBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Judul daftar + urutkan
        Row(
          children: [
            const Text('Daftar Agenda Ujian',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
            const SizedBox(width: 8),
            _pill(_filters.firstWhere((f) => f[0] == _filter)[1], const Color(0xFFFCEBC4),
                _C.goldText),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => [
                for (final e in _sorts.entries)
                  PopupMenuItem(value: e.key, child: Text(e.value)),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Urutkan: ${_sorts[_sort]}',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.emerald)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: _C.emerald),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Tidak ada ujian yang cocok.',
                  style: TextStyle(fontSize: 12.5, color: _C.ink2.withOpacity(0.8))),
            ),
          )
        else
          for (final u in list) _ujianCard(u),
      ],
    );
  }

  Widget _hero() {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
            right: -50,
            top: -36,
            child: CustomPaint(
              size: const Size(170, 170),
              painter: _StarPainter(Colors.white.withOpacity(0.07)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KHADIMUL ILMI',
                            style: TextStyle(
                                color: Color(0xFFA4D0BF),
                                fontSize: 10.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('Ujian & Remedial',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: _C.ink),
                decoration: InputDecoration(
                  hintText: 'Cari ujian, mata pelajaran, kelas...',
                  hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
                  prefixIcon: const Icon(Icons.search, size: 20, color: _C.ink),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listChip(String label, bool selected, VoidCallback onTap, {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _C.emerald : _C.chipGray,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : _C.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5)),
              if (selected && count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    Color iconBg = _C.chipGray,
    Color iconFg = _C.ink2,
    Color valueColor = _C.ink,
    Color subColor = _C.ink2,
    bool subBold = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration:
                      BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 14, color: iconFg),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
            const SizedBox(height: 2),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: subBold ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _ujianCard(Map<String, dynamic> u) {
    final st = _jenisStyle(_jenisOf(u));
    final count = _countNilai(u);
    final total = _totalSantri(u);
    final complete = total != null && count >= total;
    final double? progress =
        total == null ? null : (count / total).clamp(0.0, 1.0).toDouble();
    final remed =
        (u['remedialAktif'] as int?) ?? (u['_count']?['remedials'] as int?) ?? 0;
    final mapel = u['mapel']?['namaMapel'] ?? 'Umum';
    final kelas = u['kelas']?['namaKelas'] ?? 'Semua kelas';

    final String panelText;
    if (total == null) {
      panelText = '$count santri telah dinilai';
    } else if (complete) {
      panelText = 'Nilai Tuntas: $count / $total Santri';
    } else {
      panelText = '$count / $total Santri telah dinilai';
    }

    final Widget footLeft;
    if (remed > 0) {
      footLeft = _footPill(
          Icons.warning_amber_rounded, '$remed Santri Perlu Remedial', _C.badBg, _C.badFg);
    } else if (count == 0) {
      footLeft = _footPill(Icons.hourglass_empty_rounded, 'Belum ada nilai', _C.warnBg, _C.warnFg);
    } else if (complete) {
      footLeft = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: _C.gold),
          SizedBox(width: 5),
          Text('Nilai lengkap', style: TextStyle(fontSize: 11.5, color: _C.ink2)),
        ],
      );
    } else {
      footLeft = Text(
        _tenggat(u) ??
            (total != null ? '${total - count} santri belum dinilai' : 'Nilai sedang diinput'),
        style: const TextStyle(fontSize: 11.5, color: _C.ink2),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => UjianDetailScreen(ujian: u)))
              .then((_) => _load()),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
              boxShadow: [
                BoxShadow(
                    color: _C.emerald.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: st.iconBg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(st.icon, color: st.iconFg, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['nama'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15, color: _C.ink)),
                          const SizedBox(height: 2),
                          Text('$mapel • $kelas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: _C.ink2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration:
                          BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(8)),
                      child: Text(st.label,
                          style: TextStyle(
                              color: st.fg,
                              fontSize: 10.5,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(color: _C.ivory, borderRadius: BorderRadius.circular(12)),
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
                              color: _C.ink),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(panelText,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500, color: _C.ink2)),
                          ),
                          if (progress != null)
                            Text('${(progress * 100).round()}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16, color: _C.ink)),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: _C.trackGray,
                            valueColor: AlwaysStoppedAnimation(
                                complete ? _C.emerald : const Color(0xFF3E6658)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: footLeft),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            count == 0
                                ? 'Input Nilai'
                                : (complete ? 'Detail Nilai' : 'Lanjutkan Nilai'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12, color: _C.ink)),
                        const Icon(Icons.chevron_right, size: 16, color: _C.ink),
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

  Widget _footPill(IconData icon, String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 2. BUAT UJIAN BARU (bottom sheet)
// ─────────────────────────────────────────────────────────────
class _FormUjianSheet extends StatefulWidget {
  const _FormUjianSheet();

  @override
  State<_FormUjianSheet> createState() => _FormUjianSheetState();
}

class _FormUjianSheetState extends State<_FormUjianSheet> {
  final _nama = TextEditingController();
  final _kkm = TextEditingController(text: '75');
  String _jenis = 'UAS';
  final _mapelText = TextEditingController();
  final _lainnyaNama = TextEditingController();
  final _lainnyaKet = TextEditingController();
  List<dynamic> _mapel = []; // hanya untuk mencocokkan teks mapel dengan mapel terdaftar
  List<Map<String, dynamic>> _kelasList = [];
  Map<String, dynamic>? _kelas;
  DateTime _jadwal = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 0);
  bool _namaError = false;
  bool _kkmError = false;

  static const jenisOptions = ['ULANGAN', 'UTS', 'UAS', 'TES_TAHFIDZ', 'LAINNYA'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMapel();
      _loadKelas();
    });
  }

  Future<void> _loadMapel() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.mapel);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (mounted) setState(() => _mapel = items);
    } catch (_) {}
  }

  /// Mapel terdaftar yang namanya sama persis dengan teks yang diketik (tanpa peduli huruf besar/kecil).
  Map<String, dynamic>? get _mapelCocok {
    final t = _mapelText.text.trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final m in _mapel) {
      if (m is Map && '${m['namaMapel']}'.trim().toLowerCase() == t) {
        return Map<String, dynamic>.from(m);
      }
    }
    return null;
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
    _mapelText.dispose();
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
        context, _KelasChooser(list: _kelasList, selected: _kelas));
    if (res == null || !mounted) return;
    setState(() => _kelas = res['nama'] == '__ALL__' ? null : res);
  }

  void _submit() {
    final nama = _nama.text.trim();
    final kkm = double.tryParse(_kkm.text.replaceAll(',', '.'));
    final namaBad = nama.isEmpty;
    final kkmBad = kkm == null || kkm < 0 || kkm > 100;
    if (namaBad || kkmBad) {
      setState(() {
        _namaError = namaBad;
        _kkmError = kkmBad;
      });
      return;
    }
    final cocok = _mapelCocok;
    final payload = <String, dynamic>{
      'nama': nama,
      'jenis': _jenis,
      'mapelId': cocok?['id'],
      'kkm': kkm,
    };
    if (kKirimFieldTambahan) {
      if (_kelas?['id'] != null) payload['kelasId'] = _kelas!['id'];
      payload['tanggal'] = _jadwal.toIso8601String();
    }
    Navigator.of(context).pop(payload);
  }

  Widget _label(String text, {bool req = false, Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(text,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.ink)),
            if (req)
              const Text(' *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.badFg)),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      );

  InputDecoration _fieldDec({String? hint, Widget? suffix, String? error}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
        suffixIcon: suffix,
        errorText: error,
        filled: true,
        fillColor: _C.fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.emerald, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.badFg, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.badFg, width: 1.5)),
      );

  Widget _goldChip({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _C.goldBorder),
        ),
        child: child,
      );

  Widget _grayChip({required Widget child, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _C.chipGray,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _C.border),
          ),
          child: child,
        ),
      );

  String _kelasText(Map<String, dynamic> k) {
    final n = '${k['nama']}';
    final base = n.toLowerCase().startsWith('kelas') ? n : 'Kelas $n';
    return '$base (${k['count']} Santri)';
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
                decoration:
                    BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration:
                                  const BoxDecoration(color: _C.gold, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            const Text('Buat Ujian Baru',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700, color: _C.ink)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text('Atur identitas ujian dan parameter penilaian santri',
                            style: TextStyle(fontSize: 12, color: _C.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: _C.chipGray, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close, size: 18, color: _C.ink),
                    ),
                  ),
                ],
              ),
            ),
            // Isi form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nama Ujian', req: true),
                    TextField(
                      controller: _nama,
                      onChanged: (_) {
                        if (_namaError) setState(() => _namaError = false);
                      },
                      style: const TextStyle(fontSize: 13, color: _C.ink),
                      decoration: _fieldDec(
                        hint: 'Contoh: UAS Bahasa Arab Semester Ganjil',
                        suffix: const Icon(Icons.menu_book_outlined, size: 20, color: _C.emerald),
                        error: _namaError ? 'Nama ujian wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _label('Jenis Evaluasi',
                        req: true,
                        trailing: const Text('Akademik & Diniyah',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: _C.goldText))),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final j in jenisOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _jenis = j),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _jenis == j ? _C.emerald : _C.chipGray,
                                    borderRadius: BorderRadius.circular(99),
                                    border: _jenis == j ? null : Border.all(color: _C.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_jenis == j) ...[
                                        const Icon(Icons.check, size: 14, color: Colors.white),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(_jenisTitle(j),
                                          style: TextStyle(
                                              color: _jenis == j ? Colors.white : _C.ink,
                                              fontWeight:
                                                  _jenis == j ? FontWeight.w700 : FontWeight.w500,
                                              fontSize: 12.5)),
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

                    _label('Mata Pelajaran (Opsional)'),
                    TextField(
                      controller: _mapelText,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 13, color: _C.ink),
                      decoration: _fieldDec(hint: 'Contoh: Bahasa Arab (Nahwu & Sharaf)').copyWith(
                        prefixIcon: const Icon(Icons.translate, size: 20, color: _C.emerald),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _mapelHelper(),
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
                              const Icon(Icons.verified_outlined, size: 16, color: _C.goldText),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                    _kelas == null ? 'Semua kelas' : _kelasText(_kelas!),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _C.goldText)),
                              ),
                              if (_kelas != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _kelas = null),
                                  child: const Icon(Icons.close, size: 14, color: _C.goldText),
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
                                  const Icon(Icons.add, size: 14, color: _C.ink),
                                  const SizedBox(width: 5),
                                  Text('${k['nama']}',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: _C.ink)),
                                ],
                              ),
                            ),
                          _grayChip(
                            onTap: _pilihKelasLain,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apartment_outlined, size: 14, color: _C.ink),
                                SizedBox(width: 5),
                                Text('Pilih Kelas Lain',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: _C.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) {
                                  if (_kkmError) setState(() => _kkmError = false);
                                },
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: _C.ink),
                                decoration: _fieldDec(
                                  error: _kkmError ? '0–100' : null,
                                  suffix: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: _C.chipGray,
                                          borderRadius: BorderRadius.circular(8)),
                                      child: const Text('Poin',
                                          style: TextStyle(fontSize: 11, color: _C.ink2)),
                                    ),
                                  ),
                                ),
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
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: _C.fieldFill,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_available_outlined,
                                          size: 18, color: _C.goldText),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_fmtTanggal(_jadwal),
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _C.ink)),
                                            Text(_fmtJam(_jadwal),
                                                style: const TextStyle(
                                                    fontSize: 10.5, color: _C.ink2)),
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
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F1EC),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                                color: _C.emerald, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.verified_user_outlined,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Integritas & Khidmah',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.ink)),
                                SizedBox(height: 2),
                                Text(
                                    'Hasil evaluasi akan otomatis terhubung ke Buku Raport Santri & Rekap Wali Asrama.',
                                    style: TextStyle(fontSize: 11.5, height: 1.4, color: _C.ink2)),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _C.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: _C.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: _primaryBtn(h: 46),
                          onPressed: _submit,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Simpan & Terbitkan',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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

  Widget _mapelHelper() {
    final t = _mapelText.text.trim();
    final IconData icon;
    final String text;
    if (t.isEmpty) {
      icon = Icons.check_circle_outline;
      text = 'Kosongkan jika ujian bersifat umum (tanpa mapel khusus)';
    } else if (_mapelCocok != null) {
      icon = Icons.check_circle;
      text = 'Terhubung ke mapel terdaftar';
    } else {
      icon = Icons.info_outline;
      text = 'Belum cocok dengan mapel terdaftar. Ketik nama yang sama persis agar tertaut';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: _C.goldText),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, color: _C.goldText))),
      ],
    );
  }

  /// Form tambahan (opsional) yang muncul saat Jenis Evaluasi = Lainnya.
  Widget _lainnyaForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: _C.goldText),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Detail Penilaian Lainnya',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink)),
              ),
              _pill('Opsional', const Color(0xFFFCEBC4), _C.goldText),
            ],
          ),
          const SizedBox(height: 12),
          _label('Nama Jenis Penilaian'),
          TextField(
            controller: _lainnyaNama,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 13, color: _C.ink),
            decoration: _fieldDec(hint: 'Contoh: Praktik Khithabah, Muhadharah')
                .copyWith(fillColor: Colors.white),
          ),
          const SizedBox(height: 12),
          _label('Keterangan'),
          TextField(
            controller: _lainnyaKet,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 13, color: _C.ink),
            decoration: _fieldDec(hint: 'Deskripsi singkat atau ketentuan penilaian')
                .copyWith(fillColor: Colors.white),
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
  const _KelasChooser({required this.list, required this.selected});

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
                decoration:
                    BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('Pilih Kelas / Rombel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.groups_2_outlined, size: 20, color: _C.emerald),
                    title: const Text('Semua kelas',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    trailing: selected == null
                        ? const Icon(Icons.check_circle, size: 18, color: _C.emerald)
                        : null,
                    onTap: () => Navigator.of(context).pop(<String, dynamic>{'nama': '__ALL__'}),
                  ),
                  for (final k in list)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.apartment_outlined, size: 20, color: _C.emerald),
                      title: Text('${k['nama']}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('${k['count']} Santri',
                          style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                      trailing: selected?['nama'] == k['nama']
                          ? const Icon(Icons.check_circle, size: 18, color: _C.emerald)
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