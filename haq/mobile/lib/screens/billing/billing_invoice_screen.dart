import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 from DESIGN.md, the exact same family as
/// signup_screen.dart's PColors/PText, billing_admin_screen.dart's _BC/_BT,
/// and langganan_screen.dart's _LG/_LT.
/// ---------------------------------------------------------------------------
class _IC {
  _IC._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);
  static const onPrimaryContainerFixedVariant = Color(0xFF254E41);
  static const primaryFixed = Color(0xFFC0ECDA);

  static const secondary = Color(0xFF775A19);
  static const onSecondaryContainer = Color(0xFF785A1A);
  static const secondaryContainer = Color(0xFFFED488);
  static const secondaryFixed = Color(0xFFFFDEA5);
  static const secondaryFixedDim = Color(0xFFE9C176);
  static const onSecondaryFixed = Color(0xFF261900);

  static const background = Color(0xFFFAF9F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4F0);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);
  static const surfaceTint = Color(0xFF3E6658);

  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF414845);
  static const outline = Color(0xFF717975);
  static const outlineVariant = Color(0xFFC0C8C3);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

class _IT {
  _IT._();
  static const _font = 'Nunito';

  static const headlineLgMobile = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, height: 28 / 22,
    letterSpacing: -0.01, color: _IC.primary,
  );
  static const headlineSm = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18, color: _IC.primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: _IC.onSurfaceVariant,
  );
  static const bodySm = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, height: 18 / 12, color: _IC.onSurfaceVariant,
  );
  static const labelMd = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, height: 16 / 12, color: _IC.onSurfaceVariant,
  );
  static const labelSm = TextStyle(
    fontFamily: _font, fontSize: 10.5, fontWeight: FontWeight.w700, height: 14 / 10.5, color: _IC.onSurfaceVariant,
  );
}

enum _InvStatus { menunggak, menunggu, lunas }
enum _InvFilter { semua, menunggak, menunggu, lunas }

class BillingInvoiceScreen extends StatefulWidget {
  /// Dipanggil saat tombol back di header ditekan. Screen ini — sama seperti
  /// LanggananScreen — dirender langsung di dalam body BillingAdminScreen
  /// (bukan lewat Navigator.push), jadi tidak ada tombol back bawaan; parent
  /// yang menentukan cara kembali. Kalau null, tombol back tidak ditampilkan.
  final VoidCallback? onBack;

  const BillingInvoiceScreen({super.key, this.onBack});

  @override
  State<BillingInvoiceScreen> createState() => _BillingInvoiceScreenState();
}

class _BillingInvoiceScreenState extends State<BillingInvoiceScreen> {
  List<dynamic> _invoices = [];
  bool _loading = true;
  String? _error;

  final _search = TextEditingController();
  _InvFilter _filter = _InvFilter.semua;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final invoices = await api.get(ApiUrl.invoices);
      if (!mounted) return;
      setState(() {
        _invoices = invoices as List;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data tagihan: $e';
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Data-safety helpers
  // ---------------------------------------------------------------------
  dynamic _pick(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null) return map[k];
    }
    return null;
  }

