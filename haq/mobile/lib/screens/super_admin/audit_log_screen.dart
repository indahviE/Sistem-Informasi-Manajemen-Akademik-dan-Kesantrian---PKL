// audit_log_screen.dart
//
// Audit Log — Platform Control Panel (Super Admin)
//
// Desain memakai token warna & tipografi PColors/PText yang sudah
// didefinisikan di tenants_screen.dart (sama seperti pengaturan_screen.dart),
// font Nunito.
//
// File ini juga mengekspor:
//   - AuditEvent            : model event (dipakai screen + dashboard)
//   - AuditLogPreview       : widget ringkas "riwayat singkat" untuk dashboard
//
// Data diambil dari GET /api/audit-log (Super Admin). Filter, pencarian, dan
// paginasi dikerjakan di server.
//
// Ekspor CSV memakai saveCsv() dari services/csv_saver.dart:
//   - Web            : file diunduh lewat browser
//   - Android / iOS  : file dibuat lalu dibuka lewat share sheet

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'tenants_screen.dart' show PColors, PText;
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../services/csv_saver.dart';
import '../../services/pdf_saver.dart';

// ============================================================================
// Model
// ============================================================================

enum AuditSeverity { info, warning, critical }

enum AuditCategory { keamanan, data, billing, sistem }

enum AuditActionStyle { outline, ghost, danger, primary }

class AuditAction {
  const AuditAction(this.label, {this.icon, this.style = AuditActionStyle.ghost});

  final String label;
  final IconData? icon;
  final AuditActionStyle style;
}

class AuditEvent {
  AuditEvent({
    required this.id,
    required this.aksi,
    required this.title,
    required this.actor,
    this.actorDetail,
    required this.severity,
    required this.category,
    required this.time,
    required this.tenantName,
    required this.tenantHandle,
    required this.description,
    required this.icon,
    this.metaIcon,
    this.metaLabel,
    this.actions = const [],
    this.ip,
    this.data,
  });

  final String id;
  final String aksi; // kode event: LOGIN_GAGAL, TENANT_APPROVE, POST, DELETE, ...
  final String title;
  final String actor; // mis. "Super Admin (ROOT)" / "Brute Force Alert"
  final String? actorDetail; // mis. nama/email pelaku atau IP
  final AuditSeverity severity;
  final AuditCategory category;
  final DateTime time;
  final String tenantName;
  final String tenantHandle; // mis. "@assunnah-tahfidz"
  /// Teks di antara backtick (`...`) dirender sebagai monospace.
  final String description;
  final IconData icon;
  final IconData? metaIcon;
  final String? metaLabel;
  final List<AuditAction> actions;
  final String? ip;
  final Map<String, dynamic>? data;

