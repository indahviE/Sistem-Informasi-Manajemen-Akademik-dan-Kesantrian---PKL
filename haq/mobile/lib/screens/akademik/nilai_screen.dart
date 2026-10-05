import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet sama dengan `_AC` di absensi_screen.dart.
/// Warna utama (primary, mint, sage) ikut tema pondok yang diatur admin.
class _NC {
  _NC._();

  // Ikut tema pondok (diatur admin).
  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

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

const _kMaxCatatan = 150;

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  List<Map<String, dynamic>> _santris = [];
  String? _kelasId;
  String? _mapelId;
  String _jenis = 'HARIAN';

  final Map<String, TextEditingController> _ctrl = {}; // santriId -> nilai
  final Map<String, String> _catatan = {}; // santriId -> catatan lisan

  List<dynamic> _riwayat = [];
  int _tab = 0; // 0 = input, 1 = riwayat
  bool _sortAz = true;
  bool _loadingMeta = true;
  bool _loadingSantri = false;
  bool _saving = false;
  int _seq = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
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
    String? err;
    try {
      _kelas = _asList(await api.get(ApiUrl.kelas));
    } catch (_) {
      err = 'Gagal memuat daftar kelas.';
    }
    try {
      _mapel = _asList(await api.get(ApiUrl.mapel));
    } catch (_) {
      err ??= 'Gagal memuat daftar mapel.';
    }
    if (!mounted) return;
    setState(() {
      _loadingMeta = false;
      _error = err;
      if (_kelas.isNotEmpty) _kelasId = _kelas.first['id'] as String;
      if (_mapel.isNotEmpty) _mapelId = _mapel.first['id'] as String;
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
        for (final s in list) {
          _ctrl[s['id'] as String] = TextEditingController();
        }
        _loadingSantri = false;
      });
      if (_tab == 1) _loadRiwayat();
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

