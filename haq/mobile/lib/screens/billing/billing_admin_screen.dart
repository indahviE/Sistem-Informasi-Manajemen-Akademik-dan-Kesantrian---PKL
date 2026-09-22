import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import 'billing_invoice_screen.dart';
import 'paket_screen.dart';
import 'langganan_screen.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 from DESIGN.md, the same source signup_screen
/// .dart's `PColors`/`PText` are built from, so this page shares the exact
/// same "Islamic Academic & Kesantrian Experience" identity (Deep Emerald
/// Forest + Antique Gold on a warm ivory canvas) and the same Nunito type
/// ramp as the signup flow.
/// ---------------------------------------------------------------------------
class _BC {
  _BC._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);
  static const onPrimaryContainer = Color(0xFF7AA494);
  static const primaryFixed = Color(0xFFC0ECDA);

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
  static const onErrorContainer = Color(0xFF93000A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const successContainer = Color(0xFFC0ECDA);
}

class _BT {
  _BT._();
  static const _font = 'Nunito';

  static const headlineLgMobile = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, height: 28 / 22,
    letterSpacing: -0.01, color: _BC.primary,
  );
  static const headlineSm = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18, color: _BC.primary,
  );
  static const displayLgMobile = TextStyle(
    fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w800, height: 32 / 26, color: _BC.primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: _BC.onSurfaceVariant,
  );
  static const bodySm = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, height: 18 / 12, color: _BC.onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, height: 20 / 14, color: _BC.onSurface,
  );
  static const labelMd = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, height: 16 / 12, color: _BC.onSurfaceVariant,
  );
  static const labelSm = TextStyle(
    fontFamily: _font, fontSize: 10.5, fontWeight: FontWeight.w700, height: 14 / 10.5, color: _BC.onSurfaceVariant,
  );
  static const input = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: _BC.onSurface,
  );
}

/// Dekorasi field filled bertema hijau — dipakai oleh `_BcSelect` di bawah
/// supaya dropdown-nya tidak jatuh ke style default Material (biru).
InputDecoration _bcDecoration(String label) {
  OutlineInputBorder border([Color? color]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: _BT.bodySm,
    floatingLabelStyle: _BT.bodySm.copyWith(color: _BC.primary, fontWeight: FontWeight.w700),
    filled: true,
    fillColor: _BC.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(_BC.primary),
  );
}

/// -----------------------------------------------------------------------
/// Field pilihan bertema hijau — pengganti `TwSelect`. Sama persis gaya &
/// perilakunya dengan `_ThemedSelect` di paket_screen.dart (bottom sheet
/// "Pilih" dengan titik & checkmark hijau di opsi terpilih), supaya dropdown
/// Periode Tagihan / Pilih Pondok / Pilih Paket di halaman ini konsisten
/// dengan halaman Paket — bukan lagi biru default Material.
/// -----------------------------------------------------------------------
class _BcSelect<V> extends StatelessWidget {
  final String label;
  final V? value;
  final List<MapEntry<V, String>> options;
  final ValueChanged<V> onChanged;

  const _BcSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<V>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _BC.surfaceContainerLowest,
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
                    color: _BC.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Pilih', style: _BT.headlineSm),
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
        splashColor: _BC.primaryContainer.withOpacity(0.08),
        highlightColor: _BC.primaryContainer.withOpacity(0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _BC.successContainer.withOpacity(0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? _BC.primaryContainer : _BC.outlineVariant,
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
                    color: selected ? _BC.primary : _BC.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: _BC.primaryContainer),
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
      splashColor: _BC.primaryContainer.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: InputDecorator(
        isEmpty: current == null,
        decoration: _bcDecoration(label).copyWith(
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: _BC.onSurfaceVariant),
        ),
        child: Text(
          current ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _BT.input,
        ),
      ),
    );
  }
}

/// Periode tagihan untuk dialog Tambah/Edit Paket — nilainya harus sama
/// dengan yang diterima backend.
const _paketPeriodeLabel = {
  'HARIAN': 'Per Hari',
  'BULANAN': 'Per Bulan',
  'TAHUNAN': 'Per Tahun',
};

const _paketPeriodeSuffix = {
  'HARIAN': '/ hari',
  'BULANAN': '/ bulan',
  'TAHUNAN': '/ tahun',
};