  factory AuditEvent.fromJson(Map<String, dynamic> j) {
    final aksi = (j['aksi'] ?? '').toString();
    final severity = switch ((j['tingkat'] ?? '').toString().toUpperCase()) {
      'CRITICAL' => AuditSeverity.critical,
      'WARNING' => AuditSeverity.warning,
      _ => AuditSeverity.info,
    };
    final category = switch ((j['kategori'] ?? '').toString().toUpperCase()) {
      'KEAMANAN' => AuditCategory.keamanan,
      'BILLING' => AuditCategory.billing,
      'SISTEM' => AuditCategory.sistem,
      _ => AuditCategory.data,
    };
    final meta = j['meta']?.toString();
    final rawData = j['data'];

    return AuditEvent(
      id: j['id'].toString(),
      aksi: aksi,
      title: (j['judul'] ?? '-').toString(),
      actor: (j['aktor'] ?? 'Sistem').toString(),
      actorDetail: j['aktorDetail']?.toString(),
      severity: severity,
      category: category,
      time: DateTime.tryParse(j['waktu']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      tenantName: (j['tenantNama'] ?? 'Platform SIMPesantren').toString(),
      tenantHandle: (j['tenantHandle'] ?? '').toString(),
      description: (j['deskripsi'] ?? '').toString(),
      icon: _iconFor(aksi, category),
      metaIcon: (meta == null || meta.isEmpty)
          ? null
          : (severity == AuditSeverity.info ? Icons.check_circle_outline : Icons.error_outline),
      metaLabel: (meta == null || meta.isEmpty) ? null : meta,
      actions: _actionsFor(aksi),
      ip: j['ip']?.toString(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : null,
    );
  }
}

IconData _iconFor(String aksi, AuditCategory cat) {
  switch (aksi) {
    case 'LOGIN_BRUTE_FORCE':
      return Icons.lock_clock;
    case 'LOGIN_GAGAL':
      return Icons.lock_outline;
    case 'LOGIN_SUPER_ADMIN':
      return Icons.admin_panel_settings_outlined;
    case 'TENANT_SIGNUP':
      return Icons.add_business_outlined;
    case 'TENANT_APPROVE':
      return Icons.apartment_outlined;
    case 'TENANT_SUSPEND':
    case 'TENANT_REJECT':
      return Icons.block;
    case 'DELETE':
      return Icons.delete_outline;
  }
  return switch (cat) {
    AuditCategory.keamanan => Icons.shield_outlined,
    AuditCategory.billing => Icons.receipt_long_outlined,
    AuditCategory.sistem => Icons.tune,
    AuditCategory.data => Icons.storage_outlined,
  };
}

List<AuditAction> _actionsFor(String aksi) {
  const detail = AuditAction('Detail Event', style: AuditActionStyle.outline);
  if (aksi == 'LOGIN_BRUTE_FORCE') {
    return const [detail, AuditAction('Blokir IP', icon: Icons.block, style: AuditActionStyle.danger)];
  }
  return const [detail];
}

// ============================================================================
// Helpers
// ============================================================================

const Color _border = Color(0xFFEAE6DC);
const Color _warnBg = Color(0xFFFFF8E1);
const Color _warnFg = Color(0xFFB78103);
const Color _okBg = Color(0xFFE8F5E9);
const Color _okFg = Color(0xFF1B5E20);

TextStyle _nt(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

String _two(int v) => v.toString().padLeft(2, '0');

String _fmtJam(DateTime d) => '${_two(d.hour)}:${_two(d.minute)} WIB';

const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _fmtTanggal(DateTime d) => '${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';

String _fmtInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

// ---- Redaksi data sensitif -------------------------------------------------
//
// Audit log dari backend bisa memuat body request mentah (mis. password saat
// login). Sebelum ditampilkan di dialog detail atau diekspor ke CSV, field yang
// namanya mengandung pass/password/token/secret/authorization disamarkan.
// Ini hanya lapisan tampilan; perbaikan utama tetap di backend.

final RegExp _sensitiveKey = RegExp(r'pass(word)?|token|secret|authorization', caseSensitive: false);

dynamic _redact(dynamic v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        e.key: _sensitiveKey.hasMatch(e.key.toString()) ? '[REDACTED]' : _redact(e.value),
    };
  }
  if (v is List) return v.map(_redact).toList();
  return v;
}

// ---- CSV -------------------------------------------------------------------

String _fmtCsvTime(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// Escape sel CSV. Sel yang diawali = + - @ diberi apostrof di depan supaya
/// tidak dieksekusi sebagai formula di Excel/Sheets (isi audit log bisa
/// berasal dari input user, mis. email saat login gagal).
String _csvCell(Object? v) {
  var s = (v ?? '').toString();
  if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
  return '"${s.replaceAll('"', '""')}"';
}

String _buildCsv(List<AuditEvent> events) {
  const header = [
    'Waktu', 'Kode', 'Judul', 'Tingkat', 'Kategori', 'Pelaku',
    'Detail Pelaku', 'Tenant', 'Handle Tenant', 'Deskripsi', 'IP', 'Meta', 'Data',
  ];
  final buf = StringBuffer()..writeln(header.map(_csvCell).join(','));
  for (final e in events) {
    buf.writeln([
      _fmtCsvTime(e.time),
      e.aksi,
      e.title,
      _sevLabel(e.severity),
      e.category.name,
      e.actor,
      e.actorDetail,
      e.tenantName,
      e.tenantHandle,
      e.description.replaceAll('`', ''),
      e.ip,
      e.metaLabel,
      e.data == null ? '' : jsonEncode(_redact(e.data)),
    ].map(_csvCell).join(','));
  }
  return buf.toString();
}

// ---- PDF --------------------------------------------------------------------
//
// Kolom dipadatkan dari versi CSV (gabung Pelaku+Detail, Tenant+Handle jadi
// satu sel per baris) supaya tetap terbaca di kertas A4 landscape, dan kolom
// 'Data' (dump JSON) tidak diikutkan karena tidak muat.

const _pdfHeaders = ['Waktu', 'Event', 'Tingkat', 'Kategori', 'Pelaku', 'Tenant', 'Deskripsi', 'IP', 'Meta'];

/// Font dasar PDF (Helvetica) cuma mendukung karakter Latin-1 dasar. Karakter
/// tipografis umum (bullet, en/em dash, tanda kutip lengkung, ellipsis) —
/// baik yang kita tulis manual maupun yang mungkin ada di data asli dari
/// backend — diganti ke padanan ASCII-nya supaya tidak muncul kotak/hilang
/// saat dirender ("Unable to find a font to draw ...").
String _pdfSafe(String s) => s
    .replaceAll('•', '-')
    .replaceAll('·', '-')
    .replaceAll('–', '-')
    .replaceAll('—', '-')
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('…', '...');

const _pdfColumnWidths = <int, pw.TableColumnWidth>{
  0: pw.FixedColumnWidth(58), // Waktu
  1: pw.FlexColumnWidth(2.0), // Event (judul + kode)
  2: pw.FixedColumnWidth(48), // Tingkat
  3: pw.FixedColumnWidth(50), // Kategori
  4: pw.FlexColumnWidth(1.5), // Pelaku (+ detail)
  5: pw.FlexColumnWidth(1.5), // Tenant (+ handle)
  6: pw.FlexColumnWidth(3), // Deskripsi
  7: pw.FixedColumnWidth(46), // IP
  8: pw.FlexColumnWidth(1), // Meta
};

List<String> _pdfRow(AuditEvent e) => [
      _fmtCsvTime(e.time),
      _pdfSafe(e.aksi.isEmpty || e.aksi == e.title ? e.title : '${e.title}\n${e.aksi}'),
      _sevLabel(e.severity),
      e.category.name,
      _pdfSafe(
        e.actorDetail == null || e.actorDetail!.isEmpty ? e.actor : '${e.actor}\n${e.actorDetail}',
      ),
      _pdfSafe(e.tenantHandle.isEmpty ? e.tenantName : '${e.tenantName}\n${e.tenantHandle}'),
      _pdfSafe(e.description.replaceAll('`', '')),
      e.ip ?? '',
      e.metaLabel == null ? '' : _pdfSafe(e.metaLabel!),
    ];

const _pdfPrimary = PdfColor.fromInt(0xFF0F3A2E);
const _pdfZebra = PdfColor.fromInt(0xFFF3F1EA);
const _pdfCritical = PdfColors.red700;
const _pdfWarning = PdfColor.fromInt(0xFFB78103);

Future<Uint8List> _buildPdf(List<AuditEvent> events, {required String subtitle}) async {
  final doc = pw.Document();
  final now = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
      header: (context) {
        if (context.pageNumber > 1) return pw.SizedBox();
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Audit Log',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _pdfPrimary),
                ),
                pw.Text(
                  '${events.length} event',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),            pw.SizedBox(height: 10),
            pw.Divider(color: _pdfPrimary, thickness: 1.2),
            pw.SizedBox(height: 10),
          ],
        );
      },
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dibuat ${_fmtCsvTime(now)}  |  SIM Pesantren',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
              pw.Text(
                'Hal. ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headers: _pdfHeaders,
          data: events.map(_pdfRow).toList(),
          columnWidths: _pdfColumnWidths,
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _pdfPrimary),
          headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          headerAlignment: pw.Alignment.centerLeft,
          headerAlignments: const {2: pw.Alignment.center, 3: pw.Alignment.center, 7: pw.Alignment.center},
          cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
          cellAlignment: pw.Alignment.topLeft,
          cellAlignments: const {2: pw.Alignment.topCenter, 3: pw.Alignment.topCenter, 7: pw.Alignment.topCenter},
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
            top: pw.BorderSide(color: _pdfPrimary, width: 0.8),
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
          ),
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: _pdfZebra),
          textStyleBuilder: (index, data, rowNum) {
            if (index == 2) {
              if (data == 'Critical') {
                return pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfCritical);
              }
              if (data == 'Warning') {
                return pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pdfWarning);
              }
            }
            return const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900);
          },
        ),
      ],
    ),
  );

  return doc.save();
}

