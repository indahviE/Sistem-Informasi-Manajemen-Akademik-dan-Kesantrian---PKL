import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../services/pdf_saver.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;
import 'rapor_pdf.dart';

// ============================================================================
// Token warna lokal
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

Color _warnaNilai(double? nilai, double kkm) {
  if (nilai == null) return _DC.inkSecondary;
  return nilai >= kkm ? _DC.greenFg : _DC.redFg;
}

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
  KopPondok? _kop;
  bool _membuatPdf = false;

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

  // ---------------------------------------------------------------- PDF

  /// Data kop (nama, alamat, logo pondok) diambil sekali, lalu disimpan.
  Future<KopPondok> _ambilKop() async {
    if (_kop != null) return _kop!;
    final api = AppScope.of(context).api;
    try {
      final res = await api.get('${ApiUrl.rapor}/kop');
      var m = Map<String, dynamic>.from(res as Map);
      if (m['data'] is Map) m = Map<String, dynamic>.from(m['data'] as Map);
      _kop = await KopPondok.dariJson(m);
      return _kop!;
    } catch (_) {
      return KopPondok.cadangan; // tidak disimpan, supaya dicoba lagi next time
    }
  }

  Future<void> _jalankanPdf(
    Future<void> Function(Uint8List bytes, String namaFile) aksi,
  ) async {
    if (_membuatPdf || _rapors.isEmpty) return;
    final rapor = _rapors[_index];
    setState(() => _membuatPdf = true);
    try {
      final kop = await _ambilKop();
      final bytes = await buatRaporPdf(
        santri: widget.santri,
        rapor: rapor,
        kop: kop,
        warnaUtama: _DC.primary,
      );
      await aksi(bytes, namaFileRapor(widget.santri, rapor));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat PDF. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _membuatPdf = false);
    }
  }

  // Sama seperti ekspor PDF di Audit Log: web = diunduh lewat browser,
  // Android/iOS = dibuka lewat share sheet.
  Future<void> _unduhPdf() => _jalankanPdf((bytes, nama) async {
        await savePdf(nama, bytes);
      });

  Widget _aksiPdf() {
    final sibuk = _membuatPdf;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: sibuk ? null : _unduhPdf,
        style: FilledButton.styleFrom(
          backgroundColor: _DC.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _t(13.5, FontWeight.w800, Colors.white),
        ),
        icon: sibuk
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf_rounded, size: 18),
        label: Text(sibuk ? 'Menyiapkan PDF...' : 'Unduh PDF'),
      ),
    );
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
                Text('Rapor', style: _t(19, FontWeight.w800, _DC.ink, height: 1.15)),
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
                Text('Hanya lihat', style: _t(10.5, FontWeight.w800, _DC.primary)),
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
          _aksiPdf(),
          const SizedBox(height: 14),
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
      height: 40,
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _DC.primary : _DC.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? _DC.primary : _DC.line),
              ),
              child: Text(
                '${_rapors[i]['periode']}',
                style: _t(12, FontWeight.w800, selected ? Colors.white : _DC.inkSecondary),
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
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _DC.paper,
                shape: BoxShape.circle,
                border: Border.all(color: _DC.gold.withOpacity(0.5), width: 1.5),
              ),
              child: Icon(Icons.hourglass_top_rounded, size: 36, color: _DC.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Rapor belum terbit',
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
// Dokumen rapor (lembar rapor: kop, identitas, tabel nilai, kehadiran)
// ============================================================================

class RaporDokumen extends StatelessWidget {
  final Map<String, dynamic> santri;
  final Map<String, dynamic> rapor;
  const RaporDokumen({super.key, required this.santri, required this.rapor});

  static const double _wNo = 26;
  static const double _wNilai = 48;
  static const double _wAkhir = 54;
  static const double _wKet = 26;

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
    final rata = _num(rapor['rataRata']);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kop(),
          Container(
            height: 3,
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
                _ringkasanStrip(mapelList, ujianList, kehadiran, rata),
                if (mapelList.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _judulBagian('Nilai mata pelajaran', trailing: '${mapelList.length} mapel'),
                  const SizedBox(height: 10),
                  _tabelMapel(mapelList, rata),
                ],
                if (ujianList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _judulBagian('Nilai ujian', trailing: '${ujianList.length} ujian'),
                  const SizedBox(height: 10),
                  _tabelUjian(ujianList),
                ],
                if (kehadiran['total'] != null) ...[
                  const SizedBox(height: 24),
                  _judulBagian('Kehadiran'),
                  const SizedBox(height: 10),
                  _kehadiran(kehadiran),
                ],
                const SizedBox(height: 14),
                _legenda(),
                const SizedBox(height: 20),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DC.primary, _DC.primarySoft],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                  border: Border.all(color: _DC.goldLight.withOpacity(0.8), width: 1.4),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 22, color: _DC.goldLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan hasil belajar santri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(11.5, FontWeight.w700, _DC.goldLight),
                    ),
                    const SizedBox(height: 2),
                    Text('Rapor Digital',
                        style: _t(23, FontWeight.w800, Colors.white, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
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
                    style: _t(12.5, FontWeight.w800, Colors.white),
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

    Widget field(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _t(11, FontWeight.w700, _DC.inkMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _t(14, FontWeight.w800, _DC.ink, height: 1.2),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_DC.primary, _DC.primarySoft],
                  ),
                  border: Border.all(color: _DC.gold.withOpacity(0.65), width: 1.4),
                ),
                child: Text(_inisial(nama), style: _t(19, FontWeight.w800, _DC.goldLight)),
              ),
              const SizedBox(width: 12),
              field('Nama santri', nama),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: _DC.line),
          ),
          Row(
            children: [
              field('NIS', '${santri['nis'] ?? '-'}'),
              Container(width: 1, height: 30, color: _DC.line),
              const SizedBox(width: 14),
              field('Kelas', kelas),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- ringkasan

  /// Satu strip dengan 3 angka utama (tanpa kartu terpisah-pisah).
  Widget _ringkasanStrip(
    List<Map<String, dynamic>> mapel,
    List<Map<String, dynamic>> ujian,
    Map<String, dynamic> k,
    double? rata,
  ) {
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

    Widget seg(int flex, IconData icon, String label, String value,
        {bool utama = false}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: _DC.gold),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(11, FontWeight.w700, _DC.inkSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: _t(utama ? 28 : 22, FontWeight.w800, _DC.primary, height: 1),
              ),
            ],
          ),
        ),
      );
    }

    Widget garis() => Container(width: 1, height: 56, color: _DC.line);

    return Container(
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.line),
      ),
      child: Row(
        children: [
          seg(5, Icons.workspace_premium_outlined, 'Rata-rata',
              rata != null ? rata.toStringAsFixed(1) : '–',
              utama: true),
          garis(),
          seg(4, Icons.task_alt_rounded, 'Tuntas',
              sumber.isEmpty ? '–' : '$tuntas/${sumber.length}'),
          garis(),
          seg(4, Icons.how_to_reg_outlined, 'Hadir', persen),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- judul bagian

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
        Expanded(child: Text(text, style: _t(15, FontWeight.w800, _DC.ink))),
        if (trailing != null)
          Text(trailing, style: _t(11.5, FontWeight.w600, _DC.inkSecondary)),
      ],
    );
  }

  // ---------------------------------------------------------------- tabel

  Widget _tabelBox({
    required List<Widget> header,
    required List<Widget> rows,
    Widget? footer,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _DC.surfaceDim,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(children: header),
          ),
          ...rows,
          if (footer != null) footer,
        ],
      ),
    );
  }

  Widget _kolom(String t, {double? w, TextAlign align = TextAlign.center}) {
    final txt = Text(
      t,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _t(10.5, FontWeight.w800, _DC.inkSecondary),
    );
    return w == null ? Expanded(child: txt) : SizedBox(width: w, child: txt);
  }

  Widget _ketIcon(double? nilai, double kkm) {
    if (nilai == null) {
      return Text('-', textAlign: TextAlign.center, style: _t(12, FontWeight.w700, _DC.inkMuted));
    }
    return nilai >= kkm
        ? const Icon(Icons.check_circle_rounded, size: 18, color: _DC.greenFg)
        : const Icon(Icons.error_rounded, size: 18, color: _DC.redFg);
  }

  BoxDecoration _barisDeco(int no) => BoxDecoration(
        color: no.isEven ? _DC.background : _DC.paper,
        border: const Border(top: BorderSide(color: _DC.line)),
      );

  Widget _tabelMapel(List<Map<String, dynamic>> list, double? rata) {
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final no = i + 1;
      final akhir = _num(m['rataRata']);
      final kkm = _num(m['kkm']) ?? _DC.kkm;
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: _barisDeco(no),
          child: Row(
            children: [
              SizedBox(
                width: _wNo,
                child: Text('$no',
                    textAlign: TextAlign.center,
                    style: _t(12, FontWeight.w700, _DC.inkMuted)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m['mapel'] ?? '-'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(13, FontWeight.w800, _DC.ink, height: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text('KKM ${_kkmStr(kkm)}',
                        style: _t(10.5, FontWeight.w600, _DC.inkMuted)),
                  ],
                ),
              ),
              SizedBox(
                width: _wNilai,
                child: Text(_n(_num(m['harian'])),
                    textAlign: TextAlign.center,
                    style: _t(12.5, FontWeight.w700, _DC.inkSecondary)),
              ),
              SizedBox(
                width: _wNilai,
                child: Text(_n(_num(m['ujian'])),
                    textAlign: TextAlign.center,
                    style: _t(12.5, FontWeight.w700, _DC.inkSecondary)),
              ),
              SizedBox(
                width: _wAkhir,
                child: Text(_n(akhir),
                    textAlign: TextAlign.center,
                    style: _t(14, FontWeight.w800, _warnaNilai(akhir, kkm))),
              ),
              SizedBox(width: _wKet, child: Center(child: _ketIcon(akhir, kkm))),
            ],
          ),
        ),
      );
    }

    Widget? footer;
    if (rata != null) {
      footer = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: _DC.goldSurface,
          border: Border(top: BorderSide(color: _DC.gold.withOpacity(0.4))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Rata-rata keseluruhan',
                  style: _t(12.5, FontWeight.w800, _DC.goldDark)),
            ),
            Text(rata.toStringAsFixed(1), style: _t(16, FontWeight.w800, _DC.primary)),
          ],
        ),
      );
    }

    return _tabelBox(
      header: [
        _kolom('No', w: _wNo),
        _kolom('Mata pelajaran', align: TextAlign.left),
        _kolom('Harian', w: _wNilai),
        _kolom('Ujian', w: _wNilai),
        _kolom('Akhir', w: _wAkhir),
        _kolom('', w: _wKet),
      ],
      rows: rows,
      footer: footer,
    );
  }

  Widget _tabelUjian(List<Map<String, dynamic>> list) {
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final no = i + 1;
      final nilai = _num(m['rataRata']);
      final kkm = _num(m['kkm']) ?? _DC.kkm;
      final remedial = m['remedial'] == true;
      final nilaiAwal = _num(m['nilaiAwal']);
      final sub = remedial
          ? (nilaiAwal != null ? 'Remedial • nilai awal ${_n(nilaiAwal)}' : 'Remedial')
          : null;

      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: _barisDeco(no),
          child: Row(
            children: [
              SizedBox(
                width: _wNo,
                child: Text('$no',
                    textAlign: TextAlign.center,
                    style: _t(12, FontWeight.w700, _DC.inkMuted)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m['ujian'] ?? '-'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(13, FontWeight.w800, _DC.ink, height: 1.2),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub, style: _t(10.5, FontWeight.w700, _DC.goldDark)),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: _wAkhir,
                child: Text(_n(nilai),
                    textAlign: TextAlign.center,
                    style: _t(14, FontWeight.w800, _warnaNilai(nilai, kkm))),
              ),
              SizedBox(
                width: _wNilai,
                child: Text(_kkmStr(kkm),
                    textAlign: TextAlign.center,
                    style: _t(12.5, FontWeight.w700, _DC.inkSecondary)),
              ),
              SizedBox(width: _wKet, child: Center(child: _ketIcon(nilai, kkm))),
            ],
          ),
        ),
      );
    }

    return _tabelBox(
      header: [
        _kolom('No', w: _wNo),
        _kolom('Ujian', align: TextAlign.left),
        _kolom('Nilai', w: _wAkhir),
        _kolom('KKM', w: _wNilai),
        _kolom('', w: _wKet),
      ],
      rows: rows,
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

    Widget item(String label, int v, Color c) => Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(label, style: _t(11, FontWeight.w700, _DC.inkSecondary)),
                ],
              ),
              const SizedBox(height: 5),
              Text('$v', style: _t(20, FontWeight.w800, _DC.ink, height: 1)),
            ],
          ),
        );

    Widget sekat() => Container(width: 1, height: 36, color: _DC.line);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(14),
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
                  child: Text('tingkat kehadiran',
                      style: _t(12, FontWeight.w600, _DC.inkSecondary)),
                ),
              ),
              Text('$hadir dari $total pertemuan',
                  style: _t(11, FontWeight.w700, _DC.inkSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
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
              item('Hadir', hadir, _DC.greenFg),
              sekat(),
              item('Sakit', sakit, _DC.gold),
              sekat(),
              item('Izin', izin, _DC.amberFg),
              sekat(),
              item('Alpa', alpa, _DC.redFg),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- legenda & penutup

  Widget _legenda() {
    Widget butir(IconData icon, Color c, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
            Text(text, style: _t(11, FontWeight.w600, _DC.inkSecondary)),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        butir(Icons.check_circle_rounded, _DC.greenFg, 'Tuntas (nilai ≥ KKM)'),
        butir(Icons.error_rounded, _DC.redFg, 'Belum tuntas (nilai < KKM)'),
      ],
    );
  }

  Widget _penutup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DC.goldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _DC.gold.withOpacity(0.6), width: 1.3),
            ),
            child: Icon(Icons.verified_rounded, size: 22, color: _DC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapor telah diterbitkan',
                    style: _t(13, FontWeight.w800, _DC.goldDark)),
                const SizedBox(height: 2),
                Text(
                  'Diterbitkan secara digital melalui sistem.',
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