import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// Halaman Input Nilai (mandiri: tidak bergantung pada file ujian lain).
//
// Alur: Tahap 1 pilih santri -> Tahap 2 input nilai.
// Remedial dikerjakan di halaman tersendiri.
//
// Catatan kunci: saat ujian terkunci, layar TIDAK lagi memblokir input.
// Backend yang memutuskan boleh/tidaknya (mis. nilai susulan santri
// sakit/izin/alpa). Pesan penolakan dari backend ditampilkan apa adanya.

class _C {
  // Ikut tema pondok (diatur admin).
  static Color get emerald => SC.primary;

  static const gold = Color(0xFFC5A059);
  static const goldSoft = Color(0xFFFAF5EC);
  static const goldChip = Color(0xFFFDEFD3);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldText = Color(0xFF775A19);
  static const ivory = Color(0xFFFAF9F5);
  static const border = Color(0xFFEAE6DC);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF475569);
  static const chipGray = Color(0xFFEFEEEA);
  static const fieldFill = Color(0xFFF5F4EE);

  static const okBg = Color(0xFFE8F5E9);
  static const okFg = Color(0xFF1B5E20);
  static const okBd = Color(0xFFC8E6C9);
  static const badBg = Color(0xFFFEE2E2);
  static const badFg = Color(0xFF991B1B);
  static const badBd = Color(0xFFFECACA);
  static const badField = Color(0xFFFFF5F5);
}

const double _maxW = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double _kkmDefault = 75;

const _presets = <int>[70, 75, 80, 85, 90, 100];

BoxDecoration _cardDeco({double radius = 20}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    );

Widget _pill(String text, Color bg, Color fg, {Color? bd, double fs = 10.5, IconData? icon}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: bd == null ? null : Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fs + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: fg, fontSize: fs, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ],
      ),
    );

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