String _ribuan(String digits) =>
    digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

/// Dialog Tambah/Edit Paket — desainnya sama persis dengan
/// `_PaketFormDialog` di paket_screen.dart (kartu rounded, header +
/// subjudul, field filled, dan `_BcSelect` hijau untuk Periode Tagihan),
/// supaya "Tambah Paket" konsisten baik dibuka dari overview Billing
/// maupun dari halaman Kelola Paket.
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
    _periode = (p != null && _paketPeriodeLabel.containsKey(p)) ? p : 'TAHUNAN';
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

  /// Dekorasi bersama untuk semua field di dialog ini: filled, tanpa border
  /// kotak, radius 14 — sama dengan `_bcDecoration` tapi mendukung errorText.
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
      labelStyle: _BT.bodySm,
      floatingLabelStyle: _BT.bodySm.copyWith(color: _BC.primary, fontWeight: FontWeight.w700),
      prefixText: prefixText,
      prefixStyle: _BT.input.copyWith(fontWeight: FontWeight.w700),
      errorText: errorText,
      errorStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: _BC.error),
      filled: true,
      fillColor: _BC.surfaceContainerLow,
      alignLabelWithHint: alignHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(),
      enabledBorder: border(),
      focusedBorder: border(_BC.primary),
      errorBorder: border(_BC.error, 1),
      focusedErrorBorder: border(_BC.error),
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
      style: _BT.input,
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
      _BcSelect<String>(
        label: 'Periode Tagihan',
        value: _periode,
        options: _paketPeriodeLabel.entries.map((e) => MapEntry(e.key, e.value)).toList(),
        onChanged: (v) => setState(() => _periode = v),
      ),
      _textField(
        controller: _harga,
        label: 'Harga ${_paketPeriodeSuffix[_periode]}',
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
          color: _BC.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Paket Aktif', style: _BT.labelLg),
            Switch(
              value: _aktif,
              activeColor: _BC.primaryContainer,
              activeTrackColor: _BC.primaryContainer.withOpacity(0.35),
              onChanged: (v) => setState(() => _aktif = v),
            ),
          ],
        ),
      ),
    ];

    return Dialog(
      backgroundColor: _BC.surfaceContainerLowest,
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
              Text(_isEdit ? 'Edit Paket' : 'Tambah Paket', style: _BT.headlineSm),
              const SizedBox(height: 4),
              Text(
                _isEdit ? 'Perbarui detail paket ini.' : 'Buat paket langganan baru untuk platform.',
                style: _BT.bodySm,
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
                        foregroundColor: _BC.onSurfaceVariant,
                        side: const BorderSide(color: _BC.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _BC.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13)),
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

/// Sub-halaman yang ditampilkan in-place di dalam body screen ini.
enum _BillingView { overview, paket, langganan, invoice }

class BillingAdminScreen extends StatefulWidget {
  const BillingAdminScreen({super.key});

  @override
  State<BillingAdminScreen> createState() => _BillingAdminScreenState();
}

class _BillingAdminScreenState extends State<BillingAdminScreen> {
  List<dynamic> _pakets = [];
  List<dynamic> _subs = [];
  List<dynamic> _tenants = [];
  List<dynamic> _invoices = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastLoaded;

  /// Halaman yang sedang tampil. Paket/Langganan TIDAK dibuka lewat
  /// Navigator.push (yang akan menutupi seluruh ShellScreen, termasuk top bar
  /// & bottom nav), melainkan menggantikan konten body ini secara in-place.
  _BillingView _view = _BillingView.overview;

  final GlobalKey _overdueKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Defer to a microtask: AppScope.of(context) reads an InheritedWidget,
    // which Flutter disallows calling synchronously inside initState()
    // (it must happen after initState completes, e.g. in didChangeDependencies,
    // build, or — as here — a scheduled microtask/callback).
    Future.microtask(_load);
  }

  /// [showSpinner] controls whether the whole page swaps to the full-page
  /// loader. Pass false for refreshes triggered by an action the user just
  /// took (save/delete/assign/mark-paid) or pull-to-refresh, so the
  /// scroll view stays mounted — and the scroll position stays put —
  /// instead of being torn down and rebuilt at the top.
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
        api.get(ApiUrl.tenants),
        api.get(ApiUrl.invoices),
      ]);
      if (!mounted) return;
      setState(() {
        _pakets = results[0] as List;
        _subs = results[1] as List;
        _tenants = results[2] as List;
        _invoices = results[3] as List;
        _lastLoaded = DateTime.now();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data billing: $e';
        _loading = false;
      });
    }
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fitur ini akan segera tersedia.')));
  }

  /// Kembali dari sub-halaman Paket/Langganan ke overview billing, sekaligus
  /// refresh data di latar belakang (tanpa spinner) supaya metrik & katalog
  /// mencerminkan perubahan yang baru dilakukan di sub-halaman.
  void _backToOverview() {
    setState(() => _view = _BillingView.overview);
    _load(showSpinner: false);
  }

  // ===========================================================================
  // Small data-safety helpers
  // ===========================================================================
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

  String _rupiahCompact(num v) {
    if (v < 1000000) return _rupiah(v);
    final juta = v / 1000000;
    return 'Rp ${juta.toStringAsFixed(1).replaceAll('.', ',')} Jt';
  }

  String _bulanTahunSekarang() {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final now = DateTime.now();
    return '${bulan[now.month]} ${now.year}';
  }

  String _elapsed(DateTime? t) {
    if (t == null) return 'baru saja';
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  void _scrollToOverdue() {
    final ctx = _overdueKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Map<String, dynamic>? _paketFor(String? tenantId) {
    if (tenantId == null) return null;
    for (final s in _subs) {
      final sm = s as Map<String, dynamic>;
      final tId = (sm['tenant'] as Map?)?['id'] ?? sm['tenantId'];
      if (tId == tenantId && sm['status'] == 'AKTIF') {
        return (sm['paket'] as Map?)?.cast<String, dynamic>();
      }
    }
    return null;
  }

  // ===========================================================================
  // Package add/edit dialog — reused for both create and edit. Uses the same
  // rounded-card dialog design (with the green _BcSelect periode field) as
  // PaketScreen's own _PaketFormDialog, so "Tambah Paket" looks identical
  // whether it's opened from the Billing overview or from Kelola Paket.
  // ===========================================================================
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Toggles a package's active state directly from the catalog card switch.
  /// Optimistic UI: flips locally first, calls the API, and reverts with a
  /// message if the backend rejects it.
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
        content: Text('Hapus paket "${p['nama']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _BC.onSurfaceVariant),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _BC.error),
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

  Future<void> _assign() async {
    String? tenantId;
    String? paketId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Assign Paket ke Pondok'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BcSelect<String>(
                value: tenantId,
                label: 'Pilih Pondok',
                options: [
                  for (final t in _tenants)
                    MapEntry(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                ],
                onChanged: (v) => setSt(() => tenantId = v),
              ),
              const SizedBox(height: 10),
              _BcSelect<String>(
                value: paketId,
                label: 'Pilih Paket',
                options: [
                  for (final p in _pakets) MapEntry(p['id'] as String, p['nama'] as String),
                ],
                onChanged: (v) => setSt(() => paketId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: _BC.onSurfaceVariant),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _BC.primaryContainer),
              onPressed: tenantId == null || paketId == null
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
      await AppScope.of(context)
          .api
          .post(ApiUrl.subscriptions, {'tenantId': tenantId, 'paketId': paketId});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Langganan dibuat (1 tahun).')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _tandaiLunas(Map<String, dynamic> inv) async {
    try {
      await AppScope.of(context)
          .api
          .patch('${ApiUrl.invoices}/${inv['id']}', {'status': 'LUNAS'});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invoice ditandai LUNAS.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Sub-halaman Paket / Langganan dirender in-place (tanpa route baru),
    // sehingga top bar & bottom nav milik shell tetap terlihat. Tombol back
    // sistem/browser juga diarahkan kembali ke overview, bukan keluar dari tab.
    if (_view == _BillingView.paket) {
      return WillPopScope(
        onWillPop: () async {
          _backToOverview();
          return false;
        },
        child: PaketScreen(onBack: _backToOverview),
      );
    }
    if (_view == _BillingView.langganan) {
      return WillPopScope(
        onWillPop: () async {
          _backToOverview();
          return false;
        },
        child: LanggananScreen(onBack: _backToOverview),
      );
    }
    if (_view == _BillingView.invoice) {
      return WillPopScope(
        onWillPop: () async {
          _backToOverview();
          return false;
        },
        child: BillingInvoiceScreen(onBack: _backToOverview),
      );
    }

    return Scaffold(
      backgroundColor: _BC.background,
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
                              _buildPageHeader(),
                              const SizedBox(height: 18),
                              _buildMetricGrid(),
                              const SizedBox(height: 22),
                              Container(key: _overdueKey, child: _buildOverdueSection()),
                              const SizedBox(height: 24),
                              _buildCatalogSection(),
                              const SizedBox(height: 24),
                              _buildQuickActionsSection(),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 1. Page header — billing cycle + auto-invoice badge + title
  // ---------------------------------------------------------------------
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _BC.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 15, color: _BC.secondary),
                  const SizedBox(width: 6),
                  Text('Siklus Penagihan: Bulan Berjalan (${_bulanTahunSekarang()})', style: _BT.labelSm),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _BC.secondaryFixed.withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: _BC.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Auto-Invoice Aktif',
                      style: _BT.labelSm.copyWith(color: _BC.onSecondaryFixed, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 2. Metric grid (2x2)
  // ---------------------------------------------------------------------
  Widget _buildMetricGrid() {
    final aktifSubs = _subs.where((s) => (s as Map)['status'] == 'AKTIF').toList();

    // Normalize every paket's price to a monthly figure based on its own
    // billing `periode` (HARIAN/BULANAN/TAHUNAN), defaulting to TAHUNAN for
    // packages created before this field existed.
    num mrr = 0;
    for (final s in aktifSubs) {
      final pm = ((s as Map)['paket'] as Map?)?.cast<String, dynamic>() ?? {};
      final hargaPaket = _num(pm, ['harga']);
      final periode = (pm['periode'] as String?) ?? 'TAHUNAN';
      switch (periode) {
        case 'HARIAN':
          mrr += hargaPaket * 30;
          break;
        case 'BULANAN':
          mrr += hargaPaket;
          break;
        default: // TAHUNAN
          mrr += hargaPaket / 12;
      }
    }

    final tenantIdsBerbayar = aktifSubs
        .map((s) => (((s as Map)['tenant'] as Map?)?['id']) ?? s['tenantId'])
        .where((id) => id != null)
        .toSet();
    final totalTenant = _tenants.length;
    final berbayar = tenantIdsBerbayar.length;
    final trial = (totalTenant - berbayar).clamp(0, totalTenant);
    final progress = totalTenant > 0 ? berbayar / totalTenant : 0.0;

    final overdueInvoices = _invoices.where((i) => (i as Map)['status'] != 'LUNAS').toList();
    final overdueTenantIds = overdueInvoices
        .map((i) => (((i as Map)['tenant'] as Map?)?['id']) ?? i['tenantId'])
        .where((id) => id != null)
        .toSet();
    final totalTertunda =
        overdueInvoices.fold<num>(0, (sum, i) => sum + _num((i as Map).cast<String, dynamic>(), ['jumlah']));
        final adaTertunda = overdueInvoices.isNotEmpty;

    final totalFaktur = _invoices.length;
    final lunas = _invoices.where((i) => (i as Map)['status'] == 'LUNAS').length;
    final menunggu = totalFaktur - lunas;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _MetricCard(
          label: 'MRR Platform',
          icon: Icons.payments,
          iconColor: _BC.primary,
          iconBg: _BC.primary.withOpacity(0.10),
          value: _rupiahCompact(mrr),
          caption: 'Dari langganan aktif',
        ),
        _MetricCard(
          label: 'Lisensi Tenant',
          icon: Icons.verified,
          iconColor: _BC.secondary,
          iconBg: _BC.secondary.withOpacity(0.15),
          value: '$berbayar / $trial',
          caption: '$berbayar Berbayar • $trial Trial',
          progress: progress,
        ),
          _MetricCard(
          label: 'Tagihan Tertunda',
          icon: adaTertunda ? Icons.pending_actions : Icons.check_circle_outline,
          iconColor: adaTertunda ? _BC.error : _BC.primary,
          iconBg: adaTertunda ? _BC.errorContainer : _BC.surfaceContainerHigh,
          value: '${overdueTenantIds.length} Tenant',
          caption: adaTertunda ? _rupiah(totalTertunda) : 'Tidak ada tunggakan',
          warning: adaTertunda,
          onTapCaption: adaTertunda ? _scrollToOverdue : null,
          captionActionLabel: adaTertunda ? 'Tindak Sekarang' : null,
        ),
        _MetricCard(
          label: 'Faktur Bulan Ini',
          icon: Icons.receipt_long,
          iconColor: _BC.primary,
          iconBg: _BC.surfaceContainerHigh,
          value: '$totalFaktur Faktur',
          caption: '$lunas Lunas • $menunggu Menunggu',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 3. Tagihan Menunggak
  // ---------------------------------------------------------------------
  Widget _buildOverdueSection() {
    final overdue = _invoices.where((i) => (i as Map)['status'] != 'LUNAS').toList().cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Tagihan Menunggak', style: _BT.headlineSm),
                if (overdue.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _BC.errorContainer, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_amber_rounded, size: 12, color: _BC.onErrorContainer),
                      const SizedBox(width: 3),
                      Text('${overdue.length} Overdue',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: _BC.onErrorContainer)),
                    ]),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Masa tenggang penagihan telah habis atau mendekati batas isolasi sistem.', style: _BT.bodySm),
        const SizedBox(height: 12),
        if (overdue.isEmpty)
          _EmptyCard(text: 'Tidak ada tagihan yang menunggak saat ini.')
        else
          Column(
            children: [
              for (final inv in overdue) _overdueCard(inv),
            ],
          ),
      ],
    );
  }

  Widget _overdueCard(Map<String, dynamic> inv) {
    final t = (inv['tenant'] as Map?)?.cast<String, dynamic>() ?? {};
    final tenantId = t['id'] as String?;
    final paket = _paketFor(tenantId);
    final namaPondok = (t['namaPondok'] as String?) ?? 'Tenant';
    final kodeTenant = (t['kodeTenant'] as String?) ?? '-';
    final namaPaket = (paket?['nama'] as String?) ?? 'Tanpa Paket';
    final jumlah = _num(inv, ['jumlah']);
    final noInvoice = (inv['noInvoice'] as String?) ?? '-';

    final jatuhTempo = _pick(inv, ['jatuhTempo', 'dueDate', 'tanggalJatuhTempo']);
    String badgeText = 'Belum Lunas';
    if (jatuhTempo is String) {
      final due = DateTime.tryParse(jatuhTempo);
      if (due != null) {
        final days = DateTime.now().difference(due).inDays;
        if (days > 0) badgeText = 'Menunggak $days Hari';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _BC.surfaceContainerLowest,
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
                decoration: BoxDecoration(color: _BC.errorContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.block, color: _BC.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaPondok, maxLines: 1, overflow: TextOverflow.ellipsis, style: _BT.headlineSm.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Flexible(child: Text('@$kodeTenant', overflow: TextOverflow.ellipsis, style: _BT.labelSm)),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: _BC.outlineVariant, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(child: Text(namaPaket, overflow: TextOverflow.ellipsis, style: _BT.labelSm.copyWith(fontWeight: FontWeight.w800))),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: _BC.errorContainer, borderRadius: BorderRadius.circular(999)),
                child: Text(badgeText, style: const TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: _BC.onErrorContainer)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _BC.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faktur #$noInvoice', style: _BT.labelSm),
                    Text(_rupiah(jumlah), style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: _BC.error)),
                  ],
                ),
                InkWell(
                  onTap: () => _tandaiLunas(inv),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _BC.surfaceContainerLowest, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: _BC.primary),
                      const SizedBox(width: 4),
                      Text('Tandai Lunas', style: _BT.labelSm.copyWith(color: _BC.primary, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: _notAvailable,
                    style: FilledButton.styleFrom(
                      backgroundColor: _BC.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Kirim Tagihan WA/Email', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _notAvailable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _BC.primary,
                    backgroundColor: _BC.surfaceContainerHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Faktur', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 4. Katalog Paket
  // ---------------------------------------------------------------------
  Widget _buildCatalogSection() {
    final pakets = List<Map<String, dynamic>>.from(_pakets.map((e) => (e as Map).cast<String, dynamic>()));
    pakets.sort((a, b) => _num(a, ['harga']).compareTo(_num(b, ['harga'])));

    final paid = pakets.where((p) => _num(p, ['harga']) > 0).toList();
    final enterpriseId = paid.isNotEmpty ? paid.last['id'] : null;
    final popularId = paid.length >= 3 ? paid[paid.length - 2]['id'] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Katalog Paket', style: _BT.headlineSm),
                Text('Struktur tier dan fitur aktif platform', style: _BT.bodySm),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _assign,
                  tooltip: 'Assign Paket ke Tenant',
                  icon: const Icon(Icons.assignment_ind_outlined, color: _BC.primary),
                ),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: () => _paketDialog(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _BC.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Paket', style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (pakets.isEmpty)
          _EmptyCard(text: 'Belum ada paket. Tekan "Tambah Paket" untuk membuat.')
        else
          Column(
            children: [
              for (final p in pakets)
                _PaketTierCard(
                  paket: p,
                  isFree: _num(p, ['harga']) == 0,
                  isEnterprise: p['id'] == enterpriseId,
                  isPopular: p['id'] == popularId,
                  subscriberCount: _subs.where((s) {
                    final sm = (s as Map);
                    final pid = (sm['paket'] as Map?)?['id'] ?? sm['paketId'];
                    return pid == p['id'] && sm['status'] == 'AKTIF';
                  }).length,
                  rupiah: _rupiah,
                  onEdit: () => _paketDialog(existing: p),
                  onDelete: () => _hapusPaket(p),
                  onToggleAktif: (v) => _toggleAktif(p, v),
                ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 4b. Akses Cepat
  // ---------------------------------------------------------------------
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akses Cepat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _BC.primaryContainer,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickActionBullet(
              icon: Icons.category,
              label: 'Paket',
              color: _BC.primaryContainer,
              onTap: () => setState(() => _view = _BillingView.paket),
            ),
            _QuickActionBullet(
              icon: Icons.workspace_premium,
              label: 'Langganan',
              color: const Color(0xFFC5A059),
              onTap: () => setState(() => _view = _BillingView.langganan),
            ),
            _QuickActionBullet(
              icon: Icons.receipt,
              label: 'Tagihan',
              color: const Color(0xFFD4693F),
              onTap: () => setState(() => _view = _BillingView.invoice),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reusable pieces
/// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String caption;
  final bool warning;
  final double? progress;
  final VoidCallback? onTapCaption;
  final String? captionActionLabel;

  const _MetricCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.caption,
    this.warning = false,
    this.progress,
    this.onTapCaption,
    this.captionActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? _BC.errorContainer.withOpacity(0.35) : _BC.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _BT.labelMd.copyWith(color: warning ? _BC.onErrorContainer : _BC.onSurfaceVariant)),
              ),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w800,
                  color: warning ? _BC.error : _BC.primary)),
          const SizedBox(height: 4),
          if (onTapCaption != null)
            InkWell(
              onTap: onTapCaption,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(captionActionLabel ?? caption,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w800, color: _BC.error)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_downward, size: 11, color: _BC.error),
              ]),
            )
          else
            Text(caption,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: _BT.labelSm.copyWith(color: warning ? _BC.onErrorContainer : _BC.onSurfaceVariant, fontWeight: FontWeight.w700)),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: _BC.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation(_BC.primaryContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BC.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: _BC.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _BT.bodySm)),
        ],
      ),
    );
  }
}

