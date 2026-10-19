import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../signup_screen.dart'; // reuse PColors & PText (sama seperti ppdb_form_screen)
import '../santri/santri_ui.dart' show SC;
import '../ui_utils.dart';

// ============================================================================
// Helper status (warna & label)
// ============================================================================

class _StatusStyle {
  const _StatusStyle(this.fg, this.bg, this.label);
  final Color fg;
  final Color bg;
  final String label;
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'DIAJUKAN':
      return _StatusStyle(PColors.pendingText, PColors.pendingBg, 'Diajukan');
    case 'TES':
      return _StatusStyle(Color(0xFF0369A1), Color(0xFFE0F2FE), 'Tes');
    case 'DITERIMA':
      return _StatusStyle(PColors.successText, PColors.successBg, 'Diterima');
    case 'DITOLAK':
      return _StatusStyle(PColors.errorText, PColors.errorBg, 'Ditolak');
    case 'WAITING_LIST':
      return _StatusStyle(Color(0xFF4338CA), Color(0xFFE0E7FF), 'Waiting List');
    default:
      return _StatusStyle(PColors.inkSecondary, PColors.surfaceDim, status);
  }
}

// ============================================================================
// PpdbListScreen
// ============================================================================

class PpdbListScreen extends StatefulWidget {
  const PpdbListScreen({super.key});

  @override
  State<PpdbListScreen> createState() => _PpdbListScreenState();
}

class _PpdbListScreenState extends State<PpdbListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  /// Ringkasan jumlah per status. Hanya diperbarui saat filter = "Semua"
  /// supaya angkanya tetap akurat walau lagi memfilter.
  Map<String, int>? _counts;

  static const _filters = <List<String>>[
    ['', 'Semua'],
    ['DIAJUKAN', 'Diajukan'],
    ['TES', 'Tes'],
    ['WAITING_LIST', 'Waiting List'],
    ['DITERIMA', 'Diterima'],
    ['DITOLAK', 'Ditolak'],
  ];

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
      final q = <String, String>{if (_filter.isNotEmpty) 'status': _filter};
      final res = await api.get(ApiUrl.ppdb, query: q);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
        if (_filter.isEmpty) {
          final m = <String, int>{};
          for (final e in _items) {
            final s = (e as Map<String, dynamic>)['status'] as String;
            m[s] = (m[s] ?? 0) + 1;
          }
          _counts = m;
        }
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

  void _openDetail(Map<String, dynamic> p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PendaftarDetail(p: p, onChanged: _load),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: _load,
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 24),
              children: [
                _ListHero(
                  total: _loading || _error != null ? null : _items.length,
                  counts: _counts,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _filters) _chip(f[0], f[1]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ..._buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return [SizedBox(height: 320, child: loadingView())];
    }
    if (_error != null) {
      return [SizedBox(height: 320, child: errorView(_error!, _load))];
    }
    if (_items.isEmpty) {
      return [_EmptyState()];
    }
    return [
      for (final raw in _items)
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _PendaftarCard(
            p: raw as Map<String, dynamic>,
            onTap: () => _openDetail(raw),
          ),
        ),
    ];
  }

  Widget _chip(String value, String label) {
    final active = _filter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _filter = value);
          _load();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? SC.primary : PColors.surface,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: active ? SC.primary : PColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                Icon(Icons.check, size: 14, color: Colors.white),
                SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : PColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Hero banner (gradient + motif arabesque, sama seperti form PPDB)
// ============================================================================

