import 'dart:convert';
import 'dart:html' as html;

/// Web: buat Blob lalu picu unduhan lewat elemen <a download>.
Future<void> saveCsv(String filename, String content) async {
  final blob = html.Blob([utf8.encode(content)], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}