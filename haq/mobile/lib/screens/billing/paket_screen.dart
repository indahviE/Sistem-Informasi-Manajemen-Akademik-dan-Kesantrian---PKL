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
  static const input = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: _PK.onSurface,
  );
  static const button = TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 13);
}

/// Border krem tipis — sama dengan `_border` di audit_log_screen.dart.
const Color _searchBorder = Color(0xFFEAE6DC);

/// Periode tagihan — nilai harus sama dengan yang diterima backend.
const _periodeLabel = {
  'HARIAN': 'Per Hari',
  'BULANAN': 'Per Bulan',
  'TAHUNAN': 'Per Tahun',
};

const _periodeSuffix = {
  'HARIAN': '/ hari',
  'BULANAN': '/ bulan',
  'TAHUNAN': '/ tahun',
};

String _ribuan(String digits) =>
    digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

/// Dekorasi field filled bertema (dipakai _ThemedSelect).
InputDecoration _themedDecoration(String label) {
  OutlineInputBorder border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: _PT.bodySm,
    floatingLabelStyle: _PT.bodySm.copyWith(color: _PK.primary, fontWeight: FontWeight.w700),
    filled: true,
    fillColor: _PK.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(_PK.primary),
  );
}

enum _StatusFilter { semua, aktif, nonaktif }

class PaketScreen extends StatefulWidget {
  /// Dipanggil saat tombol back di header ditekan. Screen ini ditampilkan
  /// langsung di dalam body BillingAdminScreen (bukan lewat Navigator.push),
  /// jadi tidak ada tombol back bawaan — parent yang menentukan cara kembali.
  /// Kalau null, tombol back tidak ditampilkan.
  final VoidCallback? onBack;

  const PaketScreen({super.key, this.onBack});

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

  /// Toast bertema hijau paket_screen — dipakai untuk semua feedback
  /// sukses/error di halaman ini, gaya sama dengan _showSuccessToast di
  /// landing_screen.dart (floating, rounded, background solid, teks putih
  /// bold), tapi pakai token _PK/_PT lokal file ini.
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _PK.error : _PK.primaryContainer,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        width: 480,
        duration: Duration(seconds: isError ? 4 : 3),
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle,
                size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  String _rupiah(num v) => 'Rp ${_ribuan(v.round().toString())}';

  int _subscriberCount(String? paketId) {
    if (paketId == null) return 0;
    return _subs.where((s) {
      final sm = s as Map;
      final pid = (sm['paket'] as Map?)?['id'] ?? sm['paketId'];
      return pid == paketId && sm['status'] == 'AKTIF';
    }).length;
  }

