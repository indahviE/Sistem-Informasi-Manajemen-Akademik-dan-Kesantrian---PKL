import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

class _WS {
  _WS._();
  static Color get primary => SC.primary;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

List<Map<String, dynamic>> _asList(dynamic res) {
  final raw = res is List ? res : (res is Map ? (res['data'] ?? res['items']) : null);
  if (raw is! List) return [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

String _tgl(dynamic v) {
  final s = '${v ?? ''}';
  return s.length >= 10 ? s.substring(0, 10) : (s.isEmpty ? '-' : s);
}

String _first(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && '$v'.trim().isNotEmpty) return '$v';
  }
  return '';
}

class WaliScreen extends StatefulWidget {
  const WaliScreen({super.key});

  @override
  State<WaliScreen> createState() => _WaliScreenState();
}

class _WaliScreenState extends State<WaliScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _anak = [];
  bool _loading = true;
  String? _error;
  String? _selectedSantriId;

  bool _detailLoading = false;
  List<Map<String, dynamic>> _nilai = [];
  List<Map<String, dynamic>> _absensi = [];
  List<Map<String, dynamic>> _tahfidz = [];
  bool _nilaiErr = false;
  bool _absensiErr = false;
  bool _tahfidzErr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final d = await api.get(ApiUrl.waliMe);
      final anak = _asList(d is Map ? d['santris'] : null);
      if (!mounted) return;
      setState(() {
        _data = d as Map<String, dynamic>;
        _anak = anak;
        _selectedSantriId = anak.isNotEmpty ? '${anak.first['id']}' : null;
        _loading = false;
      });
      if (_selectedSantriId != null) _loadDetail(_selectedSantriId!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Terjadi kesalahan tak terduga: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadDetail(String id) async {
    setState(() {
      _selectedSantriId = id;
      _detailLoading = true;
    });
    final api = AppScope.of(context).api;

    Future<List<Map<String, dynamic>>?> ambil(String url) async {
      try {
        return _asList(await api.get(url, query: {'santriId': id}));
      } catch (_) {
        return null;
      }
    }

    final hasil = await Future.wait([
      ambil(ApiUrl.nilai),
      ambil(ApiUrl.absensi),
      ambil(ApiUrl.tahfidz),
    ]);
    if (!mounted || _selectedSantriId != id) return;

    int byTanggal(Map<String, dynamic> a, Map<String, dynamic> b, List<String> keys) =>
        _first(b, keys).compareTo(_first(a, keys));

    setState(() {
      _nilaiErr = hasil[0] == null;
      _absensiErr = hasil[1] == null;
      _tahfidzErr = hasil[2] == null;
      _nilai = (hasil[0] ?? [])..sort((a, b) => byTanggal(a, b, ['tanggal']));
      _absensi = (hasil[1] ?? [])..sort((a, b) => byTanggal(a, b, ['tanggal']));
      _tahfidz = (hasil[2] ?? [])..sort((a, b) => byTanggal(a, b, ['tanggalSetor', 'tanggal']));
      _detailLoading = false;
    });
  }

  // -------------------------------------------------------------------
  // UI helpers
  // -------------------------------------------------------------------
  Widget _title(IconData icon, String text, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _WS.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WS.ink)),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11.5, color: _WS.inkSecondary)),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _WS.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WS.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _info(String text, {bool error = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: error ? _WS.errorText : _WS.inkSecondary),
      ),
    );
  }

  Widget _santriTile(Map<String, dynamic> a) {
    final id = '${a['id']}';
    final selected = _selectedSantriId == id;
    final kelas = (a['kelas'] is Map ? a['kelas']['namaKelas'] : null)?.toString() ?? '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _loadDetail(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _WS.mint.withOpacity(0.45) : _WS.surfaceDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _WS.primary : _WS.border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _WS.primary : Colors.transparent,
                  border: Border.all(color: selected ? _WS.primary : _WS.inkSecondary, width: 1.6),
                ),
                child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a['nama'] ?? 'Santri'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WS.ink)),
                    const SizedBox(height: 2),
                    Text('${a['nis'] ?? '-'} • $kelas',
                        style: const TextStyle(fontSize: 11.5, color: _WS.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Kehadiran -----
  Widget _kehadiranSection() {
    int hitung(String s) =>
        _absensi.where((e) => '${e['status'] ?? ''}'.toLowerCase() == s).length;
    final hadir = hitung('hadir');
    final izin = hitung('izin');
    final sakit = hitung('sakit');
    final alpa = hitung('alpa');
    final total = _absensi.length;
    final persen = total > 0 ? (hadir / total * 100).round() : null;

    Widget box(String label, int v, Color bg, Color fg) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('$v', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        );

    return _card([
      if (_absensiErr)
        _info('Kehadiran belum bisa dimuat.', error: true)
      else if (total == 0)
        _info('Belum ada data kehadiran.')
      else ...[
        Row(
          children: [
            Expanded(
              child: Text('$total pertemuan tercatat',
                  style: const TextStyle(fontSize: 12, color: _WS.inkSecondary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _WS.mint, borderRadius: BorderRadius.circular(999)),
              child: Text('$persen% hadir',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _WS.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            box('Hadir', hadir, _WS.successBg, _WS.successText),
            const SizedBox(width: 8),
            box('Izin', izin, _WS.pendingBg, _WS.pendingText),
            const SizedBox(width: 8),
            box('Sakit', sakit, _WS.goldSurface, _WS.gold),
            const SizedBox(width: 8),
            box('Alpa', alpa, _WS.errorBg, _WS.errorText),
          ],
        ),
      ],
    ]);
  }

  // ----- Tahfidz -----
  Widget _tahfidzTile(Map<String, dynamic> t) {
    final juz = _first(t, ['juz']);
    final hal = _first(t, ['halaman']);
    final tgl = _tgl(_first(t, ['tanggalSetor', 'tanggal']));
    final cat = _first(t, ['catatanUstadz', 'catatan']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _WS.goldSurface, shape: BoxShape.circle),
            child: Text(juz.isEmpty ? '-' : juz,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _WS.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Juz ${juz.isEmpty ? '-' : juz}${hal.isEmpty ? '' : ' • Hal. $hal'}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _WS.ink)),
                const SizedBox(height: 2),
                Text(tgl, style: const TextStyle(fontSize: 11.5, color: _WS.inkSecondary)),
                if (cat.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(cat,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, fontStyle: FontStyle.italic, color: _WS.inkSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tahfidzSection() {
    final items = _tahfidz.take(5).toList();
    return _card([
      if (_tahfidzErr)
        _info('Tahfidz belum bisa dimuat.', error: true)
      else if (items.isEmpty)
        _info('Belum ada setoran tahfidz.')
      else
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: _WS.border),
          _tahfidzTile(items[i]),
        ],
    ]);
  }

  // ----- Nilai -----
  Widget _nilaiTile(Map<String, dynamic> n) {
    final v = n['nilai'] is num ? (n['nilai'] as num).toDouble() : double.tryParse('${n['nilai']}') ?? 0;
    final fg = v >= 85 ? _WS.successText : (v >= 70 ? _WS.pendingText : _WS.errorText);
    final bg = v >= 85 ? _WS.successBg : (v >= 70 ? _WS.pendingBg : _WS.errorBg);
    final mapel = (n['mapel'] is Map ? n['mapel']['namaMapel'] : null)?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(v.toStringAsFixed(0),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mapel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WS.ink)),
                const SizedBox(height: 2),
                Text('${n['jenis'] ?? ''} • ${_tgl(n['tanggal'])}',
                    style: const TextStyle(fontSize: 11.5, color: _WS.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nilaiSection() {
    return _card([
      if (_nilaiErr)
        _info('Nilai belum bisa dimuat.', error: true)
      else if (_nilai.isEmpty)
        _info('Belum ada nilai untuk santri ini.')
      else
        for (int i = 0; i < _nilai.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: _WS.border),
          _nilaiTile(_nilai[i]),
        ],
    ]);
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = loadingView();
    } else if (_error != null) {
      content = errorView(_error!, _load);
    } else if (_data == null || _anak.isEmpty) {
      content = emptyView('Akun belum terhubung ke data santri.');
    } else {
      content = RefreshIndicator(
        color: _WS.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _title(Icons.family_restroom_outlined, 'Anak Anda',
                trailing: _anak.length > 1 ? 'Pilih santri' : null),
            const SizedBox(height: 10),
            _card([for (final a in _anak) _santriTile(a)]),
            const SizedBox(height: 20),
            if (_detailLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _title(Icons.fact_check_outlined, 'Kehadiran'),
              const SizedBox(height: 10),
              _kehadiranSection(),
              const SizedBox(height: 20),
              _title(Icons.auto_stories_outlined, 'Tahfidz', trailing: 'Setoran terbaru'),
              const SizedBox(height: 10),
              _tahfidzSection(),
              const SizedBox(height: 20),
              _title(Icons.grade_outlined, 'Nilai'),
              const SizedBox(height: 10),
              _nilaiSection(),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _WS.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: content,
        ),
      ),
    );
  }
}