import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 from DESIGN.md, same family as
/// signup_screen.dart's PColors/PText and billing_admin_screen.dart's _BC/_BT.
/// ---------------------------------------------------------------------------
class _LG {
  _LG._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);

  static const secondary = Color(0xFF775A19);
  static const secondaryContainer = Color(0xFFFED488);
  static const secondaryFixed = Color(0xFFFFDEA5);
  static const onSecondaryFixed = Color(0xFF261900);

  static const background = Color(0xFFFAF9F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4F0);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);

  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF414845);
  static const outlineVariant = Color(0xFFC0C8C3);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const successContainer = Color(0xFFC0ECDA);
  static const onSuccessContainer = Color(0xFF0F3A2E);

  static const pendingContainer = Color(0xFFFFF3D6);
  static const onPendingContainer = Color(0xFF8A5B00);
}

class _LT {
  _LT._();
  static const _font = 'Nunito';

  static const headlineLgMobile = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, height: 28 / 22,
    letterSpacing: -0.01, color: _LG.primary,
  );
  static const headlineSm = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18, color: _LG.primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: _LG.onSurfaceVariant,
  );
  static const bodySm = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, height: 18 / 12, color: _LG.onSurfaceVariant,
  );
  static const labelSm = TextStyle(
    fontFamily: _font, fontSize: 10.5, fontWeight: FontWeight.w700, height: 14 / 10.5, color: _LG.onSurfaceVariant,
  );
}

enum _LangFilter { semua, aktif, akanBerakhir, trial }

class LanggananScreen extends StatefulWidget {
  const LanggananScreen({super.key});

  @override
  State<LanggananScreen> createState() => _LanggananScreenState();
}

class _LanggananScreenState extends State<LanggananScreen> {
  List<dynamic> _tenants = [];
  List<dynamic> _subs = [];
  List<dynamic> _pakets = [];
  bool _loading = true;
  String? _error;

