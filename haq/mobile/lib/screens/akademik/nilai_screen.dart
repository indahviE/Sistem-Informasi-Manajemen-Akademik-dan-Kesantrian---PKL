import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

class _Predikat {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _Predikat(this.label, this.bg, this.fg, this.icon);
}

_Predikat _predikat(double n) {
  if (n >= 90) {
    return const _Predikat('Mumtaz / A', Color(0xFFD2E4DC), Color(0xFF0F3A2E), Icons.workspace_premium_outlined);
  }
  if (n >= 80) {
    return const _Predikat('Jayyid Jiddan / B+', Color(0xFFFCD98B), Color(0xFF7A5B10), Icons.star_outline_rounded);
  }
  if (n >= 70) {
    return const _Predikat('Jayyid / B', Color(0xFFE6E4DB), Color(0xFF475569), Icons.check_circle_outline);
  }
  if (n >= 60) {
    return const _Predikat('Maqbul / C', Color(0xFFF3E2B8), Color(0xFF7A5B10), Icons.remove_circle_outline);
  }
  return const _Predikat('Rasib / D', Color(0xFFFEE2E2), Color(0xFF991B1B), Icons.error_outline);
}

const _kJenis = [
  MapEntry('HARIAN', 'Harian'),
  MapEntry('ULANGAN', 'Ulangan'),
  MapEntry('TAHFIDZ', 'Tahfidz'),
  MapEntry('BAHASA_ARAB', 'Bahasa Arab'),
];

// Kunci huruf kecil, sama dengan yang disimpan backend.
const _kSkill = [
  MapEntry('muhadatsah', 'Muhadatsah'),
  MapEntry('qiraah', "Qira'ah"),
  MapEntry('kitabah', 'Kitabah'),
  MapEntry('istima', "Istima'"),
];

