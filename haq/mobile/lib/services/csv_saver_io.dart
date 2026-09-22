import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Android/iOS/desktop: tulis ke folder sementara lalu buka share sheet.
Future<void> saveCsv(String filename, String content) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: filename,
  );
}