// ---- Warna & label tingkat -------------------------------------------------

Color _sevBg(AuditSeverity s) => switch (s) {
      AuditSeverity.critical => PColors.errorBg,
      AuditSeverity.warning => _warnBg,
      AuditSeverity.info => PColors.sage,
    };

Color _sevFg(AuditSeverity s) => switch (s) {
      AuditSeverity.critical => PColors.errorText,
      AuditSeverity.warning => _warnFg,
      AuditSeverity.info => PColors.primary,
    };

String _sevLabel(AuditSeverity s) => switch (s) {
      AuditSeverity.critical => 'Critical',
      AuditSeverity.warning => 'Warning',
      AuditSeverity.info => 'Info',
    };

/// Render teks dengan bagian `code` sebagai monospace.
InlineSpan _richDesc(String text, TextStyle base) {
  final parts = text.split('`');
  return TextSpan(
    style: base,
    children: [
      for (int i = 0; i < parts.length; i++)
        if (i.isOdd)
          TextSpan(
            text: parts[i],
            style: PText.mono.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: PColors.primary),
          )
        else
          TextSpan(text: parts[i]),
    ],
  );
}

// ============================================================================
// Screen
// ============================================================================

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  static const int _pageSize = 20;
  static const int _exportMax = 5000; // batas baris per ekspor
  static const int _exportPageSize = 200;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _initialized = false;
  bool _firstLoad = true; // loader layar penuh hanya untuk load pertama
  bool _busy = false; // reload karena filter/refresh
  bool _loadingMore = false;
  bool _exporting = false;
  String? _error;
  Timer? _syncTimer;
  bool _syncOk = true;

  List<AuditEvent> _events = [];
  String? _nextCursor;
  int _totalSemua = 0;
  int _totalKeamanan = 0;
  int _totalFilter = 0;

  List<_Opt<String?>> _tenantOpts = const [_Opt<String?>(null, 'Semua Tenant')];

  // Filter (dikirim ke server)
  String _query = '';
  AuditCategory? _category; // null = semua
  String? _tenantId; // null = semua tenant
  int _rangeDays = 7; // 0 = semua waktu
  AuditSeverity? _severity; // null = semua tingkat

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadTenants();
      _fetch();
      _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetch(silent: true));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _syncTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  ApiClient get _api => AppScope.of(context).api;

  Future<void> _loadTenants() async {
    try {
      final res = await _api.get(ApiUrl.tenants);
      final list = (res as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _tenantOpts = [
          const _Opt<String?>(null, 'Semua Tenant'),
          for (final t in list) _Opt<String?>(t['id'].toString(), (t['namaPondok'] ?? '-').toString()),
        ];
      });
    } catch (_) {
      // Dropdown tenant opsional — abaikan bila gagal.
    }
  }

  /// Query yang dikirim ke server; dipakai bersama oleh _fetch dan _export
  /// supaya filter aktif selalu sama.
  Map<String, String> _filterQuery({required String cursor, required int limit}) => {
        'q': _query.trim(),
        'kategori': _category?.name.toUpperCase() ?? '',
        'tenantId': _tenantId ?? '',
        'tingkat': _severity?.name.toUpperCase() ?? '',
        'hari': _rangeDays.toString(),
        'cursor': cursor,
        'limit': limit.toString(),
      };

  Future<void> _fetch({bool append = false, bool silent = false}) async {
    if (silent) {
      if (_busy || _loadingMore) return; // sudah ada fetch manual, lewati sync kali ini
    } else {
      setState(() {
        if (append) {
          _loadingMore = true;
        } else {
          _busy = true;
        }
        _error = null;
      });
    }
    try {
      final res = await _api.get(
        ApiUrl.auditLog,
        query: _filterQuery(cursor: append ? (_nextCursor ?? '') : '', limit: _pageSize),
      ) as Map<String, dynamic>;

      final items = (res['items'] as List? ?? [])
          .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _events = append ? [..._events, ...items] : items;
        _nextCursor = res['nextCursor']?.toString();
        _totalSemua = (res['totalSemua'] as num?)?.toInt() ?? 0;
        _totalKeamanan = (res['totalKeamanan'] as num?)?.toInt() ?? 0;
        _totalFilter = (res['totalFilter'] as num?)?.toInt() ?? 0;
        _firstLoad = false;
        _busy = false;
        _loadingMore = false;
        _syncOk = true;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Gagal memuat audit log: $e';
      setState(() {
        _firstLoad = false;
        _busy = false;
        _loadingMore = false;
        _syncOk = false;
        if (!silent && _events.isEmpty) _error = msg;
      });
      if (!silent && _events.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  /// Ambil semua log sesuai filter aktif dari server (dibatasi _exportMax),
  /// dipakai bersama oleh ekspor CSV dan PDF supaya datanya selalu sama.
  Future<(List<AuditEvent> events, bool truncated)> _fetchExportData() async {
    final all = <AuditEvent>[];
    String? cursor;
    var truncated = false;

    do {
      final res = await _api.get(
        ApiUrl.auditLog,
        query: _filterQuery(cursor: cursor ?? '', limit: _exportPageSize),
      ) as Map<String, dynamic>;

      final items = (res['items'] as List? ?? [])
          .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(items);

      cursor = res['nextCursor']?.toString();
      if (cursor != null && cursor.isEmpty) cursor = null;
      if (items.isEmpty) break;
      if (all.length >= _exportMax && cursor != null) {
        truncated = true;
        break;
      }
    } while (cursor != null);

    return (all, truncated);
  }

  String _exportBaseName(DateTime now) =>
      'audit-log_${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';

  /// Deskripsi filter aktif untuk ditampilkan di kop PDF.
  String _filterSummary() {
    final tenantLabel = _tenantOpts
        .firstWhere((o) => o.value == _tenantId, orElse: () => _tenantOpts.first)
        .label;
    final parts = <String>[
      tenantLabel,
      _category == null ? 'Semua Kategori' : _category!.name,
      switch (_rangeDays) { 1 => 'Hari Ini', 7 => '7 Hari Terakhir', 30 => '30 Hari Terakhir', _ => 'Semua Waktu' },
      _severity == null ? 'Semua Tingkat' : _sevLabel(_severity!),
    ];
    return _pdfSafe(parts.join('  |  '));
  }

  /// Ekspor semua log sesuai filter aktif ke CSV (maks. _exportMax baris).
  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyiapkan file CSV...')));

    try {
      final (all, truncated) = await _fetchExportData();

      if (all.isEmpty) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('Tidak ada log untuk diekspor.')));
        return;
      }

      final name = '${_exportBaseName(DateTime.now())}.csv';

      messenger.hideCurrentSnackBar();
      if (truncated) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Hanya $_exportMax log terbaru yang diekspor. Persempit filter untuk data lebih spesifik.'),
          ),
        );
      }

      // BOM (\uFEFF) supaya Excel membaca UTF-8 dengan benar.
      await saveCsv(name, '\uFEFF${_buildCsv(all)}');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      final msg = e is ApiException ? e.message : 'Gagal mengekspor: $e';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Ekspor semua log sesuai filter aktif ke PDF (maks. _exportMax baris).
  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyiapkan file PDF...')));

    try {
      final (all, truncated) = await _fetchExportData();

      if (all.isEmpty) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('Tidak ada log untuk diekspor.')));
        return;
      }

      final now = DateTime.now();
      final name = '${_exportBaseName(now)}.pdf';
      final bytes = await _buildPdf(all, subtitle: _filterSummary());

      messenger.hideCurrentSnackBar();
      if (truncated) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Hanya $_exportMax log terbaru yang diekspor. Persempit filter untuk data lebih spesifik.'),
          ),
        );
      }

      await savePdf(name, bytes);
    } catch (e) {
      messenger.hideCurrentSnackBar();
      final msg = e is ApiException ? e.message : 'Gagal mengekspor: $e';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _applyFilter(VoidCallback change) {
    setState(change);
    _fetch();
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini akan segera tersedia.')),
    );
  }

  void _onAction(AuditEvent e, AuditAction a) {
    if (a.label == 'Detail Event') {
      _showDetail(e);
    } else {
      _soon();
    }
  }

  void _showDetail(AuditEvent e) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 78, child: Text(label, style: PText.bodySm)),
              Expanded(child: Text(value, style: PText.labelMd.copyWith(color: PColors.primary))),
            ],
          ),
        );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(e.title, style: PText.headlineSm),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Kode', e.aksi),
              row('Waktu', '${_fmtTanggal(e.time)}, ${_fmtJam(e.time)}'),
              row('Pelaku', e.actorDetail == null ? e.actor : '${e.actor} • ${e.actorDetail}'),
              row('Tenant', '${e.tenantName} ${e.tenantHandle}'),
              row('Tingkat', _sevLabel(e.severity)),
              if (e.ip != null) row('IP', e.ip!),
              if (e.data != null) ...[
                const SizedBox(height: 4),
                Text('Data', style: PText.bodySm),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PColors.surfaceDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_redact(e.data)),
                    style: PText.mono.copyWith(fontSize: 10.5, color: PColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_firstLoad && _error == null) {
      return const Center(child: CircularProgressIndicator(color: PColors.primary));
    }
    if (_error != null && _events.isEmpty) {
      return _LoadErrorState(message: _error!, onRetry: _fetch);
    }

    // Kelompokkan per hari (server sudah mengurutkan terbaru dulu).
    final groups = <DateTime, List<AuditEvent>>{};
    for (final e in _events) {
      groups.putIfAbsent(_dayKey(e.time), () => []).add(e);
    }
    final today = _dayKey(DateTime.now());

    final tenantLabel = _tenantOpts
        .firstWhere((o) => o.value == _tenantId, orElse: () => _tenantOpts.first)
        .label;

    return RefreshIndicator(
      color: PColors.primary,
      onRefresh: () => _fetch(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _ClusterStatusBanner(),
          const SizedBox(height: 14),
          _TitleRow(onExportCsv: _exportCsv, onExportPdf: _exportPdf, busy: _exporting),
          const SizedBox(height: 14),
          _StreamStatusCard(total: _totalSemua, syncOk: _syncOk),
          const SizedBox(height: 12),
          _SearchField(
            controller: _searchCtrl,
            onChanged: (v) {
              _query = v;
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => _fetch());
              setState(() {}); // update tombol clear
            },
            onClear: () {
              _debounce?.cancel();
              _searchCtrl.clear();
              _applyFilter(() => _query = '');
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Semua',
                  count: _totalSemua,
                  selected: _category == null,
                  onTap: () => _applyFilter(() => _category = null),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Keamanan',
                  icon: Icons.shield_outlined,
                  count: _totalKeamanan,
                  tone: _ChipTone.danger,
                  selected: _category == AuditCategory.keamanan,
                  onTap: () => _applyFilter(() => _category = AuditCategory.keamanan),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Aktivitas Data',
                  icon: Icons.storage_outlined,
                  selected: _category == AuditCategory.data,
                  onTap: () => _applyFilter(() => _category = AuditCategory.data),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Billing',
                  icon: Icons.receipt_long_outlined,
                  selected: _category == AuditCategory.billing,
                  onTap: () => _applyFilter(() => _category = AuditCategory.billing),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Sistem',
                  icon: Icons.dns_outlined,
                  selected: _category == AuditCategory.sistem,
                  onTap: () => _applyFilter(() => _category = AuditCategory.sistem),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FilterPill<String?>(
                  label: tenantLabel,
                  icon: Icons.apartment_outlined,
                  value: _tenantId,
                  options: _tenantOpts,
                  onSelected: (v) => _applyFilter(() => _tenantId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPill<int>(
                  label: switch (_rangeDays) {
                    1 => 'Hari Ini',
                    7 => '7 Hari Terakhir',
                    30 => '30 Hari Terakhir',
                    _ => 'Semua Waktu',
                  },
                  trailingIcon: Icons.calendar_today_outlined,
                  value: _rangeDays,
                  options: const [
                    _Opt(1, 'Hari Ini'),
                    _Opt(7, '7 Hari Terakhir'),
                    _Opt(30, '30 Hari Terakhir'),
                    _Opt(0, 'Semua Waktu'),
                  ],
                  onSelected: (v) => _applyFilter(() => _rangeDays = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPill<AuditSeverity?>(
                  label: _severity == null ? 'Semua Tingkat' : _sevLabel(_severity!),
                  trailingIcon: Icons.filter_list,
                  value: _severity,
                  options: const [
                    _Opt(null, 'Semua Tingkat'),
                    _Opt(AuditSeverity.info, 'Info'),
                    _Opt(AuditSeverity.warning, 'Warning'),
                    _Opt(AuditSeverity.critical, 'Critical'),
                  ],
                  onSelected: (v) => _applyFilter(() => _severity = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2, color: PColors.primary),
            ),
          const SizedBox(height: 8),
          if (_events.isEmpty && !_busy)
            const _EmptyState()
          else
            for (final entry in groups.entries) ...[
              _DayHeader(day: entry.key, today: today, count: entry.value.length),
              const SizedBox(height: 10),
              for (final e in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AuditEventCard(event: e, onAction: (a) => _onAction(e, a)),
                ),
              const SizedBox(height: 6),
            ],
          if (_events.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Menampilkan ${_events.length} dari ${_fmtInt(_totalFilter)} Log',
                style: PText.bodySm,
              ),
            ),
            const SizedBox(height: 10),
            if (_nextCursor != null)
              _LoadMoreButton(
                label: _loadingMore ? 'Memuat...' : 'Muat $_pageSize Log Berikutnya',
                onPressed: () {
                  if (!_loadingMore) _fetch(append: true);
                },
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Error / empty state
// ============================================================================

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: PColors.errorText, size: 32),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: PText.bodyMd),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: PColors.primary),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: PColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          const Icon(Icons.manage_search, size: 32, color: PColors.inkSecondary),
          const SizedBox(height: 8),
          const Text('Tidak ada log yang cocok', style: PText.headlineSm),
          const SizedBox(height: 2),
          Text('Coba ubah kata kunci atau filter.', style: PText.bodySm),
        ],
      ),
    );
  }
}

