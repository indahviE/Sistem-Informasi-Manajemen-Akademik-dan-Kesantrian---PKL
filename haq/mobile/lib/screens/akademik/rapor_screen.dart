import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// ============================================================================
// Token warna lokal
// ============================================================================

class _RC {
  _RC._();

  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFF1D58F);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);

  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const inkMuted = Color(0xFF94A3B8);

  static const greenFg = Color(0xFF166534);
  static const greenBg = Color(0xFFDCFCE7);
  static const redFg = Color(0xFF991B1B);
  static const redBg = Color(0xFFFEE2E2);
  static const amberFg = Color(0xFFB78103);
  static const amberBg = Color(0xFFFFF8E1);

  // Batas nilai lulus (KKM). Ubah di sini kalau KKM berubah.
  static const double kkm = 75;
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: height,
      letterSpacing: spacing,
    );

BoxDecoration _cardDeco({double radius = 20}) => BoxDecoration(
      color: _RC.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _RC.line.withOpacity(0.8)),
      boxShadow: const [
        BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 14, offset: Offset(0, 5)),
      ],
    );

double _d(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

String _kelasNama(Map s) {
  final k = s['kelas'];
  if (k is Map && k['namaKelas'] != null && '${k['namaKelas']}'.trim().isNotEmpty) {
    return '${k['namaKelas']}';
  }
  return '-';
}

String _inisial(String nama) {
  final t = nama.trim();
  return t.isEmpty ? '?' : t.characters.first.toUpperCase();
}

/// Judul section dengan penanda emas.
Widget _secTitle(IconData icon, String text, {String? trailing}) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: _RC.gold,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 9),
      Icon(icon, size: 17, color: _RC.primary),
      const SizedBox(width: 7),
      Expanded(child: Text(text, style: _t(14.5, FontWeight.w800, _RC.ink))),
      if (trailing != null)
        Text(trailing, style: _t(11, FontWeight.w600, _RC.inkSecondary)),
    ],
  );
}

Widget _btnBatal(VoidCallback onTap) => TextButton(
      onPressed: onTap,
      child: Text('Batal', style: _t(13, FontWeight.w700, _RC.inkSecondary)),
    );

Widget _btnUtama(String label, VoidCallback onTap) => FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _RC.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text(label, style: _t(13, FontWeight.w800, Colors.white)),
    );

Widget _identitasKotak(String nama, String sub) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _RC.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _RC.line),
      ),
      child: Column(
        children: [
          Text(
            nama,
            textAlign: TextAlign.center,
            style: _t(14, FontWeight.w800, _RC.primary),
          ),
          const SizedBox(height: 2),
          Text(sub, style: _t(12, FontWeight.w600, _RC.inkSecondary)),
        ],
      ),
    );

/// Notifikasi melayang bertema (sukses = warna tema, gagal = merah lembut).
void _toast(
  BuildContext context,
  String title, {
  String? subtitle,
  bool error = false,
}) {
  final w = MediaQuery.of(context).size.width;
  final side = w > 472 ? (w - 440) / 2 : 16.0;
  final fg = error ? _RC.redFg : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        duration: Duration(seconds: error ? 4 : 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: error ? _RC.redBg : _RC.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error ? _RC.redFg.withOpacity(0.25) : _RC.gold.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: (error ? _RC.redFg : _RC.primary).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _RC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _RC.redFg : _RC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _t(13.5, FontWeight.w800, fg)),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: _t(11.5, FontWeight.w500, fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// Cincin progres melingkar (dipakai sebagai gauge rata-rata nilai).
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0).toDouble(),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}

/// Ornamen lingkaran tipis untuk hero.
Widget _ring(double size, {double opacity = 0.08}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(opacity), width: 1.5),
      ),
    );