  /// Beda dengan _subscriberCount: ini menghitung SEMUA histori langganan
  /// (aktif, expired, dibatalkan) tanpa filter status — dipakai untuk
  /// menentukan apakah paket boleh dihapus permanen atau tidak. Backend
  /// (removePaket) menolak hapus selama masih ada baris subscription apapun
  /// yang mereferensikan paket ini (foreign key Restrict di schema.prisma —
  /// relasi Subscription.paket tidak punya onDelete: SetNull, dan paketId
  /// wajib diisi), jadi UI ini mencerminkan aturan yang sama supaya user
  /// tidak sampai kena error dari backend.
  bool _pernahDipakai(String? paketId) {
    if (paketId == null) return false;
    return _subs.any((s) {
      final sm = s as Map;
      final pid = (sm['paket'] as Map?)?['id'] ?? sm['paketId'];
      return pid == paketId;
    });
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
      _showToast(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => p['aktif'] = !value);
      _showToast('Gagal memperbarui status paket.', isError: true);
    }
  }

  Future<void> _hapusPaket(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogCtx) => Dialog(
        backgroundColor: _PK.surfaceContainerLowest,
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
                  decoration: BoxDecoration(color: _PK.errorContainer, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline, color: _PK.error),
                ),
                const SizedBox(height: 14),
                const Text('Hapus Paket', style: _PT.headlineSm),
                const SizedBox(height: 6),
                Text('Hapus paket "${p['nama']}"? Tindakan ini tidak dapat dibatalkan.', style: _PT.bodyMd),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _PK.onSurfaceVariant,
                          side: const BorderSide(color: _PK.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal', style: _PT.button),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _PK.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hapus', style: _PT.button),
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
      await AppScope.of(context).api.delete('${ApiUrl.paket}/${p['id']}');
      _load(showSpinner: false);
      _showToast('Paket berhasil dihapus.', isError: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

  /// Tambah / Edit paket. Form-nya ada di [_PaketFormDialog] (bawah), yang
  /// mengembalikan body siap kirim (nama, harga, limitSantri, periode, aktif,
  /// fitur) atau null kalau dibatalkan.
  Future<void> _paketDialog({Map<String, dynamic>? existing}) async {
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _PaketFormDialog(existing: existing),
    );
    if (body == null || !mounted) return;
    try {
      final api = AppScope.of(context).api;
      if (existing == null) {
        await api.post(ApiUrl.paket, body);
      } else {
        await api.patch('${ApiUrl.paket}/${existing['id']}', body);
      }
      _load(showSpinner: false);
      _showToast(existing == null ? 'Paket berhasil ditambahkan.' : 'Paket berhasil diperbarui.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
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
      backgroundColor: _PK.background,
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
                                    for (final p in _filtered)
                                      _PaketCard(
                                        paket: p,
                                        subscriberCount: _subscriberCount(p['id'] as String?),
                                        pernahDipakai: _pernahDipakai(p['id'] as String?),
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
        if (widget.onBack != null) ...[
          IconButton(
            onPressed: widget.onBack,
            tooltip: 'Kembali ke Billing',
            icon: const Icon(Icons.arrow_back, color: _PK.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelola Paket', style: _PT.headlineLgMobile),
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

  /// Search field — gaya sama dengan `_SearchField` di audit_log_screen.dart:
  /// pill penuh, tinggi 46, border krem tipis, ikon search di kiri, dan tombol
  /// clear bulat di kanan.
  Widget _buildSearch() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _PK.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _searchBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: _PK.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              style: _PT.bodyMd,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama paket...',
                hintStyle: _PT.bodySm,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            InkWell(
              onTap: () => setState(() => _search.clear()),
              borderRadius: BorderRadius.circular(9999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.cancel, size: 18, color: _PK.onSurfaceVariant),
              ),
            ),
        ],
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
// Dialog Tambah / Edit Paket
// =============================================================================

class _PaketFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _PaketFormDialog({this.existing});

  @override
  State<_PaketFormDialog> createState() => _PaketFormDialogState();
}

class _PaketFormDialogState extends State<_PaketFormDialog> {
  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _limit;
  late final TextEditingController _fitur;
  late String _periode;
  late bool _aktif;
  String? _namaError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _nama = TextEditingController(text: (e?['nama'] as String?) ?? '');

    final hargaAwal = e == null ? null : num.tryParse('${e['harga']}');
    _harga = TextEditingController(
      text: hargaAwal == null ? '' : _ribuan(hargaAwal.round().toString()),
    );

    _limit = TextEditingController(text: e?['limitSantri'] != null ? '${e!['limitSantri']}' : '');

    final fiturList = (e?['fitur'] as List?)?.map((x) => '$x').toList() ?? const <String>[];
    _fitur = TextEditingController(text: fiturList.join('\n'));

    final p = e?['periode'] as String?;
    _periode = (p != null && _periodeLabel.containsKey(p)) ? p : 'TAHUNAN';
    _aktif = (e?['aktif'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _limit.dispose();
    _fitur.dispose();
    super.dispose();
  }

  void _submit() {
    final nama = _nama.text.trim();
    if (nama.isEmpty) {
      setState(() => _namaError = 'Nama paket wajib diisi');
      return;
    }
    final hargaDigits = _harga.text.replaceAll(RegExp(r'[^0-9]'), '');
    Navigator.pop<Map<String, dynamic>>(context, {
      'nama': nama,
      'harga': int.tryParse(hargaDigits) ?? 0,
      'limitSantri': int.tryParse(_limit.text.trim()) ?? 1,
      'periode': _periode,
      'aktif': _aktif,
      'fitur': _fitur.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    });
  }

  /// Dekorasi bersama untuk semua field & dropdown di dialog ini: filled,
  /// tanpa border kotak, radius 14.
  InputDecoration _decoration(
    String label, {
    String? prefixText,
    bool alignHint = false,
    String? errorText,
  }) {
    OutlineInputBorder border([Color? color, double width = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: _PT.bodySm,
      floatingLabelStyle: _PT.bodySm.copyWith(color: _PK.primary, fontWeight: FontWeight.w700),
      prefixText: prefixText,
      prefixStyle: _PT.input.copyWith(fontWeight: FontWeight.w700),
      errorText: errorText,
      errorStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: _PK.error),
      filled: true,
      fillColor: _PK.surfaceContainerLow,
      alignLabelWithHint: alignHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(),
      enabledBorder: border(),
      focusedBorder: border(_PK.primary),
      errorBorder: border(_PK.error, 1),
      focusedErrorBorder: border(_PK.error),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? prefixText,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      onChanged: onChanged,
      style: _PT.input,
      decoration: _decoration(
        label,
        prefixText: prefixText,
        alignHint: maxLines > 1,
        errorText: errorText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _textField(
        controller: _nama,
        label: 'Nama Paket',
        errorText: _namaError,
        onChanged: (_) {
          if (_namaError != null) setState(() => _namaError = null);
        },
      ),
      _ThemedSelect<String>(
        label: 'Periode Tagihan',
        value: _periode,
        options: _periodeLabel.entries.toList(),
        onChanged: (v) => setState(() => _periode = v),
      ),
      _textField(
        controller: _harga,
        label: 'Harga ${_periodeSuffix[_periode]}',
        keyboardType: TextInputType.number,
        formatters: [_ThousandsInputFormatter()],
        prefixText: 'Rp ',
      ),
      _textField(
        controller: _limit,
        label: 'Limit Santri',
        keyboardType: TextInputType.number,
        formatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      _textField(
        controller: _fitur,
        label: 'Daftar Fitur (satu fitur per baris)',
        maxLines: 5,
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _PK.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Paket Aktif', style: _PT.labelLg),
            Switch(
              value: _aktif,
              activeColor: _PK.primaryContainer,
              activeTrackColor: _PK.primaryContainer.withOpacity(0.35),
              onChanged: (v) => setState(() => _aktif = v),
            ),
          ],
        ),
      ),
    ];

    return Dialog(
      backgroundColor: _PK.surfaceContainerLowest,
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
              Text(_isEdit ? 'Edit Paket' : 'Tambah Paket', style: _PT.headlineSm),
              const SizedBox(height: 4),
              Text(
                _isEdit ? 'Perbarui detail paket ini.' : 'Buat paket langganan baru untuk platform.',
                style: _PT.bodySm,
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i != fields.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _PK.onSurfaceVariant,
                        side: const BorderSide(color: _PK.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal', style: _PT.button),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _PK.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan', style: _PT.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Field pilihan bertema hijau (pengganti TwSelect / dropdown bawaan): tampil
/// seperti field filled lainnya, dan saat ditekan membuka bottom sheet
/// "Pilih" dengan opsi bertanda hijau.
class _ThemedSelect<V> extends StatelessWidget {
  final String label;
  final V? value;
  final List<MapEntry<V, String>> options;
  final ValueChanged<V> onChanged;

  const _ThemedSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<V>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PK.surfaceContainerLowest,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _PK.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Pilih', style: _PT.headlineSm),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      _row(sheetCtx, o, selected: o.key == value),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  Widget _row(BuildContext sheetCtx, MapEntry<V, String> o, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => Navigator.pop<V>(sheetCtx, o.key),
        borderRadius: BorderRadius.circular(12),
        splashColor: _PK.primaryContainer.withOpacity(0.08),
        highlightColor: _PK.primaryContainer.withOpacity(0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _PK.successContainer.withOpacity(0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? _PK.primaryContainer : _PK.outlineVariant,
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
                    color: selected ? _PK.primary : _PK.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: _PK.primaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? current;
    for (final o in options) {
      if (o.key == value) current = o.value;
    }
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(14),
      splashColor: _PK.primaryContainer.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: InputDecorator(
        isEmpty: current == null,
        decoration: _themedDecoration(label).copyWith(
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: _PK.onSurfaceVariant),
        ),
        child: Text(
          current ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _PT.input,
        ),
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
  final bool pernahDipakai;
  final String Function(num) rupiah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleAktif;

  const _PaketCard({
    required this.paket,
    required this.subscriberCount,
    required this.pernahDipakai,
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
    final periode = (paket['periode'] as String?) ?? 'TAHUNAN';
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
                        Text(harga == 0 ? '' : (_periodeSuffix[periode] ?? '/ tahun'), style: _PT.bodySm),
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
            const Text('Belum ada daftar fitur untuk paket ini.', style: _PT.bodySm)
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
              Switch(
                value: aktif,
                onChanged: onToggleAktif,
                activeColor: _PK.primaryContainer,
                activeTrackColor: _PK.primaryContainer.withOpacity(0.35),
              ),
            ],
          ),
          if (pernahDipakai) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _PK.secondaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: _PK.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Paket ini pernah/sedang dipakai tenant, sehingga tidak bisa dihapus. Gunakan saklar di atas untuk menonaktifkan.',
                      style: _PT.bodySm.copyWith(color: _PK.onSecondaryContainer, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
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
              Tooltip(
                message: pernahDipakai
                    ? 'Tidak bisa dihapus — masih terkait histori langganan'
                    : 'Hapus paket',
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: pernahDipakai ? null : onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pernahDipakai ? _PK.onSurfaceVariant : _PK.error,
                      side: BorderSide(color: pernahDipakai ? _PK.outlineVariant : _PK.errorContainer),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Icon(Icons.delete_outline, size: 17),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live thousands-separator formatter for the harga field: "1500000" ->
/// "1.500.000", kursor selalu di akhir.
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');
    final formatted = _ribuan(digitsOnly);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}