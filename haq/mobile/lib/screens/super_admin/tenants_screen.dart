// tenants_screen.dart
//
// Kelola Tenant — Platform Control Panel (Super Admin)
//
// Desain memakai token warna & tipografi yang sama dengan signup_screen.dart
// (Islamic Academic & Kesantrian Experience — Deep Emerald + Antique Gold).
// Jika kamu sudah punya file token bersama (mis. lib/theme/colors.dart),
// hapus class PColors/PText di bawah ini dan import dari sana saja supaya
// tidak duplikat.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import 'tenant_detail_screen.dart';

// ============================================================================
// Design tokens (disamakan dengan signup_screen.dart)
// ============================================================================

class PColors {
  PColors._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryDark = Color(0xFF0A261E);
  static const primaryContainer = Color(0xFF1B4D3E);
  static const primaryFixed = Color(0xFFC0ECDA);

  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF785A1A);

  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const outline = Color(0xFF717975);

  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);

  static const successBg = Color(0xFFECFDF5);
  static const successText = Color(0xFF047857);
  static const successBorder = Color(0xFFA7F3D0);

  static const pendingBg = Color(0xFFFEF3C7);
  static const pendingText = Color(0xFF92400E);
  static const pendingBorder = Color(0xFFFCD34D);
  static const pendingSoftBg = Color(0xFFFFFBEB);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFFB91C1C);
  static const errorBorder = Color(0xFFFECACA);
  static const errorSoftBg = Color(0xFFFEF2F2);
}

class PText {
  PText._();

  static const _font = 'Nunito';

  static const headlineLg = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    height: 28 / 22,
    color: PColors.ink,
  );

  static const headlineSm = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 20 / 15,
    color: PColors.primary,
  );

  static const bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: PColors.inkSecondary,
  );

  static const bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    color: PColors.inkSecondary,
  );

  static const labelMd = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: PColors.ink,
  );

  static const labelSm = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.04,
    color: PColors.outline,
  );

  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: PColors.primary,
  );
}

// ============================================================================
// Screen
// ============================================================================

Future<void> _hubungiPicTenant(
    BuildContext context, Map<String, dynamic> tenant) async {
  final raw = (tenant['adminPhone'] ?? '').toString().trim();
  if (raw.isEmpty || raw == '-') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor PIC belum tersedia untuk tenant ini')),
    );
    return;
  }

  var nomor = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (nomor.startsWith('+')) {
    nomor = nomor.substring(1);
  } else if (nomor.startsWith('0')) {
    nomor = '62${nomor.substring(1)}';
  }

  final url = Uri.parse('https://wa.me/$nomor');
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
    );
  }
}

enum _StatusFilter { semua, aktif, pending, suspended }