class _ArabesquePatternPainter extends CustomPainter {
  static const double _tile = 48;
  static const double _starRadius = _tile * 0.34;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (double y = -_tile; y < size.height + _tile; y += _tile) {
      for (double x = -_tile; x < size.width + _tile; x += _tile) {
        _drawEightPointStar(canvas, Offset(x, y), _starRadius, paint);
      }
    }
  }

  void _drawEightPointStar(Canvas canvas, Offset center, double r, Paint paint) {
    final square1 = Path();
    final square2 = Path();
    for (int i = 0; i < 4; i++) {
      final a1 = (math.pi / 2) * i;
      final a2 = a1 + math.pi / 4;
      final p1 = center + Offset(math.cos(a1), math.sin(a1)) * r;
      final p2 = center + Offset(math.cos(a2), math.sin(a2)) * r;
      if (i == 0) {
        square1.moveTo(p1.dx, p1.dy);
        square2.moveTo(p2.dx, p2.dy);
      } else {
        square1.lineTo(p1.dx, p1.dy);
        square2.lineTo(p2.dx, p2.dy);
      }
    }
    square1.close();
    square2.close();
    canvas.drawPath(square1, paint);
    canvas.drawPath(square2, paint);
  }

  @override
  bool shouldRepaint(covariant _ArabesquePatternPainter oldDelegate) => false;
}

class _ListHero extends StatelessWidget {
  const _ListHero({required this.total, required this.counts});

  final int? total;
  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    final c = counts;
        final readOnly = AppScope.of(context).user?.isPimpinan == true;
    final totalAll = c?.values.fold<int>(0, (a, b) => a + b);

    return Stack(
      children: [
        // ---------- Hero gradient (sudut bawah membulat) ----------
        Padding(
          padding: EdgeInsets.only(bottom: 38),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 58),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SC.primary, SC.primaryEnd],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ArabesquePatternPainter(),
                      size: Size.infinite,
                    ),
                  ),
                ),
                // Lingkaran dekoratif lembut
                Positioned(
                  right: -50,
                  top: -60,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -46,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PColors.gold.withOpacity(0.16),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.28)),
                          ),
                          child: Icon(Icons.app_registration,
                              size: 22, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PENERIMAAN SANTRI BARU',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Data Pendaftar',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      total == null
                          ? 'Memuat data pendaftar...'
                          : '$total pendaftar ditampilkan. ${readOnly ? 'Ketuk untuk melihat detail.' : 'Ketuk untuk melihat detail dan mengambil keputusan.'}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12.5,
                        height: 18 / 12.5,
                        color: Colors.white.withOpacity(0.86),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ---------- Kartu statistik melayang ----------
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PColors.border),
              boxShadow: [
                BoxShadow(
                  color: SC.primary.withOpacity(0.10),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatCell(
                    icon: Icons.groups_2_outlined,
                    label: 'Total',
                    value: totalAll?.toString() ?? '–',
                    color: SC.primary,
                  ),
                  _StatDivider(),
                  _StatCell(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Diajukan',
                    value: c == null ? '–' : '${c['DIAJUKAN'] ?? 0}',
                    color: PColors.pendingText,
                  ),
                  _StatDivider(),
                  _StatCell(
                    icon: Icons.check_circle_outline,
                    label: 'Diterima',
                    value: c == null ? '–' : '${c['DITERIMA'] ?? 0}',
                    color: PColors.successText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 5),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(label, style: PText.bodySm),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: PColors.border);
  }
}

// ============================================================================
// Kartu pendaftar
// ============================================================================

class _PendaftarCard extends StatelessWidget {
  const _PendaftarCard({required this.p, required this.onTap});