String _initials(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
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
  bool _loading = true;
  String? _error;

  // Tahap 1
  String _query = '';
  bool _showAll = false;
  Map<String, dynamic>? _selected;

  // Tahap 2
  final _nilaiCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  bool _savingNilai = false;
  String _kehadiran = 'HADIR';

  final _step2Key = GlobalKey();

  static const _initialCount = 6;

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
    _nilaiCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────── DATA ─────────────────────────────

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
        _santriAll = santri;
        _loading = false;
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
  double get _kkm =>
      (_ujian['kkm'] is num) ? (_ujian['kkm'] as num).toDouble() : _kkmDefault;

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
    final embedded = _listOf(_data?['santris'] ?? _data?['kelas']?['santris']);
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

  String get _kelasNama => '${_ujian['kelas']?['namaKelas'] ?? ''}';

  double? get _nilaiVal {
    final v = double.tryParse(_nilaiCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // ───────────────────────────── AKSI ─────────────────────────────

  void _select(Map<String, dynamic> s) {
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
    final s = _selected;
    if (s == null) return;

    final hadir = _kehadiran == 'HADIR';
    final v = _nilaiVal;
    if (hadir && v == null) {
      _msg('Masukkan nilai antara 0 – 100.');
      return;
    }
    setState(() => _savingNilai = true);
    try {
      // Tidak ada pemblokiran di sini: kalau ujian terkunci dan backend
      // menolak, ApiException berisi alasannya dan ditampilkan di bawah.
      await AppScope.of(context).api.post('${ApiUrl.ujian}/$_id/nilai', {
        'santriId': s['id'],
        'status': _kehadiran,
        if (hadir) 'nilai': v,
        'catatan': _catCtrl.text.trim(),
      });
      await _load(silent: true);
      if (!mounted) return;
      _msg(!hadir
          ? '${s['nama']} dicatat ${_labelKehadiran(_kehadiran).toLowerCase()} (jalur susulan).'
          : ((v ?? 0) >= _kkm
              ? 'Nilai ${s['nama']} tersimpan.'
              : 'Nilai ${s['nama']} tersimpan (belum tuntas).'));
      _clearSelection();
    } on ApiException catch (e) {
      if (mounted) _msg(e.message);
    } finally {
      if (mounted) setState(() => _savingNilai = false);
    }
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
            constraints: const BoxConstraints(maxWidth: _maxW),
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
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

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
          BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: _C.chipGray, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back, size: 18, color: _C.ink),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Input Nilai',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _C.ink)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        _flowHeader(),
        const SizedBox(height: 12),
        if (_terkunci) ...[_kunciInfo(), const SizedBox(height: 12)],
        _step1(),
        if (_selected != null) ...[
          const SizedBox(height: 12),
          _step2(),
        ],
      ],
    );
  }

  // ── Header ──
  Widget _flowHeader() {
    final nama = '${_ujian['nama'] ?? ''}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.chipGray.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(color: _C.emerald, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alur Input Nilai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.ink)),
                const SizedBox(height: 2),
                Text('Sesi Penilaian $nama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
              ],
            ),
          ),
          if (_kelasNama.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
                child: _pill(_kelasNama, _C.goldChip, _C.goldText, bd: _C.goldBorder, fs: 10)),
          ],
        ],
      ),
    );
  }

  Widget _stepHeader(String tahap, String title, {Widget? trailing}) => Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: _C.goldText, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(tahap,
              style: const TextStyle(
                  color: _C.goldText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _C.ink)),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(child: trailing),
          ],
        ],
      );

  // ── Tahap 1: pilih santri ──
  Widget _step1() {
    final q = _query.trim().toLowerCase();
    final all = _santris;
    final filtered = all.where((s) {
      if (q.isEmpty) return true;
      return '${s['nama']} ${s['nis']}'.toLowerCase().contains(q);
    }).toList();
    final visible = (_showAll || q.isNotEmpty || filtered.length <= _initialCount)
        ? filtered
        : filtered.take(_initialCount).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('TAHAP 1', 'Pilih Santri untuk Dinilai',
              trailing: _selected == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _clearSelection,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 20, color: _C.ink),
                        ),
                      ),
                    )),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 13, color: _C.ink),
            decoration: InputDecoration(
              hintText: 'Cari nama / NIS…',
              hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
              prefixIcon: const Icon(Icons.search, size: 20, color: _C.ink2),
              filled: true,
              fillColor: _C.fieldFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _C.emerald, width: 2)),
            ),
          ),
          const SizedBox(height: 10),
          if (all.isEmpty)
            _emptyHint('Belum ada data santri di kelas ini.')
          else if (filtered.isEmpty)
            _emptyHint('Pastikan kata kunci sesuai nama lengkap atau NIS santri.',
                title: 'Santri tidak ditemukan?')
          else ...[
            for (final s in visible) _santriTile(s),
            if (!_showAll && q.isEmpty && filtered.length > _initialCount)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAll = true),
                  child: Text('Tampilkan semua (${filtered.length})',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.emerald)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _emptyHint(String text, {String? title}) => Container(
        padding: const EdgeInsets.all(12),
        decoration:
            BoxDecoration(color: _C.fieldFill, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.person_search_outlined, size: 18, color: _C.ink2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _C.ink)),
                  Text(text, style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _santriTile(Map<String, dynamic> s) {
    final sel = _selected != null && _selected!['id'] == s['id'];
    final n = _nilaiOf(s['id']);
    final nama = '${s['nama']}';
    final kelas = '${s['kelas']?['namaKelas'] ?? _kelasNama}';

    Widget status;
    if (n != null) {
      final v = n['nilai'] is num ? (n['nilai'] as num).toDouble() : null;
      if (v == null) {
        status = _pill(_labelKehadiran('${n['status']}'), _C.goldChip, _C.goldText,
            bd: _C.goldBorder, fs: 10);
      } else {
        status = v >= _kkm
            ? _pill('Dinilai ${_fmtNum(v)}', _C.okBg, _C.okFg, bd: _C.okBd, fs: 10)
            : _pill('Dinilai ${_fmtNum(v)}', _C.badBg, _C.badFg, bd: _C.badBd, fs: 10);
      }
    } else if (sel) {
      status = _pill('Belum Dinilai', _C.goldChip, _C.goldText, fs: 10);
    } else {
      status = _pill('Siap Dinilai', _C.chipGray, _C.ink2, fs: 10);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _select(s),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sel ? _C.goldSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? _C.goldBorder : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: _C.chipGray, borderRadius: BorderRadius.circular(10)),
                child: Text(_initials(nama),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: _C.ink)),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5, color: _C.ink)),
                        ),
                        if (sel) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_outlined, size: 15, color: _C.emerald),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('NIS: ${s['nis']}${kelas.isEmpty ? '' : ' • $kelas'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              status,
            ],
          ),
        ),
      ),
    );
  }

  // ── Tahap 2: input nilai ──
  Widget _step2() {
    final s = _selected!;
    final v = _nilaiVal;
    final hasText = _nilaiCtrl.text.trim().isNotEmpty;
    final below = v != null && v < _kkm;
    final ok = v != null && v >= _kkm;
    final hadir = _kehadiran == 'HADIR';

    return Container(
      key: _step2Key,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('TAHAP 2', 'Input Nilai Ujian',
              trailing: _pill('${s['nama']}', _C.chipGray, _C.ink2,
                  fs: 10, icon: Icons.person_outline)),
          const SizedBox(height: 16),
          const Text('Kehadiran saat ujian',
              style: TextStyle(fontSize: 12, color: _C.ink2)),
          const SizedBox(height: 8),
          _kehadiranPicker(),
          const SizedBox(height: 14),
          if (!hadir)
            _infoSusulan()
          else ...[
            Row(
              children: [
                const Expanded(
                  child: Text('Nilai Capaian Santri (Skala 0-100)',
                      style: TextStyle(fontSize: 12, color: _C.ink2)),
                ),
                if (below) _pill('Belum Tuntas', _C.badBg, _C.badFg, bd: _C.badBd, fs: 10),
                if (ok)
                  _pill('Tuntas (${_grade(v, _kkm)})', _C.okBg, _C.okFg, bd: _C.okBd, fs: 10),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: below ? _C.badField : _C.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: below ? _C.badBd : Colors.transparent),
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
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: below ? _C.badFg : (ok ? _C.okFg : _C.ink)),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: _C.ink2),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Text('KKM: $_kkmText',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: below ? _C.badFg : _C.ink2)),
                  if (below) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning_amber_rounded, size: 18, color: _C.badFg),
                  ],
                  if (ok) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline, size: 18, color: _C.okFg),
                  ],
                ],
              ),
            ),
            if (hasText && v == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Nilai harus antara 0 sampai 100.',
                    style: TextStyle(fontSize: 11.5, color: _C.badFg)),
              ),
            if (below) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.badBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.badBd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: _C.badFg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, color: _C.badFg, height: 1.35),
                          children: [
                            const TextSpan(text: 'Nilai '),
                            TextSpan(
                                text: _fmtNum(v),
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(
                                text:
                                    ' di bawah batas KKM ($_kkmText). Santri akan masuk daftar remedial.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text('Pilihan Cepat Nilai Preset:',
                style: TextStyle(fontSize: 12, color: _C.ink2)),
            const SizedBox(height: 8),
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
          const Text('Catatan Penguji / Evaluasi (Opsional)',
              style: TextStyle(fontSize: 12, color: _C.ink2)),
          const SizedBox(height: 8),
          _textArea(_catCtrl, 'Tulis catatan evaluasi santri…', lines: 3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _btn('Batal', onTap: _savingNilai ? null : _clearSelection),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn('Simpan Nilai',
                    primary: true,
                    icon: Icons.save_outlined,
                    loading: _savingNilai,
                    onTap: _savingNilai ? null : _saveNilai),
              ),
            ],
          ),
        ],
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kehadiran == o[0] ? _C.emerald : _C.chipGray,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(o[1],
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: _kehadiran == o[0] ? FontWeight.w700 : FontWeight.w500,
                      color: _kehadiran == o[0] ? Colors.white : _C.ink)),
            ),
          ),
      ],
    );
  }

  Widget _infoSusulan() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.goldSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.goldBorder),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: _C.goldText),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Santri tidak ikut ujian. Nilai dikosongkan dan santri masuk jalur ujian susulan, bukan remedial. Setelah ikut susulan, pilih "Hadir" lalu isi nilainya.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: _C.goldText)),
            ),
          ],
        ),
      );

  Widget _kunciInfo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.goldSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.goldBorder),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: _C.goldText),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Nilai ujian ini sudah dikunci. Santri susulan (sakit/izin/alpa) tetap bisa diisi nilainya. Untuk koreksi nilai lain, buka kunci di halaman Detail Ujian (alasan wajib diisi).',
                  style: TextStyle(fontSize: 12, height: 1.35, color: _C.goldText)),
            ),
          ],
        ),
      );

  Widget _presetChip(int p, double? current) {
    final sel = current != null && current == p.toDouble();
    final isKkm = p == _kkm.round();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _nilaiCtrl.text = '$p'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel || isKkm ? _C.goldChip : _C.chipGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? _C.gold : Colors.transparent, width: 1.2),
        ),
        child: Text(isKkm ? '$p (KKM)' : '$p',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: sel || isKkm ? FontWeight.w700 : FontWeight.w500,
                color: sel || isKkm ? _C.goldText : _C.ink)),
      ),
    );
  }

  // ── Komponen kecil ──
  Widget _textArea(TextEditingController c, String hint, {int lines = 3}) => TextField(
        controller: c,
        onChanged: (_) => setState(() {}),
        minLines: lines,
        maxLines: lines + 2,
        style: const TextStyle(fontSize: 13, color: _C.ink, height: 1.35),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
          filled: true,
          fillColor: _C.fieldFill,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _C.emerald, width: 2)),
        ),
      );

  Widget _btn(String label,
      {bool primary = false, IconData? icon, bool loading = false, VoidCallback? onTap}) {
    final style = FilledButton.styleFrom(
      backgroundColor: primary ? _C.emerald : _C.chipGray,
      foregroundColor: primary ? Colors.white : _C.ink,
      minimumSize: const Size.fromHeight(46),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, textAlign: TextAlign.center);
    if (icon == null || loading) {
      return FilledButton(style: style, onPressed: onTap, child: child);
    }
    return FilledButton.icon(
        style: style, onPressed: onTap, icon: Icon(icon, size: 18), label: child);
  }

  // ── Bar bawah: progres + kirim rekap ──
  Widget _bottomBar() {
    final total = _santris.length;
    final done = _santris.where((s) => _nilaiOf(s['id']) != null).length;

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
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
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Progres Penilaian',
                            style: TextStyle(fontSize: 11, color: _C.ink2)),
                        const SizedBox(height: 2),
                        Text('$done dari $total Santri Selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => _msg('Kirim rekap segera hadir.'),
                    icon: const Icon(Icons.send_outlined, size: 17),
                    label: const Text('Kirim Rekap'),
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