import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ============================================================================
// Pembuat PDF rapor (A4). Dipakai dari rapor_wali_screen.dart.
// ============================================================================

/// Data kop surat per pondok (multi-tenant): nama, alamat, logo.
class KopPondok {
  final String nama;
  final String? alamat;
  final Uint8List? logo;
  const KopPondok({required this.nama, this.alamat, this.logo});

  /// Dipakai kalau data pondok gagal dimuat.
  static const cadangan = KopPondok(nama: 'Pondok Pesantren');

  /// Dari respons `GET /rapor/kop`: { namaPondok, alamat, logoUrl }.
  /// logoUrl bisa berupa data URL base64 ("data:image/png;base64,...") atau URL http.
  static Future<KopPondok> dariJson(Map<String, dynamic> j) async {
    final nama = '${j['namaPondok'] ?? ''}'.trim();
    final alamat = '${j['alamat'] ?? ''}'.trim();
    return KopPondok(
      nama: nama.isEmpty ? 'Pondok Pesantren' : nama,
      alamat: alamat.isEmpty ? null : alamat,
      logo: await _muatLogo(j['logoUrl']?.toString()),
    );
  }

  static Future<Uint8List?> _muatLogo(String? src) async {
    if (src == null || src.trim().isEmpty) return null;
    try {
      final s = src.trim();
      if (s.startsWith('data:')) {
        final i = s.indexOf('base64,');
        if (i < 0) return null;
        return base64Decode(s.substring(i + 7).replaceAll(RegExp(r'\s'), ''));
      }
      if (s.startsWith('http')) {
        final r = await http.get(Uri.parse(s)).timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) return r.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}

/// Nama file, contoh: Rapor_Abdullah_Hasan_2026_2027_Ganjil.pdf
String namaFileRapor(Map<String, dynamic> santri, Map<String, dynamic> rapor) {
  String bersih(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return 'Rapor_${bersih('${santri['nama'] ?? 'Santri'}')}_${bersih('${rapor['periode'] ?? ''}')}.pdf';
}

// ---------------------------------------------------------------- warna & util

final _ink = PdfColor.fromHex('#0F172A');
final _inkSoft = PdfColor.fromHex('#475569');
final _muted = PdfColor.fromHex('#64748B');
final _line = PdfColor.fromHex('#D9D4C7');
final _paperDim = PdfColor.fromHex('#F7F5EF');
final _gold = PdfColor.fromHex('#C5A059');
final _goldDark = PdfColor.fromHex('#7A5B10');
final _goldSurface = PdfColor.fromHex('#FAF5EC');
final _green = PdfColor.fromHex('#166534');
final _red = PdfColor.fromHex('#991B1B');

PdfColor _pc(Color c) => PdfColor(c.r, c.g, c.b);

PdfColor _campur(PdfColor c, double t) => PdfColor(
      c.red + (1 - c.red) * t,
      c.green + (1 - c.green) * t,
      c.blue + (1 - c.blue) * t,
    );

double? _num(dynamic v) => v is num ? v.toDouble() : null;
String _n(num? v) => v == null ? '-' : v.toStringAsFixed(1);
String _kkmStr(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

List<Map<String, dynamic>> _daftar(dynamic v) => ((v as List?) ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList();

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
String _tgl(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

// ---------------------------------------------------------------- pembuat PDF

Future<Uint8List> buatRaporPdf({
  required Map<String, dynamic> santri,
  required Map<String, dynamic> rapor,
  required KopPondok kop,
  required Color warnaUtama,
  bool tandaTangan = true,
}) async {
  // Font Nunito harus di-embed (PDF tidak bisa memakai font aplikasi otomatis).
  final reg = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Bold.ttf'));

  final primary = _pc(warnaUtama);

  pw.TextStyle st(double size, {pw.Font? f, PdfColor? c, double? h}) =>
      pw.TextStyle(font: f ?? reg, fontSize: size, color: c ?? _ink, height: h);

  // Logo (kalau format tidak didukung, pakai inisial pondok)
  pw.ImageProvider? logoImg;
  if (kop.logo != null) {
    try {
      logoImg = pw.MemoryImage(kop.logo!);
    } catch (_) {
      logoImg = null;
    }
  }

  // ---- data
  final s = rapor['santri'] is Map
      ? <String, dynamic>{...santri, ...Map<String, dynamic>.from(rapor['santri'] as Map)}
      : santri;
  final nama = '${s['nama'] ?? '-'}';
  final nis = '${s['nis'] ?? '-'}';
  final kls = s['kelas'];
  final kelas = kls is Map ? '${kls['namaKelas'] ?? '-'}' : '-';
  final waliKelas = (kls is Map && kls['waliKelas'] is Map)
      ? '${(kls['waliKelas'] as Map)['nama'] ?? ''}'
      : '';
  final periode = '${rapor['periode'] ?? '-'}';

  final ringkasan = rapor['ringkasan'] is Map
      ? Map<String, dynamic>.from(rapor['ringkasan'] as Map)
      : <String, dynamic>{};
  final mapelList = _daftar(ringkasan['mapel']);
  final ujianList = _daftar(ringkasan['ujian']);
  final k = ringkasan['kehadiran'] is Map
      ? Map<String, dynamic>.from(ringkasan['kehadiran'] as Map)
      : <String, dynamic>{};
  final rata = _num(rapor['rataRata']);

  final id = '${rapor['id'] ?? ''}';
  final noDok = id.isEmpty
      ? '-'
      : 'RPR-${(id.length > 8 ? id.substring(id.length - 8) : id).toUpperCase()}';
  final terbit = DateTime.tryParse('${rapor['updatedAt'] ?? rapor['createdAt'] ?? ''}')?.toLocal();
  final dicetak = DateTime.now();

  // ketuntasan: dari mapel; kalau tidak ada mapel, dari ujian
  final sumber = mapelList.isNotEmpty ? mapelList : ujianList;
  var tuntas = 0;
  for (final m in sumber) {
    final akhir = _num(m['rataRata']);
    final kkm = _num(m['kkm']) ?? 75;
    if (akhir != null && akhir >= kkm) tuntas++;
  }

  int bil(dynamic v) => v is num ? v.toInt() : 0;
  final hadir = bil(k['hadir']);
  final sakit = bil(k['sakit']);
  final izin = bil(k['izin']);
  final alpa = bil(k['alpa']);
  final total = bil(k['total']);
  final persen = total > 0 ? (hadir / total * 100).round() : 0;

  // ---- komponen kecil
  pw.Widget sel(
    String t, {
    pw.TextAlign a = pw.TextAlign.center,
    pw.Font? f,
    PdfColor? c,
    double size = 9.5,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t, textAlign: a, style: st(size, f: f, c: c)),
      );

  pw.Widget hdr(String t, {pw.TextAlign a = pw.TextAlign.center}) =>
      sel(t, a: a, f: bold, c: PdfColors.white, size: 9);

  pw.Widget ket(double? nilai, double kkm) {
    if (nilai == null) return sel('-', c: _muted);
    final ok = nilai >= kkm;
    return sel(ok ? 'Tuntas' : 'Belum tuntas', f: bold, c: ok ? _green : _red, size: 9);
  }

  PdfColor warnaNilai(double? v, double kkm) =>
      v == null ? _inkSoft : (v >= kkm ? _green : _red);

  pw.Widget judul(String t, {String? trailing}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Row(
          children: [
            pw.Container(width: 3, height: 13, color: _gold),
            pw.SizedBox(width: 6),
            pw.Expanded(child: pw.Text(t, style: st(11.5, f: bold))),
            if (trailing != null) pw.Text(trailing, style: st(9, c: _muted)),
          ],
        ),
      );

  // ---- kop
  pw.Widget kopWidget() {
    final inisial = kop.nama.trim().isEmpty ? 'P' : kop.nama.trim().substring(0, 1).toUpperCase();
    final logo = logoImg != null
        ? pw.Container(width: 54, height: 54, child: pw.Image(logoImg, fit: pw.BoxFit.contain))
        : pw.Container(
            width: 54,
            height: 54,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: primary),
            child: pw.Text(inisial, style: st(22, f: bold, c: PdfColors.white)),
          );
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logo,
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(kop.nama, style: st(17, f: bold, c: primary)),
                  if (kop.alamat != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(kop.alamat!, style: st(9, c: _muted, h: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2.2, color: primary),
        pw.SizedBox(height: 1.5),
        pw.Container(height: 0.7, color: _gold),
      ],
    );
  }

  pw.Widget judulDokumen() => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Laporan Hasil Belajar Santri', style: st(14.5, f: bold)),
            pw.SizedBox(height: 2),
            pw.Text('Periode $periode', style: st(10.5, c: _inkSoft)),
          ],
        ),
      );

  // ---- identitas
  pw.Widget pasangan(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 62, child: pw.Text(label, style: st(9.5, c: _muted))),
            pw.Text(': ', style: st(9.5, c: _muted)),
            pw.Expanded(child: pw.Text(value, style: st(10.5, f: bold))),
          ],
        ),
      );

  pw.Widget identitas() => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 6),
        decoration: pw.BoxDecoration(
          color: _paperDim,
          border: pw.Border.all(color: _line, width: 0.6),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(children: [
                pasangan('Nama santri', nama),
                pasangan('NIS', nis),
              ]),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(children: [
                pasangan('Kelas', kelas),
                pasangan('Periode', periode),
              ]),
            ),
          ],
        ),
      );

  // ---- ringkasan
  pw.Widget stat(String label, String value, {bool besar = false}) => pw.Expanded(
        flex: besar ? 5 : 4,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: st(9, c: _muted)),
              pw.SizedBox(height: 3),
              pw.Text(value, style: st(besar ? 21 : 17, f: bold, c: primary)),
            ],
          ),
        ),
      );

  pw.Widget garis() => pw.Container(width: 0.6, height: 40, color: _line);

  pw.Widget ringkasanStrip() => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.6),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          children: [
            stat('Rata-rata nilai', rata != null ? rata.toStringAsFixed(1) : '-', besar: true),
            garis(),
            stat('Ketuntasan', sumber.isEmpty ? '-' : '$tuntas dari ${sumber.length}'),
            garis(),
            stat('Kehadiran', total > 0 ? '$persen%' : '-'),
          ],
        ),
      );

  // ---- tabel mata pelajaran
  pw.Widget tabelMapel() {
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: primary),
        children: [
          hdr('No'),
          hdr('Mata pelajaran', a: pw.TextAlign.left),
          hdr('KKM'),
          hdr('Harian'),
          hdr('Ujian'),
          hdr('Akhir'),
          hdr('Keterangan'),
        ],
      ),
    ];
    for (var i = 0; i < mapelList.length; i++) {
      final m = mapelList[i];
      final akhir = _num(m['rataRata']);
      final kkm = _num(m['kkm']) ?? 75;
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isOdd ? _paperDim : PdfColors.white),
          children: [
            sel('${i + 1}', c: _muted),
            sel('${m['mapel'] ?? '-'}', a: pw.TextAlign.left, f: bold, size: 10),
            sel(_kkmStr(kkm), c: _inkSoft),
            sel(_n(_num(m['harian'])), c: _inkSoft),
            sel(_n(_num(m['ujian'])), c: _inkSoft),
            sel(_n(akhir), f: bold, c: warnaNilai(akhir, kkm), size: 10.5),
            ket(akhir, kkm),
          ],
        ),
      );
    }
    if (rata != null) {
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _goldSurface),
          children: [
            sel(''),
            sel('Rata-rata keseluruhan', a: pw.TextAlign.left, f: bold, c: _goldDark),
            sel(''),
            sel(''),
            sel(''),
            sel(rata.toStringAsFixed(1), f: bold, c: primary, size: 11),
            sel(''),
          ],
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(34),
        3: pw.FixedColumnWidth(42),
        4: pw.FixedColumnWidth(42),
        5: pw.FixedColumnWidth(46),
        6: pw.FixedColumnWidth(70),
      },
      children: rows,
    );
  }

  // ---- tabel ujian
  pw.Widget tabelUjian() {
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: primary),
        children: [
          hdr('No'),
          hdr('Ujian', a: pw.TextAlign.left),
          hdr('KKM'),
          hdr('Nilai awal'),
          hdr('Nilai akhir'),
          hdr('Keterangan'),
        ],
      ),
    ];
    for (var i = 0; i < ujianList.length; i++) {
      final m = ujianList[i];
      final akhir = _num(m['rataRata']);
      final awal = _num(m['nilaiAwal']) ?? akhir;
      final kkm = _num(m['kkm']) ?? 75;
      final remedial = m['remedial'] == true;
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isOdd ? _paperDim : PdfColors.white),
          children: [
            sel('${i + 1}', c: _muted),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${m['ujian'] ?? '-'}', style: st(10, f: bold)),
                  if (remedial)
                    pw.Text('Mengikuti remedial', style: st(8.5, f: bold, c: _goldDark)),
                ],
              ),
            ),
            sel(_kkmStr(kkm), c: _inkSoft),
            sel(_n(awal), c: _inkSoft),
            sel(_n(akhir), f: bold, c: warnaNilai(akhir, kkm), size: 10.5),
            ket(akhir, kkm),
          ],
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(34),
        3: pw.FixedColumnWidth(54),
        4: pw.FixedColumnWidth(54),
        5: pw.FixedColumnWidth(70),
      },
      children: rows,
    );
  }

  // ---- kehadiran
  pw.Widget tabelKehadiran() {
    pw.Widget kepala(String t) => sel(t, f: bold, c: _inkSoft, size: 9);
    pw.Widget isi(int v, {PdfColor? c}) => sel('$v', f: bold, size: 13, c: c);
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _paperDim),
          children: [
            kepala('Hadir'),
            kepala('Sakit'),
            kepala('Izin'),
            kepala('Alpa'),
            kepala('Total pertemuan'),
          ],
        ),
        pw.TableRow(
          children: [
            isi(hadir, c: _green),
            isi(sakit),
            isi(izin),
            isi(alpa, c: alpa > 0 ? _red : null),
            isi(total),
          ],
        ),
      ],
    );
  }

  pw.Widget catatanKaki() => pw.Text(
        'Keterangan: KKM adalah Kriteria Ketuntasan Minimal. Nilai akhir mata pelajaran '
        'dihitung dari nilai harian dan nilai ujian. Ujian yang mengikuti remedial '
        'memakai nilai akhir remedial.',
        style: st(8.5, c: _muted, h: 1.4),
      );

  // ---- tanda tangan
  pw.Widget ttd(String atas, String jabatan, String namaPejabat) => pw.SizedBox(
        width: 170,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(atas, style: st(9.5, c: _inkSoft)),
            pw.Text(jabatan, style: st(10, f: bold)),
            pw.SizedBox(height: 46),
            pw.Container(width: 140, height: 0.6, color: _ink),
            pw.SizedBox(height: 3),
            pw.Text(namaPejabat, style: st(9.5, f: bold)),
          ],
        ),
      );

  pw.Widget blokTtd() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          ttd('Mengetahui,', 'Wali Kelas', waliKelas),
          ttd(terbit != null ? _tgl(terbit) : '', 'Pimpinan Pondok', ''),
        ],
      );

  // ---- keabsahan
  pw.Widget verifikasi() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _goldSurface,
          border: pw.Border.all(color: _gold, width: 0.6),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Rapor diterbitkan secara digital melalui sistem SIM Pesantren',
                style: st(9.5, f: bold, c: _goldDark)),
            pw.SizedBox(height: 3),
            pw.Text(
              'No. dokumen $noDok'
              '${terbit != null ? '  -  Diterbitkan ${_tgl(terbit)}' : ''}'
              '  -  Dicetak ${_tgl(dicetak)}',
              style: st(8.5, c: _goldDark),
            ),
          ],
        ),
      );

  // ---- rakit dokumen
  final doc = pw.Document(
    title: 'Rapor $nama - $periode',
    author: kop.nama,
    creator: 'SIM Pesantren',
    subject: 'Laporan hasil belajar santri',
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 30),
        theme: pw.ThemeData.withFont(base: reg, bold: bold),
      ),
      footer: (ctx) => pw.Column(
        children: [
          pw.Container(height: 0.5, color: _line),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${kop.nama}  -  $noDok', style: st(8, c: _muted)),
              pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}', style: st(8, c: _muted)),
            ],
          ),
        ],
      ),
      build: (ctx) => [
        kopWidget(),
        pw.SizedBox(height: 14),
        judulDokumen(),
        pw.SizedBox(height: 12),
        identitas(),
        pw.SizedBox(height: 10),
        ringkasanStrip(),
        if (mapelList.isNotEmpty) ...[
          judul('Nilai mata pelajaran', trailing: '${mapelList.length} mapel'),
          tabelMapel(),
        ],
        if (ujianList.isNotEmpty) ...[
          judul('Nilai ujian', trailing: '${ujianList.length} ujian'),
          tabelUjian(),
        ],
        if (k['total'] != null) ...[
          judul('Kehadiran'),
          tabelKehadiran(),
        ],
        pw.SizedBox(height: 12),
        catatanKaki(),
        if (tandaTangan) ...[
          pw.SizedBox(height: 18),
          blokTtd(),
        ],
        pw.SizedBox(height: 16),
        verifikasi(),
      ],
    ),
  );

  return doc.save();
}