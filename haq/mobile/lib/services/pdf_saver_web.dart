import 'dart:html' as html;
import 'dart:typed_data';

/// Web: buat Blob lalu picu unduhan lewat elemen <a download>.
Future<void> savePdf(String filename, Uint8List bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}