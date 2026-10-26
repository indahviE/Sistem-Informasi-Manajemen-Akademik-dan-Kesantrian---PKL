import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// ============================================================================
// Token warna lokal (disamakan dengan rapor_screen.dart)
// ============================================================================

class _DC {
  _DC._();

  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get sage => SC.sage;
  static Color get mint => SC.mint;

  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFF1D58F);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);

  static const background = Color(0xFFFAF9F5);
  static const paper = Colors.white;
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

  /// KKM bawaan kalau server tidak mengirim kkm per mapel/ujian.
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

double? _num(dynamic v) => v is num ? v.toDouble() : null;

String _n(num? v) => v == null ? '-' : v.toStringAsFixed(1);

String _kkmStr(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _inisial(String nama) {
  final t = nama.trim();
  return t.isEmpty ? '?' : t.characters.first.toUpperCase();
}

Widget _ring(double size, {double opacity = 0.08}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(opacity), width: 1.5),
      ),
    );

// ============================================================================
// Layar rapor untuk Wali Santri (read-only)
// ============================================================================

/// Dipakai dari beranda wali:
/// `Navigator.push(context, MaterialPageRoute(
///    builder: (_) => RaporWaliScreen(santri: anak)));`
/// [santri] minimal berisi: id, nama, nis, kelas.namaKelas
class RaporWaliScreen extends StatefulWidget {
  final Map<String, dynamic> santri;
  const RaporWaliScreen({super.key, required this.santri});

  @override
  State<RaporWaliScreen> createState() => _RaporWaliScreenState();
}

