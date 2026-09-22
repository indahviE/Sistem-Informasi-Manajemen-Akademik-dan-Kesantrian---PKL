// Contoh pola exportToPdf(), sejajar dengan exportToCsv() yang sudah ada.
// Butuh dua package tambahan di pubspec.yaml:
//   pdf: ^3.10.0
//   printing: ^5.11.0   (opsional, kalau mau preview/print langsung, bukan cuma share)
//
// Ganti bagian headers/rows di bawah ini dengan data asli kamu
// (yang sama persis dipakai exportToCsv() sekarang).

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_saver.dart'; // hasil generate di atas

Future<void> exportToPdf({
  required String filename,
  required List<String> headers,
  required List<List<String>> rows,
  String? title,
}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        if (title != null) ...[
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Table.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  await savePdf(filename, bytes);
}