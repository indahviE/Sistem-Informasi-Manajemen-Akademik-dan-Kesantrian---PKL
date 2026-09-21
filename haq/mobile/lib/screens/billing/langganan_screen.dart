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
  static const input = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: _LG.onSurface,
  );
  static const button = TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 13);
}

/// Border krem tipis — sama dengan `_border` di audit_log_screen.dart.
const Color _searchBorder = Color(0xFFEAE6DC);

/// Dekorasi field filled bertema: tanpa border kotak, radius 14, fokus hijau.
InputDecoration _themedDecoration(String label) {
  OutlineInputBorder border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: _LT.bodySm,
    floatingLabelStyle: _LT.bodySm.copyWith(color: _LG.primary, fontWeight: FontWeight.w700),
    filled: true,
    fillColor: _LG.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(_LG.primary),
  );
}

enum _LangFilter { semua, aktif, akanBerakhir, trial }

class LanggananScreen extends StatefulWidget {
  /// Dipanggil saat tombol back di header ditekan. Screen ini ditampilkan
  /// langsung di dalam body BillingAdminScreen (bukan lewat Navigator.push),
  /// jadi tidak ada tombol back bawaan — parent yang menentukan cara kembali.
  /// Kalau null, tombol back tidak ditampilkan.
  final VoidCallback? onBack;