  final _search = TextEditingController();
  _LangFilter _filter = _LangFilter.semua;

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
      final results = await Future.wait([
        api.get(ApiUrl.tenants),
        api.get(ApiUrl.subscriptions),
        api.get(ApiUrl.paket),
      ]);
      if (!mounted) return;
      setState(() {
        _tenants = results[0] as List;
        _subs = results[1] as List;
        _pakets = results[2] as List;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data langganan: $e';
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Data-safety helpers
  // ---------------------------------------------------------------------
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

  /// Finds the active subscription (if any) for a tenant id.
  Map<String, dynamic>? _subFor(String tenantId) {
    for (final s in _subs) {
      final sm = (s as Map).cast<String, dynamic>();
      final tId = (sm['tenant'] as Map?)?['id'] ?? sm['tenantId'];
      if (tId == tenantId && sm['status'] == 'AKTIF') return sm;
    }
    return null;
  }

  /// Days remaining until a subscription ends, based on the real backend
  /// field `tanggalAkhir` (Subscription: tenantId, paketId, tanggalMulai,
  /// tanggalAkhir, status).
  int? _daysRemaining(Map<String, dynamic> sub) {
    final raw = sub['tanggalAkhir'];
    if (raw is! String) return null;
    final end = DateTime.tryParse(raw);
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = List<Map<String, dynamic>>.from(_tenants.map((e) => (e as Map).cast<String, dynamic>()));

    if (q.isNotEmpty) {
      list = list.where((t) {
        final nama = (t['namaPondok'] as String? ?? '').toLowerCase();
        final kode = (t['kodeTenant'] as String? ?? '').toLowerCase();
        return nama.contains(q) || kode.contains(q);
      }).toList();
    }

    if (_filter != _LangFilter.semua) {
      list = list.where((t) {
        final sub = _subFor(t['id'] as String);
        if (_filter == _LangFilter.trial) return sub == null;
        if (sub == null) return false;
        final days = _daysRemaining(sub);
        if (_filter == _LangFilter.akanBerakhir) return days != null && days >= 0 && days <= 14;
        return _filter == _LangFilter.aktif; // any active, regardless of days left
      }).toList();
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------
  Future<void> _assignDialog({String? tenantId}) async {
    String? selectedTenant = tenantId;
    String? selectedPaket;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Assign Paket ke Pondok'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TwSelect(
                value: selectedTenant,
                label: 'Pilih Pondok',
                options: [
                  for (final t in _tenants)
                    DropdownOption(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                ],
                onChanged: tenantId != null
                    ? (String? v) {}
                    : (String? v) => setSt(() => selectedTenant = v),
              ),
              const SizedBox(height: 10),
              TwSelect(
                value: selectedPaket,
                label: 'Pilih Paket',
                options: [for (final p in _pakets) DropdownOption(p['id'] as String, p['nama'] as String)],
                onChanged: (v) => setSt(() => selectedPaket = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: selectedTenant == null || selectedPaket == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      // Backend's assignSubscription otomatis meng-expire-kan langganan AKTIF
      // lama milik tenant ini (jika ada) lalu membuat subscription baru
      // dengan tanggalAkhir = +1 tahun — endpoint yang sama ini juga dipakai
      // untuk "Ubah Paket" / "Perpanjang".
      await AppScope.of(context)
          .api
          .post(ApiUrl.subscriptions, {'tenantId': selectedTenant, 'paketId': selectedPaket});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Langganan berhasil dibuat.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _batalkan(Map<String, dynamic> sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Langganan'),
        content: const Text('Langganan ini akan dihentikan dan tenant kembali ke status Trial. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _LG.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      // StatusSubscription: AKTIF | EXPIRED | CANCELED
      await AppScope.of(context)
          .api
          .patch('${ApiUrl.subscriptions}/${sub['id']}', {'status': 'CANCELED'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Langganan dibatalkan.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Tanpa Scaffold.appBar sendiri (disamakan dengan tenants_screen.dart):
    // judul halaman cukup ditampilkan lewat _buildHeader() di dalam body,
    // supaya top bar & bottom nav bar milik shell platform (di luar screen
    // ini) tetap terlihat saat berpindah ke halaman Langganan.
    // Center + ConstrainedBox(maxWidth: 480) tetap dipakai agar konten fix
    // di tengah dan tidak melebar penuh saat dibuka di web.
    return Scaffold(
      backgroundColor: _LG.background,
      body: SafeArea(
        child: Center(
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
                              if (_filtered.isEmpty)
                                _EmptyState(hasQuery: _search.text.trim().isNotEmpty)
                              else
                                Column(
                                  children: [
                                    for (final t in _filtered)
                                      _LanggananCard(
                                        tenant: t,
                                        sub: _subFor(t['id'] as String),
                                        daysRemaining: () {
                                          final s = _subFor(t['id'] as String);
                                          return s == null ? null : _daysRemaining(s);
                                        }(),
                                        rupiah: _rupiah,
                                        num_: _num,
                                        onAssign: () => _assignDialog(tenantId: t['id'] as String),
                                        onBatalkan: (s) => _batalkan(s),
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
    final aktifCount = _tenants.where((t) => _subFor((t as Map)['id'] as String) != null).length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kelola Langganan', style: _LT.headlineLgMobile),
              const SizedBox(height: 2),
              Text('$aktifCount langganan aktif dari ${_tenants.length} tenant', style: _LT.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: () => _assignDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: _LG.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: 'Cari nama pondok atau kode tenant...',
        hintStyle: _LT.bodyMd,
        prefixIcon: const Icon(Icons.search, color: _LG.onSurfaceVariant, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: _LG.onSurfaceVariant),
                onPressed: () => setState(() => _search.clear()),
              ),
        filled: true,
        fillColor: _LG.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _LangFilter value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700,
              color: selected ? _LG.onPrimary : _LG.onSurfaceVariant)),
          selected: selected,
          onSelected: (_) => setState(() => _filter = value),
          selectedColor: _LG.primaryContainer,
          backgroundColor: _LG.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide.none),
          showCheckmark: false,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('Semua', _LangFilter.semua),
        chip('Aktif', _LangFilter.aktif),
        chip('Akan Berakhir', _LangFilter.akanBerakhir),
        chip('Trial', _LangFilter.trial),
      ]),
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
      decoration: BoxDecoration(color: _LG.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 28, color: _LG.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'Tidak ada tenant yang cocok dengan pencarian.' : 'Belum ada tenant terdaftar.',
            textAlign: TextAlign.center,
            style: _LT.bodySm,
          ),
        ],
      ),
    );
  }
}

class _LanggananCard extends StatelessWidget {
  final Map<String, dynamic> tenant;
  final Map<String, dynamic>? sub;
  final int? daysRemaining;
  final String Function(num) rupiah;
  final num Function(Map<String, dynamic>, List<String>, [num]) num_;
  final VoidCallback onAssign;
  final ValueChanged<Map<String, dynamic>> onBatalkan;

  const _LanggananCard({
    required this.tenant,
    required this.sub,
    required this.daysRemaining,
    required this.rupiah,
    required this.num_,
    required this.onAssign,
    required this.onBatalkan,
  });

  @override
  Widget build(BuildContext context) {
    final namaPondok = (tenant['namaPondok'] as String?) ?? 'Tenant';
    final kodeTenant = (tenant['kodeTenant'] as String?) ?? '-';
    final isTrial = sub == null;
    final paket = (sub?['paket'] as Map?)?.cast<String, dynamic>();
    final namaPaket = (paket?['nama'] as String?) ?? 'Belum Berlangganan';
    final harga = paket != null ? num_(paket, ['harga']) : 0;

    // Status badge logic.
    Color badgeBg = _LG.successContainer;
    Color badgeFg = _LG.onSuccessContainer;
    String badgeText = 'Aktif';
    if (isTrial) {
      badgeBg = _LG.secondaryFixed.withOpacity(0.6);
      badgeFg = _LG.onSecondaryFixed;
      badgeText = 'Trial';
    } else if (daysRemaining != null && daysRemaining! <= 14) {
      badgeBg = _LG.pendingContainer;
      badgeFg = _LG.onPendingContainer;
      badgeText = daysRemaining! < 0 ? 'Berakhir' : 'Berakhir $daysRemaining Hari Lagi';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _LG.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _LG.primaryContainer.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.apartment, color: _LG.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaPondok, maxLines: 1, overflow: TextOverflow.ellipsis, style: _LT.headlineSm.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Flexible(child: Text('@$kodeTenant', overflow: TextOverflow.ellipsis, style: _LT.labelSm)),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: _LG.outlineVariant, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(child: Text(namaPaket, overflow: TextOverflow.ellipsis, style: _LT.labelSm.copyWith(fontWeight: FontWeight.w800))),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Text(badgeText, style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeFg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _LG.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTrial ? 'Belum ada langganan berbayar' : 'Biaya Langganan', style: _LT.labelSm),
                    Text(
                      isTrial ? 'Trial' : rupiah(harga),
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: _LG.primary),
                    ),
                  ],
                ),
                if (isTrial)
                  FilledButton.icon(
                    onPressed: onAssign,
                    style: FilledButton.styleFrom(
                      backgroundColor: _LG.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Assign Paket', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
                  )
                else
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedButton(
                      onPressed: onAssign,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LG.primary,
                        backgroundColor: _LG.surfaceContainerHigh,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text('Ubah Paket', style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => onBatalkan(sub!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LG.error,
                        side: const BorderSide(color: _LG.errorContainer),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text('Batalkan', style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}