class _PaketTierCard extends StatelessWidget {
  final Map<String, dynamic> paket;
  final bool isFree;
  final bool isEnterprise;
  final bool isPopular;
  final int subscriberCount;
  final String Function(num) rupiah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleAktif;

  const _PaketTierCard({
    required this.paket,
    required this.isFree,
    required this.isEnterprise,
    required this.isPopular,
    required this.subscriberCount,
    required this.rupiah,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAktif,
  });

  static const _periodeSuffix = {
    'HARIAN': '/ hari',
    'BULANAN': '/ bulan',
    'TAHUNAN': '/ tahun',
  };

  @override
  Widget build(BuildContext context) {
    final nama = paket['nama'] as String? ?? 'Paket';
    final harga = (paket['harga'] as num?) ?? 0;
    final limit = paket['limitSantri'];
    final periode = (paket['periode'] as String?) ?? 'TAHUNAN';
    final fitur = ((paket['fitur'] as List?)?.cast<String>()) ?? const <String>[];
    final aktif = (paket['aktif'] as bool?) ?? true;

    final bg = isEnterprise ? _BC.secondaryContainer.withOpacity(0.25) : _BC.surfaceContainerLowest;
    final badgeBg = isFree
        ? _BC.surfaceContainerHigh
        : isEnterprise
            ? _BC.secondaryContainer
            : isPopular
                ? _BC.primary.withOpacity(0.10)
                : _BC.secondaryFixed.withOpacity(0.6);
    final badgeFg = isFree
        ? _BC.onSurfaceVariant
        : isEnterprise
            ? _BC.onSecondaryContainer
            : isPopular
                ? _BC.primary
                : _BC.onSecondaryFixed;
    final priceColor = isEnterprise ? _BC.secondary : _BC.primary;

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isEnterprise ? 0.07 : 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isEnterprise)
            Positioned(
              right: -20, bottom: -20,
              child: Opacity(
                opacity: 0.08,
                child: Transform.rotate(angle: 0.785398, child: Icon(Icons.hotel_class, size: 130, color: _BC.secondary)),
              ),
            ),
          if (isPopular)
            Positioned(
              top: -16, right: -16,
              child: Container(
                padding: const EdgeInsets.only(left: 14, right: 8, top: 14, bottom: 6),
                decoration: BoxDecoration(color: _BC.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified, size: 12, color: _BC.onPrimary),
                  const SizedBox(width: 3),
                  const Text('Populer', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: _BC.onPrimary)),
                ]),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isEnterprise) ...[
                              Icon(Icons.hotel_class, size: 13, color: badgeFg),
                              const SizedBox(width: 4),
                            ],
                            Text(nama, style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w800, color: badgeFg)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(harga == 0 ? 'Rp 0' : rupiah(harga),
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w800, color: priceColor)),
                            const SizedBox(width: 4),
                            Text(harga == 0 ? '' : (_periodeSuffix[periode] ?? '/ tahun'), style: _BT.bodySm),
                          ],
                        ),
                        if (limit != null) ...[
                          const SizedBox(height: 3),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.groups, size: 13, color: isEnterprise ? _BC.secondary : _BC.secondary),
                            const SizedBox(width: 3),
                            Text('Maks $limit santri',
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700, color: _BC.secondary)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Pengguna Aktif', style: _BT.labelSm),
                      Text('$subscriberCount Pondok',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: priceColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _BC.surfaceContainerHigh),
              const SizedBox(height: 12),
              if (fitur.isEmpty)
                Text('Belum ada daftar fitur untuk paket ini.', style: _BT.bodySm)
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
                            Icon(Icons.check_circle, size: 17,
                                color: isEnterprise ? _BC.secondary : _BC.primaryContainer),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: _BT.bodyMd.copyWith(color: _BC.onSurface))),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: onDelete,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _BC.primary,
                        backgroundColor: _BC.surfaceContainerHigh,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit Paket', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(aktif ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                              color: aktif ? (isEnterprise ? _BC.secondary : _BC.primary) : _BC.onSurfaceVariant)),
                      Switch(
                        value: aktif,
                        onChanged: onToggleAktif,
                        activeColor: isEnterprise ? _BC.secondary : _BC.primaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Tahan lama tombol Edit untuk menghapus paket ini.',
                    style: _BT.labelSm.copyWith(fontSize: 9.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Action Bullet Widget
class _QuickActionBullet extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBullet({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Live thousands-separator formatter for the harga field: as the user
/// types digits, it re-inserts dots ("1500000" -> "1.500.000") so what
/// they see while editing matches how prices are shown everywhere else
/// on this page, and keeps the cursor at the end (simplest correct
/// behaviour for a field that's always edited by typing/deleting digits
/// at the end).
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
   }
}