const _kMaxCatatan = 150;

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  /// Pimpinan/Mudir hanya memantau: hanya bisa melihat List dan Riwayat.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  List<Map<String, dynamic>> _santris = [];

  /// Penugasan ustadz yang login: [{kelasId, mapelId}, ...].
  /// null = tidak dibatasi (admin/pimpinan), tampil semua mapel.
  List<Map<String, dynamic>>? _tugas;

  /// Mapel yang boleh dipilih untuk kelas yang sedang dipilih.
  List<Map<String, dynamic>> get _mapelTersedia {
    final t = _tugas;
    if (t == null) return _mapel;
    final ids = t
        .where((e) => e['kelasId']?.toString() == _kelasId)
        .map((e) => e['mapelId']?.toString())
        .toSet();
    return _mapel.where((m) => ids.contains(m['id']?.toString())).toList();
  }

  /// Pastikan _mapelId valid untuk kelas saat ini.
  void _selaraskanMapel() {
    final list = _mapelTersedia;
    if (list.any((m) => m['id'] == _mapelId)) return;
    _mapelId = list.isEmpty ? null : list.first['id'] as String;
  }

  String? _kelasId;
  String? _mapelId;
  String _jenis = 'HARIAN';
  String _skill = 'muhadatsah'; // hanya dipakai kalau _jenis == 'BAHASA_ARAB'

  bool get _pakaiSkill => _jenis == 'BAHASA_ARAB';
  String get _skillLabel => _kSkill.firstWhere((e) => e.key == _skill).value;

  /// Respons /nilai membawa kolom skill; untuk Bahasa Arab hanya ambil skill terpilih.
  bool _cocokSkill(dynamic r) =>
      !_pakaiSkill || (r['skill'] ?? '').toString() == _skill;

  final Map<String, TextEditingController> _ctrl = {}; // santriId -> nilai
  final Map<String, String> _catatan = {}; // santriId -> catatan lisan

  List<dynamic> _riwayat = [];
  int _tab = 0; // 0 = input, 1 = list, 2 = riwayat
  String? _editTanggal; // null = input baru; terisi = sedang mengubah sesi tanggal itu
  bool _sortAz = true;
  bool _loadingMeta = true;
  bool _loadingSantri = false;
  bool _saving = false;
  int _seq = 0;
  int _seqRiwayat = 0;
  String? _error;

  final ScrollController _scroll = ScrollController();

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  // Filter riwayat
  final TextEditingController _cari = TextEditingController();
  String _cariQ = '';
  bool _terbaru = true; // urutan sesi di Riwayat

  // Cari santri di tab Input & List
  final TextEditingController _cariS = TextEditingController();
  String _qS = '';

  /// Baris nilai HARI INI untuk kelas + mapel + jenis (+ skill) yang dipilih.
  List<Map<String, dynamic>> get _sesiHariIni {
    final hariIni = _iso(DateTime.now());
    return [
      for (final r in _riwayat)
        if (_tgl10((r as Map)['tanggal']) == hariIni && _cocokSkill(r))
          Map<String, dynamic>.from(r),
    ];
  }

  bool get _adaTersimpan => _sesiHariIni.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scroll.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _cari.dispose();
    _cariS.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  List<Map<String, dynamic>> _asList(dynamic res) {
    final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
    return (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _init() async {
    final api = AppScope.of(context).api;
    final isUstadz = AppScope.of(context).user?.role == 'USTADZ';
    String? err;
    try {
      // Backend yang menyaring: ustadz hanya dapat kelas yang diampu.
      _kelas = _asList(await api.get(ApiUrl.kelas, query: {'diampu': 'true'}));
    } catch (_) {
      err = 'Gagal memuat daftar kelas.';
    }
    try {
      _mapel = _asList(await api.get(ApiUrl.mapel));
    } catch (_) {
      err ??= 'Gagal memuat daftar mapel.';
    }

    // Mapel yang dipegang per kelas (khusus ustadz).
    if (isUstadz) {
      try {
        _tugas = _asList(await api.get('/mengajar/saya'));
      } catch (_) {
        _tugas = null; // gagal: tampilkan semua mapel
      }
    }

    if (!mounted) return;
    setState(() {
      _loadingMeta = false;
      _error = err;
      if (_readOnly) _tab = 1;
      if (_kelas.isNotEmpty) _kelasId = _kelas.first['id'] as String;
      _mapelId = null;
      _selaraskanMapel();
      if (_tugas == null && _mapelId == null && _mapel.isNotEmpty) {
        _mapelId = _mapel.first['id'] as String;
      }
    });
    await _loadSantri();
  }

  Future<void> _loadSantri() async {
    if (_kelasId == null) return;
    final seq = ++_seq;
    setState(() {
      _loadingSantri = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'kelasId': _kelasId!, 'perPage': '100'});
      if (!mounted || seq != _seq) return;
      final list = _asList(res);
      setState(() {
        for (final c in _ctrl.values) {
          c.dispose();
        }
        _ctrl.clear();
        _catatan.clear();
        _santris = list;
        _cariS.clear();
        _qS = '';
        _riwayat = [];
        _editTanggal = null;
        for (final s in list) {
          _ctrl[s['id'] as String] = TextEditingController();
        }
        _loadingSantri = false;
      });
      await _loadRiwayat();
    } on ApiException catch (e) {
      if (mounted && seq == _seq) {
        setState(() {
          _error = e.message;
          _loadingSantri = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) {
        setState(() {
          _error = 'Gagal memuat daftar santri.';
          _loadingSantri = false;
        });
      }
    }
  }

  /// Memuat semua nilai tersimpan untuk mapel + jenis yang dipilih.
  /// Dipakai oleh tab List (sesi hari ini) dan tab Riwayat (semua sesi).
  Future<void> _loadRiwayat() async {
    final seq = ++_seqRiwayat;
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.nilai, query: {
        if (_mapelId != null) 'mapelId': _mapelId!,
        'jenis': _jenis,
      });
      if (!mounted || seq != _seqRiwayat) return;
      final ids = _santris.map((e) => e['id']).toSet();
      setState(() {
        _riwayat = _asList(res).where((r) => ids.contains(r['santriId'])).toList();
      });
    } catch (_) {}
  }

  /// Mapel / jenis / skill berganti: kosongkan isian, muat ulang riwayat.
  void _paramBerubah() {
    setState(() {
      _editTanggal = null;
      _riwayat = [];
      for (final c in _ctrl.values) {
        c.clear();
      }
      _catatan.clear();
    });
    _loadRiwayat();
  }

  // ---------------------------------------------------------------------
  // Nilai
  // ---------------------------------------------------------------------
  double? _val(String id) {
    final t = _ctrl[id]?.text.trim().replaceAll(',', '.') ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null || n < 0 || n > 100) return null;
    return n;
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _step(String id, int delta) {
    final cur = _val(id) ?? 0;
    final next = (cur + delta).clamp(0, 100).toDouble();
    setState(() => _ctrl[id]!.text = _fmt(next));
  }

  void _quickAdd() {
    setState(() {
      for (final s in _santris) {
        final id = s['id'] as String;
        final v = _val(id);
        if (v != null) _ctrl[id]!.text = _fmt((v + 2).clamp(0, 100).toDouble());
      }
    });
  }

  /// Daftar santri yang tampil: disaring pencarian (nama / NIS), lalu diurutkan.
  /// Penyimpanan tetap memakai _santris, jadi santri yang tersaring tidak hilang.
  List<Map<String, dynamic>> get _sorted {
    final l = _santris.where((s) {
      if (_qS.isEmpty) return true;
      return '${s['nama'] ?? ''} ${s['nis'] ?? ''}'.toLowerCase().contains(_qS);
    }).toList();
    l.sort((a, b) => (a['nama'] ?? '').toString().toLowerCase().compareTo((b['nama'] ?? '').toString().toLowerCase()));
    return _sortAz ? l : l.reversed.toList();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving || _santris.isEmpty) return;

    final tanggal = _editTanggal ?? _iso(DateTime.now());
    final items = <Map<String, dynamic>>[];
    for (final s in _santris) {
      final id = s['id'] as String;
      final raw = _ctrl[id]!.text.trim();
      if (raw.isEmpty) continue;
      final v = _val(id);
      if (v == null) {
        setState(() => _error = 'Nilai ${s['nama']} tidak valid (harus 0-100).');
        return;
      }
      final cat = (_catatan[id] ?? '').trim();
      items.add({
        'santriId': id,
        'nilai': v,
        if (cat.isNotEmpty) 'catatan': cat,
      });
    }
    if (items.isEmpty) {
      setState(() => _error = 'Belum ada nilai yang diisi.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    // Dihitung dulu di luar string supaya tidak ada tanda kutip bersarang.
    final namaMapel = _nameOf(_mapel, _mapelId, 'namaMapel');
    final modeEdit = _editTanggal != null;

    try {
      final api = AppScope.of(context).api;
      // Satu request, satu transaksi: semua tersimpan atau tidak sama sekali.
      await api.post('${ApiUrl.nilai}/bulk', {
        'mapelId': _mapelId,
        'jenis': _jenis,
        if (_pakaiSkill) 'skill': _skill,
        'tanggal': tanggal,
        'items': items,
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editTanggal = null;
        for (final c in _ctrl.values) {
          c.clear(); // Input kosong lagi
        }
        _catatan.clear();
        // sesi hari ini -> List, sesi tanggal lama -> Riwayat
        _tab = tanggal == _iso(DateTime.now()) ? 1 : 2;
      });
      _toast(
        modeEdit ? 'Perubahan nilai disimpan' : 'Nilai berhasil disimpan',
        subtitle: '${items.length} santri • $_jenisLabel • $namaMapel',
      );
      _loadRiwayat();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        e is ApiException ? e.message : 'Gagal menyimpan nilai.',
        error: true,
      );
    }
  }

  /// Isi Input dengan nilai satu sesi, lalu buka tab Input dalam mode ubah.
  void _mulaiUbah(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return;
    final first = rows.first;
    final sk = (first['skill'] ?? '').toString();
    setState(() {
      for (final c in _ctrl.values) {
        c.clear();
      }
      _catatan.clear();
      _editTanggal = _tgl10(first['tanggal']);
      if (_kSkill.any((e) => e.key == sk)) _skill = sk;
      for (final r in rows) {
        final id = r['santriId'].toString();
        final n = r['nilai'];
        if (n is num) _ctrl[id]?.text = _fmt(n.toDouble());
        final k = (r['keterangan'] ?? r['catatan'] ?? '').toString().trim();
        if (k.isNotEmpty) _catatan[id] = k;
      }
      _tab = 0;
    });
  }

  void _batalUbah() {
    setState(() {
      _editTanggal = null;
      for (final c in _ctrl.values) {
        c.clear();
      }
      _catatan.clear();
      _tab = 1;
    });
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
    // Banner ada di bawah hero, jadi gulir ke atas supaya kelihatan.
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
  // Bottom sheets
  // ---------------------------------------------------------------------
  Future<void> _showPicker({
    required String title,
    required List<MapEntry<String, String>> items,
    required String? selectedId,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: SC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: sty(15, FontWeight.w800, SC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in items)
                    ListTile(
                      title: Text(it.value,
                          style: sty(14, it.key == selectedId ? FontWeight.w800 : FontWeight.w500, SC.ink)),
                      trailing:
                          it.key == selectedId ? Icon(Icons.check_circle, color: SC.primary, size: 20) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelect(it.key);
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

  Future<void> _editCatatan(String id, String nama) async {
    final res = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CatatanSheet(
        title: 'Catatan Lisan • $nama',
        initial: _catatan[id] ?? '',
      ),
    );
    if (res == null || !mounted) return;
    setState(() {
      final t = res.trim();
      if (t.isEmpty) {
        _catatan.remove(id);
      } else {
        _catatan[id] = t;
      }
    });
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero(List<double> vals) {
    final n = DateTime.now();
    final mulai = n.month >= 7 ? n.year : n.year - 1;
    final avg = vals.isEmpty ? null : vals.reduce((a, b) => a + b) / vals.length;
    final mx = vals.isEmpty ? null : vals.reduce((a, b) => a > b ? a : b);
    final mn = vals.isEmpty ? null : vals.reduce((a, b) => a < b ? a : b);
    String f(double? v) => v == null ? '–' : _fmt(v);

    final ket = _tab == 0
        ? 'Statistik isian saat ini'
        : (_tab == 1 ? 'Statistik nilai hari ini' : 'Statistik semua sesi');

    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white.withOpacity(0.7)),
              const SizedBox(height: 5),
              Text(value, style: sty(20, FontWeight.w800, Colors.white, h: 1.1)),
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
                child: const Icon(Icons.grading_rounded, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penilaian Santri', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      'T.A. $mulai/${mulai + 1} • Skala 0 - 100',
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
                stat(Icons.functions_rounded, f(avg), 'Rata-rata'),
                garis(),
                stat(Icons.trending_up_rounded, f(mx), 'Tertinggi'),
                garis(),
                stat(Icons.trending_down_rounded, f(mn), 'Terendah'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(ket, style: sty(11, FontWeight.w600, Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: child,
    );
  }

  /// Kontrol segmen Input / List / Riwayat.
  Widget _tabs() {
    Widget item(int i, IconData icon, String label) {
      final on = _tab == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _tab = i);
            if (i != 0) _loadRiwayat();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? SC.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: on ? Colors.white : SC.inkSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12, FontWeight.w700, on ? Colors.white : SC.inkSecondary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SC.surfaceDim,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SC.border),
      ),
      child: Row(children: [
        if (!_readOnly) item(0, Icons.edit_note_rounded, 'Input'),
        item(1, Icons.list_alt_rounded, 'List'),
        item(2, Icons.history_rounded, 'Riwayat'),
      ]),
    );
  }

  String _nameOf(List<Map<String, dynamic>> list, String? id, String key) {
    if (id == null) return '-';
    for (final e in list) {
      if (e['id'] == id) return e[key]?.toString() ?? '-';
    }
    return '-';
  }

  String get _jenisLabel => _kJenis.firstWhere((e) => e.key == _jenis).value;

  Widget _pickerRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 19, color: SC.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: sty(10, FontWeight.w700, SC.inkSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(14.5, FontWeight.w800, SC.ink)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: SC.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ganti', style: sty(11.5, FontWeight.w700, SC.primary)),
                  const SizedBox(width: 2),
                  Icon(Icons.unfold_more_rounded, size: 14, color: SC.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: SC.border),
      );

  Widget _paramCard() {
    return _card(
      child: Column(
        children: [
          _pickerRow(
            icon: Icons.groups_2_outlined,
            label: 'KELAS',
            value: _nameOf(_kelas, _kelasId, 'namaKelas'),
            onTap: _kelas.isEmpty
                ? null
                : () => _showPicker(
                      title: 'Pilih Kelas',
                      items: [for (final k in _kelas) MapEntry(k['id'] as String, '${k['namaKelas']}')],
                      selectedId: _kelasId,
                      onSelect: (v) {
                        setState(() {
                          _kelasId = v;
                          _selaraskanMapel();
                        });
                        _loadSantri(); // sudah memuat riwayat di dalamnya
                      },
                    ),
          ),
          _divider(),
          _pickerRow(
            icon: Icons.menu_book_outlined,
            label: 'MATA PELAJARAN',
            value: _nameOf(_mapel, _mapelId, 'namaMapel'),
            onTap: _mapelTersedia.isEmpty
                ? null
                : () => _showPicker(
                      title: 'Pilih Mata Pelajaran',
                      items: [for (final m in _mapelTersedia) MapEntry(m['id'] as String, '${m['namaMapel']}')],
                      selectedId: _mapelId,
                      onSelect: (v) {
                        setState(() => _mapelId = v);
                        _paramBerubah();
                      },
                    ),
          ),
          _divider(),
          _pickerRow(
            icon: Icons.fact_check_outlined,
            label: 'JENIS PENILAIAN',
            value: _jenisLabel,
            onTap: () => _showPicker(
              title: 'Pilih Jenis Penilaian',
              items: _kJenis,
              selectedId: _jenis,
              onSelect: (v) {
                setState(() => _jenis = v);
                _paramBerubah();
              },
            ),
          ),
          if (_pakaiSkill) ...[
            _divider(),
            _pickerRow(
              icon: Icons.translate_rounded,
              label: 'SKILL',
              value: _skillLabel,
              onTap: () => _showPicker(
                title: 'Pilih Skill',
                items: _kSkill,
                selectedId: _skill,
                onSelect: (v) {
                  setState(() => _skill = v);
                  _paramBerubah();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kolom cari santri (nama / NIS) untuk tab Input dan List.
  Widget _searchSantri() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _cariS,
        onChanged: (v) => setState(() => _qS = v.trim().toLowerCase()),
        textInputAction: TextInputAction.search,
        style: sty(14, FontWeight.w600, SC.ink),
        decoration: InputDecoration(
          hintText: 'Cari nama atau NIS santri',
          hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
          prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
          suffixIcon: _qS.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                  onPressed: () {
                    _cariS.clear();
                    setState(() => _qS = '');
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
    );
  }

  Widget _listHeader(int total, bool adaIsian) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(children: [
            Text('Daftar Santri', style: sty(15, FontWeight.w800, SC.ink)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
              child: Text('$total', style: sty(10.5, FontWeight.w800, SC.primary)),
            ),
          ]),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: adaIsian ? 1 : 0.4,
              child: InkWell(
                onTap: adaIsian ? _quickAdd : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SC.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SC.primary.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 14, color: SC.primary),
                      const SizedBox(width: 4),
                      Text('+2 Cepat', style: sty(11, FontWeight.w800, SC.primary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _sortAz = !_sortAz),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 16, color: SC.goldDark),
                  const SizedBox(width: 4),
                  Text(_sortAz ? 'A-Z' : 'Z-A', style: sty(12, FontWeight.w700, SC.goldDark)),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatar(String nama, int index) {
    final even = index.isEven;
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: even ? SC.sage : SC.goldSurface, shape: BoxShape.circle),
      child: Text(inisial, style: sty(17, FontWeight.w800, even ? SC.primary : SC.gold)),
    );
  }

  Widget _badge(double? v) {
    if (v == null) return const SizedBox.shrink();
    final p = _predikat(v);
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 14, color: p.fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(p.label, style: sty(11.5, FontWeight.w700, p.fg, h: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 24,
        decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: SC.ink),
      ),
    );
  }

  Widget _santriCard(int index, Map<String, dynamic> s) {
    final id = s['id'] as String;
    final nama = (s['nama'] ?? '-').toString().trim();
    final nis = s['nis']?.toString() ?? '-';
    final cat = (_catatan[id] ?? '').trim();
    final v = _val(id);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(nama, index),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(15, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 2),
                    Text('NIS: $nis', style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _badge(v),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nilai Akhir', style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
              Text('Catatan Lisan', style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 52,
                child: TextField(
                  controller: _ctrl[id],
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  onChanged: (_) => setState(() {}),
                  style: sty(20, FontWeight.w700, SC.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: SC.surfaceDim,
                    hintText: '-',
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: SC.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stepBtn(Icons.keyboard_arrow_up_rounded, () => _step(id, 1)),
                  const SizedBox(height: 4),
                  _stepBtn(Icons.keyboard_arrow_down_rounded, () => _step(id, -1)),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _editCatatan(id, nama),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: SC.goldDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.isEmpty ? 'Tambah catatan' : cat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sty(13, FontWeight.w500, cat.isEmpty ? SC.inkSecondary : SC.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: SC.errorBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: SC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: sty(12.5, FontWeight.w500, SC.errorText, h: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner(String text, {VoidCallback? onBatal}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: SC.goldSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: SC.goldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: sty(12.5, FontWeight.w600, SC.goldDark, h: 1.35)),
          ),
          if (onBatal != null)
            TextButton(
              onPressed: onBatal,
              child: Text('Batal', style: sty(13, FontWeight.w800, SC.goldDark)),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(int filled, int total) {
    final pct = total > 0 ? (filled / total * 100).round() : 0;
    final labelSimpan = _saving
        ? 'Menyimpan...'
        : (_editTanggal != null ? 'Simpan Perubahan' : 'Simpan Nilai');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.circle, size: 8, color: SC.gold),
                  const SizedBox(width: 6),
                  Text('Status Isian', style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                ]),
                const SizedBox(height: 2),
                Text('$filled / $total Nilai Terisi ($pct%)',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(14, FontWeight.w800, SC.ink)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: SC.primary,
                disabledBackgroundColor: SC.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      _editTanggal != null ? Icons.edit_outlined : Icons.cloud_upload_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
              label: Text(labelSimpan, style: sty(14, FontWeight.w700, Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// Bar bawah di tab List: nilai sudah tersimpan, tombol untuk mengubah.
  Widget _ubahBar(int total) {
    final filled = _sesiHariIni.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: SC.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nilai sudah tersimpan', style: sty(13, FontWeight.w800, SC.ink)),
                const SizedBox(height: 2),
                Text('$filled / $total santri dinilai', style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _mulaiUbah(_sesiHariIni),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('Ubah Nilai', style: sty(13, FontWeight.w700, SC.primary)),
            style: OutlinedButton.styleFrom(
              foregroundColor: SC.primary,
              side: BorderSide(color: SC.border),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Helper tanggal / label
  // ---------------------------------------------------------------------
  String _tgl10(dynamic t) {
    final s = (t ?? '').toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _fmtTgl(String iso) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final p = iso.split('-');
    if (p.length != 3) return iso;
    final m = int.tryParse(p[1]) ?? 0;
    return '${int.tryParse(p[2]) ?? p[2]} ${m >= 1 && m <= 12 ? bln[m] : p[1]} ${p[0]}';
  }

  String _hari(String iso) {
    const h = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final d = DateTime.tryParse(iso);
    return d == null ? '' : h[d.weekday - 1];
  }

  String _jenisLabelOf(dynamic r) {
    final j = (r['jenis'] ?? '').toString();
    final base = _kJenis.firstWhere((e) => e.key == j, orElse: () => MapEntry(j, j)).value;
    final sk = (r['skill'] ?? '').toString();
    if (sk.isEmpty) return base;
    final skLabel = _kSkill.firstWhere((e) => e.key == sk, orElse: () => MapEntry(sk, sk)).value;
    return '$base • $skLabel';
  }

  // ---------------------------------------------------------------------
  // Tab List: nilai sesi hari ini (dibaca dari data tersimpan)
  // ---------------------------------------------------------------------
  List<Widget> _listTab(List<Map<String, dynamic>> sorted) {
    final rows = _sesiHariIni;
    if (rows.isEmpty) {
      return [
        emptyView('Belum ada nilai hari ini untuk pilihan di atas.'),
        if (!_readOnly) ...[
          const SizedBox(height: 12),
          Center(
            child: FilledButton.icon(
              onPressed: () => setState(() => _tab = 0),
              icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
              label: Text('Input Nilai', style: sty(13, FontWeight.w700, Colors.white)),
              style: FilledButton.styleFrom(
                backgroundColor: SC.primary,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ],
      ];
    }
    if (sorted.isEmpty) return [emptyView('Tidak ada santri yang cocok.')];
    final byId = {for (final r in rows) r['santriId'].toString(): r};
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Nilai Hari Ini', style: sty(15, FontWeight.w800, SC.ink)),
          Text('$_jenisLabel • ${_fmtTgl(_iso(DateTime.now()))}',
              style: sty(11, FontWeight.w500, SC.inkSecondary)),
        ],
      ),
      const SizedBox(height: 10),
      for (int i = 0; i < sorted.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _listCard(i, sorted[i], byId[sorted[i]['id'].toString()]),
        ),
    ];
  }

  Widget _listCard(int index, Map<String, dynamic> s, Map<String, dynamic>? r) {
    final nama = (s['nama'] ?? '-').toString().trim();
    final nis = s['nis']?.toString() ?? '-';
    final cat = (r?['keterangan'] ?? r?['catatan'] ?? '').toString().trim();
    final v = (r?['nilai'] as num?)?.toDouble();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(nama, index),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(15, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 2),
                    Text('NIS: $nis', style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (v == null)
                Text('Belum dinilai',
                    style: TextStyle(
                        fontSize: 12, fontStyle: FontStyle.italic, color: SC.inkSecondary))
              else
                Text(_fmt(v), style: sty(24, FontWeight.w800, SC.primary)),
            ],
          ),
          if (v != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _badge(v),
                if (cat.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Ket: $cat',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.3)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tab Riwayat: cari + urutan + kartu per sesi
  // ---------------------------------------------------------------------
  Widget _filterPill<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<MapEntry<T, String>> options,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      color: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(
            value: o.key,
            child: Text(o.value,
                style: sty(13, o.key == value ? FontWeight.w800 : FontWeight.w600,
                    o.key == value ? SC.primary : SC.inkSecondary)),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: SC.inkSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(12, FontWeight.w700, SC.primary)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: SC.inkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom cari: gaya sama dengan halaman Ustadz
        SizedBox(
          height: 48,
          child: TextField(
            controller: _cari,
            onChanged: (v) => setState(() => _cariQ = v.trim().toLowerCase()),
            textInputAction: TextInputAction.search,
            style: sty(14, FontWeight.w600, SC.ink),
            decoration: InputDecoration(
              hintText: 'Cari nama santri atau tanggal',
              hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
              prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
              suffixIcon: _cariQ.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                      onPressed: () {
                        _cari.clear();
                        setState(() => _cariQ = '');
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
        const SizedBox(height: 10),
        _filterPill<bool>(
          label: _terbaru ? 'Urutkan: Terbaru' : 'Urutkan: Terlama',
          icon: Icons.swap_vert_rounded,
          value: _terbaru,
          options: const [
            MapEntry(true, 'Terbaru'),
            MapEntry(false, 'Terlama'),
          ],
          onSelected: (v) => setState(() => _terbaru = v),
        ),
      ],
    );
  }

  List<Widget> _riwayatList() {
    final q = _cariQ;
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in _riwayat) {
      final m = Map<String, dynamic>.from(r as Map);
      final tgl = _tgl10(m['tanggal']);
      final key = '$tgl|${m['mapelId']}|${m['jenis']}|${m['skill'] ?? ''}';
      groups.putIfAbsent(key, () => []).add(m);
    }
    final totalSesi = groups.length; // sebelum pencarian
    if (q.isNotEmpty) {
      groups.removeWhere((key, rows) {
        final tgl = _tgl10(rows.first['tanggal']);
        if (_fmtTgl(tgl).toLowerCase().contains(q) || tgl.contains(q)) return false;
        return !rows.any((r) =>
            ((r['santri'] as Map?)?['nama'] ?? '').toString().toLowerCase().contains(q));
      });
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => _terbaru ? b.compareTo(a) : a.compareTo(b));

    return [
      _filterBar(),
      const SizedBox(height: 12),
      if (_riwayat.isEmpty)
        emptyView('Belum ada nilai.')
      else if (keys.isEmpty)
        emptyView('Tidak ada sesi yang cocok.')
      else ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Menampilkan ${keys.length} dari $totalSesi sesi',
              style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
        ),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _sesiCard(groups[k]!),
          ),
      ],
    ];
  }

  Widget _sesiCard(List<Map<String, dynamic>> rows) {
    final first = rows.first;
    final vals = [for (final r in rows) ((r['nilai'] as num?) ?? 0).toDouble()];
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final mapel = (first['mapel'] as Map?)?['namaMapel'] ?? '';

    return _card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _bukaDetail(rows),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
                child: Text(_fmt(avg), style: sty(15, FontWeight.w800, SC.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$mapel • ${_jenisLabelOf(first)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(14, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 2),
                    Text('${_fmtTgl(_tgl10(first['tanggal']))} • ${rows.length} santri • rata-rata ${_fmt(avg)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: SC.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Halaman detail sesi
  // ---------------------------------------------------------------------
  void _bukaDetail(List<Map<String, dynamic>> rows) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _detailPage(rows)));
  }

  Widget _ringkasTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: sty(12, FontWeight.w600, Colors.white.withOpacity(0.85))),
            const SizedBox(height: 4),
            Text(value, style: sty(26, FontWeight.w800, Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _detailPage(List<Map<String, dynamic>> rows) {
    final first = rows.first;
    final tgl = _tgl10(first['tanggal']);
    final mapel = (first['mapel'] as Map?)?['namaMapel'] ?? '';
    final kelas = _nameOf(_kelas, _kelasId, 'namaKelas');
    final nisById = {
      for (final s in _santris) s['id'].toString(): (s['nis']?.toString() ?? '-'),
    };
    double nilaiOf(Map<String, dynamic> r) => ((r['nilai'] as num?) ?? 0).toDouble();

    final vals = [for (final r in rows) nilaiOf(r)];
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final mx = vals.reduce((a, b) => a > b ? a : b);
    final mn = vals.reduce((a, b) => a < b ? a : b);

    const kunci = ['A', 'B+', 'B', 'C', 'D'];
    const contoh = [95.0, 85.0, 75.0, 65.0, 50.0]; // untuk mengambil warna predikat
    final dist = {for (final k in kunci) k: 0};
    for (final v in vals) {
      final k = _predikat(v).label.split(' / ').last;
      dist[k] = (dist[k] ?? 0) + 1;
    }

    bool desc = true;

    return StatefulBuilder(builder: (ctx, setL) {
      final list = [...rows]
        ..sort((a, b) => desc ? nilaiOf(b).compareTo(nilaiOf(a)) : nilaiOf(a).compareTo(nilaiOf(b)));

      return Scaffold(
        backgroundColor: SC.background,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        // Header
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: SC.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SC.border),
                                ),
                                child: const Icon(Icons.chevron_left_rounded, size: 26, color: SC.ink),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$mapel · ${_jenisLabelOf(first)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(17, FontWeight.w800, SC.ink)),
                                  const SizedBox(height: 2),
                                  Text('$kelas · ${_hari(tgl)}, ${_fmtTgl(tgl)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(12, FontWeight.w500, SC.inkSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Ringkasan sesi
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [SC.primary, SC.primaryEnd],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('RINGKASAN SESI',
                                      style: sty(11, FontWeight.w700, Colors.white.withOpacity(0.75))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: SC.gold.withOpacity(0.7)),
                                    ),
                                    child: Text('${vals.length} santri dinilai',
                                        style: sty(11, FontWeight.w700, SC.gold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _ringkasTile('Rata', _fmt(avg)),
                                  const SizedBox(width: 10),
                                  _ringkasTile('Tertinggi', _fmt(mx)),
                                  const SizedBox(width: 10),
                                  _ringkasTile('Terendah', _fmt(mn)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text('Sebaran predikat',
                                  style: sty(12, FontWeight.w500, Colors.white.withOpacity(0.8))),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  height: 10,
                                  child: Row(
                                    children: [
                                      for (int i = 0; i < kunci.length; i++)
                                        if (dist[kunci[i]]! > 0)
                                          Expanded(
                                            flex: dist[kunci[i]]!,
                                            child: Container(color: _predikat(contoh[i]).bg),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (final k in kunci)
                                    Text('$k·${dist[k]}',
                                        style: sty(11, FontWeight.w700, Colors.white.withOpacity(0.85))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Judul + urutan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nilai per Santri', style: sty(15, FontWeight.w800, SC.ink)),
                            InkWell(
                              onTap: () => setL(() => desc = !desc),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(children: [
                                  Icon(Icons.swap_vert_rounded, size: 16, color: SC.goldDark),
                                  const SizedBox(width: 4),
                                  Text(desc ? 'Nilai tertinggi' : 'Nilai terendah',
                                      style: sty(12, FontWeight.w700, SC.goldDark)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Kartu per santri
                        for (int i = 0; i < list.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Builder(builder: (_) {
                              final r = list[i];
                              final nama = ((r['santri'] as Map?)?['nama'] ?? '-').toString().trim();
                              final nis = nisById[r['santriId'].toString()] ?? '-';
                              final cat = (r['keterangan'] ?? r['catatan'] ?? '').toString().trim();
                              final v = nilaiOf(r);
                              return _card(
                                child: Row(
                                  children: [
                                    _avatar(nama, i),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(nama,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: sty(15, FontWeight.w800, SC.ink)),
                                          const SizedBox(height: 2),
                                          Text('NIS $nis', style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
                                          if (cat.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(children: [
                                              Icon(Icons.edit_outlined, size: 12, color: SC.goldDark),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(cat,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: sty(12, FontWeight.w500, SC.goldDark)),
                                              ),
                                            ]),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(_fmt(v), style: sty(24, FontWeight.w800, SC.ink)),
                                        const SizedBox(height: 4),
                                        _badge(v),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),

                  // Bar bawah
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: SC.surface,
                      border: Border(top: BorderSide(color: SC.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sesi ${_fmtTgl(tgl)}', style: sty(14, FontWeight.w800, SC.ink)),
                              const SizedBox(height: 2),
                              Text(
                                  _readOnly
                                      ? 'Mode pantau, hanya bisa dilihat'
                                      : 'Hanya guru pengampu yang bisa mengubah',
                                  style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                            ],
                          ),
                        ),
                        if (!_readOnly) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _mulaiUbah(rows);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text('Ubah Nilai', style: sty(13.5, FontWeight.w700, SC.primary)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SC.primary,
                              side: BorderSide(color: SC.border),
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final total = _santris.length;
    final vals = <double>[
      for (final s in _santris)
        if (_val(s['id'] as String) != null) _val(s['id'] as String)!,
    ];
    final filled = vals.length;
    final sorted = _sorted;

    // Statistik di hero mengikuti tab yang sedang dibuka.
    final List<double> heroVals;
    if (_tab == 0) {
      heroVals = vals;
    } else if (_tab == 1) {
      heroVals = [for (final r in _sesiHariIni) ((r['nilai'] as num?) ?? 0).toDouble()];
    } else {
      heroVals = [for (final r in _riwayat) (((r as Map)['nilai'] as num?) ?? 0).toDouble()];
    }

    return Scaffold(
      backgroundColor: SC.background,
      body: _loadingMeta
          ? loadingView()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        children: [
                          _hero(heroVals),
                          _banner(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _tabs(),
                                const SizedBox(height: 14),
                                _paramCard(),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  _errorBox(_error!),
                                ],
                                const SizedBox(height: 14),
                                if (!_loadingSantri && total > 0 && _tab != 2) ...[
                                  _searchSantri(),
                                  const SizedBox(height: 12),
                                ],
                                if (_loadingSantri)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(child: CircularProgressIndicator(color: SC.primary)),
                                  )
                                else if (total == 0)
                                  emptyView('Kelas ini belum punya santri.')
                                else if (_tab == 0) ...[
                                  if (_editTanggal != null) ...[
                                    _infoBanner('Mengubah nilai sesi ${_fmtTgl(_editTanggal!)}',
                                        onBatal: _batalUbah),
                                    const SizedBox(height: 12),
                                  ] else if (_adaTersimpan) ...[
                                    _infoBanner(
                                        'Nilai hari ini untuk pilihan ini sudah ada. Menyimpan lagi bisa menimpa nilai santri yang sama. Untuk mengubah, pakai Ubah Nilai di tab List.'),
                                    const SizedBox(height: 12),
                                  ],
                                  _listHeader(sorted.length, filled > 0),
                                  const SizedBox(height: 10),
                                  if (sorted.isEmpty)
                                    emptyView('Tidak ada santri yang cocok.')
                                  else
                                    for (int i = 0; i < sorted.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _santriCard(i, sorted[i]),
                                      ),
                                ] else if (_tab == 1)
                                  ..._listTab(sorted)
                                else
                                  ..._riwayatList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_readOnly && _tab == 0 && !_loadingSantri && total > 0)
                      _bottomBar(filled, total),
                    if (!_readOnly && _tab == 1 && !_loadingSantri && _adaTersimpan)
                      _ubahBar(total),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet catatan lisan
// ---------------------------------------------------------------------
class _CatatanSheet extends StatefulWidget {
  final String title;
  final String initial;

  const _CatatanSheet({required this.title, required this.initial});

  @override
  State<_CatatanSheet> createState() => _CatatanSheetState();
}

class _CatatanSheetState extends State<_CatatanSheet> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(15, FontWeight.w800, SC.ink)),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                autofocus: true,
                maxLength: _kMaxCatatan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: sty(14, FontWeight.w500, SC.ink),
                decoration: InputDecoration(
                  hintText: 'Contoh: Pelafalan makhraj sudah baik',
                  hintStyle: sty(13, FontWeight.w500, SC.inkSecondary),
                  filled: true,
                  fillColor: SC.surfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: SC.primary, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.initial.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: Text('Hapus', style: sty(13, FontWeight.w700, SC.errorText)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _c.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: SC.primary,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text('Simpan', style: sty(14, FontWeight.w700, Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}