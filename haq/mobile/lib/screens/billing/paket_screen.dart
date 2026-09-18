import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 from DESIGN.md, same as signup_screen.dart's
/// PColors/PText and billing_admin_screen.dart's _BC/_BT, so this page keeps
/// the exact same "Islamic Academic & Kesantrian Experience" identity.
/// ---------------------------------------------------------------------------
class _PK {
  _PK._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);

  static const secondary = Color(0xFF775A19);
  static const onSecondaryContainer = Color(0xFF785A1A);
  static const secondaryContainer = Color(0xFFFED488);
  static const secondaryFixed = Color(0xFFFFDEA5);
  static const onSecondaryFixed = Color(0xFF261900);

  static const background = Color(0xFFFAF9F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4F0);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);

  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF414845);
  static const outlineVariant = Color(0xFFC0C8C3);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const successContainer = Color(0xFFC0ECDA);
  static const onSuccessContainer = Color(0xFF0F3A2E);
}

class _PT {
  _PT._();
  static const _font = 'Nunito';

  static const headlineLgMobile = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, height: 28 / 22,
    letterSpacing: -0.01, color: _PK.primary,
  );
  static const headlineSm = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18, color: _PK.primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: _PK.onSurfaceVariant,
  );
  static const bodySm = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, height: 18 / 12, color: _PK.onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, height: 20 / 14, color: _PK.onSurface,
  );
  static const labelSm = TextStyle(
    fontFamily: _font, fontSize: 10.5, fontWeight: FontWeight.w700, height: 14 / 10.5, color: _PK.onSurfaceVariant,
  );
}

enum _StatusFilter { semua, aktif, nonaktif }

class PaketScreen extends StatefulWidget {
  const PaketScreen({super.key});