  num _num(Map<String, dynamic> map, List<String> keys, [num fallback = 0]) {
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v;
      if (v is String) {
        final p = num.tryParse(v);
        if (p != null) return p;
      }
    }
    return fallback;
  }

  String _rupiah(num v) =>
      'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  DateTime? _dueDate(Map<String, dynamic> inv) {
    final raw = _pick(inv, ['jatuhTempo', 'tanggalJatuhTempo', 'dueDate']);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? _paidDate(Map<String, dynamic> inv) {
    final raw = _pick(inv, ['tanggalDibayar', 'paidAt', 'lunasPada']);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  String _fmtDate(DateTime d) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${bulan[d.month]} ${d.year}';
  }

  _InvStatus _classify(Map<String, dynamic> inv) {
    if (inv['status'] == 'LUNAS') return _InvStatus.lunas;
    final due = _dueDate(inv);
    if (due != null && DateTime.now().isAfter(due)) return _InvStatus.menunggak;
    return _InvStatus.menunggu;
  }

  List<Map<String, dynamic>> get _all =>
      List<Map<String, dynamic>>.from(_invoices.map((e) => (e as Map).cast<String, dynamic>()));

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = _all;

    if (q.isNotEmpty) {
      list = list.where((inv) {
        final t = (inv['tenant'] as Map?)?.cast<String, dynamic>() ?? {};
        final nama = ((t['namaPondok'] as String?) ?? '').toLowerCase();
        final kode = ((t['kodeTenant'] as String?) ?? '').toLowerCase();
        final no = ((_pick(inv, ['noInvoice', 'nomorInvoice']) as String?) ?? '').toLowerCase();
        return nama.contains(q) || kode.contains(q) || no.contains(q);
      }).toList();
    }

    if (_filter != _InvFilter.semua) {
      list = list.where((inv) {
        final s = _classify(inv);
        switch (_filter) {
          case _InvFilter.menunggak:
            return s == _InvStatus.menunggak;
          case _InvFilter.menunggu:
            return s == _InvStatus.menunggu;
          case _InvFilter.lunas:
            return s == _InvStatus.lunas;
          case _InvFilter.semua:
            return true;
        }
      }).toList();
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------
  Future<void> _tandaiLunas(Map<String, dynamic> inv) async {
    try {
      await AppScope.of(context).api.patch('${ApiUrl.invoices}/${inv['id']}', {'status': 'LUNAS'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice ditandai LUNAS.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _suspendTenant(Map<String, dynamic> inv) async {
    final t = (inv['tenant'] as Map?)?.cast<String, dynamic>() ?? {};
    final tenantId = t['id'] as String?;
    if (tenantId == null) {
      _notAvailable();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Suspend Tenant'),
        content: Text('Suspend akses "${t['namaPondok']}" karena tagihan menunggak?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _IC.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.tenantSuspend, {'tenantId': tenantId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t['namaPondok']} disuspend.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fitur ini akan segera tersedia.')));
  }

  void _openDetail(Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(
        invoice: inv,
        status: _classify(inv),
        rupiah: _rupiah,
        num_: _num,
        pick: _pick,
        fmtDate: _fmtDate,
        onKirimUlang: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Faktur dikirim ulang ke email admin tenant.')));
        },
        onUnduh: _notAvailable,
      ),
    );
  }

  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Tanpa Scaffold.appBar sendiri: screen ini dirender di dalam body
    // BillingAdminScreen (tanpa Navigator.push), jadi top bar & bottom nav
    // milik shell platform tetap terlihat. Judul halaman + tombol back
    // ditampilkan lewat _buildHeader() di dalam body. Center + ConstrainedBox
    // (maxWidth: 480) tetap dipakai agar konten fix di tengah dan tidak
    // melebar penuh saat dibuka di web — persis pola LanggananScreen.
    return Scaffold(
      backgroundColor: _IC.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _loading
                ? loadingView()
                : _error != null
                    ? errorView(_error!, _load)
                    : RefreshIndicator(
                        onRefresh: () => _load(showSpinner: false),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 16),
                              _buildSearch(),
                              const SizedBox(height: 10),
                              _buildFilterChips(),
                              const SizedBox(height: 16),
                              _buildSummaryBanner(),
                              const SizedBox(height: 16),
                              if (_filtered.isEmpty)
                                _EmptyState(hasQuery: _search.text.trim().isNotEmpty)
                              else
                                Column(
                                  children: [
                                    for (final inv in _filtered)
                                      _InvoiceCard(
                                        invoice: inv,
                                        status: _classify(inv),
                                        rupiah: _rupiah,
                                        dueDate: _dueDate(inv),
                                        paidDate: _paidDate(inv),
                                        fmtDate: _fmtDate,
                                        onTapName: () => _openDetail(inv),
                                        onTandaiLunas: () => _tandaiLunas(inv),
                                        onSuspend: () => _suspendTenant(inv),
                                        onReminder: _notAvailable,
                                        onCekBukti: _notAvailable,
                                        onLihatFaktur: () => _openDetail(inv),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _all.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back, color: _IC.primary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tagihan & Langganan', style: _IT.headlineLgMobile),
              const SizedBox(height: 2),
              Text('$total Faktur Terdaftar', style: _IT.bodyMd),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: 'Cari nama tenant, slug, atau no faktur...',
        hintStyle: _IT.bodyMd,
        prefixIcon: const Icon(Icons.search, color: _IC.onSurfaceVariant, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: _IC.onSurfaceVariant),
                onPressed: () => setState(() => _search.clear()),
              ),
        filled: true,
        fillColor: _IC.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterChips() {
    final all = _all;
    final counts = {
      _InvFilter.semua: all.length,
      _InvFilter.menunggak: all.where((i) => _classify(i) == _InvStatus.menunggak).length,
      _InvFilter.menunggu: all.where((i) => _classify(i) == _InvStatus.menunggu).length,
      _InvFilter.lunas: all.where((i) => _classify(i) == _InvStatus.lunas).length,
    };

    Widget chip(String label, _InvFilter value, {Color? dot}) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: selected ? _IC.onPrimary : _IC.onSurfaceVariant)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.2) : _IC.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${counts[value] ?? 0}',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800,
                        color: selected ? _IC.onPrimary : _IC.onSurfaceVariant)),
              ),
            ],
          ),
          selected: selected,
          onSelected: (_) => setState(() => _filter = value),
          selectedColor: _IC.primaryContainer,
          backgroundColor: _IC.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide.none),
          showCheckmark: false,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('Semua', _InvFilter.semua),
        chip('Menunggak', _InvFilter.menunggak, dot: _IC.error),
        chip('Menunggu', _InvFilter.menunggu, dot: _IC.secondaryFixedDim),
        chip('Lunas', _InvFilter.lunas, dot: _IC.surfaceTint),
      ]),
    );
  }

  Widget _buildSummaryBanner() {
    final all = _all;
    final menunggak = all.where((i) => _classify(i) == _InvStatus.menunggak).toList();
    final menunggu = all.where((i) => _classify(i) == _InvStatus.menunggu).toList();
    final totalMenunggak = menunggak.fold<num>(0, (s, i) => s + _num(i, ['jumlah', 'nominal']));
    final totalMenunggu = menunggu.fold<num>(0, (s, i) => s + _num(i, ['jumlah', 'nominal']));
    final perluAksi = menunggak.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _IC.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _IC.errorContainer, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_wallet, size: 17, color: _IC.onErrorContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REKAP ARUS KAS', style: _IT.labelSm),
                    if (perluAksi)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: _IC.error, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Perlu Aksi', style: _IT.labelSm.copyWith(color: _IC.error)),
                      ]),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Tertunggak: ', style: _IT.labelSm),
                      Text(_rupiah(totalMenunggak), style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w800, color: _IC.error)),
                      Text(' (${menunggak.length})', style: _IT.labelSm),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Menunggu: ', style: _IT.labelSm),
                      Text(_rupiah(totalMenunggu), style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w800, color: _IC.secondary)),
                      Text(' (${menunggu.length})', style: _IT.labelSm),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable pieces
