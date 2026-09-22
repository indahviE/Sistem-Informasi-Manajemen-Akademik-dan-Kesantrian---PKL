import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Android/iOS/desktop: tulis ke folder sementara lalu buka share sheet.
Future<void> savePdf(String filename, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: filename,
  );
}