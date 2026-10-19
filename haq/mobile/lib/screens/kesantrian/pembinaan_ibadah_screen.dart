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

  Future<void> _add() async {
    if (_readOnly) return;
    if (_santris.isEmpty) await _loadSantris();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CatatIbadahDialog(santris: _santris),
    );
    if (result == null || !mounted) return;
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.pembinaanIbadah, result);
      _load(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PTheme.primary, content: const Text('Rekap ibadah tersimpan.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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

  /// Data dalam lingkup anak terpilih + rentang waktu (dasar ringkasan & hitungan chip).
  List<Map<String, dynamic>> get _scope {
    return _items.where((p) {
      if (_isWali && _selectedSantriId != null && p['santriId']?.toString() != _selectedSantriId) return false;
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

    final children = <Widget>[
      if (isWali) ..._waliBlock(),
      _ringkasan(scope),
      const SizedBox(height: 16),
      _buildSearch(),
      const SizedBox(height: 10),
      _timeChips(),
      const SizedBox(height: 8),
      _statusChips(scope),
      const SizedBox(height: 14),
    ];

    if (filtered.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: emptyView(_items.isEmpty ? 'Belum ada rekap pembinaan ibadah.' : 'Tidak ada catatan yang cocok.'),
      ));
    } else {
      String? lastKey;
      for (final p in filtered) {
        final t = _tgl(p);
        final key = t == null ? '-' : '${t.year}-${t.month}-${t.day}';
        if (key != lastKey) {
          children.add(_dateHeader(t));
          lastKey = key;
        }
        children.add(_ibadahCard(p));
      }
    }

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
                    Expanded(
                      child: _loading
                          ? loadingView()
                          : _error != null
                              ? errorView(_error!, _load)
                              : RefreshIndicator(
                                  color: PTheme.primary,
                                  onRefresh: () => _load(showSpinner: false),
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(16, 12, 16, readOnly ? 24 : 100),
                                    children: children,
                                  ),
                                ),
                    ),
                  ],
                ),
                if (!readOnly)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _add,
                      backgroundColor: PTheme.primary,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text('Catat Ibadah',
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
  // Header & blok khusus wali
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined, size: 12, color: PColors.infoText),
                const SizedBox(width: 4),
                Text('Mode Pantau (Read-Only)',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: PColors.infoText)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (anak.length > 1) ...[
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                label: 'Semua Anak',
                selected: _selectedSantriId == null,
                onTap: () => setState(() => _selectedSantriId = null),
              ),
              const SizedBox(width: 8),
              for (final e in anak.entries) ...[
                _chip(
                  label: e.value.split(' ').first,
                  selected: _selectedSantriId == e.key,
                  onTap: () => setState(() => _selectedSantriId = e.key),
                ),
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
          borderRadius: BorderRadius.circular(12),
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
      const SizedBox(height: 16),
    ];
  }

  // ---------------------------------------------------------------------
  // Ringkasan & rekap per jenis ibadah
  // ---------------------------------------------------------------------
  Widget _ringkasan(List<Map<String, dynamic>> data) {
    final total = data.length;
    final hadir = _countStatus(data, 'HADIR');
    final izin = _countStatus(data, 'IZIN');
    final alpa = _countStatus(data, 'ALPA');
    final persen = total == 0 ? null : hadir * 100 / total;

    final perJenis = <String, List<int>>{}; // jenis -> [hadir, total]
    for (final p in data) {
      final j = (p['jenisIbadah'] ?? '-').toString();
      final e = perJenis.putIfAbsent(j, () => [0, 0]);
      e[1]++;
      if ((p['status'] ?? 'HADIR').toString() == 'HADIR') e[0]++;
    }
    final rows = perJenis.entries.toList()..sort((a, b) => b.value[1].compareTo(a.value[1]));

    Widget pill(String label, int n) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$n',
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 1),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PTheme.primary, PTheme.primaryEnd],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: PTheme.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('KEHADIRAN IBADAH',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white70)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                    child: Text(_timeFilter,
                        style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (persen == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Belum ada catatan ibadah pada rentang ini',
                          style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${persen.round()}%',
                        style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$hadir hadir dari $total catatan',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: persen == null ? 0 : persen / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(PColors.gold),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  pill('Hadir', hadir),
                  const SizedBox(width: 8),
                  pill('Izin', izin),
                  const SizedBox(width: 8),
                  pill('Alpa', alpa),
                ],
              ),
            ],
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rekap per Jenis Ibadah',
                    style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final r in rows.take(5)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PText.bodySm.copyWith(color: PTheme.ink, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text('${r.value[0]}/${r.value[1]}',
                          style: PText.bodySm.copyWith(color: PTheme.inkSecondary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: r.value[1] == 0 ? 0 : r.value[0] / r.value[1],
                      minHeight: 5,
                      backgroundColor: PTheme.sage,
                      valueColor: AlwaysStoppedAnimation<Color>(PTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Pencarian & filter
  // ---------------------------------------------------------------------
  Widget _buildSearch() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: PText.bodyMd.copyWith(color: PTheme.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintText: _isWali ? 'Cari jenis ibadah...' : 'Cari nama santri, NIS, atau jenis ibadah...',
          hintStyle: PText.bodySm,
          prefixIcon: Icon(Icons.search, size: 20, color: PTheme.inkSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _searchCtrl.clear()),
        ),
      ),
    );
  }

  Widget _timeChips() {
    const waktu = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];
    return Row(
      children: [
        for (int i = 0; i < waktu.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _chip(
              label: waktu[i],
              selected: _timeFilter == waktu[i],
              onTap: () => setState(() => _timeFilter = waktu[i]),
              expand: true,
            ),
          ),
        ],
      ],
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
          Expanded(
            child: _chip(
              label: opsi[i][1],
              count: opsi[i][0] == 'SEMUA' ? scope.length : _countStatus(scope, opsi[i][0]),
              selected: _statusFilter == opsi[i][0],
              onTap: () => setState(() => _statusFilter = opsi[i][0]),
              expand: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip({
    required String label,
    int? count,
    required bool selected,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        alignment: expand ? Alignment.center : null,
        padding: EdgeInsets.symmetric(horizontal: expand ? 6 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3)],
        ),
        child: Row(
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
                  color: selected ? Colors.white.withOpacity(0.25) : PTheme.background,
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
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Daftar catatan
  // ---------------------------------------------------------------------
  Widget _dateHeader(DateTime? t) {
    String label = 'Tanpa tanggal';
    if (t != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final base = '${_hariNama[t.weekday - 1]}, ${t.day} ${_bulanNama[t.month - 1]} ${t.year}';
      label = t == today ? 'Hari Ini • $base' : base;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Text(label, style: PText.labelMd.copyWith(color: PTheme.inkSecondary, fontWeight: FontWeight.w800)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: PTheme.sage, borderRadius: BorderRadius.circular(12)),
            child: Icon(_iconJenis(jenis), size: 20, color: PTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jenis, style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w800)),
                if (tampilNama) ...[
                  const SizedBox(height: 2),
                  Text(nis != null && nis.isNotEmpty ? '$nama • NIS $nis' : nama,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm.copyWith(fontSize: 11.5)),
                ],
                if (catatan != null && catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: PTheme.background, borderRadius: BorderRadius.circular(10)),
                    child: Text(catatan, style: PText.bodySm.copyWith(color: PTheme.ink, fontSize: 11.5, height: 1.4)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
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
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Dialog "Catat Pembinaan Ibadah"
// ===========================================================================
class _CatatIbadahDialog extends StatefulWidget {
  const _CatatIbadahDialog({required this.santris});
  final List<Map<String, dynamic>> santris;

  @override
  State<_CatatIbadahDialog> createState() => _CatatIbadahDialogState();
}

class _CatatIbadahDialogState extends State<_CatatIbadahDialog> {
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final list = widget.santris.where((s) {
            final n = (s['nama'] ?? '').toString().toLowerCase();
            final nis = (s['nis'] ?? '').toString().toLowerCase();
            return q.isEmpty || n.contains(q) || nis.contains(q);
          }).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Pilih Santri', style: PText.headlineSm),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: TextField(
                        onChanged: (v) => setSheet(() => q = v.trim().toLowerCase()),
                        style: PText.bodyMd.copyWith(color: PTheme.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: PTheme.background,
                          hintText: 'Cari nama atau NIS...',
                          hintStyle: PText.bodySm,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final s = list[i];
                          final label = _kelasLabel(s);
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: PTheme.primary, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(_initialsOf(s['nama']?.toString() ?? '-'),
                                  style: const TextStyle(
                                      fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                            title: Text(s['nama']?.toString() ?? '-', style: PText.bodyMd),
                            subtitle: Text('NIS: ${s['nis'] ?? '-'}${label.isEmpty ? '' : ' • $label'}',
                                style: PText.bodySm),
                            trailing: _santri?['id'] == s['id']
                                ? Icon(Icons.check_circle_rounded, color: PTheme.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _santri = s;
                                _errSantri = null;
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

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (d != null) setState(() => _tanggal = d);
  }

  void _submit() {
    setState(() {
      _errSantri = _santri == null ? 'Silakan pilih santri terlebih dahulu.' : null;
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

  Widget _requiredLabel(String text) {
    return Text.rich(TextSpan(text: text, style: PText.labelMd.copyWith(color: PTheme.ink), children: const [
      TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
    ]));
  }

  Widget _statusToggle(String value) {
    final m = _meta(value);
    final selected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? m.bg : PTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? m.fg : Colors.transparent, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.icon, size: 15, color: selected ? m.fg : PTheme.inkSecondary),
              const SizedBox(width: 5),
              Text(m.label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? m.fg : PTheme.inkSecondary)),
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
    final kelasLabel = _santri == null ? '' : _kelasLabel(_santri!);
    final jenisSekarang = _jenisCtrl.text.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(color: PTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: PTheme.primary.withOpacity(0.10), shape: BoxShape.circle),
                      child: Icon(Icons.mosque_rounded, color: PTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Catat Pembinaan Ibadah', style: PText.headlineSm),
                          const SizedBox(height: 1),
                          Text('Rekap Kehadiran Ibadah', style: PText.bodySm),
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
                        onTap: _pilihSantri,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: _errSantri != null ? Border.all(color: Colors.red, width: 1.4) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(color: PTheme.primary, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(_initialsOf(nama),
                                    style: const TextStyle(
                                        fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('NIS: $nis${kelasLabel.isEmpty ? '' : ' • $kelasLabel'}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: PText.bodySm),
                                  ],
                                ),
                              ),
                              if (widget.santris.length > 1)
                                Icon(Icons.unfold_more, size: 18, color: PTheme.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (_errSantri != null) ...[
                        const SizedBox(height: 4),
                        Text(_errSantri!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),
                      _requiredLabel('Jenis Ibadah'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final j in _jenisIbadahPreset)
                            InkWell(
                              onTap: () => setState(() {
                                _jenisCtrl.text = j;
                                _errJenis = null;
                              }),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: jenisSekarang == j ? PTheme.primary : PTheme.background,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(j,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: jenisSekarang == j ? Colors.white : PTheme.inkSecondary,
                                    )),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                          hintText: 'Pilih di atas, atau tulis jenis ibadah lain',
                          hintStyle: PText.bodySm,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _errJenis != null ? const BorderSide(color: Colors.red, width: 1.4) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _errJenis != null ? const BorderSide(color: Colors.red, width: 1.4) : BorderSide.none,
                          ),
                        ),
                      ),
                      if (_errJenis != null) ...[
                        const SizedBox(height: 4),
                        Text(_errJenis!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),
                      _requiredLabel('Status Kehadiran'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _statusToggle('HADIR'),
                          const SizedBox(width: 8),
                          _statusToggle('IZIN'),
                          const SizedBox(width: 8),
                          _statusToggle('ALPA'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _requiredLabel('Tanggal'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pilihTanggal,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(color: PTheme.background, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_hariNama[_tanggal.weekday - 1]}, ${_tanggal.day} ${_bulanNama[_tanggal.month - 1]} ${_tanggal.year}',
                                  style: PText.bodySm.copyWith(color: PTheme.ink, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined, size: 16, color: PTheme.inkSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text.rich(TextSpan(
                              text: 'Catatan ',
                              style: PText.labelMd.copyWith(color: PTheme.ink),
                              children: [TextSpan(text: '(Opsional)', style: PText.bodySm)])),
                          const Spacer(),
                          Text('${_catatanCtrl.text.length}/200', style: PText.bodySm),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: PTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 17),
                        label: const Text('Simpan Rekap',
                            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal', style: PText.bodyMd.copyWith(color: PTheme.ink, fontWeight: FontWeight.w700)),
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
}