// ============================================================================
// Daftar santri
// ============================================================================

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  List<dynamic> _santri = [];
  bool _loading = true;
  String? _error;

  String _q = '';
  String _kelas = 'SEMUA';
  final _searchC = TextEditingController();

  /// Pimpinan/Mudir hanya memantau: tidak bisa generate, memperbarui, atau menerbitkan rapor.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get('${ApiUrl.rapor}/santri');
      final items = res is List
          ? res
          : ((res as Map<String, dynamic>)['items'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _santri = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar santri.';
          _loading = false;
        });
      }
    }
  }

  String _periodeSekarang() {
    final n = DateTime.now();
    if (n.month >= 7) return '${n.year}/${n.year + 1} - Ganjil';
    return '${n.year - 1}/${n.year} - Genap';
  }

  List<String> get _daftarKelas {
    final set = <String>{};
    for (final s in _santri) {
      if (s is Map) {
        final k = _kelasNama(s);
        if (k != '-') set.add(k);
      }
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    return _santri
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((s) {
      if (_kelas != 'SEMUA' && _kelasNama(s) != _kelas) return false;
      if (q.isEmpty) return true;
      return '${s['nama'] ?? ''}'.toLowerCase().contains(q) ||
          '${s['nis'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _generate(Map<String, dynamic> santri) async {
    if (_readOnly) return;
    final periode = TextEditingController(text: _periodeSekarang());
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _RC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _RC.sage,
            shape: BoxShape.circle,
            border: Border.all(color: _RC.gold.withOpacity(0.45)),
          ),
          child: Icon(Icons.auto_awesome_outlined, size: 26, color: _RC.primary),
        ),
        title: Text(
          'Generate Rapor',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _RC.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _identitasKotak('${santri['nama']}', 'NIS ${santri['nis']}'),
            const SizedBox(height: 14),
            TextField(
              controller: periode,
              style: _t(14, FontWeight.w700, _RC.primary),
              decoration: InputDecoration(
                labelText: 'Periode',
                hintText: 'Contoh: 2026/2027 - Ganjil',
                labelStyle: _t(13, FontWeight.w600, _RC.inkSecondary),
                hintStyle: _t(13, FontWeight.w500, _RC.inkSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: _RC.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _RC.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _RC.primary, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nilai dan kehadiran akan ditarik otomatis dari data terbaru.',
              textAlign: TextAlign.center,
              style: _t(11.5, FontWeight.w500, _RC.inkSecondary, height: 1.4),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          _btnBatal(() => Navigator.of(ctx).pop()),
          _btnUtama('Generate', () {
            if (periode.text.trim().isEmpty) return;
            Navigator.of(ctx).pop(periode.text.trim());
          }),
        ],
      ),
    );
    if (confirmed == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.raporGenerate, {
        'santriId': santri['id'],
        'periode': confirmed.trim(),
      });
      if (!mounted) return;
      _toast(
        context,
        'Rapor berhasil digenerate',
        subtitle: '${santri['nama']} • $confirmed',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal generate rapor.', error: true);
    }
  }

  void _bukaDetail(Map<String, dynamic> s) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RaporDetailScreen(santri: s)));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = loadingView();
    } else if (_error != null) {
      body = errorView(_error!, _load);
    } else if (_santri.isEmpty) {
      body = emptyView('Belum ada santri.');
    } else {
      final list = _filtered;
      final kelasList = _daftarKelas;
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: _RC.primary,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _header(),
                const SizedBox(height: 16),
                _searchField(),
                if (kelasList.length > 1) ...[
                  const SizedBox(height: 12),
                  _kelasChips(kelasList),
                ],
                const SizedBox(height: 16),
                _secTitle(
                  Icons.groups_2_outlined,
                  'Daftar Santri',
                  trailing: '${list.length} santri',
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  _noResult()
                else
                  for (final s in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _santriCard(s),
                    ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(backgroundColor: _RC.background, body: body);
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  Widget _header() {
    final jumlahKelas = _daftarKelas.length;

    Widget pill(IconData icon, String text, {required Color bg, required Color fg, Color? border}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(text, style: _t(11, FontWeight.w700, fg)),
            ],
          ),
        );

    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white70),
              const SizedBox(height: 5),
              Text(value, style: _t(21, FontWeight.w800, Colors.white, height: 1.1)),
              const SizedBox(height: 2),
              Text(label, style: _t(10.5, FontWeight.w600, Colors.white70)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_RC.primary, _RC.primarySoft],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _RC.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -38, top: -44, child: _ring(160)),
          Positioned(right: 14, top: 14, child: _ring(72, opacity: 0.12)),
          Positioned(
            left: -34,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _RC.gold.withOpacity(0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: _RC.gold.withOpacity(0.65)),
                      ),
                      child: const Icon(Icons.workspace_premium_outlined,
                          size: 24, color: _RC.goldLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LAPORAN HASIL BELAJAR',
                              style: _t(9.5, FontWeight.w800, _RC.goldLight, spacing: 1.0)),
                          const SizedBox(height: 3),
                          Text('Rapor Digital',
                              style: _t(22, FontWeight.w800, Colors.white, height: 1.1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _readOnly
                      ? 'Pantau rapor seluruh santri dalam satu tempat.'
                      : 'Generate, tinjau, lalu terbitkan rapor santri.',
                  style: _t(12, FontWeight.w500, Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill(
                      Icons.event_available_outlined,
                      _periodeSekarang(),
                      bg: _RC.gold.withOpacity(0.18),
                      fg: _RC.goldLight,
                      border: _RC.gold.withOpacity(0.5),
                    ),
                    if (_readOnly)
                      pill(
                        Icons.visibility_outlined,
                        'Mode Pantau',
                        bg: Colors.white.withOpacity(0.12),
                        fg: Colors.white,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      stat(Icons.groups_outlined, '${_santri.length}', 'Santri'),
                      Container(width: 1, height: 38, color: Colors.white.withOpacity(0.18)),
                      stat(Icons.class_outlined, '$jumlahKelas', 'Kelas'),
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

  Widget _searchField() {
    return TextField(
      controller: _searchC,
      onChanged: (v) => setState(() => _q = v),
      style: _t(14, FontWeight.w600, _RC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama atau NIS santri',
        hintStyle: _t(13.5, FontWeight.w500, _RC.inkMuted),
        prefixIcon: Icon(Icons.search_rounded, size: 21, color: _RC.primary),
        suffixIcon: _q.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close_rounded, size: 18, color: _RC.inkSecondary),
                onPressed: () {
                  _searchC.clear();
                  setState(() => _q = '');
                },
              ),
        filled: true,
        fillColor: _RC.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _RC.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _RC.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _kelasChips(List<String> kelas) {
    Widget chip(String value, String label) {
      final selected = _kelas == value;
      return GestureDetector(
        onTap: () => setState(() => _kelas = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _RC.primary : _RC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? _RC.primary : _RC.line),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _RC.primary.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: _t(12, FontWeight.w700, selected ? Colors.white : _RC.inkSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('SEMUA', 'Semua kelas'),
          for (final k in kelas) ...[
            const SizedBox(width: 8),
            chip(k, k),
          ],
        ],
      ),
    );
  }

  Widget _noResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: _RC.sage, shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 28, color: _RC.primary),
          ),
          const SizedBox(height: 12),
          Text('Tidak ada hasil', style: _t(14, FontWeight.w800, _RC.ink)),
          const SizedBox(height: 4),
          Text(
            'Tidak ada santri yang cocok dengan pencarian atau filter ini.',
            textAlign: TextAlign.center,
            style: _t(12, FontWeight.w500, _RC.inkSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Kartu santri
  // -------------------------------------------------------------------------
  Widget _santriCard(Map<String, dynamic> s) {
    final nama = (s['nama'] ?? '-').toString();
    final kelas = _kelasNama(s);

    Widget aksi(IconData icon, String label, VoidCallback onTap, {bool filled = false}) {
      return Expanded(
        child: Material(
          color: filled ? _RC.primary : _RC.surface,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: filled ? null : Border.all(color: _RC.primary.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: filled ? Colors.white : _RC.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: _t(12, FontWeight.w800, filled ? Colors.white : _RC.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco(radius: 22),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _bukaDetail(s),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_RC.primary, _RC.primarySoft],
                        ),
                        border: Border.all(color: _RC.gold.withOpacity(0.6), width: 1.4),
                      ),
                      child: Text(_inisial(nama), style: _t(20, FontWeight.w800, _RC.goldLight)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _t(14.5, FontWeight.w800, _RC.ink, height: 1.25),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _miniPill(Icons.tag_rounded, 'NIS ${s['nis'] ?? '-'}',
                                  _RC.surfaceDim, _RC.inkSecondary),
                              if (kelas != '-')
                                _miniPill(Icons.class_outlined, kelas, _RC.sage, _RC.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 22, color: _RC.inkMuted),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: _RC.surfaceDim,
                border: Border(top: BorderSide(color: _RC.line)),
              ),
              child: Row(
                children: [
                  aksi(Icons.description_outlined, 'Lihat Rapor', () => _bukaDetail(s)),
                  if (!_readOnly) ...[
                    const SizedBox(width: 10),
                    aksi(Icons.auto_awesome_outlined, 'Generate', () => _generate(s), filled: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPill(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(text, style: _t(10.5, FontWeight.w800, fg)),
        ],
      ),
    );
  }
}

// ============================================================================
// Detail rapor
// ============================================================================

class RaporDetailScreen extends StatefulWidget {
  final Map<String, dynamic> santri;
  const RaporDetailScreen({super.key, required this.santri});

  @override
  State<RaporDetailScreen> createState() => _RaporDetailScreenState();
}

class _RaporDetailScreenState extends State<RaporDetailScreen> {
  List<dynamic> _rapors = [];
  String? _busy; // 'terbit:<id>' atau 'perbarui:<id>' saat proses berjalan
  bool _loading = true;
  String? _error;
  int _idx = 0; // rapor (periode) yang sedang ditampilkan

  /// Pimpinan/Mudir hanya memantau: tidak bisa memperbarui atau menerbitkan rapor.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

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
      final res = await AppScope.of(context).api.get(
        ApiUrl.rapor,
        query: {'santriId': widget.santri['id'] as String},
      );
      final items = res is List
          ? res
          : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _rapors = items;
        if (_idx >= _rapors.length) _idx = 0;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat rapor.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _terbit(Map<String, dynamic> r) async {
    if (_busy != null || _readOnly) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _RC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _RC.sage,
            shape: BoxShape.circle,
            border: Border.all(color: _RC.gold.withOpacity(0.45)),
          ),
          child: Icon(Icons.send_outlined, size: 25, color: _RC.primary),
        ),
        title: Text(
          'Terbitkan rapor?',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _RC.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _identitasKotak('${widget.santri['nama']}', '${r['periode']}'),
            const SizedBox(height: 12),
            Text(
              'Pastikan nilai dan kehadiran sudah benar. '
              'Rapor yang sudah diterbitkan tidak dapat diubah lagi.',
              textAlign: TextAlign.center,
              style: _t(12.5, FontWeight.w500, _RC.inkSecondary, height: 1.45),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          _btnBatal(() => Navigator.of(ctx).pop(false)),
          _btnUtama('Terbitkan', () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = 'terbit:${r['id']}');
    try {
      await AppScope.of(context).api.patch('${ApiUrl.rapor}/${r['id']}/terbit');
      if (!mounted) return;
      // Ubah status langsung di list (tanpa _load) supaya layar tidak berkedip.
      setState(() => r['status'] = 'TERBIT');
      _toast(
        context,
        'Rapor diterbitkan',
        subtitle: '${r['periode']} • Status: TERBIT',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal menerbitkan rapor.', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// Tarik ulang nilai & kehadiran untuk rapor yang masih draft.
  Future<void> _perbarui(Map<String, dynamic> r) async {
    if (_busy != null || _readOnly) return;
    setState(() => _busy = 'perbarui:${r['id']}');
    try {
      await AppScope.of(context).api.post(ApiUrl.raporGenerate, {
        'santriId': widget.santri['id'],
        'periode': r['periode'],
      });
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _toast(
        context,
        'Rapor diperbarui',
        subtitle: 'Nilai & kehadiran ditarik ulang',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal memperbarui rapor.', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  // -------------------------------------------------------------------------
  // Kerangka layar
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RC.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _topBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final nama = (widget.santri['nama'] ?? '-').toString();
    final kelas = _kelasNama(widget.santri);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Material(
            color: _RC.surface,
            shape: CircleBorder(side: BorderSide(color: _RC.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_rounded, size: 20, color: _RC.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_RC.primary, _RC.primarySoft],
              ),
              border: Border.all(color: _RC.gold.withOpacity(0.6)),
            ),
            child: Text(_inisial(nama), style: _t(17, FontWeight.w800, _RC.goldLight)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(16.5, FontWeight.w800, _RC.ink, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS ${widget.santri['nis']}${kelas != '-' ? ' • $kelas' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(11.5, FontWeight.w500, _RC.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_rapors.isEmpty) return _emptyState();

    final idx = _idx >= _rapors.length ? 0 : _idx;
    final r = _rapors[idx] as Map<String, dynamic>;

    return RefreshIndicator(
      color: _RC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          if (_rapors.length > 1) ...[
            _periodeSelector(idx),
            const SizedBox(height: 14),
          ],
          _raporCard(r),
        ],
      ),
    );
  }

  /// Pilihan periode kalau santri punya lebih dari satu rapor.
  Widget _periodeSelector(int aktif) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rapors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final r = _rapors[i] as Map<String, dynamic>;
          final selected = i == aktif;
          final terbit = r['status'] == 'TERBIT';
          return GestureDetector(
            onTap: () => setState(() => _idx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _RC.primary : _RC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _RC.primary : _RC.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: terbit ? const Color(0xFF16A34A) : _RC.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r['periode']}',
                    style: _t(12, FontWeight.w800, selected ? Colors.white : _RC.inkSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: _RC.sage.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _RC.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _RC.gold.withOpacity(0.5), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F3A2E),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.description_outlined, size: 40, color: _RC.primary),
                  ),
                  const Positioned(
                    top: 10,
                    right: 18,
                    child: Icon(Icons.star_rounded, size: 18, color: _RC.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Belum Ada Rapor',
              textAlign: TextAlign.center,
              style: _t(19, FontWeight.w800, _RC.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _readOnly
                  ? 'Rapor untuk ${widget.santri['nama']} belum dibuat oleh pengelola.'
                  : 'Rapor untuk ${widget.santri['nama']} belum dibuat. '
                      'Kembali ke daftar santri, lalu tekan tombol Generate '
                      'pada kartu santri ini.',
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w500, _RC.inkSecondary, height: 1.5),
            ),
            const SizedBox(height: 22),
            Material(
              color: _RC.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Kembali ke Daftar Santri',
                        style: _t(13.5, FontWeight.w800, Colors.white),
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

  // -------------------------------------------------------------------------
  // Lembar rapor
  // -------------------------------------------------------------------------
  Widget _raporCard(Map<String, dynamic> r) {
    final ringkasan = (r['ringkasan'] as Map<String, dynamic>?) ?? {};
    final mapelList = (ringkasan['mapel'] as List? ?? []);
    final ujianList = (ringkasan['ujian'] as List? ?? []);
    final kehadiran = (ringkasan['kehadiran'] as Map<String, dynamic>?) ?? {};
    final terbit = r['status'] == 'TERBIT';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _RC.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: terbit ? _RC.primary.withOpacity(0.35) : _RC.line.withOpacity(0.8),
          width: terbit ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _RC.primary.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHeader(r, mapelList, ujianList, kehadiran, terbit),
          // Garis emas ala kop surat
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_RC.goldDark, _RC.goldLight, _RC.gold, _RC.goldDark],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mapelList.isNotEmpty) ...[
                  _secTitle(Icons.menu_book_outlined, 'Nilai Mata Pelajaran',
                      trailing: '${mapelList.length} mapel'),
                  const SizedBox(height: 6),
                  ...mapelList.map((m) {
                    final mm = m as Map<String, dynamic>;
                    final harian = mm['harian'] as num?;
                    final ujian = mm['ujian'] as num?;
                    final rincian = [
                      if (harian != null) 'Harian ${harian.toStringAsFixed(1)}',
                      if (ujian != null) 'Ujian ${ujian.toStringAsFixed(1)}',
                    ].join('  •  ');
                    return _nilaiBar(
                      mm['mapel'].toString(),
                      _d(mm['rataRata']),
                      kkm: (mm['kkm'] as num?)?.toDouble(),
                      rincian: rincian,
                    );
                  }),
                ],
                if (ujianList.isNotEmpty) ...[
                  if (mapelList.isNotEmpty) const SizedBox(height: 22),
                  _secTitle(Icons.fact_check_outlined, 'Nilai Ujian',
                      trailing: '${ujianList.length} ujian'),
                  const SizedBox(height: 6),
                  ...ujianList.map((m) {
                    final mm = m as Map<String, dynamic>;
                    return _nilaiBar(
                      mm['ujian'].toString(),
                      _d(mm['rataRata']),
                      kkm: (mm['kkm'] as num?)?.toDouble(),
                      rincian: mm['remedial'] == true
                          ? 'Awal ${_d(mm['nilaiAwal']).toStringAsFixed(1)} • Remedial'
                          : null,
                    );
                  }),
                ],
                if (kehadiran['total'] != null) ...[
                  if (mapelList.isNotEmpty || ujianList.isNotEmpty)
                    const SizedBox(height: 22),
                  _secTitle(Icons.how_to_reg_outlined, 'Kehadiran'),
                  const SizedBox(height: 12),
                  _kehadiranPanel(kehadiran),
                ],
                const SizedBox(height: 22),
                _statusPanel(terbit),
                if (!terbit && !_readOnly) ...[
                  const SizedBox(height: 12),
                  _aksiDraft(r),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kepala lembar: periode, status, gauge rata-rata, dan ringkasan cepat.
  Widget _sheetHeader(
    Map<String, dynamic> r,
    List mapelList,
    List ujianList,
    Map<String, dynamic> k,
    bool terbit,
  ) {
    final rata = r['rataRata'] != null ? _d(r['rataRata']) : null;

    var lulus = 0;
    for (final m in mapelList) {
      if (m is Map) {
        final batas = (m['kkm'] as num?)?.toDouble() ?? _RC.kkm;
        if (_d(m['rataRata']) >= batas) lulus++;
      }
    }

    final totalHadir = k['total'] is num ? (k['total'] as num).toDouble() : 0.0;
    final hadir = k['hadir'] is num ? (k['hadir'] as num).toDouble() : 0.0;
    final persenHadir = totalHadir > 0 ? '${(hadir / totalHadir * 100).round()}%' : '–';

    Widget hStat(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(icon, size: 15, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: _t(12, FontWeight.w600, Colors.white70))),
              Text(value, style: _t(13.5, FontWeight.w800, Colors.white)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_RC.primary, _RC.primarySoft],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -40, top: -50, child: _ring(170)),
          Positioned(right: 18, top: 18, child: _ring(76, opacity: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RAPOR DIGITAL',
                        style: _t(10, FontWeight.w800, _RC.goldLight, spacing: 1.2),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: terbit ? _RC.mint : _RC.goldLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            terbit ? Icons.verified_rounded : Icons.edit_note_rounded,
                            size: 14,
                            color: _RC.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            terbit ? 'Diterbitkan' : 'Draft',
                            style: _t(10.5, FontWeight.w800, _RC.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${r['periode']}',
                  style: _t(22, FontWeight.w800, Colors.white, height: 1.15),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(104, 104),
                            painter: _RingPainter(
                              progress: rata != null ? rata / 100 : 0,
                              color: _RC.goldLight,
                              track: Colors.white.withOpacity(0.16),
                              stroke: 9,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rata != null ? rata.toStringAsFixed(1) : '–',
                                style: _t(25, FontWeight.w800, Colors.white, height: 1.05),
                              ),
                              Text('rata-rata', style: _t(10, FontWeight.w600, Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: [
                          hStat(
                            Icons.task_alt_rounded,
                            'Lulus KKM',
                            mapelList.isEmpty ? '–' : '$lulus/${mapelList.length}',
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.14)),
                          hStat(Icons.fact_check_outlined, 'Ujian', '${ujianList.length}'),
                          Divider(height: 1, color: Colors.white.withOpacity(0.14)),
                          hStat(Icons.how_to_reg_outlined, 'Kehadiran', persenHadir),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu baris nilai dengan penanda KKM pada bar.
  Widget _nilaiBar(String label, double nilai, {double? kkm, String? rincian}) {
    final batas = kkm ?? _RC.kkm;
    final lulus = nilai >= batas;
    final fg = lulus ? _RC.greenFg : _RC.redFg;
    final bg = lulus ? _RC.greenBg : _RC.redBg;
    final warnaBar = lulus ? _RC.primary : const Color(0xFFDC2626);
    final frac = (nilai / 100).clamp(0.0, 1.0).toDouble();
    final kkmFrac = (batas / 100).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w700, _RC.ink),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(nilai.toStringAsFixed(1), style: _t(12.5, FontWeight.w800, fg)),
              ),
            ],
          ),
          if (rincian != null && rincian.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(rincian, style: _t(11, FontWeight.w500, _RC.inkSecondary)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (ctx, c) {
                final w = c.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _RC.surfaceDim,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 4,
                      child: Container(
                        width: w * frac,
                        height: 6,
                        decoration: BoxDecoration(
                          color: warnaBar,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: w * kkmFrac - 1,
                      top: 0,
                      child: Container(
                        width: 2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _RC.goldDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'KKM ${batas.toStringAsFixed(0)}',
            style: _t(10, FontWeight.w700, _RC.goldDark),
          ),
        ],
      ),
    );
  }

  /// Kehadiran: bar bersegmen + legenda.
  Widget _kehadiranPanel(Map<String, dynamic> k) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    final total = n(k['total']);
    final hadir = n(k['hadir']);
    final detail = k['sakit'] != null;
    final sakit = n(k['sakit']);
    final izin = n(k['izin']);
    final alpa = n(k['alpa']);
    final persen = total > 0 ? (hadir / total * 100).round() : 0;

    final segs = detail
        ? <(int, Color, String)>[
            (hadir, _RC.greenFg, 'Hadir'),
            (sakit, _RC.gold, 'Sakit'),
            (izin, _RC.amberFg, 'Izin'),
            (alpa, _RC.redFg, 'Alpa'),
          ]
        : <(int, Color, String)>[
            (hadir, _RC.greenFg, 'Hadir'),
            (math.max(0, total - hadir), _RC.inkMuted, 'Tidak hadir'),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RC.surfaceDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _RC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$persen%', style: _t(30, FontWeight.w800, _RC.primary, height: 1)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'tingkat kehadiran',
                    style: _t(12, FontWeight.w600, _RC.inkSecondary),
                  ),
                ),
              ),
              Text(
                '$hadir dari $total hari',
                style: _t(11.5, FontWeight.w700, _RC.inkSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 11,
              child: total == 0
                  ? Container(color: _RC.line)
                  : Row(
                      children: [
                        for (final s in segs)
                          if (s.$1 > 0)
                            Expanded(
                              flex: s.$1,
                              child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                color: s.$2,
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in segs)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _RC.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _RC.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: s.$2, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.$3}  ${s.$1}',
                        style: _t(11.5, FontWeight.w700, _RC.inkSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Panel status: jelas beda antara draft dan sudah terbit.
  Widget _statusPanel(bool terbit) {
    final bg = terbit ? _RC.sage : _RC.goldSurface;
    final fg = terbit ? _RC.primary : _RC.goldDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: (terbit ? _RC.gold : fg).withOpacity(0.5)),
            ),
            child: Icon(
              terbit ? Icons.verified_rounded : Icons.edit_note_rounded,
              size: 22,
              color: terbit ? _RC.primary : fg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terbit ? 'Rapor sudah diterbitkan' : 'Masih berstatus draft',
                  style: _t(13, FontWeight.w800, fg),
                ),
                const SizedBox(height: 2),
                Text(
                  terbit
                      ? 'Rapor ini sudah final dan tidak dapat diubah.'
                      : (_readOnly
                          ? 'Rapor ini belum diterbitkan oleh pengelola.'
                          : 'Periksa nilai dan kehadiran, perbarui jika perlu, lalu terbitkan.'),
                  style: _t(11.5, FontWeight.w500, fg.withOpacity(0.85), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol aksi untuk rapor draft: Perbarui + Terbitkan.
  Widget _aksiDraft(Map<String, dynamic> r) {
    final id = r['id']?.toString();
    final sibuk = _busy != null;
    final loadingTerbit = _busy == 'terbit:$id';
    final loadingPerbarui = _busy == 'perbarui:$id';

    Widget spinner(Color c) => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: c),
        );

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: sibuk ? null : () => _perbarui(r),
          icon: loadingPerbarui
              ? spinner(_RC.primary)
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text('Perbarui', style: _t(13, FontWeight.w800, _RC.primary)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _RC.primary,
            side: BorderSide(color: _RC.primary.withOpacity(0.4)),
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: sibuk ? null : () => _terbit(r),
              icon: loadingTerbit
                  ? spinner(Colors.white)
                  : const Icon(Icons.send_outlined, size: 18, color: Colors.white),
              label: Text('Terbitkan', style: _t(14, FontWeight.w800, Colors.white)),
              style: FilledButton.styleFrom(
                backgroundColor: _RC.primary,
                disabledBackgroundColor: _RC.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}