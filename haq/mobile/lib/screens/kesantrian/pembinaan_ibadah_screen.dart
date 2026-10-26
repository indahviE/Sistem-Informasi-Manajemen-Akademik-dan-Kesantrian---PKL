import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../p_theme.dart';
import '../signup_screen.dart' show PColors, PText;

// ============================================================================
// Pembinaan Ibadah — Rekap kehadiran ibadah santri (PRD Modul Kesantrian).
//
// Field yang dipakai (sama dengan endpoint yang sudah ada):
//   id, santriId, jenisIbadah, tanggal, status (HADIR | IZIN | ALPA), catatan
//   santri (nested, opsional): { nama, nis, kelas: { namaKelas } }
//
// Wali Santri: read-only (tanpa tombol catat), melihat rekap anaknya.
// Pimpinan/Mudir: read-only, memantau rekap semua santri.
// Musyrif/Admin: melihat semua + bisa mencatat.
// ============================================================================

const List<String> _jenisIbadahPreset = [
  'Sholat Subuh Berjamaah',
  'Sholat Dzuhur Berjamaah',
  'Sholat Ashar Berjamaah',
  'Sholat Maghrib Berjamaah',
  'Sholat Isya Berjamaah',
  'Sholat Tahajud',
  'Sholat Dhuha',
  "Tilawah Al-Qur'an",
  'Dzikir Pagi/Petang',
  'Puasa Sunnah',
];

const _hariNama = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'];
const _bulanNama = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

String _initialsOf(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

DateTime? _tgl(Map<String, dynamic> p) {
  final s = p['tanggal']?.toString() ?? '';
  if (s.length < 10) return null;
  return DateTime.tryParse(s.substring(0, 10));
}

String _fmtTgl(DateTime t) => '${_hariNama[t.weekday - 1]}, ${t.day} ${_bulanNama[t.month - 1]} ${t.year}';

IconData _iconJenis(String jenis) {
  final j = jenis.toLowerCase();
  if (j.contains('tilawah') || j.contains('qur')) return Icons.menu_book_rounded;
  if (j.contains('tahajud')) return Icons.bedtime_rounded;
  if (j.contains('dhuha')) return Icons.wb_sunny_rounded;
  if (j.contains('puasa')) return Icons.nightlight_round;
  if (j.contains('dzikir')) return Icons.auto_awesome_rounded;
  return Icons.mosque_rounded;
}

class _StatusMeta {
  const _StatusMeta(this.label, this.bg, this.fg, this.border, this.icon);
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;
}

_StatusMeta _meta(String s) {
  switch (s) {
    case 'HADIR':
      return const _StatusMeta(
          'Hadir', PColors.successBg, PColors.successText, PColors.successBorder, Icons.check_circle_rounded);
    case 'IZIN':
      return const _StatusMeta(
          'Izin', PColors.pendingBg, PColors.pendingText, PColors.pendingBorder, Icons.schedule_rounded);
    default:
      return const _StatusMeta('Alpa', PColors.errorBg, PColors.errorText, PColors.errorBorder, Icons.cancel_rounded);
  }
}

/// Warna & predikat berdasarkan persentase kehadiran.
Color _warnaPersen(double p) {
  if (p >= 85) return PColors.successText;
  if (p >= 70) return PColors.pendingText;
  return PColors.errorText;
}

String _predikat(double p) {
  if (p >= 90) return 'Sangat Baik';
  if (p >= 75) return 'Baik';
  if (p >= 60) return 'Cukup';
  return 'Perlu Pembinaan';
}

// ---------------------------------------------------------------------------
// Painter cincin progres
// ---------------------------------------------------------------------------
class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color, this.stroke = 9});
  final double value; // 0..1
  final Color track;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, base);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}

class PembinaanIbadahScreen extends StatefulWidget {
  const PembinaanIbadahScreen({super.key});

  @override
  State<PembinaanIbadahScreen> createState() => _PembinaanIbadahScreenState();
}

