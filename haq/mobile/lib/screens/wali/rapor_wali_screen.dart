import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// ============================================================================
// Token warna lokal (disamakan dengan rapor_screen.dart)
// ============================================================================

class _DC {
  static Color get primary => SC.primary;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFF9D77E);
  static const background = Color(0xFFFAF9F5);
  static const paper = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const ink = Color(0xFF1F2937);
  static const inkSecondary = Color(0xFF475569);
  static const greenFg = Color(0xFF166534);
  static const redFg = Color(0xFF991B1B);

  /// KKM bawaan kalau server tidak mengirim kkm per mapel/ujian.
  static const double kkm = 75;
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) => TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: height,
    );

String _n(num? v) => v == null ? '-' : v.toStringAsFixed(1);

String _kkmStr(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class _Cell {
  final String text;
  final String? sub;
  final Color? color;
  final bool bold;
  final TextAlign align;
  const _Cell(
    this.text, {
    this.sub,
    this.color,
    this.bold = false,
    this.align = TextAlign.center,
  });
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
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: _DC.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapor Digital',
                  style: _t(19, FontWeight.w800, _DC.primary, height: 1.15),
                ),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _rapors.length; i++)
          Material(
            color: i == _index ? _DC.primary : _DC.paper,
            borderRadius: BorderRadius.circular(9999),
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () => setState(() => _index = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: i == _index ? _DC.primary : _DC.line,
                  ),
                ),
                child: Text(
                  '${_rapors[i]['periode']}',
                  style: _t(
                    12,
                    FontWeight.w800,
                    i == _index ? Colors.white : _DC.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
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
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: _DC.sage.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 44,
                color: _DC.primary,
              ),
            ),
            const SizedBox(height: 20),
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

  @override
  Widget build(BuildContext context) {
    final ringkasan = (rapor['ringkasan'] as Map<String, dynamic>?) ?? {};
    final mapelList = (ringkasan['mapel'] as List? ?? []);
    final ujianList = (ringkasan['ujian'] as List? ?? []);
    final kehadiran = (ringkasan['kehadiran'] as Map<String, dynamic>?) ?? {};
    final rataRata = rapor['rataRata'] as num?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: _DC.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _DC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F3A2E),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kop(),
          const SizedBox(height: 16),
          _identitas(),
          if (mapelList.isNotEmpty) ...[
            const SizedBox(height: 20),
            _judulBagian('A. Nilai Mata Pelajaran'),
            const SizedBox(height: 8),
            _tabelMapel(mapelList),
          ],
          if (ujianList.isNotEmpty) ...[
            const SizedBox(height: 20),
            _judulBagian(
              mapelList.isNotEmpty ? 'B. Nilai Ujian' : 'A. Nilai Ujian',
            ),
            const SizedBox(height: 8),
            _tabelUjian(ujianList),
          ],
          if (kehadiran['total'] != null) ...[
            const SizedBox(height: 20),
            _judulBagian(_hurufBagian(mapelList, ujianList) + '. Kehadiran'),
            const SizedBox(height: 8),
            _kehadiran(kehadiran),
          ],
          if (rataRata != null) ...[
            const SizedBox(height: 20),
            _ringkasanAkhir(rataRata),
          ],
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Rapor ini diterbitkan secara digital melalui sistem.',
              textAlign: TextAlign.center,
              style: _t(10.5, FontWeight.w500, _DC.inkSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _hurufBagian(List mapel, List ujian) {
    var n = 0;
    if (mapel.isNotEmpty) n++;
    if (ujian.isNotEmpty) n++;
    return String.fromCharCode('A'.codeUnitAt(0) + n);
  }

  // ---------------------------------------------------------------- kop

  Widget _kop() {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _DC.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 26,
            color: _DC.gold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'RAPOR DIGITAL',
          textAlign: TextAlign.center,
          style: _t(18, FontWeight.w800, _DC.primary, height: 1.1),
        ),
        const SizedBox(height: 3),
        Text(
          'Laporan Hasil Belajar Santri',
          textAlign: TextAlign.center,
          style: _t(12, FontWeight.w600, _DC.inkSecondary),
        ),
        const SizedBox(height: 12),
        // Garis ganda khas kop surat
        Container(height: 2, color: _DC.primary),
        const SizedBox(height: 3),
        Container(height: 1, color: _DC.primary.withOpacity(0.5)),
      ],
    );
  }

  // ---------------------------------------------------------------- identitas

  Widget _identitas() {
    final kelas = santri['kelas']?['namaKelas'] ?? '-';
    return Column(
      children: [
        _barisIdentitas('Nama', '${santri['nama'] ?? '-'}'),
        _barisIdentitas('NIS', '${santri['nis'] ?? '-'}'),
        _barisIdentitas('Kelas', '$kelas'),
        _barisIdentitas('Periode', '${rapor['periode'] ?? '-'}'),
      ],
    );
  }

  Widget _barisIdentitas(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: _t(12.5, FontWeight.w600, _DC.inkSecondary),
            ),
          ),
          Text(':  ', style: _t(12.5, FontWeight.w600, _DC.inkSecondary)),
          Expanded(
            child: Text(value, style: _t(12.5, FontWeight.w800, _DC.ink)),
          ),
        ],
      ),
    );
  }

  Widget _judulBagian(String text) =>
      Text(text, style: _t(13.5, FontWeight.w800, _DC.primary));

  // ---------------------------------------------------------------- tabel

  Widget _tabelMapel(List list) {
    final rows = <List<_Cell>>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i] as Map<String, dynamic>;
      final akhir = (m['rataRata'] as num?)?.toDouble();
      final kkm = (m['kkm'] as num?)?.toDouble() ?? _DC.kkm;
      final tuntas = akhir != null && akhir >= kkm;
      rows.add([
        _Cell('${i + 1}'),
        _Cell('${m['mapel'] ?? '-'}', align: TextAlign.left, bold: true),
        _Cell(_n(m['harian'] as num?)),
        _Cell(_n(m['ujian'] as num?)),
        _Cell(
          _n(akhir),
          bold: true,
          color: akhir == null
              ? _DC.inkSecondary
              : (tuntas ? _DC.greenFg : _DC.redFg),
        ),
        _Cell(_kkmStr(kkm)),
        _Cell(
          akhir == null ? '-' : (tuntas ? 'Tuntas' : 'Belum'),
          bold: true,
          color: akhir == null
              ? _DC.inkSecondary
              : (tuntas ? _DC.greenFg : _DC.redFg),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabel(
          const ['No', 'Mata Pelajaran', 'Harian', 'Ujian', 'Akhir', 'KKM', 'Ket'],
          rows,
          const {
            0: FixedColumnWidth(24),
            1: FlexColumnWidth(),
            2: FixedColumnWidth(44),
            3: FixedColumnWidth(44),
            4: FixedColumnWidth(46),
            5: FixedColumnWidth(36),
            6: FixedColumnWidth(50),
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Ket: Tuntas = nilai akhir mencapai KKM.',
          style: _t(10.5, FontWeight.w500, _DC.inkSecondary),
        ),
      ],
    );
  }

  Widget _tabelUjian(List list) {
    final rows = <List<_Cell>>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i] as Map<String, dynamic>;
      final nilai = (m['rataRata'] as num?)?.toDouble();
      final kkm = (m['kkm'] as num?)?.toDouble() ?? _DC.kkm;
      final tuntas = nilai != null && nilai >= kkm;
      final remedial = m['remedial'] == true;
      rows.add([
        _Cell('${i + 1}'),
        _Cell(
          '${m['ujian'] ?? '-'}',
          bold: true,
          align: TextAlign.left,
          sub: remedial && m['nilaiAwal'] != null
              ? 'Remedial • nilai awal ${_n(m['nilaiAwal'] as num?)}'
              : null,
        ),
        _Cell(
          _n(nilai),
          bold: true,
          color: nilai == null
              ? _DC.inkSecondary
              : (tuntas ? _DC.greenFg : _DC.redFg),
        ),
        _Cell(_kkmStr(kkm)),
        _Cell(
          nilai == null ? '-' : (tuntas ? 'Tuntas' : 'Belum'),
          bold: true,
          color: nilai == null
              ? _DC.inkSecondary
              : (tuntas ? _DC.greenFg : _DC.redFg),
        ),
      ]);
    }

    return _tabel(
      const ['No', 'Ujian', 'Nilai', 'KKM', 'Ket'],
      rows,
      const {
        0: FixedColumnWidth(24),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(48),
        3: FixedColumnWidth(36),
        4: FixedColumnWidth(50),
      },
    );
  }

  /// Kolom ke-1 selalu rata kiri (nama mapel / nama ujian).
  Widget _tabel(
    List<String> head,
    List<List<_Cell>> rows,
    Map<int, TableColumnWidth> widths,
  ) {
    return Table(
      columnWidths: widths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        top: BorderSide(color: _DC.primary.withOpacity(0.5)),
        bottom: BorderSide(color: _DC.primary.withOpacity(0.5)),
        horizontalInside: const BorderSide(color: _DC.line),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: _DC.sage),
          children: [
            for (var i = 0; i < head.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  head[i],
                  textAlign: i == 1 ? TextAlign.left : TextAlign.center,
                  style: _t(10.5, FontWeight.w800, _DC.primary),
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (final c in row)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    crossAxisAlignment: c.align == TextAlign.left
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        c.text,
                        textAlign: c.align,
                        style: _t(
                          11.5,
                          c.bold ? FontWeight.w800 : FontWeight.w600,
                          c.color ?? _DC.ink,
                          height: 1.25,
                        ),
                      ),
                      if (c.sub != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          c.sub!,
                          textAlign: c.align,
                          style: _t(10, FontWeight.w500, _DC.inkSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- kehadiran

  Widget _kehadiran(Map<String, dynamic> k) {
    final hadir = (k['hadir'] as num?)?.toInt() ?? 0;
    final total = (k['total'] as num?)?.toInt() ?? 0;
    final persen = total > 0 ? (hadir / total * 100) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _kotakHadir('Hadir', '$hadir')),
            const SizedBox(width: 8),
            Expanded(child: _kotakHadir('Sakit', '${k['sakit'] ?? 0}')),
            const SizedBox(width: 8),
            Expanded(child: _kotakHadir('Izin', '${k['izin'] ?? 0}')),
            const SizedBox(width: 8),
            Expanded(child: _kotakHadir('Alpa', '${k['alpa'] ?? 0}')),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Persentase kehadiran: ${persen.toStringAsFixed(0)}% '
            '($hadir dari $total pertemuan)',
            style: _t(11.5, FontWeight.w600, _DC.inkSecondary),
          ),
        ),
      ],
    );
  }

  Widget _kotakHadir(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _DC.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DC.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: _t(17, FontWeight.w800, _DC.primary, height: 1),
          ),
          const SizedBox(height: 4),
          Text(label, style: _t(10.5, FontWeight.w700, _DC.inkSecondary)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- ringkasan

  Widget _ringkasanAkhir(num rataRata) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _DC.sage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DC.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rata-rata Nilai',
              style: _t(13, FontWeight.w800, _DC.primary),
            ),
          ),
          Text(
            rataRata.toStringAsFixed(1),
            style: _t(26, FontWeight.w800, _DC.primary, height: 1),
          ),
        ],
      ),
    );
  }
}