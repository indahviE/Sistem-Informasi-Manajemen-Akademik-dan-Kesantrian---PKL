import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC, SantriAvatar, SPill, statusColors;
import '../santri/santri_detail_screen.dart';
import 'rapor_wali_screen.dart';

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

  /// Anak yang sedang dipilih (fallback ke anak pertama).
  Map<String, dynamic> get _anakTerpilih => _anak.firstWhere(
        (a) => '${a['id']}' == _selectedSantriId,
        orElse: () => _anak.first,
      );

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

    Future<List<Map<String, dynamic>>?> ambil(
      String url, {
      Map<String, String>? tambahan,
    }) async {
      try {
        return _asList(await api.get(url, query: {'santriId': id, ...?tambahan}));
      } catch (e) {
        debugPrint('GAGAL muat $url: $e');
        return null;
      }
    }

    final hasil = await Future.wait([
      ambil(ApiUrl.nilai, tambahan: {'tahunAjaranId': 'semua'}),
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

  void _bukaProfil(Map<String, dynamic> a) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SantriDetailScreen(santriId: '${a['id']}', readOnly: true),
      ),
    );
  }

  // ----- Selector anak (hanya muncul kalau punya lebih dari satu anak) -----
  Widget _anakSelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _anak.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final a = _anak[i];
          final id = '${a['id']}';
          final selected = _selectedSantriId == id;
          final nama = '${a['nama'] ?? 'Santri'}'.trim();
          final inisial = nama.isEmpty ? '?' : nama.characters.first.toUpperCase();
          final namaDepan = nama.split(' ').first;

          return GestureDetector(
            onTap: () {
              if (!selected) _loadDetail(id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
              decoration: BoxDecoration(
                color: selected ? _WS.primary : _WS.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _WS.primary : _WS.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? Colors.white.withOpacity(0.16) : _WS.sage,
                    ),
                    child: Text(
                      inisial,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? SC.gold : _WS.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    namaDepan,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _WS.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----- Kartu profil anak (ketuk untuk membuka profil lengkap) -----
  Widget _profilAnak() {
    final a = _anakTerpilih;
    final nama = '${a['nama'] ?? 'Santri'}';
    final nis = '${a['nis'] ?? '-'}';
    final kelas = (a['kelas'] is Map ? a['kelas']['namaKelas'] : null)?.toString();
    final status = a['status']?.toString();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SC.primary, SC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SC.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _bukaProfil(a),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -34,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                  ),
                ),
              ),
              Positioned(
                left: -28,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SC.gold.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SantriAvatar(
                      name: nama,
                      gender: a['jenisKelamin']?.toString(),
                      size: 60,
                      onDark: true,
                      badge: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              SPill(
                                'NIS $nis',
                                icon: Icons.tag_rounded,
                                bg: Colors.white.withOpacity(0.14),
                                fg: Colors.white,
                              ),
                              if (kelas != null && kelas.trim().isNotEmpty)
                                SPill(kelas, icon: Icons.class_outlined, bg: SC.mint, fg: SC.primary),
                              if (status != null && status.isNotEmpty)
                                SPill(
                                  status,
                                  bg: statusColors(status).bg,
                                  fg: statusColors(status).fg,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: SC.gold.withOpacity(0.6)),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: SC.gold),
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

  // ----- Rapor Digital -----
  Widget _raporCard() {
    final anak = _anakTerpilih;
    return Container(
      decoration: BoxDecoration(
        color: _WS.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WS.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RaporWaliScreen(santri: anak)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _WS.sage, shape: BoxShape.circle),
                  child: Icon(Icons.description_outlined, size: 20, color: _WS.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rapor Digital',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WS.ink)),
                      const SizedBox(height: 2),
                      Text('Lihat rapor ${anak['nama'] ?? 'santri'} yang sudah terbit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: _WS.inkSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _WS.primary),
              ],
            ),
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
    final persen = total > 0 ? (hadir / total * 100).round() : 0;

    const cHadir = _WS.successText;
    const cIzin = _WS.pendingText;
    const cSakit = _WS.gold;
    const cAlpa = _WS.errorText;

    Widget baris(String label, int v, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _WS.inkSecondary,
                  ),
                ),
              ),
              Text(
                '$v',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _WS.ink,
                ),
              ),
            ],
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
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(108, 108),
                    painter: _DonutPainter(
                      values: [
                        hadir.toDouble(),
                        izin.toDouble(),
                        sakit.toDouble(),
                        alpa.toDouble(),
                      ],
                      colors: const [cHadir, cIzin, cSakit, cAlpa],
                      track: _WS.surfaceDim,
                      stroke: 12,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$persen%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _WS.primary,
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'hadir',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _WS.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  baris('Hadir', hadir, cHadir),
                  baris('Izin', izin, cIzin),
                  baris('Sakit', sakit, cSakit),
                  baris('Alpa', alpa, cAlpa),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _WS.surfaceDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_note_outlined, size: 15, color: _WS.inkSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hadir $hadir dari $total pertemuan tercatat',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _WS.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
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
            _title(
              Icons.family_restroom_outlined,
              _anak.length > 1 ? 'Anak Saya' : 'Profil Anak',
              trailing: _anak.length > 1 ? '${_anak.length} santri' : null,
            ),
            const SizedBox(height: 12),
            if (_anak.length > 1) ...[
              _anakSelector(),
              const SizedBox(height: 12),
            ],
            _profilAnak(),
            const SizedBox(height: 12),
            _raporCard(),
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

/// Donat bersegmen untuk komposisi kehadiran (hadir / izin / sakit / alpa).
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color track;
  final double stroke;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final aktif = values.where((v) => v > 0).length;
    final gap = aktif > 1 ? 0.07 : 0.0;
    var start = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      final seg = sweep > gap ? sweep - gap : sweep;
      canvas.drawArc(
        rect,
        start + (sweep - seg) / 2,
        seg,
        false,
        base..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors || old.track != track;
}