  final Map<String, dynamic> p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = p['status'] as String;
    final st = _statusStyle(status);
    final nama = (p['nama'] as String).trim();
    final inisial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PColors.border),
          boxShadow: [
            BoxShadow(color: SC.primary.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
              child: Text(
                inisial,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: SC.primary,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PText.labelLg,
                  ),
                  SizedBox(height: 3),
                  Text(
                    '${p['noPendaftaran'] ?? 'Belum ada nomor'} • ${p['jalur'] ?? 'Reguler'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PText.bodySm,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            _StatusPill(label: st.label, fg: st.fg, bg: st.bg),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: PColors.inkSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
            child: Icon(Icons.inbox_outlined, size: 32, color: SC.primary),
          ),
          SizedBox(height: 14),
          Text('Belum ada pendaftar.', style: PText.labelLg),
          SizedBox(height: 4),
          Text(
            'Pendaftar baru akan muncul di sini setelah mengisi formulir PPDB.',
            textAlign: TextAlign.center,
            style: PText.bodySm,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Detail pendaftar
// ============================================================================

class _PendaftarDetail extends StatefulWidget {
  final Map<String, dynamic> p;
  final VoidCallback onChanged;
  const _PendaftarDetail({required this.p, required this.onChanged});

  @override
  State<_PendaftarDetail> createState() => _PendaftarDetailState();
}

class _PendaftarDetailState extends State<_PendaftarDetail> {
  /// Pimpinan/Mudir hanya memantau: tidak bisa input tes atau mengubah status.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  late Map<String, dynamic> _p;
  final _testNilai = TextEditingController();
  final _testHasil = TextEditingController();
  final _testCatatan = TextEditingController();
  bool _saving = false;
  bool _editingTest = false; // true = hasil tes dibuka kuncinya untuk diubah
  List<Map<String, dynamic>> _kelas = [];

  @override
  void initState() {
    super.initState();
    _p = widget.p;
    _isiFormTest();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadKelas();
    });
  }

  Future<void> _loadKelas() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.kelas);
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      if (!mounted) return;
      setState(() {
        _kelas = (raw is List ? raw : [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (_) {
      // Diam-diam: pilihan kelas kosong, admin tetap bisa terima tanpa kelas.
    }
  }

  /// Cari kelas yang namanya cocok dengan rekomendasi tersimpan (hasil tes).
  String? get _kelasRekomendasiId {
    final h = ((_p['ujian'] as Map?)?['hasil'] as String? ?? '').trim().toLowerCase();
    if (h.isEmpty) return null;
    for (final k in _kelas) {
      if ((k['namaKelas']?.toString() ?? '').trim().toLowerCase() == h) {
        return k['id'] as String;
      }
    }
    return null;
  }

  String _namaKelas(String? id) {
    if (id == null) return '';
    for (final k in _kelas) {
      if (k['id'] == id) return k['namaKelas']?.toString() ?? '';
    }
    return '';
  }

  /// Isi form dengan hasil tes yang sudah tersimpan (kalau ada),
  /// supaya tinggal diedit, bukan mengetik ulang.
  void _isiFormTest() {
    final u = _p['ujian'] as Map<String, dynamic>?;
    if (u == null) return;
    _testNilai.text = u['nilai']?.toString() ?? '';
    _testHasil.text = u['hasil'] as String? ?? '';
    _testCatatan.text = u['catatan'] as String? ?? '';
  }

  @override
  void dispose() {
    _testNilai.dispose();
    _testHasil.dispose();
    _testCatatan.dispose();
    super.dispose();
  }

  Future<void> _simpanTest() async {
    final nilaiText = _testNilai.text.trim();
    final nilai = double.tryParse(nilaiText);
    if (nilaiText.isNotEmpty && (nilai == null || nilai < 0 || nilai > 100)) {
      _toast('Nilai tidak valid', subtitle: 'Isi angka antara 0 sampai 100.', error: true);
      return;
    }
    final body = <String, dynamic>{
      if (nilai != null) 'nilai': nilai,
      if (_testHasil.text.trim().isNotEmpty) 'hasil': _testHasil.text.trim(),
      if (_testCatatan.text.trim().isNotEmpty) 'catatan': _testCatatan.text.trim(),
    };
    if (body.isEmpty) {
      _toast('Belum ada yang diisi',
          subtitle: 'Isi nilai, rekomendasi kelas, atau catatan.', error: true);
      return;
    }

    final wasEditing = _editingTest;
    setState(() => _saving = true);
    try {
      final api = AppScope.of(context).api;
      final has = _p['ujian'] != null;
      await (has
          ? api.patch('${ApiUrl.ppdb}/${_p['id']}/placement-test', body)
          : api.post('${ApiUrl.ppdb}/${_p['id']}/placement-test', body));
      _p = await api.get('${ApiUrl.ppdb}/${_p['id']}') as Map<String, dynamic>;
      widget.onChanged();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editingTest = false;
        _isiFormTest();
      });
      _toast(
        wasEditing ? 'Perubahan hasil tes disimpan' : 'Hasil tes berhasil disimpan',
        subtitle: '${_p['nama']}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Gagal menyimpan hasil tes.', error: true);
    }
  }

  Future<void> _ubahStatus(String status, {String? kelasId}) async {
    try {
      final api = AppScope.of(context).api;
      await api.patch('${ApiUrl.ppdb}/${_p['id']}', {
        'status': status,
        if (kelasId != null) 'kelasId': kelasId,
      });
      _p = await api.get('${ApiUrl.ppdb}/${_p['id']}') as Map<String, dynamic>;
      widget.onChanged();
      if (!mounted) return;
      setState(() {});
      if (status == 'DITERIMA') {
        final kelas = _namaKelas(kelasId);
        _toast('Pendaftar diterima',
            subtitle: kelas.isEmpty
                ? '${_p['nama']} • santri dibuat, belum punya kelas'
                : '${_p['nama']} • masuk kelas $kelas');
      } else {
        _toast('Status diperbarui', subtitle: 'Sekarang: ${_statusStyle(status).label}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _toast('Gagal memperbarui status.', error: true);
    }
  }

  /// Notifikasi melayang bertema (sama seperti di halaman absensi).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? PColors.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? PColors.errorBg : SC.primary,
          elevation: 6,
          margin: EdgeInsets.fromLTRB(side, 0, side, 24),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error
                  ? PColors.errorText.withOpacity(0.25)
                  : PColors.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : PColors.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? PColors.errorText : PColors.gold,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<bool> _konfirmasi({
    required String judul,
    required String pesan,
    required String label,
    bool bahaya = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(judul, style: PText.headlineSm),
        content: Text(pesan, style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: PColors.inkSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: bahaya ? PColors.errorText : SC.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Dialog Terima: kelas rekomendasi sudah terpilih, admin boleh mengganti.
  /// Mengembalikan null kalau dibatalkan, atau {'kelasId': String?} kalau lanjut.
  Future<Map<String, dynamic>?> _dialogTerima() {
    String? pilihan = _kelasRekomendasiId;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: PColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Terima pendaftar ini?', style: PText.headlineSm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_p['nama']} akan dinyatakan diterima dan data santri dibuat otomatis.',
                style: PText.bodyMd,
              ),
              SizedBox(height: 16),
              Text('Tempatkan di kelas', style: PText.labelLg),
              SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: pilihan,
                isExpanded: true,
                decoration: _fieldDecoration('Kelas', icon: Icons.class_outlined),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Belum ditempatkan (isi nanti)'),
                  ),
                  for (final k in _kelas)
                    DropdownMenuItem<String?>(
                      value: k['id'] as String,
                      child: Text('${k['namaKelas']}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setD(() => pilihan = v),
              ),
              if (_kelasRekomendasiId != null) ...[
                SizedBox(height: 8),
                Text('Terpilih otomatis dari rekomendasi placement test.',
                    style: PText.bodySm),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: PColors.inkSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SC.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              onPressed: () => Navigator.pop(ctx, {'kelasId': pilihan}),
              child: Text('Ya, Terima',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _terima() async {
    final hasil = await _dialogTerima();
    if (hasil == null) return;
    setState(() => _saving = true);
    await _ubahStatus('DITERIMA', kelasId: hasil['kelasId'] as String?);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _aksi(
    String status, {
    String? judul,
    String? pesan,
    String? label,
    bool bahaya = false,
  }) async {
    if (judul != null) {
      final ok = await _konfirmasi(
        judul: judul,
        pesan: pesan ?? '',
        label: label ?? 'Ya, Lanjutkan',
        bahaya: bahaya,
      );
      if (!ok) return;
    }
    setState(() => _saving = true);
    await _ubahStatus(status);
    if (mounted) setState(() => _saving = false);
  }

  // -------------------------------------------------------------------------
  // Helper UI: komponen tampilan
  // -------------------------------------------------------------------------

  Widget _card({
    required String title,
    IconData? icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PColors.border),
          boxShadow: [
            BoxShadow(color: SC.primary.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SC.sage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: SC.primary),
                  ),
                  SizedBox(width: 10),
                ],
                Expanded(child: Text(title, style: PText.headlineSm)),
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6),
              Text(subtitle, style: PText.bodySm),
            ],
            SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: PColors.inkSecondary),
          SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: PText.bodySm)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: PText.bodyMd,
      hintStyle: PText.bodyMd,
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: PColors.inkSecondary),
      filled: true,
      fillColor: PColors.background,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(PColors.inputBorder),
      enabledBorder: border(PColors.inputBorder),
      focusedBorder: border(SC.primary, 2),
    );
  }

  Widget _subJudul(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: PColors.inkSecondary,
        ),
      ),
    );
  }

  Future<void> _pilihKelasRekomendasi() async {
    final nama = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PColors.surface,
      constraints: BoxConstraints(maxWidth: 480),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text('Pilih Rekomendasi Kelas', style: PText.headlineSm),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final k in _kelas)
                    ListTile(
                      title: Text('${k['namaKelas']}', style: PText.labelLg),
                      trailing: (k['namaKelas']?.toString() ?? '') == _testHasil.text.trim()
                          ? Icon(Icons.check_circle, color: SC.primary, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, k['namaKelas']?.toString() ?? ''),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (nama != null && mounted) setState(() => _testHasil.text = nama);
  }

  Widget _hasilTesBox(Map<String, dynamic> ujian) {
    final nilai = ujian['nilai']?.toString() ?? '—';
    final hasil = (ujian['hasil'] as String? ?? '').trim();
    final catatan = (ujian['catatan'] as String? ?? '').trim();
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.sage,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                nilai,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: SC.primary,
                ),
              ),
              Text('Nilai', style: PText.bodySm),
            ],
          ),
          SizedBox(width: 16),
          Container(width: 1, height: 44, color: PColors.border),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rekomendasi Kelas', style: PText.bodySm),
                SizedBox(height: 2),
                Text(
                  hasil.isEmpty ? '—' : hasil,
                  style: PText.labelLg,
                ),
                if (catatan.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('Catatan Tes', style: PText.bodySm),
                  SizedBox(height: 2),
                  Text(catatan, style: PText.bodyMd.copyWith(color: PColors.ink)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle get _pillFilled => FilledButton.styleFrom(
        backgroundColor: SC.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      );

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ujian = _p['ujian'] as Map<String, dynamic>?;
    final status = _p['status'] as String;
    final st = _statusStyle(status);
    final nama = (_p['nama'] as String).trim();
    final inisial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();
    final jk = _p['jenisKelamin'] as String == 'L' ? 'Laki-laki' : 'Perempuan';

    return Scaffold(
      backgroundColor: PColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: Container(
          color: PColors.background,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Material(
                        color: PColors.surface,
                        shape: CircleBorder(
                          side: BorderSide(color: PColors.border),
                        ),
                        child: InkWell(
                          customBorder: CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(Icons.arrow_back_rounded,
                                size: 20, color: PColors.ink),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Detail Pendaftar',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: PColors.ink,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text('Data & tindak lanjut seleksi', style: PText.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // ---------- Header identitas ----------
              Container(
                padding: EdgeInsets.all(18),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SC.primary, SC.primaryEnd],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ArabesquePatternPainter(),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -40,
                      top: -50,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Text(
                            inisial,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                _p['noPendaftaran'] == null
                                    ? 'Nomor pendaftaran belum tersedia'
                                    : 'No. ${_p['noPendaftaran']}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              SizedBox(height: 8),
                              _StatusPill(label: st.label, fg: st.fg, bg: st.bg),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),

              // ---------- Tahapan seleksi ----------
              _card(
                title: 'Tahapan Seleksi',
                icon: Icons.timeline,
                children: [_TahapanSeleksi(status: status)],
              ),

              // ---------- Data calon santri ----------
              _card(
                title: 'Data Calon Santri',
                icon: Icons.badge_outlined,
                children: [
                  _infoRow(Icons.wc, 'Jenis Kelamin', jk),
                  _infoRow(Icons.cake_outlined, 'Tgl Lahir',
                      (_p['tanggalLahir'] as String? ?? '').split('T').first),
                  _infoRow(Icons.school_outlined, 'Asal Sekolah',
                      _p['asalSekolah'] as String? ?? ''),
                  _infoRow(Icons.alt_route, 'Jalur', _p['jalur'] as String? ?? 'Reguler'),
                  _infoRow(Icons.event_available_outlined, 'Tgl Daftar',
                      (_p['tanggalDaftar'] as String).split('T').first),
                ],
              ),

              // ---------- Kontak wali ----------
              _card(
                title: 'Kontak Wali',
                icon: Icons.contact_phone_outlined,
                children: [
                  _infoRow(Icons.phone_outlined, 'No. HP', _p['noHp'] as String? ?? ''),
                  _infoRow(Icons.mail_outline, 'Email', _p['email'] as String? ?? ''),
                  _infoRow(Icons.home_outlined, 'Alamat', _p['alamat'] as String? ?? ''),
                ],
              ),

                            // ---------- Placement test ----------
              _card(
                title: 'Placement Test',
                icon: Icons.quiz_outlined,
                                subtitle: _readOnly
                    ? (ujian == null ? 'Belum ada hasil tes.' : 'Hasil placement test.')
                    : ujian == null
                        ? 'Belum ada hasil tes. Isi nilai dan rekomendasi kelas di bawah.'
                        : (_editingTest
                            ? 'Mode ubah: perbarui hasil tes lalu simpan.'
                            : 'Hasil tes sudah tersimpan dan terkunci.'),
                children: [
                                    if (ujian != null) _hasilTesBox(ujian),
                  if (_readOnly)
                    const SizedBox.shrink()
                  else if (ujian != null && !_editingTest)
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _editingTest = true),
                        icon: Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          'Ubah Hasil Tes',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SC.primary,
                          side: BorderSide(color: PColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999)),
                        ),
                      ),
                    )
                  else ...[
                    _subJudul(ujian == null ? 'Input hasil tes' : 'Perbarui hasil tes'),
                    TextField(
                      controller: _testNilai,
                      keyboardType: TextInputType.number,
                      style: PText.bodyMd.copyWith(color: PColors.ink),
                      decoration:
                          _fieldDecoration('Nilai (0-100)', icon: Icons.grade_outlined),
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _kelas.isEmpty ? null : _pilihKelasRekomendasi,
                      child: InputDecorator(
                        isEmpty: _testHasil.text.trim().isEmpty,
                        decoration: _fieldDecoration(
                          _kelas.isEmpty ? 'Belum ada kelas' : 'Rekomendasi Kelas',
                          icon: Icons.class_outlined,
                        ).copyWith(
                          suffixIcon: Icon(Icons.unfold_more_rounded,
                              size: 20, color: PColors.inkSecondary),
                        ),
                        child: Text(
                          _testHasil.text.trim(),
                          style: PText.bodyMd.copyWith(color: PColors.ink),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _testCatatan,
                      style: PText.bodyMd.copyWith(color: PColors.ink),
                      decoration: _fieldDecoration('Catatan Tes', icon: Icons.notes),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: _pillFilled,
                              onPressed: _saving ? null : _simpanTest,
                              child: _saving
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _editingTest
                                          ? 'Simpan Perubahan'
                                          : 'Simpan Hasil Tes',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: PColors.gold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (_editingTest) ...[
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                      _editingTest = false;
                                      _isiFormTest(); // kembalikan ke nilai tersimpan
                                    }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PColors.inkSecondary,
                              side: BorderSide(color: PColors.border),
                              minimumSize: Size(0, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999)),
                            ),
                            child: Text('Batal',
                                style: TextStyle(
                                    fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),

                            // ---------- Tindak lanjut ----------
              if (!_readOnly)
              _card(
                title: 'Tindak Lanjut Pendaftaran',
                icon: Icons.fact_check_outlined,
                subtitle:
                    'Pilih langkah berikutnya untuk pendaftar ini. Status saat ini: ${st.label}.',
                children: [
                  _subJudul('Ubah tahap seleksi'),
                  _AksiTile(
                    icon: Icons.event_note_outlined,
                    title: 'Jadwalkan Tes',
                    desc: 'Pindahkan ke tahap tes masuk. Belum diterima atau ditolak.',
                    fg: Color(0xFF0369A1),
                    bg: Color(0xFFE0F2FE),
                    current: status == 'TES',
                    onTap: (_saving || status == 'TES') ? null : () => _aksi('TES'),
                  ),
                  SizedBox(height: 8),
                  _AksiTile(
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Masukkan ke Waiting List',
                    desc: 'Masuk daftar tunggu, bisa diterima nanti jika kuota tersedia.',
                    fg: Color(0xFF4338CA),
                    bg: Color(0xFFE0E7FF),
                    current: status == 'WAITING_LIST',
                    onTap: (_saving || status == 'WAITING_LIST')
                        ? null
                        : () => _aksi('WAITING_LIST'),
                  ),
                  SizedBox(height: 14),
                  _subJudul('Keputusan akhir'),
                  _AksiTile(
                    icon: Icons.verified_outlined,
                    title: 'Terima Sebagai Santri',
                    desc: 'Dinyatakan lulus. Data santri dibuat otomatis dari data pendaftar ini.',
                    fg: PColors.successText,
                    bg: PColors.successBg,
                    current: status == 'DITERIMA',
                    onTap: (_saving || status == 'DITERIMA')
                        ? null
                        : _terima,
                  ),
                  SizedBox(height: 8),
                  _AksiTile(
                    icon: Icons.cancel_outlined,
                    title: 'Tolak Pendaftaran',
                    desc: 'Dinyatakan tidak lulus seleksi.',
                    fg: PColors.errorText,
                    bg: PColors.errorBg,
                    current: status == 'DITOLAK',
                    onTap: (_saving || status == 'DITOLAK')
                        ? null
                        : () => _aksi(
                              'DITOLAK',
                              judul: 'Tolak pendaftar ini?',
                              pesan:
                                  '${_p['nama']} akan dinyatakan tidak lulus seleksi.',
                              label: 'Ya, Tolak',
                              bahaya: true,
                            ),
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

// ============================================================================
// Tile aksi (tindak lanjut)
// ============================================================================

class _AksiTile extends StatelessWidget {
  const _AksiTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.fg,
    required this.bg,
    required this.onTap,
    this.current = false,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Color fg;
  final Color bg;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !current;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: current ? bg : PColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: current ? fg.withOpacity(0.4) : PColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: fg),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PText.labelLg),
                      SizedBox(height: 2),
                      Text(desc, style: PText.bodySm),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (current)
                  _StatusPill(label: 'Saat ini', fg: fg, bg: Colors.white)
                else
                  Icon(Icons.chevron_right, color: PColors.inkSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Indikator tahapan seleksi
// ============================================================================

class _TahapanSeleksi extends StatelessWidget {
  const _TahapanSeleksi({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final current = status == 'DIAJUKAN' ? 0 : (status == 'TES' ? 1 : 2);
    final st = _statusStyle(status);
    final labels = ['Diajukan', 'Tes', current == 2 ? st.label : 'Keputusan'];

    IconData finalIcon() {
      switch (status) {
        case 'DITERIMA':
          return Icons.check;
        case 'DITOLAK':
          return Icons.close;
        default:
          return Icons.hourglass_bottom_rounded;
      }
    }

    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          final done = (i - 1) ~/ 2 < current;
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(bottom: 22, left: 4, right: 4),
              color: done ? SC.primary : PColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final active = idx == current;
        final done = idx < current;
        final isFinal = idx == 2 && current == 2;
        final circleColor = isFinal
            ? st.fg
            : (active || done)
                ? SC.primary
                : PColors.surfaceDim;
        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
              child: isFinal
                  ? Icon(finalIcon(), size: 17, color: Colors.white)
                  : done
                      ? Icon(Icons.check, size: 17, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : PColors.inkSecondary,
                          ),
                        ),
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 76,
              child: Text(
                labels[idx],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? PColors.ink : PColors.inkSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}