class _RaporWaliScreenState extends State<RaporWaliScreen> {
  List<Map<String, dynamic>> _rapors = [];
  int _index = 0;
  bool _loading = true;
  String? _error;

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
        // Pengaman di sisi aplikasi: wali hanya boleh melihat rapor TERBIT.
        // (Filter utama tetap harus di backend.)
        _rapors = items
            .whereType<Map<String, dynamic>>()
            .where((r) => r['status'] == 'TERBIT')
            .toList();
        _index = 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _topBar(),
                Expanded(child: _content()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Material(
            color: _DC.paper,
            shape: CircleBorder(side: BorderSide(color: _DC.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_rounded, size: 20, color: _DC.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapor Digital', style: _t(19, FontWeight.w800, _DC.ink, height: 1.15)),
                const SizedBox(height: 2),
                Text(
                  '${widget.santri['nama'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12, FontWeight.w500, _DC.inkSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _DC.sage,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: _DC.primary),
                const SizedBox(width: 5),
                Text('Hanya Lihat', style: _t(10.5, FontWeight.w800, _DC.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_rapors.isEmpty) return _emptyState();

    final rapor = _rapors[_index];

    return RefreshIndicator(
      color: _DC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (_rapors.length > 1) ...[
            _periodePicker(),
            const SizedBox(height: 14),
          ],
          RaporDokumen(
            key: ValueKey(rapor['id']),
            santri: widget.santri,
            rapor: rapor,
          ),
        ],
      ),
    );
  }

  Widget _periodePicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rapors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final selected = i == _index;
          return GestureDetector(
            onTap: () => setState(() => _index = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _DC.primary : _DC.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _DC.primary : _DC.line),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _DC.primary.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 15,
                    color: selected ? _DC.goldLight : _DC.inkSecondary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${_rapors[i]['periode']}',
                    style: _t(12, FontWeight.w800, selected ? Colors.white : _DC.inkSecondary),
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
                      color: _DC.sage.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _DC.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: _DC.gold.withOpacity(0.5), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F3A2E),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.hourglass_top_rounded, size: 38, color: _DC.primary),
                  ),
                  const Positioned(
                    top: 10,
                    right: 18,
                    child: Icon(Icons.star_rounded, size: 18, color: _DC.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Rapor Belum Terbit',
              textAlign: TextAlign.center,
              style: _t(19, FontWeight.w800, _DC.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Rapor ${widget.santri['nama'] ?? 'santri'} belum diterbitkan '
              'oleh pihak pondok. Anda akan melihatnya di sini setelah rapor terbit.',
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w500, _DC.inkSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Dokumen rapor (tampilan seperti lembar rapor resmi)
// ============================================================================

class RaporDokumen extends StatelessWidget {
  final Map<String, dynamic> santri;
  final Map<String, dynamic> rapor;
  const RaporDokumen({super.key, required this.santri, required this.rapor});

  List<Map<String, dynamic>> _daftar(dynamic v) => ((v as List?) ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  @override
  Widget build(BuildContext context) {
    final ringkasan = (rapor['ringkasan'] as Map<String, dynamic>?) ?? {};
    final mapelList = _daftar(ringkasan['mapel']);
    final ujianList = _daftar(ringkasan['ujian']);
    final kehadiran = (ringkasan['kehadiran'] as Map<String, dynamic>?) ?? {};

    var bagian = 0;
    String huruf() => String.fromCharCode('A'.codeUnitAt(0) + bagian++);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _DC.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _DC.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kop(),
          // Garis ganda emas khas kop surat
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_DC.goldDark, _DC.goldLight, _DC.gold, _DC.goldDark],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _identitas(),
                const SizedBox(height: 14),
                _ringkasanTiles(mapelList, ujianList, kehadiran),
                if (mapelList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _judulBagian('${huruf()}. Nilai Mata Pelajaran',
                      trailing: '${mapelList.length} mapel'),
                  const SizedBox(height: 12),
                  for (var i = 0; i < mapelList.length; i++) _itemMapel(i + 1, mapelList[i]),
                ],
                if (ujianList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _judulBagian('${huruf()}. Nilai Ujian', trailing: '${ujianList.length} ujian'),
                  const SizedBox(height: 12),
                  for (var i = 0; i < ujianList.length; i++) _itemUjian(i + 1, ujianList[i]),
                ],
                if (kehadiran['total'] != null) ...[
                  const SizedBox(height: 16),
                  _judulBagian('${huruf()}. Kehadiran'),
                  const SizedBox(height: 12),
                  _kehadiran(kehadiran),
                ],
                const SizedBox(height: 22),
                _penutup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- kop

  Widget _kop() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DC.primary, _DC.primarySoft],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -40, top: -50, child: _ring(170)),
          Positioned(left: -30, bottom: -60, child: _ring(140, opacity: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                    border: Border.all(color: _DC.goldLight.withOpacity(0.8), width: 1.6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _DC.gold.withOpacity(0.55)),
                      ),
                      child: const Icon(Icons.menu_book_rounded, size: 26, color: _DC.goldLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RAPOR DIGITAL',
                  textAlign: TextAlign.center,
                  style: _t(19, FontWeight.w800, Colors.white, height: 1.1, spacing: 2.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'Laporan Hasil Belajar Santri',
                  textAlign: TextAlign.center,
                  style: _t(12, FontWeight.w600, Colors.white70),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _DC.gold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _DC.gold.withOpacity(0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_available_outlined, size: 14, color: _DC.goldLight),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Periode ${rapor['periode'] ?? '-'}',
                          overflow: TextOverflow.ellipsis,
                          style: _t(12, FontWeight.w800, _DC.goldLight),
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

  // ---------------------------------------------------------------- identitas

  Widget _identitas() {
    final nama = '${santri['nama'] ?? '-'}';
    final k = santri['kelas'];
    final kelas = k is Map ? '${k['namaKelas'] ?? '-'}' : '-';

    Widget kotak(IconData icon, String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: _DC.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DC.line),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _DC.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: _t(9.5, FontWeight.w700, _DC.inkMuted, spacing: 0.4)),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(12.5, FontWeight.w800, _DC.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.surfaceDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_DC.primary, _DC.primarySoft],
                  ),
                  border: Border.all(color: _DC.gold.withOpacity(0.65), width: 1.5),
                ),
                child: Text(_inisial(nama), style: _t(22, FontWeight.w800, _DC.goldLight)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NAMA SANTRI', style: _t(9.5, FontWeight.w800, _DC.inkMuted, spacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(
                      nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(16, FontWeight.w800, _DC.ink, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              kotak(Icons.tag_rounded, 'NIS', '${santri['nis'] ?? '-'}'),
              const SizedBox(width: 8),
              kotak(Icons.class_outlined, 'KELAS', kelas),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- ringkasan

  Widget _ringkasanTiles(
    List<Map<String, dynamic>> mapel,
    List<Map<String, dynamic>> ujian,
    Map<String, dynamic> k,
  ) {
    final rata = _num(rapor['rataRata']);

    // "Tuntas" dihitung dari mapel; kalau tidak ada mapel, pakai ujian.
    final sumber = mapel.isNotEmpty ? mapel : ujian;
    var tuntas = 0;
    for (final m in sumber) {
      final akhir = _num(m['rataRata']);
      final kkm = _num(m['kkm']) ?? _DC.kkm;
      if (akhir != null && akhir >= kkm) tuntas++;
    }

    final total = _num(k['total']) ?? 0;
    final hadir = _num(k['hadir']) ?? 0;
    final persen = total > 0 ? '${(hadir / total * 100).round()}%' : '–';

    Widget tile(IconData icon, String label, String value,
        {bool utama = false, String? sub}) {
      final fg = utama ? Colors.white : _DC.primary;
      return Expanded(
        flex: utama ? 5 : 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: utama
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_DC.primary, _DC.primarySoft],
                  )
                : null,
            color: utama ? null : _DC.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: utama ? _DC.primary : _DC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: utama ? _DC.goldLight : _DC.gold),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(10.5, FontWeight.w700, utama ? Colors.white70 : _DC.inkSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: _t(utama ? 28 : 22, FontWeight.w800, fg, height: 1)),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(10, FontWeight.w600, utama ? Colors.white60 : _DC.inkMuted),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(Icons.workspace_premium_outlined, 'Rata-rata',
              rata != null ? rata.toStringAsFixed(1) : '–',
              utama: true, sub: 'Nilai keseluruhan'),
          const SizedBox(width: 8),
          tile(Icons.task_alt_rounded, 'Tuntas',
              sumber.isEmpty ? '–' : '$tuntas/${sumber.length}'),
          const SizedBox(width: 8),
          tile(Icons.how_to_reg_outlined, 'Hadir', persen),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- bagian

  Widget _judulBagian(String text, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _DC.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: _t(14, FontWeight.w800, _DC.ink))),
        if (trailing != null)
          Text(trailing, style: _t(11, FontWeight.w600, _DC.inkSecondary)),
      ],
    );
  }

  Widget _pillKet(double? nilai, double kkm) {
    if (nilai == null) {
      return _pill('-', _DC.surfaceDim, _DC.inkSecondary, null);
    }
    final tuntas = nilai >= kkm;
    return tuntas
        ? _pill('Tuntas', _DC.greenBg, _DC.greenFg, Icons.check_circle_rounded)
        : _pill('Belum tuntas', _DC.redBg, _DC.redFg, Icons.error_outline_rounded);
  }

  Widget _pill(String text, Color bg, Color fg, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: _t(10.5, FontWeight.w800, fg)),
        ],
      ),
    );
  }

  Widget _komponen(String label, String value, {Color? color, bool tebal = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _t(10, FontWeight.w700, _DC.inkMuted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: _t(tebal ? 16 : 14, FontWeight.w800, color ?? _DC.ink, height: 1),
          ),
        ],
      ),
    );
  }

  /// Bar nilai dengan penanda KKM.
  Widget _barNilai(double? nilai, double kkm) {
    final frac = ((nilai ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    final kkmFrac = (kkm / 100).clamp(0.0, 1.0).toDouble();
    final lulus = nilai != null && nilai >= kkm;

    return SizedBox(
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
                    color: _DC.surfaceDim,
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
                    color: lulus ? _DC.primary : const Color(0xFFDC2626),
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
                    color: _DC.goldDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _itemKartu({
    required int no,
    required String nama,
    String? sub,
    required double? akhir,
    required double kkm,
    required List<Widget> komponen,
  }) {
    final warna = akhir == null
        ? _DC.inkSecondary
        : (akhir >= kkm ? _DC.greenFg : _DC.redFg);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _DC.sage, shape: BoxShape.circle),
                child: Text('$no', style: _t(11.5, FontWeight.w800, _DC.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(13.5, FontWeight.w800, _DC.ink, height: 1.25),
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub, style: _t(10.5, FontWeight.w500, _DC.inkSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _pillKet(akhir, kkm),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [...komponen]),
          const SizedBox(height: 10),
          _barNilai(akhir, kkm),
          const SizedBox(height: 3),
          Row(
            children: [
              Text('KKM ${_kkmStr(kkm)}', style: _t(10, FontWeight.w700, _DC.goldDark)),
              const Spacer(),
              Text(
                akhir == null ? '' : '${akhir.toStringAsFixed(1)} / 100',
                style: _t(10, FontWeight.w700, warna),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemMapel(int no, Map<String, dynamic> m) {
    final akhir = _num(m['rataRata']);
    final kkm = _num(m['kkm']) ?? _DC.kkm;
    final warna = akhir == null
        ? _DC.inkSecondary
        : (akhir >= kkm ? _DC.greenFg : _DC.redFg);

    return _itemKartu(
      no: no,
      nama: '${m['mapel'] ?? '-'}',
      akhir: akhir,
      kkm: kkm,
      komponen: [
        _komponen('Harian', _n(m['harian'] as num?)),
        _komponen('Ujian', _n(m['ujian'] as num?)),
        _komponen('Nilai Akhir', _n(akhir), color: warna, tebal: true),
      ],
    );
  }

  Widget _itemUjian(int no, Map<String, dynamic> m) {
    final nilai = _num(m['rataRata']);
    final kkm = _num(m['kkm']) ?? _DC.kkm;
    final remedial = m['remedial'] == true;
    final warna = nilai == null
        ? _DC.inkSecondary
        : (nilai >= kkm ? _DC.greenFg : _DC.redFg);

    return _itemKartu(
      no: no,
      nama: '${m['ujian'] ?? '-'}',
      sub: remedial
          ? (m['nilaiAwal'] != null
              ? 'Remedial • nilai awal ${_n(m['nilaiAwal'] as num?)}'
              : 'Remedial')
          : null,
      akhir: nilai,
      kkm: kkm,
      komponen: [
        _komponen('Nilai', _n(nilai), color: warna, tebal: true),
        _komponen('KKM', _kkmStr(kkm)),
      ],
    );
  }

  // ---------------------------------------------------------------- kehadiran

  Widget _kehadiran(Map<String, dynamic> k) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    final hadir = n(k['hadir']);
    final total = n(k['total']);
    final sakit = n(k['sakit']);
    final izin = n(k['izin']);
    final alpa = n(k['alpa']);
    final persen = total > 0 ? (hadir / total * 100).round() : 0;

    final segs = <(int, Color)>[
      (hadir, _DC.greenFg),
      (sakit, _DC.gold),
      (izin, _DC.amberFg),
      (alpa, _DC.redFg),
    ];

    Widget kotak(String label, int v, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: _DC.surfaceDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DC.line),
            ),
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(height: 7),
                Text('$v', style: _t(18, FontWeight.w800, _DC.ink, height: 1)),
                const SizedBox(height: 4),
                Text(label, style: _t(10.5, FontWeight.w700, _DC.inkSecondary)),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$persen%', style: _t(30, FontWeight.w800, _DC.primary, height: 1)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'tingkat kehadiran',
                    style: _t(12, FontWeight.w600, _DC.inkSecondary),
                  ),
                ),
              ),
              Text('$hadir dari $total pertemuan', style: _t(11, FontWeight.w700, _DC.inkSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 11,
              child: total == 0
                  ? Container(color: _DC.line)
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
          Row(
            children: [
              kotak('Hadir', hadir, _DC.greenFg),
              const SizedBox(width: 8),
              kotak('Sakit', sakit, _DC.gold),
              const SizedBox(width: 8),
              kotak('Izin', izin, _DC.amberFg),
              const SizedBox(width: 8),
              kotak('Alpa', alpa, _DC.redFg),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- penutup

  Widget _penutup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.goldSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DC.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _DC.gold.withOpacity(0.6), width: 1.4),
            ),
            child: Icon(Icons.verified_rounded, size: 24, color: _DC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapor Telah Diterbitkan', style: _t(13, FontWeight.w800, _DC.goldDark)),
                const SizedBox(height: 2),
                Text(
                  'Rapor ini diterbitkan secara digital melalui sistem.',
                  style: _t(11, FontWeight.w500, _DC.goldDark.withOpacity(0.85), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}