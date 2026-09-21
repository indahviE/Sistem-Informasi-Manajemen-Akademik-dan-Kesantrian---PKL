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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'tenants_screen.dart' show PColors, PText;
import '../../services/api_client.dart';
import '../../services/app_scope.dart';

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

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _initialized = false;
  bool _firstLoad = true; // loader layar penuh hanya untuk load pertama
  bool _busy = false; // reload karena filter/refresh
  bool _loadingMore = false;
  String? _error;

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
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  Future<void> _fetch({bool append = false}) async {
    setState(() {
      if (append) {
        _loadingMore = true;
      } else {
        _busy = true;
      }
      _error = null;
    });
    try {
      final res = await _api.get(ApiUrl.auditLog, query: {
        'q': _query.trim(),
        'kategori': _category?.name.toUpperCase() ?? '',
        'tenantId': _tenantId ?? '',
        'tingkat': _severity?.name.toUpperCase() ?? '',
        'hari': _rangeDays.toString(),
        'cursor': append ? (_nextCursor ?? '') : '',
        'limit': _pageSize.toString(),
      }) as Map<String, dynamic>;

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
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Gagal memuat audit log: $e';
      setState(() {
        _firstLoad = false;
        _busy = false;
        _loadingMore = false;
        if (_events.isEmpty) _error = msg;
      });
      if (_events.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
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
                    const JsonEncoder.withIndent('  ').convert(e.data),
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
          _TitleRow(onExport: _soon),
          const SizedBox(height: 14),
          _StreamStatusCard(total: _totalSemua),
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

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.onExport});

  final VoidCallback onExport;

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
        Material(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onExport,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ios_share, size: 16, color: PColors.primary),
                  const SizedBox(width: 6),
                  Text('Ekspor', style: PText.labelMd.copyWith(color: PColors.primary)),
                ],
              ),
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

class _StreamStatusCard extends StatelessWidget {
  const _StreamStatusCard({required this.total});

  final int total;

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
              color: PColors.surfaceDim,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync, size: 14, color: PColors.primary),
                const SizedBox(width: 5),
                Text('Sync Aktif', style: PText.labelMd.copyWith(color: PColors.primary)),
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