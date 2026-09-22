// pdf_saver.dart
//
// Satu pintu untuk menyimpan/mengunduh file PDF di semua platform:
//   - Web            -> pdf_saver_web.dart  (unduh lewat browser)
//   - Android / iOS  -> pdf_saver_io.dart   (share sheet)
//   - lainnya        -> pdf_saver_stub.dart (tidak didukung)
//
// Pemakaian: await savePdf('nama-file.pdf', bytesPdf);

export 'pdf_saver_stub.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    if (dart.library.io) 'pdf_saver_io.dart';