class _PembinaanIbadahScreenState extends State<PembinaanIbadahScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _santris = [];
  bool _loading = true;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _timeFilter = 'Bulan Ini'; // Hari Ini | Minggu Ini | Bulan Ini | Semua
  String _statusFilter = 'SEMUA'; // SEMUA | HADIR | IZIN | ALPA
  String? _selectedSantriId; // khusus wali dengan lebih dari satu anak
  bool _showAllJenis = false;

  bool get _isWali => AppScope.of(context).user?.isWali == true;

  /// Wali dan Pimpinan/Mudir hanya memantau: tidak bisa mencatat rekap ibadah.
  bool get _readOnly => _isWali || AppScope.of(context).user?.isPimpinan == true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.pembinaanIbadah);
      final raw = res is List ? res : (res is Map ? (res['items'] as List? ?? []) : []);
      final list = raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      list.sort((a, b) => (_tgl(b) ?? DateTime(2000)).compareTo(_tgl(a) ?? DateTime(2000)));
      if (!mounted) return;
      setState(() {
        _items = list;
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
          _error = 'Gagal memuat rekap ibadah: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSantris() async {
    try {
      final api = AppScope.of(context).api;
      final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      final raw = s is List ? s : (s is Map ? (s['items'] as List? ?? []) : []);
      if (mounted) {
        setState(() => _santris = raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList());
      }
    } catch (_) {}
  }

  void _toast(String msg, {bool error = false}) {
    // Lebar toast dibatasi ±400px supaya tidak melebar di layar web,
    // dan diangkat di atas bar "Catat Ibadah".
    final lebar = MediaQuery.of(context).size.width;
    final sisi = math.max(16.0, (lebar - 400) / 2);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: error ? PColors.errorText : PTheme.primary,
          margin: EdgeInsets.fromLTRB(sisi, 0, sisi, _readOnly ? 12 : 84),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _add() async {
    if (_readOnly) return;
    if (_santris.isEmpty) await _loadSantris();
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatatIbadahSheet(santris: _santris, existing: _items),
    );
    if (result == null || !mounted) return;
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.pembinaanIbadah, result);
      _load(showSpinner: false);
      _toast('Rekap ibadah tersimpan.');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  Map<String, dynamic> _santriOf(Map<String, dynamic> p) {
    final s = p['santri'];
    return s is Map ? s.cast<String, dynamic>() : <String, dynamic>{};
  }

  /// Daftar anak (id -> nama) yang muncul di data. Dipakai wali multi-anak.
  Map<String, String> get _anak {
    final m = <String, String>{};
    for (final p in _items) {
      final id = p['santriId']?.toString();
      final nama = _santriOf(p)['nama']?.toString();
      if (id != null && nama != null && nama.isNotEmpty) m[id] = nama;
    }
    return m;
  }

  bool _inTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_timeFilter) {
      case 'Hari Ini':
        return t == today;
      case 'Minggu Ini':
        final d = today.difference(t).inDays;
        return d >= 0 && d <= 6;
      case 'Bulan Ini':
        return t.year == now.year && t.month == now.month;
      default:
        return true;
    }
  }

  /// Data setelah filter anak (khusus wali), tanpa filter waktu. Dasar grafik tren.
  List<Map<String, dynamic>> get _byAnak {
    return _items.where((p) {
      if (_isWali && _selectedSantriId != null && p['santriId']?.toString() != _selectedSantriId) return false;
      return true;
    }).toList();
  }

  /// Data dalam lingkup anak terpilih + rentang waktu (dasar ringkasan & hitungan chip).
  List<Map<String, dynamic>> get _scope {
    return _byAnak.where((p) {
      final t = _tgl(p);
      if (t == null) return _timeFilter == 'Semua';
      return _inTime(t);
    }).toList();
  }

  List<Map<String, dynamic>> get _filtered {
    return _scope.where((p) {
      if (_statusFilter != 'SEMUA' && (p['status'] ?? 'HADIR').toString() != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final s = _santriOf(p);
      final nama = (s['nama'] ?? '').toString().toLowerCase();
      final nis = (s['nis'] ?? '').toString().toLowerCase();
      final jenis = (p['jenisIbadah'] ?? '').toString().toLowerCase();
      return nama.contains(_query) || nis.contains(_query) || jenis.contains(_query);
    }).toList();
  }

  int _countStatus(List<Map<String, dynamic>> data, String status) =>
      data.where((p) => (p['status'] ?? 'HADIR').toString() == status).length;

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWali = _isWali;
    final readOnly = _readOnly;
    final scope = _scope;
    final filtered = _filtered;

    final kosong = _items.isEmpty;

    final children = <Widget>[
      if (isWali) ..._waliBlock(),
      _hero(scope),
      const SizedBox(height: 12),
      if (kosong)
        _kosongState(readOnly)
      else ...[
        _trenMingguan(),
        if (scope.isNotEmpty) ...[
          const SizedBox(height: 12),
          _rekapJenis(scope),
        ],
        const SizedBox(height: 20),
        _sectionTitle('Riwayat Catatan', trailing: '${filtered.length} catatan'),
        const SizedBox(height: 10),
        _buildSearch(),
        const SizedBox(height: 10),
        _timeSegment(),
        const SizedBox(height: 10),
        _statusChips(scope),
        const SizedBox(height: 16),
      ],
    ];

    if (kosong) {
      // sudah ditangani _kosongState
    } else if (filtered.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: emptyView(_items.isEmpty ? 'Belum ada rekap pembinaan ibadah.' : 'Tidak ada catatan yang cocok.'),
      ));
    } else {
      // Kelompokkan per tanggal (data sudah terurut menurun).
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final p in filtered) {
        final t = _tgl(p);
        final key = t == null ? '-' : '${t.year}-${t.month}-${t.day}';
        groups.putIfAbsent(key, () => []).add(p);
      }
      for (final g in groups.values) {
        children.add(_dateHeader(_tgl(g.first), g));
        for (final p in g) {
          children.add(_ibadahCard(p));
        }
        children.add(const SizedBox(height: 6));
      }
    }

    return Scaffold(
      backgroundColor: PTheme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _loading
                ? loadingView()
                : _error != null
                    ? errorView(_error!, _load)
                    : RefreshIndicator(
                        color: PTheme.primary,
                        onRefresh: () => _load(showSpinner: false),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: children,
                        ),
                      ),
          ),
        ),
      ),
      // Bar aksi bawah (bukan FAB) supaya toast tidak menumpuk.
      bottomNavigationBar: readOnly
          ? null
          : Container(
              decoration: BoxDecoration(
                color: PTheme.surface,
                border: Border(top: BorderSide(color: PColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _add,
                          style: FilledButton.styleFrom(
                            backgroundColor: PTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Catat Ibadah',
                              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 14.5)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Komponen umum
  // ---------------------------------------------------------------------
  Widget _sectionTitle(String text, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: PColors.gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800))),
        if (trailing != null) Text(trailing, style: PText.bodySm),
      ],
    );
  }

  /// Tampilan saat belum ada satu pun catatan ibadah.
  Widget _kosongState(bool readOnly) {
    Widget fitur(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, size: 22, color: PTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: PText.bodySm.copyWith(
                      fontSize: 11, fontWeight: FontWeight.w700, color: PTheme.ink, height: 1.3)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      decoration: _cardDeco(),
      child: Column(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: PTheme.sage.withOpacity(0.55)),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: PTheme.sage),
                ),
                Icon(Icons.mosque_rounded, size: 46, color: PTheme.primary),
                const Positioned(top: 10, right: 16, child: Icon(Icons.star_rounded, size: 18, color: PColors.gold)),
                Positioned(
                    bottom: 18,
                    left: 14,
                    child: Icon(Icons.star_rounded, size: 12, color: PColors.gold.withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Belum Ada Catatan Ibadah',
              textAlign: TextAlign.center,
              style: PText.headlineSm.copyWith(color: PTheme.ink)),
          const SizedBox(height: 6),
          Text(
            readOnly
                ? 'Rekap kehadiran ibadah akan muncul di sini setelah musyrif mulai mencatat.'
                : 'Mulai catat kehadiran ibadah santri lewat tombol "Catat Ibadah" di bawah.',
            textAlign: TextAlign.center,
            style: PText.bodySm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 22),
          Divider(color: PColors.border, height: 1),
          const SizedBox(height: 18),
          Text('YANG AKAN TAMPIL DI SINI',
              style: PText.bodySm.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: PTheme.inkSecondary)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fitur(Icons.donut_large_rounded, 'Persentase\nkehadiran'),
              fitur(Icons.bar_chart_rounded, 'Tren\n7 hari'),
              fitur(Icons.checklist_rounded, 'Rekap per\njenis ibadah'),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: PTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      );

  // ---------------------------------------------------------------------
  // Blok khusus wali
  // ---------------------------------------------------------------------
  List<Widget> _waliBlock() {
    final anak = _anak;
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 12, color: PColors.infoText),
                SizedBox(width: 4),
                Text('Mode Pantau',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: PColors.infoText)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (anak.length > 1) ...[
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _anakChip('Semua Anak', null, _selectedSantriId == null, () => setState(() => _selectedSantriId = null)),
              const SizedBox(width: 8),
              for (final e in anak.entries) ...[
                _anakChip(e.value.split(' ').first, e.value, _selectedSantriId == e.key,
                    () => setState(() => _selectedSantriId = e.key)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PColors.infoBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PColors.infoBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: PColors.infoText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kehadiran ibadah dicatat oleh musyrif atau pembina asrama. Wali dapat memantau perkembangan ibadah anak secara berkala.',
                style: PText.bodySm.copyWith(color: PColors.infoText, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
    ];
  }

  Widget _anakChip(String label, String? fullName, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? PTheme.primary : PColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : PTheme.sage,
                shape: BoxShape.circle,
              ),
              child: fullName == null
                  ? Icon(Icons.groups_rounded, size: 15, color: selected ? Colors.white : PTheme.primary)
                  : Text(_initialsOf(fullName),
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : PTheme.primary)),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : PTheme.ink)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero ringkasan (cincin progres + statistik)
  // ---------------------------------------------------------------------
  Widget _hero(List<Map<String, dynamic>> data) {
    final total = data.length;
    final hadir = _countStatus(data, 'HADIR');
    final izin = _countStatus(data, 'IZIN');
    final alpa = _countStatus(data, 'ALPA');
    final double? persen = total == 0 ? null : hadir * 100 / total;

    Widget stat(IconData icon, String label, int n, Color accent) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$n',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1)),
                      Text(label,
                          style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PTheme.primary, PTheme.primaryEnd],
          ),
          boxShadow: [BoxShadow(color: PTheme.primary.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            // Ornamen dekoratif
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: PColors.gold.withOpacity(0.10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mosque_rounded, size: 16, color: PColors.gold),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('KEHADIRAN IBADAH',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white70)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
                        child: Text(_timeFilter,
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(96, 96),
                              painter: _RingPainter(
                                value: persen == null ? 0 : persen / 100,
                                track: Colors.white.withOpacity(0.18),
                                color: PColors.gold,
                              ),
                            ),
                            persen == null
                                ? const Icon(Icons.hourglass_empty_rounded, color: Colors.white70, size: 26)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${persen.round()}%',
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              height: 1)),
                                      const SizedBox(height: 2),
                                      const Text('hadir',
                                          style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70)),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: persen == null
                            ? const Text('Belum ada catatan ibadah pada rentang ini.',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.4))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: PColors.gold.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: PColors.gold.withOpacity(0.5)),
                                    ),
                                    child: Text(_predikat(persen),
                                        style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: PColors.gold)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('$hadir hadir dari $total catatan',
                                      style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('${izin + alpa} catatan tidak hadir',
                                      style: const TextStyle(
                                          fontFamily: 'Nunito', fontSize: 11.5, color: Colors.white70)),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      stat(Icons.check_circle_rounded, 'Hadir', hadir, const Color(0xFF9BE7B4)),
                      const SizedBox(width: 8),
                      stat(Icons.schedule_rounded, 'Izin', izin, PColors.gold),
                      const SizedBox(width: 8),
                      stat(Icons.cancel_rounded, 'Alpa', alpa, const Color(0xFFFFA8A8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tren 7 hari terakhir
  // ---------------------------------------------------------------------
  Widget _trenMingguan() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final data = _byAnak;

    final days = <DateTime>[for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final pcts = <double?>[];
    for (final d in days) {
      int h = 0, t = 0;
      for (final p in data) {
        if (_tgl(p) == d) {
          t++;
          if ((p['status'] ?? 'HADIR').toString() == 'HADIR') h++;
        }
      }
      pcts.add(t == 0 ? null : h * 100 / t);
    }

    const maxH = 64.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Tren 7 Hari Terakhir'),
          const SizedBox(height: 14),
          SizedBox(
            height: maxH + 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < days.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(pcts[i] == null ? '' : '${pcts[i]!.round()}',
                            style: PText.bodySm.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: PTheme.ink)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: 22,
                          height: pcts[i] == null ? 4 : math.max(6.0, maxH * pcts[i]! / 100),
                          decoration: BoxDecoration(
                            color: pcts[i] == null ? PColors.border : _warnaPersen(pcts[i]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hariNama[days[i].weekday - 1].substring(0, 3),
                          style: PText.bodySm.copyWith(
                            fontSize: 10.5,
                            fontWeight: days[i] == today ? FontWeight.w800 : FontWeight.w600,
                            color: days[i] == today ? PTheme.primary : PTheme.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Rekap per jenis ibadah
  // ---------------------------------------------------------------------
  Widget _rekapJenis(List<Map<String, dynamic>> data) {
    final perJenis = <String, List<int>>{}; // jenis -> [hadir, total]
    for (final p in data) {
      final j = (p['jenisIbadah'] ?? '-').toString();
      final e = perJenis.putIfAbsent(j, () => [0, 0]);
      e[1]++;
      if ((p['status'] ?? 'HADIR').toString() == 'HADIR') e[0]++;
    }
    final rows = perJenis.entries.toList()..sort((a, b) => b.value[1].compareTo(a.value[1]));
    final tampil = _showAllJenis ? rows : rows.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Rekap per Jenis Ibadah', trailing: '${rows.length} jenis'),
          const SizedBox(height: 14),
          for (int i = 0; i < tampil.length; i++) ...[
            _jenisRow(tampil[i].key, tampil[i].value[0], tampil[i].value[1]),
            if (i != tampil.length - 1) const SizedBox(height: 14),
          ],
          if (rows.length > 4) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _showAllJenis = !_showAllJenis),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_showAllJenis ? 'Tampilkan lebih sedikit' : 'Lihat semua (${rows.length})',
                        style: PText.bodySm.copyWith(color: PTheme.primary, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 2),
                    Icon(_showAllJenis ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18, color: PTheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jenisRow(String jenis, int hadir, int total) {
    final pct = total == 0 ? 0.0 : hadir * 100 / total;
    final warna = _warnaPersen(pct);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(12)),
          child: Icon(_iconJenis(jenis), size: 19, color: PTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(jenis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PText.bodySm.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text('$hadir/$total',
                      style: PText.bodySm.copyWith(color: PTheme.inkSecondary, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${pct.round()}%',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: warna)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: PTheme.sage,
                  valueColor: AlwaysStoppedAnimation<Color>(warna),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Pencarian & filter
  // ---------------------------------------------------------------------
  Widget _buildSearch() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PColors.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: PText.bodyMd.copyWith(color: PTheme.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          hintText: _isWali ? 'Cari jenis ibadah...' : 'Cari nama santri, NIS, atau jenis ibadah...',
          hintStyle: PText.bodySm,
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: PTheme.inkSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => _searchCtrl.clear()),
        ),
      ),
    );
  }

  Widget _timeSegment() {
    const waktu = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        children: [
          for (final w in waktu)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _timeFilter = w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _timeFilter == w ? PTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    w,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _timeFilter == w ? Colors.white : PTheme.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChips(List<Map<String, dynamic>> scope) {
    final opsi = <List<String>>[
      ['SEMUA', 'Semua'],
      ['HADIR', 'Hadir'],
      ['IZIN', 'Izin'],
      ['ALPA', 'Alpa'],
    ];
    return Row(
      children: [
        for (int i = 0; i < opsi.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _statusChip(opsi[i][0], opsi[i][1], scope)),
        ],
      ],
    );
  }

  Widget _statusChip(String kode, String label, List<Map<String, dynamic>> scope) {
    final selected = _statusFilter == kode;
    final count = kode == 'SEMUA' ? scope.length : _countStatus(scope, kode);
    final warna = kode == 'SEMUA' ? PTheme.primary : _meta(kode).fg;
    final bg = kode == 'SEMUA' ? PTheme.primary : _meta(kode).bg;

    return InkWell(
      onTap: () => setState(() => _statusFilter = kode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? warna : PColors.border, width: selected ? 1.3 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected ? (kode == 'SEMUA' ? Colors.white : warna) : PTheme.ink,
                    height: 1.1)),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? (kode == 'SEMUA' ? Colors.white70 : warna) : PTheme.inkSecondary)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Daftar catatan
  // ---------------------------------------------------------------------
  Widget _dateHeader(DateTime? t, List<Map<String, dynamic>> group) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = t != null && t == today;
    final hadir = _countStatus(group, 'HADIR');

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isToday ? PTheme.primary : PTheme.sage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(t == null ? '-' : '${t.day}',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: isToday ? Colors.white : PTheme.primary)),
                Text(t == null ? '' : _bulanNama[t.month - 1],
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white70 : PTheme.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t == null ? 'Tanpa tanggal' : (isToday ? 'Hari Ini' : _hariNama[t.weekday - 1]),
                    style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                if (t != null) Text('${t.day} ${_bulanNama[t.month - 1]} ${t.year}', style: PText.bodySm),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PColors.successBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: PColors.successBorder),
            ),
            child: Text('$hadir/${group.length} hadir',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: PColors.successText)),
          ),
        ],
      ),
    );
  }

  Widget _ibadahCard(Map<String, dynamic> p) {
    final m = _meta((p['status'] ?? 'HADIR').toString());
    final santri = _santriOf(p);
    final nama = santri['nama']?.toString();
    final nis = santri['nis']?.toString();
    final jenis = (p['jenisIbadah'] ?? '-').toString();
    final catatan = p['catatan']?.toString().trim();
    final tampilNama = (!_isWali || _anak.length > 1) && nama != null && nama.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: PTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDetail(p),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: m.fg),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(13)),
                              child: Icon(_iconJenis(jenis), size: 21, color: PTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(jenis,
                                      style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                                  if (tampilNama) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded, size: 12, color: PTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(nis != null && nis.isNotEmpty ? '$nama • NIS $nis' : nama,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: PText.bodySm.copyWith(fontSize: 11.5)),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (catatan != null && catatan.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                          color: PTheme.background, borderRadius: BorderRadius.circular(10)),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.notes_rounded, size: 13, color: PTheme.inkSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(catatan,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    PText.bodySm.copyWith(color: PTheme.ink, fontSize: 11.5, height: 1.4)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusPill(m),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(_StatusMeta m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: m.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: m.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.icon, size: 12, color: m.fg),
          const SizedBox(width: 4),
          Text(m.label,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: m.fg)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Detail catatan (bottom sheet)
  // ---------------------------------------------------------------------
  void _showDetail(Map<String, dynamic> p) {
    final m = _meta((p['status'] ?? 'HADIR').toString());
    final s = _santriOf(p);
    final nama = s['nama']?.toString() ?? '-';
    final nis = s['nis']?.toString() ?? '-';
    final k = s['kelas'];
    final kelas = k is Map ? (k['namaKelas'] ?? k['nama'])?.toString() : k?.toString();
    final jenis = (p['jenisIbadah'] ?? '-').toString();
    final t = _tgl(p);
    final catatan = p['catatan']?.toString().trim();

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: PTheme.background, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: PTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PText.bodySm.copyWith(fontSize: 11)),
                    const SizedBox(height: 1),
                    Text(value, style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      backgroundColor: PTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: PColors.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(15)),
                    child: Icon(_iconJenis(jenis), size: 24, color: PTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(jenis, style: PText.headlineSm)),
                  _statusPill(m),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 20),
              row(Icons.person_rounded, 'Santri', nama),
              row(Icons.badge_outlined, 'NIS', kelas != null && kelas.isNotEmpty ? '$nis • Kelas $kelas' : nis),
              row(Icons.event_rounded, 'Tanggal', t == null ? '-' : _fmtTgl(t)),
              row(Icons.notes_rounded, 'Catatan', (catatan == null || catatan.isEmpty) ? 'Tidak ada catatan.' : catatan),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: PColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('Tutup', style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
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
// Bottom sheet "Catat Pembinaan Ibadah"
// ===========================================================================
class _CatatIbadahSheet extends StatefulWidget {
  const _CatatIbadahSheet({required this.santris, this.existing = const []});
  final List<Map<String, dynamic>> santris;
  final List<Map<String, dynamic>> existing; // catatan yang sudah ada (untuk cek duplikat)

  @override
  State<_CatatIbadahSheet> createState() => _CatatIbadahSheetState();
}

class _CatatIbadahSheetState extends State<_CatatIbadahSheet> {
  Map<String, dynamic>? _santri;
  final _jenisCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String _status = 'HADIR';
  DateTime _tanggal = DateTime.now();
  String? _errSantri;
  String? _errJenis;

  @override
  void initState() {
    super.initState();
    _santri = widget.santris.isEmpty ? null : widget.santris.first;
    _jenisCtrl.addListener(() => setState(() {}));
    _catatanCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _jenisCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  String _tglKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// santriId -> status, untuk jenis ibadah + tanggal yang sedang dipilih.
  Map<String, String> get _sudahDicatat {
    final jenis = _jenisCtrl.text.trim().toLowerCase();
    if (jenis.isEmpty) return {};
    final tgl = _tglKey(_tanggal);
    final m = <String, String>{};
    for (final p in widget.existing) {
      final pj = (p['jenisIbadah'] ?? '').toString().trim().toLowerCase();
      final pt = (p['tanggal'] ?? '').toString();
      if (pj == jenis && pt.length >= 10 && pt.substring(0, 10) == tgl) {
        final id = p['santriId']?.toString();
        if (id != null) m[id] = (p['status'] ?? 'HADIR').toString();
      }
    }
    return m;
  }

  String _kelasLabel(Map<String, dynamic> s) {
    final k = s['kelas'];
    final kelas = k is Map ? (k['namaKelas'] ?? k['nama'])?.toString() : k?.toString();
    final kamar = s['asrama']?.toString();
    final parts = [
      if (kelas != null && kelas.isNotEmpty) 'Kelas $kelas',
      if (kamar != null && kamar.isNotEmpty) 'Kamar $kamar',
    ];
    return parts.join(' • ');
  }

  void _pilihSantri() {
    if (widget.santris.isEmpty) return;
    String q = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final list = widget.santris.where((s) {
            final n = (s['nama'] ?? '').toString().toLowerCase();
            final nis = (s['nis'] ?? '').toString().toLowerCase();
            return q.isEmpty || n.contains(q) || nis.contains(q);
          }).toList();
          final sudah = _sudahDicatat;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: PColors.border, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 14),
                    Text('Pilih Santri', style: PText.headlineSm),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: TextField(
                        onChanged: (v) => setSheet(() => q = v.trim().toLowerCase()),
                        style: PText.bodyMd.copyWith(color: PTheme.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: PTheme.background,
                          hintText: 'Cari nama atau NIS...',
                          hintStyle: PText.bodySm,
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    if (_jenisCtrl.text.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 15, color: PTheme.inkSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pilih jenis ibadah & tanggal dulu agar santri yang sudah tercatat otomatis abu-abu.',
                                style: PText.bodySm.copyWith(fontSize: 11.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: list.isEmpty
                          ? Center(child: Text('Santri tidak ditemukan.', style: PText.bodySm))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final s = list[i];
                                final label = _kelasLabel(s);
                                final dipilih = _santri?['id'] == s['id'];
                                final statusLama = sudah[s['id']?.toString()];
                                final terkunci = statusLama != null;
                                final mLama = terkunci ? _meta(statusLama) : null;
                                return Opacity(
                                  opacity: terkunci ? 0.55 : 1,
                                  child: ListTile(
                                    enabled: !terkunci,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: terkunci ? PColors.border : PTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: terkunci
                                          ? Icon(Icons.check_rounded, size: 20, color: PTheme.inkSecondary)
                                          : Text(_initialsOf(s['nama']?.toString() ?? '-'),
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white)),
                                    ),
                                    title: Text(s['nama']?.toString() ?? '-',
                                        style: PText.bodyMd.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: terkunci ? PTheme.inkSecondary : null)),
                                    subtitle: Text(
                                        terkunci
                                            ? 'Sudah dicatat • ${mLama!.label}'
                                            : 'NIS: ${s['nis'] ?? '-'}${label.isEmpty ? '' : ' • $label'}',
                                        style: PText.bodySm),
                                    trailing: terkunci
                                        ? Icon(Icons.lock_outline_rounded, size: 18, color: PTheme.inkSecondary)
                                        : (dipilih ? Icon(Icons.check_circle_rounded, color: PTheme.primary) : null),
                                    onTap: terkunci
                                        ? null
                                        : () {
                                            setState(() {
                                              _santri = s;
                                              _errSantri = null;
                                            });
                                            Navigator.pop(ctx);
                                          },
                                  ),
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

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (d != null) setState(() => _tanggal = DateTime(d.year, d.month, d.day));
  }

  void _submit() {
    setState(() {
      _errSantri = _santri == null
          ? 'Silakan pilih santri terlebih dahulu.'
          : (_sudahDicatat.containsKey(_santri!['id']?.toString())
              ? 'Santri ini sudah dicatat untuk ibadah & tanggal tersebut.'
              : null);
      _errJenis = _jenisCtrl.text.trim().isEmpty ? 'Jenis ibadah wajib diisi.' : null;
    });
    if (_errSantri != null || _errJenis != null) return;

    final t = _tanggal;
    Navigator.pop(context, {
      'santriId': _santri!['id'],
      'jenisIbadah': _jenisCtrl.text.trim(),
      'tanggal':
          '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}',
      'status': _status,
      'catatan': _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
    });
  }

  Widget _requiredLabel(String text, {bool required = true, String? hint}) {
    return Text.rich(TextSpan(text: text, style: PText.labelMd.copyWith(color: PTheme.ink), children: [
      if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
      if (hint != null) TextSpan(text: ' $hint', style: PText.bodySm),
    ]));
  }

  Widget _statusToggle(String value) {
    final m = _meta(value);
    final selected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? m.bg : PTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? m.fg : Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.icon, size: 22, color: selected ? m.fg : PTheme.inkSecondary),
              const SizedBox(height: 4),
              Text(m.label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? m.fg : PTheme.inkSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tanggalChip(String label, DateTime value) {
    final today = DateTime.now();
    final target = DateTime(value.year, value.month, value.day);
    final selected = DateTime(_tanggal.year, _tanggal.month, _tanggal.day) == target;
    return InkWell(
      onTap: () => setState(() => _tanggal = target),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : PTheme.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : PTheme.inkSecondary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = _santri?['nama']?.toString() ?? 'Belum ada data santri';
    final nis = _santri?['nis']?.toString() ?? '-';
    final kelasLabel = _santri == null ? '' : _kelasLabel(_santri!);
    final jenisSekarang = _jenisCtrl.text.trim();
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final kemarin = hariIni.subtract(const Duration(days: 1));
    final tglTerpilih = DateTime(_tanggal.year, _tanggal.month, _tanggal.day);
    final customDate = tglTerpilih != hariIni && tglTerpilih != kemarin;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: PTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(color: PColors.border, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: PTheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(15)),
                  child: Icon(Icons.mosque_rounded, color: PTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catat Pembinaan Ibadah', style: PText.headlineSm),
                      const SizedBox(height: 1),
                      Text('Rekap kehadiran ibadah santri', style: PText.bodySm),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Santri
                  _requiredLabel('Santri'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pilihSantri,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: _errSantri != null ? Border.all(color: Colors.red, width: 1.4) : null,
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
                                    fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nama,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('NIS: $nis${kelasLabel.isEmpty ? '' : ' • $kelasLabel'}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm),
                              ],
                            ),
                          ),
                          if (widget.santris.length > 1)
                            Icon(Icons.unfold_more_rounded, size: 20, color: PTheme.inkSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (_errSantri != null) ...[
                    const SizedBox(height: 4),
                    Text(_errSantri!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  if (_errSantri == null && _santri != null && _sudahDicatat.containsKey(_santri!['id']?.toString())) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: PColors.pendingBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PColors.pendingBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: PColors.pendingText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Santri ini sudah dicatat untuk ibadah & tanggal tersebut.',
                                style: PText.bodySm.copyWith(color: PColors.pendingText, fontSize: 11.5)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Jenis ibadah
                  const SizedBox(height: 20),
                  _requiredLabel('Jenis Ibadah'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final j in _jenisIbadahPreset)
                        InkWell(
                          onTap: () => setState(() {
                            _jenisCtrl.text = j;
                            _errJenis = null;
                          }),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                            decoration: BoxDecoration(
                              color: jenisSekarang == j ? PTheme.primary : PTheme.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconJenis(j),
                                    size: 14, color: jenisSekarang == j ? Colors.white : PTheme.primary),
                                const SizedBox(width: 6),
                                Text(j,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: jenisSekarang == j ? Colors.white : PTheme.inkSecondary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _jenisCtrl,
                    maxLength: 100,
                    onChanged: (_) {
                      if (_errJenis != null) setState(() => _errJenis = null);
                    },
                    style: PText.bodyMd.copyWith(color: PTheme.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: PTheme.background,
                      prefixIcon: Icon(Icons.edit_note_rounded, size: 20, color: PTheme.inkSecondary),
                      hintText: 'Pilih di atas, atau tulis jenis ibadah lain',
                      hintStyle: PText.bodySm,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: _errJenis != null ? const BorderSide(color: Colors.red, width: 1.4) : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: _errJenis != null ? const BorderSide(color: Colors.red, width: 1.4) : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _errJenis != null ? Colors.red : PTheme.primary, width: 1.4),
                      ),
                    ),
                  ),
                  if (_errJenis != null) ...[
                    const SizedBox(height: 4),
                    Text(_errJenis!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],

                  // --- Status
                  const SizedBox(height: 20),
                  _requiredLabel('Status Kehadiran'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusToggle('HADIR'),
                      const SizedBox(width: 8),
                      _statusToggle('IZIN'),
                      const SizedBox(width: 8),
                      _statusToggle('ALPA'),
                    ],
                  ),

                  // --- Tanggal
                  const SizedBox(height: 20),
                  _requiredLabel('Tanggal'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _tanggalChip('Hari Ini', hariIni),
                      _tanggalChip('Kemarin', kemarin),
                      InkWell(
                        onTap: _pilihTanggal,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: customDate ? PTheme.primary : PTheme.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 13, color: customDate ? Colors.white : PTheme.inkSecondary),
                              const SizedBox(width: 6),
                              Text(customDate ? _fmtTgl(_tanggal) : 'Pilih tanggal',
                                  style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: customDate ? Colors.white : PTheme.inkSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Catatan
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _requiredLabel('Catatan', required: false, hint: '(Opsional)'),
                      const Spacer(),
                      Text('${_catatanCtrl.text.length}/200', style: PText.bodySm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanCtrl,
                    maxLength: 200,
                    maxLines: 3,
                    style: PText.bodyMd.copyWith(color: PTheme.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: PTheme.background,
                      hintText: 'Contoh: terlambat 10 menit, sakit perut...',
                      hintStyle: PText.bodySm,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: PTheme.primary, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // --- Aksi
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: PColors.border))),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: PColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text('Batal', style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: PTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Simpan Rekap',
                            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
                      ),
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