enum _SortOption { terbaru, namaAz, userTerbanyak, santriTerbanyak }

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  final _searchCtrl = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.semua;
  String _packageFilter = 'Semua Paket';
  _SortOption _sort = _SortOption.terbaru;

  int _visibleCount = 5;
  bool _archivedExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.tenants);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
        _visibleCount = 5;
      });
    } catch (e, st) {
      debugPrint('TenantsScreen load error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Gagal memuat data: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(Map<String, dynamic> t, String action) async {
    try {
      final api = AppScope.of(context).api;
      // 'restore' dipetakan ke endpoint approve karena keduanya sama-sama
      // memindahkan tenant SUSPENDED ke status AKTIF.
      final url = switch (action) {
        'approve' => ApiUrl.tenantApprove,
        'restore' => ApiUrl.tenantApprove,
        'archive' => ApiUrl.tenantArchive,
        'unarchive' => ApiUrl.tenantUnarchive,
        'delete' => ApiUrl.tenantDeletePending,
        _ => ApiUrl.tenantSuspend,
      };
      await api.post(url, {'tenantId': t['id']});
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showTenantDetail(Map<String, dynamic> t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantDetailScreen(
          tenant: t,
          onApprove: () => _action(t, 'approve'),
          onSuspend: () => _action(t, 'suspend'),
          onRestore: () => _action(t, 'restore'),
          onArchive: () => _action(t, 'archive'),
          onUnarchive: () => _action(t, 'unarchive'),
          onDelete: () => _action(t, 'delete'),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------

  String _statusOf(Map<String, dynamic> t) =>
      (t['status'] ?? 'AKTIF').toString().toUpperCase();

  String _paketOf(Map<String, dynamic> t) => (t['paket'] ?? 'Basic').toString();

  Map<_StatusFilter, int> get _statusCounts {
    final counts = {
      _StatusFilter.semua: 0,
      _StatusFilter.aktif: 0,
      _StatusFilter.pending: 0,
      _StatusFilter.suspended: 0,
    };
    for (final raw in _items) {
      final t = raw as Map<String, dynamic>;
      final s = _statusOf(t);
      if (s == 'ARCHIVED') continue; // tidak dihitung di sini, punya section sendiri
      counts[_StatusFilter.semua] = counts[_StatusFilter.semua]! + 1;
      switch (s) {
        case 'AKTIF':
          counts[_StatusFilter.aktif] = counts[_StatusFilter.aktif]! + 1;
        case 'PENDING':
          counts[_StatusFilter.pending] = counts[_StatusFilter.pending]! + 1;
        case 'SUSPENDED':
          counts[_StatusFilter.suspended] =
              counts[_StatusFilter.suspended]! + 1;
      }
    }
    return counts;
  }

  List<Map<String, dynamic>> get _archivedItems => _items
      .cast<Map<String, dynamic>>()
      .where((t) => _statusOf(t) == 'ARCHIVED')
      .toList();

  List<Map<String, dynamic>> get _filtered {
    var list = _items.cast<Map<String, dynamic>>().where((t) {
      if (_statusOf(t) == 'ARCHIVED') return false; // punya section sendiri
      final matchesStatus = switch (_statusFilter) {
        _StatusFilter.semua => true,
        _StatusFilter.aktif => _statusOf(t) == 'AKTIF',
        _StatusFilter.pending => _statusOf(t) == 'PENDING',
        _StatusFilter.suspended => _statusOf(t) == 'SUSPENDED',
      };
      final matchesPackage =
          _packageFilter == 'Semua Paket' || _paketOf(t) == _packageFilter;
      final haystack = [
        t['namaPondok'],
        t['kodeTenant'],
        t['subdomain'],
      ].where((e) => e != null).join(' ').toLowerCase();
      final matchesQuery = _query.isEmpty || haystack.contains(_query);
      return matchesStatus && matchesPackage && matchesQuery;
    }).toList();

    switch (_sort) {
      case _SortOption.terbaru:
        break; // asumsikan API sudah mengurutkan terbaru lebih dulu
      case _SortOption.namaAz:
        list.sort((a, b) => (a['namaPondok'] ?? '')
            .toString()
            .compareTo((b['namaPondok'] ?? '').toString()));
      case _SortOption.userTerbanyak:
        list.sort((a, b) =>
            (b['jumlahUser'] ?? 0).compareTo(a['jumlahUser'] ?? 0));
      case _SortOption.santriTerbanyak:
        list.sort((a, b) =>
            (b['jumlahSantri'] ?? 0).compareTo(a['jumlahSantri'] ?? 0));
    }
    return list;
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PColors.primary),
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final counts = _statusCounts;

    return RefreshIndicator(
      color: PColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _PageTitleRow(total: _items.length),
          const SizedBox(height: 14),
          _SearchField(controller: _searchCtrl),
          const SizedBox(height: 10),
          _StatusChips(
            counts: counts,
            selected: _statusFilter,
            onSelected: (v) => setState(() {
              _statusFilter = v;
              _visibleCount = 5;
            }),
          ),
          const SizedBox(height: 10),
          _FilterDropdowns(
            packageValue: _packageFilter,
            sortValue: _sort,
            onPackageChanged: (v) => setState(() {
              _packageFilter = v;
              _visibleCount = 5;
            }),
            onSortChanged: (v) => setState(() => _sort = v),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    style: PText.bodySm,
                    children: [
                      const TextSpan(text: 'Menampilkan '),
                      TextSpan(
                        text: '${visible.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: PColors.primary,
                        ),
                      ),
                      TextSpan(text: ' dari ${filtered.length} Tenant'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 13, color: PColors.outline),
                    const SizedBox(width: 3),
                    Text('Tap kartu untuk detail', style: PText.bodySm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const _EmptyState()
          else
            ...visible.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TenantCard(
                  tenant: t,
                  onTap: () => _showTenantDetail(t),
                  onApprove: () => _action(t, 'approve'),
                  onSuspend: () => _action(t, 'suspend'),
                  onRestore: () => _action(t, 'restore'),
                  onArchive: () => _action(t, 'archive'),
                  onUnarchive: () => _action(t, 'unarchive'),
                ),
              ),
            ),
          if (filtered.length > _visibleCount) ...[
            const SizedBox(height: 4),
            _LoadMoreButton(
              remaining: filtered.length - _visibleCount,
              onPressed: () => setState(() => _visibleCount += 10),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Menampilkan $_visibleCount dari ${filtered.length} Tenant • '
                'Halaman ${(_visibleCount / 5).ceil().clamp(1, 999)} dari '
                '${(filtered.length / 5).ceil().clamp(1, 999)}',
                style: PText.labelSm,
              ),
            ),
          ],
          if (_archivedItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ArchivedSection(
              items: _archivedItems,
              expanded: _archivedExpanded,
              onToggle: () =>
                  setState(() => _archivedExpanded = !_archivedExpanded),
              onUnarchive: (t) => _action(t, 'unarchive'),
              onTapTenant: _showTenantDetail,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Page title + CTA
// ============================================================================

class _PageTitleRow extends StatelessWidget {
  const _PageTitleRow({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelola Tenant', style: PText.headlineLg),
              const SizedBox(height: 2),
              Text('$total pondok terdaftar di platform', style: PText.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Search
// ============================================================================

class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 19, color: PColors.outline),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: (_) => setState(() {}),
              style: PText.bodyMd.copyWith(color: PColors.ink, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama pondok, kode tenant, subdomain...',
                hintStyle: PText.bodyMd.copyWith(color: PColors.outline),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            InkWell(
              onTap: () => setState(() => widget.controller.clear()),
              borderRadius: BorderRadius.circular(9999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.cancel, size: 18, color: PColors.outline),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Status filter chips
// ============================================================================

class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final Map<_StatusFilter, int> counts;
  final _StatusFilter selected;
  final ValueChanged<_StatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required _StatusFilter value,
      required String label,
      Color? dotColor,
    }) {
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? PColors.primary : PColors.surface,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: isSelected ? PColors.primary : PColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : PColors.inkSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : PColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${counts[value] ?? 0}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : PColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(value: _StatusFilter.semua, label: 'Semua'),
          chip(
            value: _StatusFilter.aktif,
            label: 'Aktif',
            dotColor: PColors.successText,
          ),
          chip(
            value: _StatusFilter.pending,
            label: 'Pending Review',
            dotColor: PColors.pendingBorder,
          ),
          chip(
            value: _StatusFilter.suspended,
            label: 'Suspended',
            dotColor: PColors.errorText,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Package + sort dropdowns
// ============================================================================

class _FilterDropdowns extends StatelessWidget {
  const _FilterDropdowns({
    required this.packageValue,
    required this.sortValue,
    required this.onPackageChanged,
    required this.onSortChanged,
  });

  final String packageValue;
  final _SortOption sortValue;
  final ValueChanged<String> onPackageChanged;
  final ValueChanged<_SortOption> onSortChanged;

  static const _packages = [
    'Semua Paket',
    'Free Trial',
    'Basic',
    'Pro',
    'Enterprise',
  ];

  static const _sortLabels = {
    _SortOption.terbaru: 'Terbaru Daftar',
    _SortOption.namaAz: 'Nama Pondok (A-Z)',
    _SortOption.userTerbanyak: 'User Terbanyak',
    _SortOption.santriTerbanyak: 'Santri Terbanyak',
  };

  InputDecoration _decoration(IconData icon) => InputDecoration(
        filled: true,
        fillColor: PColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PColors.border),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: packageValue,
            isExpanded: true,
            icon: const Icon(Icons.expand_more, size: 18, color: PColors.outline),
            style: PText.labelMd.copyWith(fontSize: 12),
            decoration: _decoration(Icons.expand_more),
            items: _packages
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) onPackageChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<_SortOption>(
            initialValue: sortValue,
            isExpanded: true,
            icon: const Icon(Icons.sort, size: 18, color: PColors.outline),
            style: PText.labelMd.copyWith(fontSize: 12),
            decoration: _decoration(Icons.sort),
            items: _SortOption.values
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(_sortLabels[s]!)))
                .toList(),
            onChanged: (v) {
              if (v != null) onSortChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Tenant card
// ============================================================================

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.onTap,
    required this.onApprove,
    required this.onSuspend,
    required this.onRestore,
    required this.onArchive,
    required this.onUnarchive,
  });

  final Map<String, dynamic> tenant;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final VoidCallback onRestore;
  final VoidCallback onArchive;
  final VoidCallback onUnarchive;

  String get _status => (tenant['status'] ?? 'AKTIF').toString().toUpperCase();
  String get _paket => (tenant['paket'] ?? 'Basic').toString();

  String _fmt(num? n) {
    if (n == null) return '-';
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final namaPondok = (tenant['namaPondok'] ?? '-').toString();
    final kodeTenant = (tenant['kodeTenant'] ?? '-').toString();
    final wilayah = (tenant['wilayah'] ?? tenant['lokasi'] ?? '').toString();
    final subdomain =
        (tenant['subdomain'] ?? '$kodeTenant.sistempesantren.com').toString();
    final tanggal =
        (tenant['tanggalGabung'] ?? tenant['createdAt'] ?? '-').toString();

    final borderColor = switch (_status) {
      'SUSPENDED' => PColors.errorBorder,
      'PENDING' => PColors.pendingBorder,
      _ => PColors.border,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaPondok,
                      style: PText.headlineSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: PColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(kodeTenant, style: PText.mono),
                        ),
                        if (wilayah.isNotEmpty) ...[
                          Text('•', style: TextStyle(color: PColors.outline)),
                          Text(wilayah, style: PText.bodySm),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: _status),
                  const SizedBox(height: 6),
                  _PackageBadge(paket: _paket),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: PColors.surfaceDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PColors.border.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 14, color: PColors.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subdomain,
                    style: PText.mono.copyWith(
                      fontSize: 11,
                      color: _status == 'AKTIF'
                          ? PColors.primary
                          : PColors.inkSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_status == 'AKTIF')
                  const Icon(Icons.open_in_new, size: 13, color: PColors.outline),
              ],
            ),
          ),
          if (_status == 'SUSPENDED') ...[
            const SizedBox(height: 10),
            _SuspendedNotice(
              reason: (tenant['alasanPenangguhan'] ??
                      'Tagihan lisensi SaaS menunggak. Akses modul asrama & akademik dibatasi sementara.')
                  .toString(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _hubungiPicTenant(context, tenant),
                  style: TextButton.styleFrom(
                    backgroundColor: PColors.surfaceContainerHigh,
                    foregroundColor: PColors.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hubungi PIC Tenant',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: PColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.lock_open, size: 14),
                  label: const Text('Pulihkan Akses',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ] else if (_status == 'PENDING') ...[
            const SizedBox(height: 10),
            _PendingNotice(
              note: (tenant['catatanPending'] ??
                      'Menunggu validasi SK Kemenag & berkas legalitas pendaftaran baru.')
                  .toString(),
              onReview: () {},
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: _status == 'PENDING' ? 'Estimasi User' : 'Total User',
                    value: _fmt(tenant['jumlahUser'] as num?),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: _status == 'PENDING' ? 'Santri Terdata' : 'Santri Aktif',
                    value: tenant['jumlahSantri'] == null
                        ? '-'
                        : _fmt(tenant['jumlahSantri'] as num?),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: _status == 'PENDING' ? 'Didaftarkan' : 'Bergabung',
                    value: tanggal,
                    small: true,
                  ),
                ),
              ],
            ),
          ),
          if (_status == 'PENDING') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: PColors.mint,
                  foregroundColor: PColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text('Setujui & Aktifkan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          if (_status == 'AKTIF') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onArchive,
                  style: TextButton.styleFrom(foregroundColor: PColors.outline),
                  child: const Text('Arsipkan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onSuspend,
                  style: TextButton.styleFrom(foregroundColor: PColors.errorText),
                  child: const Text('Suspend',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, label, dot) = switch (status) {
      'SUSPENDED' => (
          PColors.errorBg,
          PColors.errorText,
          PColors.errorBorder,
          'Suspended',
          true,
        ),
      'PENDING' => (
          PColors.pendingBg,
          PColors.pendingText,
          PColors.pendingBorder,
          'Pending',
          true,
        ),
      'ARCHIVED' => (
          PColors.surfaceContainerHigh,
          PColors.outline,
          PColors.border,
          'Diarsipkan',
          true,
        ),
      _ => (
          PColors.successBg,
          PColors.successText,
          PColors.successBorder,
          'Aktif',
          true,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge({required this.paket});

  final String paket;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = paket.toLowerCase() == 'enterprise';
    final isPro = paket.toLowerCase() == 'pro';
    final (bg, fg, border) = isEnterprise
        ? (PColors.goldSurface, PColors.goldDark, PColors.goldBorder)
        : isPro
            ? (PColors.sage, PColors.primary, PColors.primary.withOpacity(0.4))
            : (PColors.surfaceContainerHigh, PColors.inkSecondary, PColors.border);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEnterprise) ...[
            Icon(Icons.star, size: 10, color: PColors.gold),
            const SizedBox(width: 3),
          ],
          Text(
            paket,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuspendedNotice extends StatelessWidget {
  const _SuspendedNotice({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.errorSoftBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PColors.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: PColors.errorText),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11, color: PColors.errorText),
                children: [
                  const TextSpan(
                      text: 'Alasan Penangguhan: ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice({required this.note, required this.onReview});

  final String note;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.pendingSoftBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PColors.pendingBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, size: 15, color: PColors.pendingText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 11, color: PColors.pendingText),
            ),
          ),
          TextButton(
            onPressed: onReview,
            style: TextButton.styleFrom(
              foregroundColor: PColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text('Tinjau Berkas →',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _ArchivedNotice extends StatelessWidget {
  const _ArchivedNotice({required this.onUnarchive});

  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive_outlined, size: 15, color: PColors.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tenant ini diarsipkan. Seluruh user tidak bisa login.',
              style: PText.bodySm.copyWith(color: PColors.inkSecondary),
            ),
          ),
          TextButton(
            onPressed: onUnarchive,
            style: TextButton.styleFrom(
              foregroundColor: PColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text('Pulihkan →',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.small = false});

  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: PText.labelSm),
        const SizedBox(height: 2),
        Text(
          value,
          style: small
              ? PText.bodySm.copyWith(
                  fontWeight: FontWeight.w600, color: PColors.inkSecondary)
              : const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PColors.primary,
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// Empty / error / load more
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: PColors.border, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PColors.surfaceDim,
              shape: BoxShape.circle,
              border: Border.all(color: PColors.border),
            ),
            child: const Icon(Icons.domain_disabled, color: PColors.outline),
          ),
          const SizedBox(height: 10),
          const Text('Tidak ada tenant yang cocok',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: PColors.primary)),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci pencarian atau sesuaikan filter status dan paket pondok.',
            textAlign: TextAlign.center,
            style: PText.bodySm,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.remaining, required this.onPressed});

  final int remaining;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PColors.primary,
          side: const BorderSide(color: PColors.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.expand_more, size: 18),
        label: Text(
          'Muat Lebih Banyak ($remaining Tenant Lainnya)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ============================================================================
// Archived section (folder-style, mirip Chat Diarsipkan di WhatsApp)
// ============================================================================

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({
    required this.items,
    required this.expanded,
    required this.onToggle,
    required this.onUnarchive,
    required this.onTapTenant,
  });

  final List<Map<String, dynamic>> items;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onUnarchive;
  final ValueChanged<Map<String, dynamic>> onTapTenant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PColors.surfaceDim,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(Icons.archive_outlined,
                        size: 16, color: PColors.outline),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arsip (${items.length})',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PColors.ink,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more,
                        size: 20, color: PColors.outline),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Column(
              children: [
                const Divider(color: PColors.border, height: 1),
                for (final t in items) _ArchivedTenantRow(
                  tenant: t,
                  onTap: () => onTapTenant(t),
                  onUnarchive: () => onUnarchive(t),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ArchivedTenantRow extends StatelessWidget {
  const _ArchivedTenantRow({
    required this.tenant,
    required this.onTap,
    required this.onUnarchive,
  });

  final Map<String, dynamic> tenant;
  final VoidCallback onTap;
  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    final namaPondok = (tenant['namaPondok'] ?? '-').toString();
    final kodeTenant = (tenant['kodeTenant'] ?? '-').toString();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaPondok,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(kodeTenant, style: PText.mono.copyWith(fontSize: 10)),
                ],
              ),
            ),
            TextButton(
              onPressed: onUnarchive,
              style: TextButton.styleFrom(
                foregroundColor: PColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Pulihkan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}