  @override
  State<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends State<PaketScreen> {
  List<dynamic> _pakets = [];
  List<dynamic> _subs = [];
  bool _loading = true;
  String? _error;

  final _search = TextEditingController();
  _StatusFilter _filter = _StatusFilter.semua;

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
        api.get(ApiUrl.paket),
        api.get(ApiUrl.subscriptions),
      ]);
      if (!mounted) return;
      setState(() {
        _pakets = results[0] as List;
        _subs = results[1] as List;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data paket: $e';
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Data-safety helpers (mirrors billing_admin_screen.dart)
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

  num _parseRupiah(String text) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return num.tryParse(digitsOnly) ?? 0;
  }

  int _subscriberCount(String? paketId) {
    if (paketId == null) return 0;
    return _subs.where((s) {
      final sm = s as Map;
      final pid = (sm['paket'] as Map?)?['id'] ?? sm['paketId'];
      return pid == paketId && sm['status'] == 'AKTIF';
    }).length;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = List<Map<String, dynamic>>.from(_pakets.map((e) => (e as Map).cast<String, dynamic>()));
    list.sort((a, b) => _num(a, ['harga']).compareTo(_num(b, ['harga'])));
    if (_filter != _StatusFilter.semua) {
      final wantAktif = _filter == _StatusFilter.aktif;
      list = list.where((p) => ((p['aktif'] as bool?) ?? true) == wantAktif).toList();
    }
    if (q.isNotEmpty) {
      list = list.where((p) => (p['nama'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------
  Future<void> _toggleAktif(Map<String, dynamic> p, bool value) async {
    setState(() => p['aktif'] = value);
    try {
      await AppScope.of(context).api.patch('${ApiUrl.paket}/${p['id']}', {'aktif': value});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => p['aktif'] = !value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => p['aktif'] = !value);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal memperbarui status paket.')));
    }
  }

  Future<void> _hapusPaket(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Paket'),
        content: Text('Hapus paket "${p['nama']}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _PK.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.paket}/${p['id']}');
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Add/edit dialog. Fields match the real backend Paket model exactly:
  /// id, nama, harga, limitSantri, fitur, aktif — there is no `periode`
  /// column, so no billing-cycle selector here.
  Future<void> _paketDialog({Map<String, dynamic>? existing}) async {
    final nama = TextEditingController(text: existing?['nama'] as String? ?? '');
    final harga = TextEditingController(
        text: existing != null ? _rupiah((existing['harga'] as num)).replaceFirst('Rp ', '') : '');
    final limit = TextEditingController(text: existing != null ? '${existing['limitSantri']}' : '');
    final fiturList = ((existing?['fitur'] as List?)?.cast<String>()) ?? const <String>[];
    final fitur = TextEditingController(text: fiturList.join('\n'));
    bool aktif = (existing?['aktif'] as bool?) ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Tambah Paket' : 'Edit Paket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Paket')),
                const SizedBox(height: 8),
                TextField(
                  controller: harga,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ThousandsInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Harga (Rp) / tahun', prefixText: 'Rp '),
                ),
                const SizedBox(height: 8),
                TextField(controller: limit, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Limit Santri')),
                const SizedBox(height: 8),
                TextField(
                  controller: fitur,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Daftar Fitur (satu fitur per baris)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paket Aktif'),
                    Switch(value: aktif, onChanged: (v) => setSt(() => aktif = v)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final body = {
        'nama': nama.text.trim(),
        'harga': _parseRupiah(harga.text),
        'limitSantri': int.tryParse(limit.text.trim()) ?? 1,
        'aktif': aktif,
        'fitur': fitur.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };
      if (existing == null) {
        await api.post(ApiUrl.paket, body);
      } else {
        await api.patch('${ApiUrl.paket}/${existing['id']}', body);
      }
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
    // ini) tetap terlihat saat berpindah ke halaman Paket.
    // Center + ConstrainedBox(maxWidth: 480) tetap dipakai agar konten fix
    // di tengah dan tidak melebar penuh saat dibuka di web.
    return Scaffold(
      backgroundColor: _PK.background,
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
                                    for (final p in _filtered)
                                      _PaketCard(
                                        paket: p,
                                        subscriberCount: _subscriberCount(p['id'] as String?),
                                        rupiah: _rupiah,
                                        onEdit: () => _paketDialog(existing: p),
                                        onDelete: () => _hapusPaket(p),
                                        onToggleAktif: (v) => _toggleAktif(p, v),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kelola Paket', style: _PT.headlineLgMobile),
              const SizedBox(height: 2),
              Text('${_pakets.length} paket terdaftar di platform', style: _PT.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: () => _paketDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: _PK.primaryContainer,
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
        hintText: 'Cari nama paket...',
        hintStyle: _PT.bodyMd,
        prefixIcon: const Icon(Icons.search, color: _PK.onSurfaceVariant, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: _PK.onSurfaceVariant),
                onPressed: () => setState(() => _search.clear()),
              ),
        filled: true,
        fillColor: _PK.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _StatusFilter value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700,
              color: selected ? _PK.onPrimary : _PK.onSurfaceVariant)),
          selected: selected,
          onSelected: (_) => setState(() => _filter = value),
          selectedColor: _PK.primaryContainer,
          backgroundColor: _PK.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide.none),
          showCheckmark: false,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('Semua', _StatusFilter.semua),
        chip('Aktif', _StatusFilter.aktif),
        chip('Nonaktif', _StatusFilter.nonaktif),
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
      decoration: BoxDecoration(color: _PK.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 28, color: _PK.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'Tidak ada paket yang cocok dengan pencarian.' : 'Belum ada paket. Tekan "Tambah" untuk membuat.',
            textAlign: TextAlign.center,
            style: _PT.bodySm,
          ),
        ],
      ),
    );
  }
}

class _PaketCard extends StatelessWidget {
  final Map<String, dynamic> paket;
  final int subscriberCount;
  final String Function(num) rupiah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleAktif;

  const _PaketCard({
    required this.paket,
    required this.subscriberCount,
    required this.rupiah,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAktif,
  });

  @override
  Widget build(BuildContext context) {
    final nama = paket['nama'] as String? ?? 'Paket';
    final harga = (paket['harga'] as num?) ?? 0;
    final limit = paket['limitSantri'];
    final fitur = ((paket['fitur'] as List?)?.cast<String>()) ?? const <String>[];
    final aktif = (paket['aktif'] as bool?) ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PK.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
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
                    Row(children: [
                      Expanded(
                        child: Text(nama, style: _PT.headlineSm.copyWith(fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: aktif ? _PK.successContainer : _PK.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(aktif ? 'Aktif' : 'Nonaktif', style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800,
                            color: aktif ? _PK.onSuccessContainer : _PK.onSurfaceVariant)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(harga == 0 ? 'Rp 0' : rupiah(harga),
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w800, color: _PK.primary)),
                        const SizedBox(width: 4),
                        Text(harga == 0 ? '' : '/ tahun', style: _PT.bodySm),
                      ],
                    ),
                    if (limit != null) ...[
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.groups, size: 13, color: _PK.secondary),
                        const SizedBox(width: 3),
                        Text('Maks $limit santri',
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700, color: _PK.secondary)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _PK.surfaceContainerHigh),
          const SizedBox(height: 12),
          if (fitur.isEmpty)
            Text('Belum ada daftar fitur untuk paket ini.', style: _PT.bodySm)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in fitur)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: _PK.primaryContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: _PT.bodyMd.copyWith(color: _PK.onSurface))),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.storefront_outlined, size: 14, color: _PK.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('$subscriberCount Pondok Aktif', style: _PT.labelSm),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(aktif ? 'Aktif' : 'Nonaktif', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                    color: aktif ? _PK.primary : _PK.onSurfaceVariant)),
                Switch(value: aktif, onChanged: onToggleAktif, activeColor: _PK.primaryContainer),
              ]),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _PK.primary,
                    backgroundColor: _PK.surfaceContainerHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit Paket', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _PK.error,
                    side: const BorderSide(color: _PK.errorContainer),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Icon(Icons.delete_outline, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live thousands-separator formatter for the harga field (same behaviour
/// as billing_admin_screen.dart's).
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');
    final formatted = digitsOnly.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}