// =============================================================================

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(color: _IC.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 28, color: _IC.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'Tidak ada faktur yang cocok dengan pencarian.' : 'Belum ada faktur tercatat.',
            textAlign: TextAlign.center,
            style: _IT.bodySm,
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final _InvStatus status;
  final String Function(num) rupiah;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String Function(DateTime) fmtDate;
  final VoidCallback onTapName;
  final VoidCallback onTandaiLunas;
  final VoidCallback onSuspend;
  final VoidCallback onReminder;
  final VoidCallback onCekBukti;
  final VoidCallback onLihatFaktur;

  const _InvoiceCard({
    required this.invoice,
    required this.status,
    required this.rupiah,
    required this.dueDate,
    required this.paidDate,
    required this.fmtDate,
    required this.onTapName,
    required this.onTandaiLunas,
    required this.onSuspend,
    required this.onReminder,
    required this.onCekBukti,
    required this.onLihatFaktur,
  });

  @override
  Widget build(BuildContext context) {
    final t = (invoice['tenant'] as Map?)?.cast<String, dynamic>() ?? {};
    final namaPondok = (t['namaPondok'] as String?) ?? 'Tenant';
    final kodeTenant = (t['kodeTenant'] as String?) ?? '-';
    final noInvoice = (invoice['noInvoice'] ?? invoice['nomorInvoice']) as String? ?? '-';
    final paketNama = ((invoice['paket'] as Map?)?['nama'] as String?) ??
        ((t['paket'] as Map?)?['nama'] as String?);
    final jumlah = (invoice['jumlah'] ?? invoice['nominal']) as num? ?? 0;

    final barColor = status == _InvStatus.menunggak
        ? _IC.error
        : status == _InvStatus.menunggu
            ? _IC.secondaryFixedDim
            : _IC.surfaceTint;

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _IC.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: barColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onTapName,
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  if (paketNama != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: _IC.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                                      child: Text(paketNama.toUpperCase(),
                                          style: _IT.labelSm.copyWith(fontSize: 9.5)),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(child: Text(noInvoice, overflow: TextOverflow.ellipsis, style: _IT.labelSm.copyWith(color: _IC.outline))),
                                ]),
                                const SizedBox(height: 3),
                                Text(namaPondok, maxLines: 1, overflow: TextOverflow.ellipsis, style: _IT.headlineSm.copyWith(fontSize: 15.5)),
                                Text('@$kodeTenant', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: _IT.labelSm.copyWith(color: _IC.primary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: _IC.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(status == _InvStatus.lunas ? 'Nominal Dibayar' : 'Nominal Tagihan', style: _IT.labelSm),
                              Text(rupiah(jumlah),
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800,
                                      color: status == _InvStatus.lunas ? _IC.primary : _IC.onSurface)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (status == _InvStatus.menunggak && dueDate != null) ...[
                                Text('Terlambat ${DateTime.now().difference(dueDate!).inDays} hari',
                                    style: _IT.labelSm.copyWith(color: _IC.error)),
                                Text('Tempo: ${fmtDate(dueDate!)}', style: _IT.labelSm),
                              ] else if (status == _InvStatus.menunggu) ...[
                                Text('Jatuh tempo', style: _IT.labelSm.copyWith(color: _IC.onSurfaceVariant)),
                                Text(dueDate != null ? fmtDate(dueDate!) : '-', style: _IT.labelSm),
                              ] else ...[
                                Text('Lunas pada', style: _IT.labelSm.copyWith(color: _IC.surfaceTint)),
                                Text(paidDate != null ? fmtDate(paidDate!) : '-', style: _IT.labelSm),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _actionRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(_InvStatus s) {
    final bg = s == _InvStatus.menunggak
        ? _IC.errorContainer
        : s == _InvStatus.menunggu
            ? _IC.secondaryFixed
            : _IC.primaryFixed;
    final fg = s == _InvStatus.menunggak
        ? _IC.onErrorContainer
        : s == _InvStatus.menunggu
            ? _IC.onSecondaryFixed
            : _IC.onPrimaryContainerFixedVariant;
    final icon = s == _InvStatus.menunggak
        ? Icons.warning_amber_rounded
        : s == _InvStatus.menunggu
            ? Icons.hourglass_top
            : Icons.done_all;
    final label = s == _InvStatus.menunggak ? 'Menunggak' : s == _InvStatus.menunggu ? 'Menunggu' : 'Lunas';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
      ]),
    );
  }

  Widget _actionRow() {
    switch (status) {
      case _InvStatus.menunggak:
        return Row(children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onReminder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _IC.primary,
                  backgroundColor: _IC.surfaceContainer,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.forward_to_inbox, size: 16),
                label: const Text('Kirim Reminder', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: onSuspend,
              style: FilledButton.styleFrom(
                backgroundColor: _IC.errorContainer,
                foregroundColor: _IC.onErrorContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.block, size: 15),
              label: const Text('Suspend', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]);
      case _InvStatus.menunggu:
        return SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: onTandaiLunas,
            style: FilledButton.styleFrom(
              backgroundColor: _IC.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Tandai Lunas', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        );
      case _InvStatus.lunas:
        return SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onLihatFaktur,
            style: OutlinedButton.styleFrom(
              foregroundColor: _IC.primary,
              backgroundColor: _IC.surfaceContainer,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Lihat Faktur & Kwitansi', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        );
    }
  }
}

/// The bottom sheet shown when a tenant name / invoice card is tapped —
/// matches the "Faktur #..." mockup: tenant & PIC info, a SaaS line-item
/// breakdown, an optional payment-method note, and follow-up actions.
class _InvoiceDetailSheet extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final _InvStatus status;
  final String Function(num) rupiah;
  final num Function(Map<String, dynamic>, List<String>, [num]) num_;
  final dynamic Function(Map<String, dynamic>, List<String>) pick;
  final String Function(DateTime) fmtDate;
  final VoidCallback onKirimUlang;
  final VoidCallback onUnduh;

  const _InvoiceDetailSheet({
    required this.invoice,
    required this.status,
    required this.rupiah,
    required this.num_,
    required this.pick,
    required this.fmtDate,
    required this.onKirimUlang,
    required this.onUnduh,
  });

  @override
  Widget build(BuildContext context) {
    final t = (invoice['tenant'] as Map?)?.cast<String, dynamic>() ?? {};
    final namaPondok = (t['namaPondok'] as String?) ?? 'Tenant';
    final kodeTenant = (t['kodeTenant'] as String?) ?? '-';
    final noInvoice = (invoice['noInvoice'] ?? invoice['nomorInvoice']) as String? ?? '-';
    final paketNama = ((invoice['paket'] as Map?)?['nama'] as String?) ??
        ((t['paket'] as Map?)?['nama'] as String?);
    final jumlah = (invoice['jumlah'] ?? invoice['nominal']) as num? ?? 0;

    final picNama = pick(invoice, ['picNama', 'contactName']) as String?;
    final picTelepon = pick(invoice, ['picTelepon', 'contactPhone']) as String?;
    final periodeMulai = pick(invoice, ['periodeMulai', 'tanggalMulai']);
    final periodeAkhir = pick(invoice, ['periodeAkhir', 'tanggalAkhir']);
    String? periodeText;
    if (periodeMulai is String && periodeAkhir is String) {
      final mulai = DateTime.tryParse(periodeMulai);
      final akhir = DateTime.tryParse(periodeAkhir);
      if (mulai != null && akhir != null) {
        periodeText = 'Periode Tagihan: ${fmtDate(mulai)} \u2013 ${fmtDate(akhir)}';
      }
    }
    final metode = pick(invoice, ['metodePembayaran', 'paymentMethod']) as String?;
    final catatanMetode = pick(invoice, ['catatanPembayaran', 'paymentNote']) as String?;

    final label = status == _InvStatus.menunggak ? 'Menunggak' : status == _InvStatus.menunggu ? 'Menunggu' : 'Lunas';
    final badgeBg = status == _InvStatus.menunggak
        ? _IC.errorContainer
        : status == _InvStatus.menunggu
            ? _IC.secondaryFixed
            : _IC.primaryFixed;
    final badgeFg = status == _InvStatus.menunggak
        ? _IC.onErrorContainer
        : status == _InvStatus.menunggu
            ? _IC.onSecondaryFixed
            : _IC.onPrimaryContainerFixedVariant;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _IC.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 44, height: 5, decoration: BoxDecoration(color: _IC.outlineVariant.withOpacity(0.6), borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: _IC.surfaceContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.receipt, size: 17, color: _IC.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(child: Text('Faktur #$noInvoice', overflow: TextOverflow.ellipsis, style: _IT.headlineSm)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                              child: Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeFg)),
                            ),
                          ]),
                          Text('Dibuat otomatis oleh Sistem Billing SIMPesantren', style: _IT.labelSm.copyWith(color: _IC.outline)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _IC.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _IC.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
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
                                      Text('TENANT PEMBAYAR', style: _IT.labelSm.copyWith(color: _IC.outline)),
                                      Text(namaPondok, style: _IT.headlineSm),
                                      Text('Slug: @$kodeTenant', style: _IT.labelSm.copyWith(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                if (paketNama != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _IC.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                                    child: Text('Paket $paketNama', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: _IC.primary)),
                                  ),
                              ],
                            ),
                            if (picNama != null) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.person, size: 15, color: _IC.primary),
                                const SizedBox(width: 6),
                                Expanded(child: Text('PIC: $picNama${picTelepon != null ? ' • $picTelepon' : ''}', style: _IT.labelSm)),
                              ]),
                            ],
                            if (periodeText != null) ...[
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.event_repeat, size: 15, color: _IC.primary),
                                const SizedBox(width: 6),
                                Expanded(child: Text(periodeText, style: _IT.labelSm)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('RINCIAN LAYANAN SAAS', style: _IT.labelSm.copyWith(color: _IC.outline)),
                          Text('SUBTOTAL', style: _IT.labelSm.copyWith(color: _IC.outline)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _IC.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Langganan SIMPesantren Cloud',
                                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: _IC.onSurface)),
                                      Text(paketNama != null ? 'Paket $paketNama' : 'Biaya langganan', style: _IT.labelSm.copyWith(color: _IC.outline)),
                                    ],
                                  ),
                                ),
                                Text(rupiah(jumlah),
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: _IC.onSurface)),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: _IC.surfaceContainerHigh)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Pembayaran', style: _IT.headlineSm.copyWith(fontSize: 15)),
                                Text(rupiah(jumlah), style: _IT.headlineSm.copyWith(fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (metode != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _IC.secondaryContainer.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22, height: 22,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(color: _IC.secondaryContainer, shape: BoxShape.circle),
                                child: const Icon(Icons.info, size: 13, color: _IC.onSecondaryContainer),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Metode: $metode', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: _IC.secondary)),
                                    if (catatanMetode != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(catatanMetode, style: _IT.bodySm),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: onKirimUlang,
                          style: FilledButton.styleFrom(
                            backgroundColor: _IC.primaryContainer,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.mail, size: 18),
                          label: const Text('Kirim Ulang ke Email Admin Tenant', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: onUnduh,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _IC.primary,
                                backgroundColor: _IC.surfaceContainer,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Unduh PDF Faktur', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _IC.onSurfaceVariant,
                              backgroundColor: _IC.surfaceContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: const Text('Tutup', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}