  Future<void> _loadRiwayat() async {
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.nilai, query: {
        if (_mapelId != null) 'mapelId': _mapelId!,
        'jenis': _jenis,
      });
      if (!mounted) return;
      final ids = _santris.map((e) => e['id']).toSet();
      setState(() {
        _riwayat = _asList(res).where((r) => ids.contains(r['santriId'])).toList();
      });
    } catch (_) {}
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

  List<Map<String, dynamic>> get _sorted {
    final l = [..._santris];
    l.sort((a, b) => (a['nama'] ?? '').toString().toLowerCase().compareTo((b['nama'] ?? '').toString().toLowerCase()));
    return _sortAz ? l : l.reversed.toList();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_saving || _santris.isEmpty) return;

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
        'mapelId': _mapelId,
        'jenis': _jenis,
        'nilai': v,
        'tanggal': _iso(DateTime.now()),
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
    try {
      final api = AppScope.of(context).api;
      await Future.wait(items.map((e) => api.post(ApiUrl.nilai, e)));
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${items.length} nilai disimpan.')));
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (mounted) setState(() {
        _saving = false;
        _error = 'Gagal menyimpan nilai.';
      });
    }
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
      backgroundColor: _NC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in items)
                    ListTile(
                      title: Text(it.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: it.key == selectedId ? FontWeight.w800 : FontWeight.w500,
                            color: _NC.ink,
                          )),
                      trailing: it.key == selectedId
                          ? Icon(Icons.check_circle, color: _NC.primary, size: 20)
                          : null,
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
      backgroundColor: _NC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _NC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _NC.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _tabs() {
    Widget item(int i, IconData icon, String label) {
      final on = _tab == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _tab = i);
            if (i == 1) _loadRiwayat();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? _NC.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: on ? Colors.white : _NC.inkSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : _NC.inkSecondary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _NC.surfaceDim, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        item(0, Icons.edit_note_rounded, 'Input Nilai Aktif'),
        item(1, Icons.history_rounded, 'Riwayat Nilai'),
      ]),
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: _NC.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _NC.ink)),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: _NC.ink),
              ],
            ),
          ),
        ),
      ],
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

  Widget _paramCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.tune_rounded, size: 16, color: _NC.goldDark),
                SizedBox(width: 6),
                Text('PARAMETER PENILAIAN',
                    style: TextStyle(
                        fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: _NC.goldDark)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFCD98B), borderRadius: BorderRadius.circular(999)),
                child: const Text('Skala: 0 - 100',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _NC.goldDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _selectField(
                  label: 'Rombel / Kelas',
                  value: _nameOf(_kelas, _kelasId, 'namaKelas'),
                  onTap: _kelas.isEmpty
                      ? null
                      : () => _showPicker(
                            title: 'Pilih Kelas',
                            items: [for (final k in _kelas) MapEntry(k['id'] as String, '${k['namaKelas']}')],
                            selectedId: _kelasId,
                            onSelect: (v) {
                              setState(() => _kelasId = v);
                              _loadSantri();
                            },
                          ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _selectField(
                  label: 'Mata Pelajaran',
                  value: _nameOf(_mapel, _mapelId, 'namaMapel'),
                  onTap: _mapel.isEmpty
                      ? null
                      : () => _showPicker(
                            title: 'Pilih Mata Pelajaran',
                            items: [for (final m in _mapel) MapEntry(m['id'] as String, '${m['namaMapel']}')],
                            selectedId: _mapelId,
                            onSelect: (v) {
                              setState(() => _mapelId = v);
                              if (_tab == 1) _loadRiwayat();
                            },
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _selectField(
            label: 'Jenis Penilaian',
            value: _jenisLabel,
            onTap: () => _showPicker(
              title: 'Pilih Jenis Penilaian',
              items: _kJenis,
              selectedId: _jenis,
              onSelect: (v) {
                setState(() => _jenis = v);
                if (_tab == 1) _loadRiwayat();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _statsCard(List<double> vals) {
    final avg = vals.isEmpty ? null : vals.reduce((a, b) => a + b) / vals.length;
    final mx = vals.isEmpty ? null : vals.reduce((a, b) => a > b ? a : b);
    final mn = vals.isEmpty ? null : vals.reduce((a, b) => a < b ? a : b);
    String f(double? v) => v == null ? '-' : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_NC.primary, _NC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _NC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik Kelas Saat Ini',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 6),
          Row(
            children: [
              _stat('Rata:', f(avg)),
              _stat('Max:', f(mx)),
              _stat('Min:', f(mn)),
              InkWell(
                onTap: vals.isEmpty ? null : _quickAdd,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                      SizedBox(width: 6),
                      Text('+2\nCepat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listHeader(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(children: [
            const Text('Daftar Santri',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _NC.ink)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _NC.surfaceDim, borderRadius: BorderRadius.circular(999)),
              child: Text('$total Santri Ditampilkan',
                  style: const TextStyle(fontSize: 10.5, color: _NC.inkSecondary)),
            ),
          ]),
        ),
        InkWell(
          onTap: () => setState(() => _sortAz = !_sortAz),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              Icon(_sortAz ? Icons.sort_by_alpha_rounded : Icons.sort_by_alpha_rounded,
                  size: 16, color: _NC.goldDark),
              const SizedBox(width: 4),
              Text(_sortAz ? 'Urut Abjad' : 'Urut Z-A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _NC.goldDark)),
            ]),
          ),
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
      decoration: BoxDecoration(color: even ? _NC.sage : _NC.goldSurface, shape: BoxShape.circle),
      child: Text(inisial,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: even ? _NC.primary : _NC.gold)),
    );
  }

  Widget _badge(double? v) {
    if (v == null) return const SizedBox.shrink();
    final p = _predikat(v);
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 14, color: p.fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(p.label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.fg, height: 1.2)),
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
        decoration: BoxDecoration(color: _NC.surfaceDim, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: _NC.ink),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NC.ink)),
                    const SizedBox(height: 2),
                    Text('NIS: $nis',
                        style: const TextStyle(fontSize: 12.5, color: _NC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _badge(v),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nilai Akhir', style: TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
              Text('Catatan Lisan', style: TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _NC.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _NC.surfaceDim,
                    hintText: '-',
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _NC.surfaceDim, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 18, color: _NC.goldDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.isEmpty ? 'Tambah catatan' : cat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: cat.isEmpty ? _NC.inkSecondary : _NC.ink,
                            ),
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
      decoration: BoxDecoration(color: _NC.errorBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: _NC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(fontSize: 12.5, color: _NC.errorText, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(int filled, int total) {
    final pct = total > 0 ? (filled / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: _NC.surface,
        border: Border(top: BorderSide(color: _NC.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.circle, size: 8, color: _NC.gold),
                  SizedBox(width: 6),
                  Text('Status Isian', style: TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
                ]),
                const SizedBox(height: 2),
                Text('$filled / $total Nilai Terisi ($pct%)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _NC.ink)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _NC.primary,
                disabledBackgroundColor: _NC.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.white),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Nilai',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Riwayat
  // ---------------------------------------------------------------------
  List<Widget> _riwayatList() {
    if (_riwayat.isEmpty) return [emptyView('Belum ada nilai.')];
    return [
      for (final r in _riwayat)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _card(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _NC.sage, shape: BoxShape.circle),
                  child: Text(((r['nilai'] as num?) ?? 0).toStringAsFixed(0),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _NC.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(r['santri'] as Map?)?['nama'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _NC.ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${(r['mapel'] as Map?)?['namaMapel'] ?? ''} • ${r['jenis']} • ${(r['tanggal'] as String? ?? '').padRight(10).substring(0, 10).trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _NC.inkSecondary),
                      ),
                    ],
                  ),
                ),
                _badge(((r['nilai'] as num?) ?? 0).toDouble()),
              ],
            ),
          ),
        ),
    ];
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

    return Scaffold(
      backgroundColor: _NC.background,
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
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        children: [
                          _tabs(),
                          const SizedBox(height: 14),
                          _paramCard(),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _errorBox(_error!),
                          ],
                          const SizedBox(height: 14),
                          if (_loadingSantri)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator(color: _NC.primary)),
                            )
                          else if (total == 0)
                            emptyView('Kelas ini belum punya santri.')
                          else if (_tab == 0) ...[
                            _statsCard(vals),
                            const SizedBox(height: 16),
                            _listHeader(total),
                            const SizedBox(height: 10),
                            for (int i = 0; i < sorted.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _santriCard(i, sorted[i]),
                              ),
                          ] else
                            ..._riwayatList(),
                        ],
                      ),
                    ),
                    if (_tab == 0 && !_loadingSantri && total > 0) _bottomBar(filled, total),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NC.ink)),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                autofocus: true,
                maxLength: _kMaxCatatan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: _NC.ink),
                decoration: InputDecoration(
                  hintText: 'Contoh: Pelafalan makhraj sudah baik',
                  hintStyle: const TextStyle(fontSize: 13, color: _NC.inkSecondary),
                  filled: true,
                  fillColor: _NC.surfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.initial.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('Hapus',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _NC.errorText)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _c.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: _NC.primary,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Simpan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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