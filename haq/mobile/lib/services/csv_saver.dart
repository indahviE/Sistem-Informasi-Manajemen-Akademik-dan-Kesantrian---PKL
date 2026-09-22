// csv_saver.dart
//
// Satu pintu untuk menyimpan/mengunduh file CSV di semua platform:
//   - Web            -> csv_saver_web.dart  (unduh lewat browser)
//   - Android / iOS  -> csv_saver_io.dart   (share sheet)
//   - lainnya        -> csv_saver_stub.dart (tidak didukung)
//
// Pemakaian: await saveCsv('nama-file.csv', isiCsv);

export 'csv_saver_stub.dart'
    if (dart.library.html) 'csv_saver_web.dart'
    if (dart.library.io) 'csv_saver_io.dart';