// ============================================================================
// Cluster status banner (sama seperti di Pengaturan)
// ============================================================================

class _ClusterStatusBanner extends StatelessWidget {
  const _ClusterStatusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, size: 16, color: PColors.inkSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ap-southeast-1 • Jakarta DC',
              style: PText.bodySm,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('SEMUA NODE SEHAT', style: PText.labelSm.copyWith(color: PColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Title row
// ============================================================================

enum _ExportFormat { csv, pdf }

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.onExportCsv, required this.onExportPdf, this.busy = false});

  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Audit Log', style: PText.headlineLg),
              const SizedBox(height: 2),
              Text('Riwayat aktivitas & keamanan seluruh tenant', style: PText.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<_ExportFormat>(
          color: PColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          enabled: !busy,
          onSelected: (f) => f == _ExportFormat.csv ? onExportCsv() : onExportPdf(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _ExportFormat.csv,
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, size: 16, color: PColors.primary),
                  SizedBox(width: 8),
                  Text('Ekspor CSV'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _ExportFormat.pdf,
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 16, color: PColors.primary),
                  SizedBox(width: 8),
                  Text('Ekspor PDF'),
                ],
              ),
            ),
          ],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: PColors.primary),
                      )
                    : const Icon(Icons.ios_share, size: 16, color: PColors.primary),
                const SizedBox(width: 6),
                Text('Ekspor', style: PText.labelMd.copyWith(color: PColors.primary)),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: PColors.inkSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Stream status