  const LanggananScreen({super.key, this.onBack});

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
  /// UI-nya custom (bukan AlertDialog bawaan Material) supaya konsisten
  /// dengan tema "Islamic Academic & Kesantrian Experience" di layar ini:
  /// radius besar, pilihan lewat bottom sheet hijau, tombol pill.
  Future<void> _assignDialog({String? tenantId}) async {
    String? selectedTenant = tenantId;
    String? selectedPaket;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: _LG.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign Paket ke Pondok', style: _LT.headlineSm),
                  const SizedBox(height: 4),
                  Text(
                    tenantId != null
                        ? 'Pilih paket baru untuk pondok ini.'
                        : 'Pilih pondok dan paket yang ingin diassign.',
                    style: _LT.bodySm,
                  ),
                  const SizedBox(height: 18),
                  _ThemedSelect<String>(
                    label: 'Pilih Pondok',
                    value: selectedTenant,
                    // Kalau dibuka dari kartu tenant ("Ubah Paket"), pondok
                    // sudah pasti dan tidak bisa diganti.
                    enabled: tenantId == null,
                    // Jumlah tenant terus bertambah — beri kolom cari.
                    searchable: true,
                    options: [
                      for (final t in _tenants)
                        MapEntry(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                    ],
                    onChanged: (v) => setSt(() => selectedTenant = v),
                  ),
                  const SizedBox(height: 12),
                  _ThemedSelect<String>(
                    label: 'Pilih Paket',
                    value: selectedPaket,
                    options: [
                      for (final p in _pakets) MapEntry(p['id'] as String, p['nama'] as String),
                    ],
                    onChanged: (v) => setSt(() => selectedPaket = v),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _LG.onSurfaceVariant,
                            side: const BorderSide(color: _LG.outlineVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal', style: _LT.button),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: selectedTenant == null || selectedPaket == null
                              ? null
                              : () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _LG.primaryContainer,
                            disabledBackgroundColor: _LG.outlineVariant,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Assign', style: _LT.button),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
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
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogCtx) => Dialog(
        backgroundColor: _LG.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: _LG.errorContainer, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.warning_amber_rounded, color: _LG.error),
                ),
                const SizedBox(height: 14),
                const Text('Batalkan Langganan', style: _LT.headlineSm),
                const SizedBox(height: 6),
                const Text(
                  'Langganan ini akan dihentikan dan tenant kembali ke status Trial. Lanjutkan?',
                  style: _LT.bodyMd,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LG.onSurfaceVariant,
                          side: const BorderSide(color: _LG.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal', style: _LT.button),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _LG.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batalkan', style: _LT.button),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
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
    // Tanpa Scaffold.appBar sendiri: screen ini dirender di dalam body
    // BillingAdminScreen (tanpa Navigator.push), jadi top bar & bottom nav
    // milik shell platform tetap terlihat. Judul halaman + tombol back +
    // tombol Tambah ditampilkan lewat _buildHeader() di dalam body.
    // Center + ConstrainedBox(maxWidth: 480) tetap dipakai agar konten fix
    // di tengah dan tidak melebar penuh saat dibuka di web.
    return Scaffold(
      backgroundColor: _LG.background,
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
        if (widget.onBack != null) ...[
          IconButton(
            onPressed: widget.onBack,
            tooltip: 'Kembali ke Billing',
            icon: const Icon(Icons.arrow_back, color: _LG.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelola Langganan', style: _LT.headlineLgMobile),
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

  /// Search field — gaya sama dengan `_SearchField` di audit_log_screen.dart:
  /// pill penuh, tinggi 46, border krem tipis, ikon search di kiri, dan tombol
  /// clear bulat di kanan.
  Widget _buildSearch() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _LG.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _searchBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: _LG.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              style: _LT.bodyMd,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama pondok atau kode tenant...',
                hintStyle: _LT.bodySm,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            InkWell(
              onTap: () => setState(() => _search.clear()),
              borderRadius: BorderRadius.circular(9999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.cancel, size: 18, color: _LG.onSurfaceVariant),
              ),
            ),
        ],
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

/// Field pilihan bertema hijau (pengganti TwSelect): tampil seperti field
/// filled lainnya, dan saat ditekan membuka bottom sheet "Pilih" dengan opsi
/// bertanda hijau. Kalau [enabled] false, field hanya menampilkan nilai.
/// Kalau [searchable] true, bottom sheet punya kolom cari (filter lokal
/// berdasarkan teks label opsi) dan tingginya dibuat tetap.
class _ThemedSelect<V> extends StatelessWidget {
  final String label;
  final V? value;
  final List<MapEntry<V, String>> options;
  final ValueChanged<V> onChanged;
  final bool enabled;
  final bool searchable;

  const _ThemedSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.searchable = false,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<V>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _LG.surfaceContainerLowest,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SelectSheet<V>(
        options: options,
        value: value,
        searchable: searchable,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    String? current;
    for (final o in options) {
      if (o.key == value) current = o.value;
    }
    return InkWell(
      onTap: enabled ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(14),
      splashColor: _LG.primaryContainer.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: InputDecorator(
        isEmpty: current == null,
        decoration: _themedDecoration(label).copyWith(
          suffixIcon: enabled
              ? const Icon(Icons.keyboard_arrow_down_rounded, color: _LG.onSurfaceVariant)
              : const Icon(Icons.lock_outline_rounded, size: 18, color: _LG.onSurfaceVariant),
        ),
        child: Text(
          current ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: enabled ? _LT.input : _LT.input.copyWith(color: _LG.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Isi bottom sheet untuk [_ThemedSelect]. Kalau [searchable], ada kolom cari
/// bergaya pill (sama seperti search di halaman) di bawah judul, tinggi sheet
/// dibuat tetap (maks 70% layar) supaya tidak loncat saat hasil filter
/// berubah, dan sheet ikut naik saat keyboard muncul.
class _SelectSheet<V> extends StatefulWidget {
  final List<MapEntry<V, String>> options;
  final V? value;
  final bool searchable;

  const _SelectSheet({
    required this.options,
    required this.value,
    required this.searchable,
  });

  @override
  State<_SelectSheet<V>> createState() => _SelectSheetState<V>();
}

class _SelectSheetState<V> extends State<_SelectSheet<V>> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<MapEntry<V, String>> get _visible {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((o) => o.value.toLowerCase().contains(q)).toList();
  }

  Widget _searchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _LG.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _searchBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: _LG.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: _LT.bodyMd,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama pondok atau kode...',
                hintStyle: _LT.bodySm,
              ),
            ),
          ),
          if (_query.text.isNotEmpty)
            InkWell(
              onTap: () => setState(() => _query.clear()),
              borderRadius: BorderRadius.circular(9999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.cancel, size: 18, color: _LG.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(MapEntry<V, String> o, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => Navigator.pop<V>(context, o.key),
        borderRadius: BorderRadius.circular(12),
        splashColor: _LG.primaryContainer.withOpacity(0.08),
        highlightColor: _LG.primaryContainer.withOpacity(0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _LG.successContainer.withOpacity(0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? _LG.primaryContainer : _LG.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? _LG.primary : _LG.onSurface,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_rounded, size: 20, color: _LG.primaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final visible = _visible;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _LG.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('Pilih', style: _LT.headlineSm),
        ),
        const SizedBox(height: 8),
        if (widget.searchable) ...[
          _searchField(),
          const SizedBox(height: 8),
        ],
      ],
    );

    final list = visible.isEmpty
        ? SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Tidak ada hasil yang cocok.',
                textAlign: TextAlign.center,
                style: _LT.bodySm,
              ),
            ),
          )
        : ListView(
            shrinkWrap: !widget.searchable,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              for (final o in visible) _row(o, selected: o.key == widget.value),
            ],
          );

    Widget body;
    if (widget.searchable) {
      // Tinggi tetap: 70% layar, tapi tidak lebih dari ruang yang tersisa
      // di atas keyboard.
      final preferred = mq.size.height * 0.7;
      final available = mq.size.height - keyboard - mq.padding.top - 24;
      final h = preferred < available ? preferred : available;
      body = SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Expanded(child: list),
          ],
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Flexible(child: list),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        bottom: keyboard == 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: body,
        ),
      ),
    );
  }
}

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