// ============================================================================

class _StreamStatusCard extends StatefulWidget {
  const _StreamStatusCard({required this.total, required this.syncOk});

  final int total;
  final bool syncOk;

  @override
  State<_StreamStatusCard> createState() => _StreamStatusCardState();
}

class _StreamStatusCardState extends State<_StreamStatusCard> with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  int get total => widget.total;
  bool get syncOk => widget.syncOk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: PColors.sage, shape: BoxShape.circle),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATUS STREAM', style: PText.labelSm),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_fmtInt(total), style: _nt(20, FontWeight.w800, PColors.primary)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Event Tercatat',
                        overflow: TextOverflow.ellipsis,
                        style: PText.labelMd.copyWith(color: PColors.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: syncOk ? PColors.surfaceDim : _warnBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                syncOk
                    ? RotationTransition(
                        turns: _spinCtrl,
                        child: const Icon(Icons.sync, size: 14, color: PColors.primary),
                      )
                    : Icon(Icons.sync_problem, size: 14, color: _warnFg),
                const SizedBox(width: 5),
                Text(
                  syncOk ? 'Sync Aktif' : 'Sync Terputus',
                  style: PText.labelMd.copyWith(color: syncOk ? PColors.primary : _warnFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Search
// ============================================================================

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: PColors.inkSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: PText.bodyMd,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama tenant, user, IP, atau event...',
                hintStyle: PText.bodySm,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(9999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.cancel, size: 18, color: PColors.inkSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Filters
// ============================================================================

enum _ChipTone { normal, danger }

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
    this.tone = _ChipTone.normal,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == _ChipTone.danger;
    final bg = selected
        ? (danger ? PColors.errorText : PColors.primary)
        : (danger ? PColors.errorBg : PColors.surfaceContainerHigh);
    final fg = selected ? Colors.white : (danger ? PColors.errorText : PColors.inkSecondary);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: _nt(12.5, FontWeight.w700, fg)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.2) : PColors.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(_fmtInt(count!), style: _nt(10.5, FontWeight.w800, fg)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Opt<T> {
  const _Opt(this.value, this.label);

  final T value;
  final String label;
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final T value;
  final List<_Opt<T>> options;
  final ValueChanged<T> onSelected;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Opt<T>>(
      color: PColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (o) => onSelected(o.value),
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<_Opt<T>>(
            value: o,
            child: Text(
              o.label,
              style: PText.labelMd.copyWith(
                color: o.value == value ? PColors.primary : PColors.inkSecondary,
                fontWeight: o.value == value ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: PColors.inkSecondary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _nt(11.5, FontWeight.w700, PColors.primary),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              trailingIcon ?? Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: PColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Day header
// ============================================================================

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today, required this.count});

  final DateTime day;
  final DateTime today;
  final int count;

  @override
  Widget build(BuildContext context) {
    final diff = today.difference(day).inDays;
    final label = diff == 0
        ? 'HARI INI'
        : diff == 1
            ? 'KEMARIN'
            : _fmtTanggal(day).toUpperCase();

    return Row(
      children: [
        Text(label, style: _nt(12, FontWeight.w800, PColors.primary)),
        const SizedBox(width: 8),
        if (diff <= 1) ...[
          Text('—', style: PText.bodySm),
          const SizedBox(width: 8),
          Text(_fmtTanggal(day), style: PText.bodySm),
        ],
        const Spacer(),
        Text('$count Event', style: PText.labelSm),
      ],
    );
  }
}

// ============================================================================
// Event card
// ============================================================================

class _AuditEventCard extends StatelessWidget {
  const _AuditEventCard({required this.event, required this.onAction});

  final AuditEvent event;
  final ValueChanged<AuditAction> onAction;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final fg = _sevFg(e.severity);
    final emphasize = e.severity != AuditSeverity.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _sevBg(e.severity), borderRadius: BorderRadius.circular(12)),
                child: Icon(e.icon, size: 21, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: _nt(14, FontWeight.w800, PColors.primary, height: 1.25)),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: e.actor, style: PText.labelSm.copyWith(color: PColors.primary)),
                          if (e.actorDetail != null)
                            TextSpan(
                              text: ' • ${e.actorDetail}',
                              style: e.actorDetail!.contains('.') && RegExp(r'^\d').hasMatch(e.actorDetail!)
                                  ? PText.mono.copyWith(fontSize: 11, color: _warnFg)
                                  : PText.bodySm,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SeverityBadge(severity: e.severity),
                  const SizedBox(height: 6),
                  Text(_fmtJam(e.time), style: PText.labelSm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        emphasize && e.severity == AuditSeverity.critical
                            ? Icons.warning_amber_rounded
                            : Icons.apartment_outlined,
                        size: 15,
                        color: emphasize && e.severity == AuditSeverity.critical ? fg : PColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e.tenantName, style: PText.labelMd.copyWith(color: PColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e.tenantHandle,
                      style: PText.mono.copyWith(
                        fontSize: 10.5,
                        color: emphasize ? PColors.errorText : PColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  _richDesc(e.description, PText.bodySm.copyWith(height: 1.45)),
                ),
              ],
            ),
          ),

          // Footer
          if (e.metaLabel != null || e.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (e.metaLabel != null)
                  Expanded(
                    child: Row(
                      children: [
                        if (e.metaIcon != null) ...[
                          Icon(
                            e.metaIcon,
                            size: 14,
                            color: e.severity == AuditSeverity.critical ? PColors.errorText : PColors.inkSecondary,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            e.metaLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: PText.labelSm.copyWith(
                              color: e.severity == AuditSeverity.critical
                                  ? PColors.errorText
                                  : PColors.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                for (int i = 0; i < e.actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _ActionButton(action: e.actions[i], onPressed: () => onAction(e.actions[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final AuditSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (severity) {
      AuditSeverity.critical => (PColors.errorBg, PColors.errorText),
      AuditSeverity.warning => (_warnBg, _warnFg),
      AuditSeverity.info => (_okBg, _okFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(_sevLabel(severity), style: _nt(10.5, FontWeight.w800, fg)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onPressed});

  final AuditAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (action.style) {
      AuditActionStyle.primary => (PColors.primary, Colors.white, null),
      AuditActionStyle.danger => (PColors.errorText, Colors.white, null),
      AuditActionStyle.outline => (PColors.surface, PColors.primary, _border),
      AuditActionStyle.ghost => (PColors.surfaceContainerHigh, PColors.primary, null),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.icon != null) ...[
                Icon(action.icon, size: 14, color: fg),
                const SizedBox(width: 5),
              ],
              Text(action.label, style: _nt(11.5, FontWeight.w700, fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: PColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.expand_circle_down_outlined, size: 18, color: PColors.primary),
                const SizedBox(width: 8),
                Text(label, style: _nt(13, FontWeight.w700, PColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Preview ringkas untuk DASHBOARD Super Admin
//
// Pemakaian di dashboard_screen.dart (menggantikan blok "Audit Keamanan &
// Mutasi"):
//
//   AuditLogPreview(
//     events: ((_data!['auditKeamanan'] as List?) ?? const [])
//         .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
//         .toList(),
//     limit: 3,
//     onLihatSemua: () => <pindah ke tab Audit Log>,
//   )
// ============================================================================

class AuditLogPreview extends StatelessWidget {
  const AuditLogPreview({
    super.key,
    required this.events,
    this.limit = 3,
    this.onLihatSemua,
  });

  final List<AuditEvent> events;
  final int limit;
  final VoidCallback? onLihatSemua;

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin, ${_fmtJam(t)}';
    return '${d.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]..sort((a, b) => b.time.compareTo(a.time));
    final items = sorted.take(limit).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Audit Keamanan & Mutasi', style: PText.headlineSm)),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: PColors.goldDark, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('Real-time', style: _nt(11, FontWeight.w700, PColors.goldDark)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('Belum ada aktivitas tercatat.', style: PText.bodySm)
          else
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: _sevBg(items[i].severity), shape: BoxShape.circle),
                      child: Icon(items[i].icon, size: 16, color: _sevFg(items[i].severity)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: PText.labelMd.copyWith(
                              color: items[i].severity == AuditSeverity.critical
                                  ? PColors.errorText
                                  : PColors.primary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            items[i].tenantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PText.bodySm,
                          ),
                          const SizedBox(height: 2),
                          Text(_relative(items[i].time), style: PText.labelSm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (onLihatSemua != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: PColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onLihatSemua,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lihat Semua Audit Log', style: _nt(12.5, FontWeight.w700, PColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18, color: PColors.primary),
                      ],
                      
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}