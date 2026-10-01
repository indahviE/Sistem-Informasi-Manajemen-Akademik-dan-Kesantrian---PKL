import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';
import 'billing_invoice_screen.dart';
import 'paket_screen.dart';
import 'langganan_screen.dart';

// ===========================================================================
// Konstanta periode paket (nilainya harus sama dengan yang diterima backend)
// ===========================================================================
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

// ===========================================================================
// Field pilihan (bottom sheet) bergaya SC
// ===========================================================================
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
      backgroundColor: SC.surface,
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
                    color: SC.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(label, style: sty(16, FontWeight.w800, SC.ink)),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options) _row(sheetCtx, o, selected: o.key == value),
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? SC.sage : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? SC.primary : SC.border,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(14.5, selected ? FontWeight.w800 : FontWeight.w600, SC.ink),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 20, color: SC.primary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(label, style: sty(12.5, FontWeight.w700, SC.ink)),
        ),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: SC.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SC.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current ?? 'Pilih...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: current == null
                        ? sty(14, FontWeight.w500, SC.inkMuted)
                        : sty(14, FontWeight.w600, SC.ink),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: SC.inkSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Dialog Tambah / Edit Paket
// ===========================================================================
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

  InputDecoration _dec({String? hint, String? prefixText, String? errorText}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
      prefixText: prefixText,
      prefixStyle: sty(14, FontWeight.w700, SC.ink),
      errorText: errorText,
      errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
      filled: true,
      fillColor: SC.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: b(SC.border),
      enabledBorder: b(SC.border),
      focusedBorder: b(SC.primary, 1.6),
      errorBorder: b(SC.errorText.withValues(alpha: 0.6)),
      focusedErrorBorder: b(SC.errorText, 1.6),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(label, style: sty(12.5, FontWeight.w700, SC.ink)),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SC.sage,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.add_box_rounded,
                      size: 20,
                      color: SC.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEdit ? 'Edit paket' : 'Tambah paket',
                            style: sty(16, FontWeight.w800, SC.ink)),
                        Text(
                          _isEdit
                              ? 'Perbarui detail paket ini'
                              : 'Buat paket langganan baru untuk platform',
                          style: sty(11.5, FontWeight.w500, SC.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _labeled(
                'Nama paket',
                TextField(
                  controller: _nama,
                  style: sty(14, FontWeight.w600, SC.ink),
                  onChanged: (_) {
                    if (_namaError != null) setState(() => _namaError = null);
                  },
                  decoration: _dec(hint: 'Contoh: Pro', errorText: _namaError),
                ),
              ),
              const SizedBox(height: 14),
              _BcSelect<String>(
                label: 'Periode tagihan',
                value: _periode,
                options: _paketPeriodeLabel.entries.map((e) => MapEntry(e.key, e.value)).toList(),
                onChanged: (v) => setState(() => _periode = v),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _labeled(
                      'Harga ${_paketPeriodeSuffix[_periode]}',
                      TextField(
                        controller: _harga,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_ThousandsInputFormatter()],
                        style: sty(14, FontWeight.w600, SC.ink),
                        decoration: _dec(prefixText: 'Rp '),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _labeled(
                      'Limit santri',
                      TextField(
                        controller: _limit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: sty(14, FontWeight.w600, SC.ink),
                        decoration: _dec(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _labeled(
                'Daftar fitur',
                TextField(
                  controller: _fitur,
                  maxLines: 5,
                  minLines: 3,
                  style: sty(14, FontWeight.w600, SC.ink),
                  decoration: _dec(hint: 'Satu fitur per baris'),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                decoration: BoxDecoration(
                  color: SC.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SC.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paket aktif', style: sty(13.5, FontWeight.w800, SC.ink)),
                          Text('Paket nonaktif tidak bisa dipilih pondok',
                              style: sty(11, FontWeight.w500, SC.inkSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _aktif,
                      activeThumbColor: SC.primary,
                      activeTrackColor: SC.primary.withValues(alpha: 0.35),
                      onChanged: (v) => setState(() => _aktif = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SC.inkSecondary,
                        side: BorderSide(color: SC.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: SC.primary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(color: SC.gold.withValues(alpha: 0.6)),
                        ),
                      ),
                      child: Text('Simpan', style: sty(13, FontWeight.w700, Colors.white)),
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

/// Ringkasan angka yang dihitung dari data API (hanya tampilan, bukan logika baru).
class _Stats {
  const _Stats({
    required this.mrr,
    required this.berbayar,
    required this.trial,
    required this.totalTenant,
    required this.progress,
    required this.langgananAktif,
    required this.overdue,
    required this.overdueTenants,
    required this.totalTertunda,
    required this.totalFaktur,
    required this.lunas,
    required this.menunggu,
  });

  final num mrr;
  final int berbayar;
  final int trial;
  final int totalTenant;
  final double progress;
  final int langgananAktif;
  final List<Map<String, dynamic>> overdue;
  final int overdueTenants;
  final num totalTertunda;
  final int totalFaktur;
  final int lunas;
  final int menunggu;
}

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

  /// Paket/Langganan/Tagihan TIDAK dibuka lewat Navigator.push (yang akan
  /// menutupi top bar & bottom nav shell), melainkan menggantikan body ini.
  _BillingView _view = _BillingView.overview;

  final GlobalKey _overdueKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // AppScope.of(context) tidak boleh dipanggil sinkron di initState.
    Future.microtask(_load);
  }

  /// [showSpinner] false = refresh senyap supaya posisi scroll tidak reset.
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
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data billing: $e';
          _loading = false;
        });
      }
    }
  }

  void _notAvailable() => _showToast('Fitur ini akan segera tersedia.');

  void _backToOverview() {
    setState(() => _view = _BillingView.overview);
    _load(showSpinner: false);
  }

  // ===========================================================================
  // Helper data
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

  String _rupiah(num v) => 'Rp ${_ribuan(v.round().toString())}';

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
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
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

  _Stats _computeStats() {
    final aktifSubs = _subs.where((s) => (s as Map)['status'] == 'AKTIF').toList();

    // Harga tiap paket dinormalisasi ke per bulan sesuai `periode`-nya.
    num mrr = 0;
    for (final s in aktifSubs) {
      final pm = ((s as Map)['paket'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final hargaPaket = _num(pm, ['harga']);
      final periode = (pm['periode'] as String?) ?? 'TAHUNAN';
      switch (periode) {
        case 'HARIAN':
          mrr += hargaPaket * 30;
          break;
        case 'BULANAN':
          mrr += hargaPaket;
          break;
        default:
          mrr += hargaPaket / 12;
      }
    }

    final tenantIdsBerbayar = aktifSubs
        .map((s) => (((s as Map)['tenant'] as Map?)?['id']) ?? s['tenantId'])
        .where((id) => id != null)
        .toSet();
    final tenantEligible =
        _tenants.where((t) => t['status'] == 'PENDING' || t['status'] == 'AKTIF').toList();
    final eligibleIds = tenantEligible.map((t) => t['id']).toSet();
    final totalTenant = tenantEligible.length;
    final berbayar = tenantIdsBerbayar.where(eligibleIds.contains).length;
    final trial = totalTenant - berbayar < 0 ? 0 : totalTenant - berbayar;
    final progress = totalTenant > 0 ? berbayar / totalTenant : 0.0;

    final overdue = _invoices
        .where((i) => (i as Map)['status'] != 'LUNAS')
        .map((i) => (i as Map).cast<String, dynamic>())
        .toList();
    final overdueTenantIds = overdue
        .map((i) => ((i['tenant'] as Map?)?['id']) ?? i['tenantId'])
        .where((id) => id != null)
        .toSet();
    num totalTertunda = 0;
    for (final i in overdue) {
      totalTertunda += _num(i, ['jumlah']);
    }

    final totalFaktur = _invoices.length;
    final lunas = _invoices.where((i) => (i as Map)['status'] == 'LUNAS').length;

    return _Stats(
      mrr: mrr,
      berbayar: berbayar,
      trial: trial,
      totalTenant: totalTenant,
      progress: progress,
      langgananAktif: aktifSubs.length,
      overdue: overdue,
      overdueTenants: overdueTenantIds.length,
      totalTertunda: totalTertunda,
      totalFaktur: totalFaktur,
      lunas: lunas,
      menunggu: totalFaktur - lunas,
    );
  }

  // ===========================================================================
  // Notifikasi (snackbar mengambang, supaya tetap terlihat saat halaman digulir)
  // ===========================================================================
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 480 ? (w - 480) / 2 + 16 : 16.0;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? SC.errorBg : SC.primary,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError
                ? SC.errorText.withValues(alpha: 0.25)
                : SC.gold.withValues(alpha: 0.5),
          ),
        ),
        duration: Duration(seconds: isError ? 4 : 3),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isError ? Colors.white : SC.gold.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_rounded,
                size: 18,
                color: isError ? SC.errorText : SC.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: sty(13, FontWeight.w700, isError ? SC.errorText : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Aksi (logika tidak diubah)
  // ===========================================================================
  Future<void> _paketDialog({Map<String, dynamic>? existing}) async {
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _PaketFormDialog(existing: existing),
    );
    if (body == null || !mounted) return;
    try {
      final api = AppScope.of(context).api;
      if (existing == null) {
        await api.post(ApiUrl.paket, body);
        _showToast('Paket berhasil ditambahkan');
      } else {
        await api.patch('${ApiUrl.paket}/${existing['id']}', body);
        _showToast('Paket berhasil diperbarui');
      }
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

  /// Optimistic UI: balik lokal dulu, panggil API, kembalikan kalau ditolak.
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
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
          child: Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
        ),
        title: Text('Hapus paket?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          'Paket "${p['nama']}" akan dihapus dan tidak bisa dikembalikan.',
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: SC.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SC.errorText,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, hapus', style: sty(13, FontWeight.w700, Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.paket}/${p['id']}');
      _showToast('Paket berhasil dihapus');
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

  Future<void> _assign() async {
    String? tenantId;
    String? paketId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: SC.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SC.sage,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.assignment_ind_rounded, size: 20, color: SC.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assign paket', style: sty(16, FontWeight.w800, SC.ink)),
                    Text('Pasang paket langganan ke pondok',
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BcSelect<String>(
                  value: tenantId,
                  label: 'Pilih pondok',
                  options: [
                    for (final t in _tenants)
                      if (t['status'] == 'PENDING' || t['status'] == 'AKTIF')
                        MapEntry(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                  ],
                  onChanged: (v) => setSt(() => tenantId = v),
                ),
                const SizedBox(height: 14),
                _BcSelect<String>(
                  value: paketId,
                  label: 'Pilih paket',
                  options: [
                    for (final p in _pakets) MapEntry(p['id'] as String, p['nama'] as String),
                  ],
                  onChanged: (v) => setSt(() => paketId = v),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: SC.inkSecondary,
                side: BorderSide(color: SC.border),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
            ),
            FilledButton(
              onPressed: tenantId == null || paketId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: SC.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: SC.gold.withValues(alpha: 0.6)),
                ),
              ),
              child: Text('Assign', style: sty(13, FontWeight.w700, Colors.white)),
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
      _showToast('Langganan berhasil dibuat');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

  Future<void> _tandaiLunas(Map<String, dynamic> inv) async {
    try {
      await AppScope.of(context)
          .api
          .patch('${ApiUrl.invoices}/${inv['id']}', {'status': 'LUNAS'});
      if (!mounted) return;
      _showToast('Invoice ditandai lunas');
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

  // ===========================================================================
  // Build
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Sub-halaman dirender in-place supaya top bar & bottom nav shell tetap ada.
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

    final stats = _computeStats();
    final loaded = !_loading && _error == null;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: () => _load(showSpinner: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(stats, loaded),
                  ..._body(stats),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(_Stats s) {
    if (_loading) {
      return [SizedBox(height: 320, child: loadingView())];
    }
    if (_error != null) {
      return [SizedBox(height: 320, child: errorView(_error!, () => _load()))];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _quickActions(s),
            const SizedBox(height: 14),
            _summaryCard(s),
            const SizedBox(height: 22),
            Container(key: _overdueKey, child: _overdueSection(s)),
            const SizedBox(height: 22),
            _catalogSection(),
          ],
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero(_Stats s, bool loaded) {
    String ringkasan;
    if (_error != null) {
      ringkasan = 'Data tidak dapat dimuat';
    } else if (!loaded) {
      ringkasan = 'Memuat data...';
    } else {
      ringkasan = 'Siklus ${_bulanTahunSekarang()} • diperbarui ${_elapsed(_lastLoaded)}';
    }
    String v(String x) => loaded ? x : '–';
    final adaTertunda = loaded && s.overdue.isNotEmpty;

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SC.gold.withValues(alpha: 0.55)),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billing Platform',
                        style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      ringkasan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withValues(alpha: 0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _glass(Icons.payments_outlined, v(_rupiahCompact(s.mrr)), 'MRR'),
              const SizedBox(width: 8),
              _glass(Icons.verified_outlined, v('${s.berbayar}/${s.totalTenant}'), 'Berbayar'),
              const SizedBox(width: 8),
              _glass(
                adaTertunda ? Icons.pending_actions : Icons.check_circle_outline,
                v('${s.overdueTenants}'),
                'Menunggak',
                onTap: adaTertunda ? _scrollToOverdue : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glass(IconData icon, String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: SC.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: sty(17, FontWeight.w800, Colors.white, h: 1.1)),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(10.5, FontWeight.w600, Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Akses cepat
  // ---------------------------------------------------------------------
  Widget _quickActions(_Stats s) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _quickTile(
          icon: Icons.category_rounded,
          label: 'Paket',
          caption: '${_pakets.length} paket',
          bg: SC.sage,
          fg: SC.primary,
          onTap: () => setState(() => _view = _BillingView.paket),
        ),
        const SizedBox(width: 8),
        _quickTile(
          icon: Icons.workspace_premium_rounded,
          label: 'Langganan',
          caption: '${s.langgananAktif} aktif',
          bg: SC.goldSurface,
          fg: SC.goldDark,
          onTap: () => setState(() => _view = _BillingView.langganan),
        ),
        const SizedBox(width: 8),
        _quickTile(
          icon: Icons.receipt_long_rounded,
          label: 'Tagihan',
          caption: '${s.totalFaktur} faktur',
          bg: SC.pendingBg,
          fg: SC.pendingText,
          onTap: () => setState(() => _view = _BillingView.invoice),
        ),
      ],
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String label,
    required String caption,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 21, color: fg),
                  ),
                  const SizedBox(height: 10),
                  Text(label, style: sty(13.5, FontWeight.w800, SC.ink)),
                  const SizedBox(height: 1),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(11, FontWeight.w600, SC.inkSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Ringkasan lisensi & faktur
  // ---------------------------------------------------------------------
  Widget _summaryCard(_Stats s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SC.sage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_rounded, size: 19, color: SC.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lisensi tenant', style: sty(15, FontWeight.w800, SC.ink)),
                    Text('${s.berbayar} berbayar, ${s.trial} masih trial',
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
              Text('${s.berbayar}/${s.totalTenant}',
                  style: sty(15, FontWeight.w800, SC.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: s.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: SC.surfaceDim,
              valueColor: AlwaysStoppedAnimation(SC.primary),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: SC.border),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('${s.totalFaktur}', 'Faktur', SC.ink),
              _miniDivider(),
              _miniStat('${s.lunas}', 'Lunas', SC.primary),
              _miniDivider(),
              _miniStat('${s.menunggu}', 'Menunggu', s.menunggu > 0 ? SC.errorText : SC.ink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: sty(18, FontWeight.w800, color, h: 1.1)),
          const SizedBox(height: 2),
          Text(label, style: sty(11, FontWeight.w600, SC.inkSecondary)),
        ],
      ),
    );
  }

  Widget _miniDivider() => Container(width: 1, height: 30, color: SC.border);

  // ---------------------------------------------------------------------
  // Judul seksi (gaya sama dengan daftar santri)
  // ---------------------------------------------------------------------
  Widget _sectionHeader(IconData icon, String title, {int? count, bool danger = false}) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: danger ? SC.errorBg : SC.sage,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: danger ? SC.errorText : SC.primary),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sty(14, FontWeight.w800, SC.ink)),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: danger ? SC.errorBg : SC.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: danger
                    ? SC.errorText.withValues(alpha: 0.3)
                    : SC.gold.withValues(alpha: 0.4),
              ),
            ),
            child: Text('$count',
                style: sty(11, FontWeight.w800, danger ? SC.errorText : SC.goldDark)),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(child: Divider(height: 1, thickness: 1, color: SC.border)),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
            child: Icon(Icons.inbox_outlined, size: 18, color: SC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: sty(12.5, FontWeight.w600, SC.inkSecondary, h: 1.4)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tagihan menunggak
  // ---------------------------------------------------------------------
  Widget _overdueSection(_Stats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.warning_amber_rounded,
          'Tagihan menunggak',
          count: s.overdue.isEmpty ? null : s.overdue.length,
          danger: s.overdue.isNotEmpty,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            s.overdue.isEmpty
                ? 'Semua tagihan pondok sudah lunas.'
                : 'Total tertunda ${_rupiah(s.totalTertunda)} dari ${s.overdueTenants} pondok. Masa tenggang sudah habis atau hampir habis.',
            style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        if (s.overdue.isEmpty)
          _emptyCard('Tidak ada tagihan yang menunggak saat ini.')
        else
          for (final inv in s.overdue) _overdueCard(inv),
      ],
    );
  }

  Widget _overdueCard(Map<String, dynamic> inv) {
    final t = (inv['tenant'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final tenantId = t['id'] as String?;
    final paket = _paketFor(tenantId);
    final namaPondok = (t['namaPondok'] as String?) ?? 'Tenant';
    final kodeTenant = (t['kodeTenant'] as String?) ?? '-';
    final namaPaket = (paket?['nama'] as String?) ?? 'Tanpa paket';
    final jumlah = _num(inv, ['jumlah']);
    final noInvoice = (inv['noInvoice'] as String?) ?? '-';

    final jatuhTempo = _pick(inv, ['jatuhTempo', 'dueDate', 'tanggalJatuhTempo']);
    String badgeText = 'Belum lunas';
    if (jatuhTempo is String) {
      final due = DateTime.tryParse(jatuhTempo);
      if (due != null) {
        final days = DateTime.now().difference(due).inDays;
        if (days > 0) badgeText = 'Menunggak $days hari';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: SC.errorText),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SC.errorBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.block_rounded, size: 22, color: SC.errorText),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(namaPondok,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: sty(14.5, FontWeight.w800, SC.ink)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text('@$kodeTenant',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration:
                                        BoxDecoration(color: SC.inkMuted, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(namaPaket,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: sty(11.5, FontWeight.w800, SC.goldDark)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              SPill(badgeText,
                                  icon: Icons.schedule_rounded,
                                  bg: SC.errorBg,
                                  fg: SC.errorText,
                                  size: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: SC.surfaceDim,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Faktur #$noInvoice',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: sty(11, FontWeight.w600, SC.inkSecondary)),
                                const SizedBox(height: 1),
                                Text(_rupiah(jumlah),
                                    style: sty(17, FontWeight.w800, SC.errorText)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _tandaiLunas(inv),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: SC.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: SC.primary.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 15, color: SC.primary),
                                  const SizedBox(width: 5),
                                  Text('Tandai lunas',
                                      style: sty(11.5, FontWeight.w800, SC.primary)),
                                ],
                              ),
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
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: _notAvailable,
                              style: FilledButton.styleFrom(
                                backgroundColor: SC.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  side: BorderSide(color: SC.gold.withValues(alpha: 0.6)),
                                ),
                              ),
                              icon: Icon(Icons.send_rounded, size: 16, color: SC.gold),
                              label: Text(
                                'Kirim tagihan WA/Email',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sty(12.5, FontWeight.w700, Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _notAvailable,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SC.primary,
                              side: BorderSide(color: SC.border),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            icon: Icon(Icons.description_outlined, size: 16, color: SC.primary),
                            label: Text('Faktur', style: sty(12.5, FontWeight.w700, SC.primary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Katalog paket
  // ---------------------------------------------------------------------
  Widget _catalogSection() {
    final pakets = List<Map<String, dynamic>>.from(
        _pakets.map((e) => (e as Map).cast<String, dynamic>()));
    pakets.sort((a, b) => _num(a, ['harga']).compareTo(_num(b, ['harga'])));

    final paid = pakets.where((p) => _num(p, ['harga']) > 0).toList();
    final enterpriseId = paid.isNotEmpty ? paid.last['id'] : null;
    final popularId = paid.length >= 3 ? paid[paid.length - 2]['id'] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.inventory_2_rounded, 'Katalog paket', count: pakets.length),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text('Tier dan fitur yang tersedia untuk pondok',
              style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _assign,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SC.primary,
                    side: BorderSide(color: SC.border),
                    backgroundColor: SC.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: Icon(Icons.assignment_ind_outlined, size: 18, color: SC.primary),
                  label: Text('Assign ke pondok', style: sty(12.5, FontWeight.w700, SC.primary)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () => _paketDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: SC.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: SC.gold.withValues(alpha: 0.6)),
                    ),
                  ),
                  icon: Icon(Icons.add_rounded, size: 18, color: SC.gold),
                  label: Text('Tambah paket', style: sty(12.5, FontWeight.w700, Colors.white)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (pakets.isEmpty)
          _emptyCard('Belum ada paket. Tekan "Tambah paket" untuk membuat.')
        else
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
    );
  }
}

// ===========================================================================
// Kartu tier paket
// ===========================================================================
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

  @override
  Widget build(BuildContext context) {
    final nama = paket['nama'] as String? ?? 'Paket';
    final harga = (paket['harga'] as num?) ?? 0;
    final limit = paket['limitSantri'];
    final periode = (paket['periode'] as String?) ?? 'TAHUNAN';
    final fitur = ((paket['fitur'] as List?)?.cast<String>()) ?? const <String>[];
    final aktif = (paket['aktif'] as bool?) ?? true;

    final accent = isEnterprise ? SC.goldDark : SC.primary;
    final checkColor = isEnterprise ? SC.gold : SC.primary;
    final badgeBg = isFree
        ? SC.surfaceDim
        : isEnterprise
            ? SC.gold.withValues(alpha: 0.22)
            : SC.sage;
    final badgeFg = isFree ? SC.inkSecondary : accent;

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEnterprise ? SC.goldSurface : SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnterprise ? SC.gold.withValues(alpha: 0.55) : SC.border,
        ),
        boxShadow: softShadow,
      ),
      child: Stack(
        children: [
          if (isEnterprise)
            Positioned(
              right: -18,
              bottom: -18,
              child: Opacity(
                opacity: 0.10,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Icon(Icons.hotel_class, size: 120, color: SC.gold),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isEnterprise) ...[
                                      Icon(Icons.hotel_class, size: 13, color: badgeFg),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(nama, style: sty(12, FontWeight.w800, badgeFg)),
                                  ],
                                ),
                              ),
                              if (isPopular)
                                SPill('Populer',
                                    icon: Icons.verified_rounded,
                                    bg: SC.primary,
                                    fg: Colors.white,
                                    size: 10),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(harga == 0 ? 'Rp 0' : rupiah(harga),
                                  style: sty(24, FontWeight.w800, accent)),
                              const SizedBox(width: 4),
                              Text(harga == 0 ? '' : (_paketPeriodeSuffix[periode] ?? '/ tahun'),
                                  style: sty(12, FontWeight.w600, SC.inkSecondary)),
                            ],
                          ),
                          if (limit != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.groups_rounded, size: 14, color: SC.goldDark),
                                const SizedBox(width: 4),
                                Text('Maks $limit santri',
                                    style: sty(11.5, FontWeight.w700, SC.goldDark)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Dipakai', style: sty(10.5, FontWeight.w600, SC.inkSecondary)),
                        Text('$subscriberCount pondok', style: sty(13, FontWeight.w800, accent)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, thickness: 1, color: SC.border),
                const SizedBox(height: 14),
                if (fitur.isEmpty)
                  Text('Belum ada daftar fitur untuk paket ini.',
                      style: sty(12, FontWeight.w500, SC.inkSecondary))
                else
                  for (final f in fitur)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 17, color: checkColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f, style: sty(13, FontWeight.w600, SC.ink, h: 1.35)),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SC.primary,
                        backgroundColor: SC.surface,
                        side: BorderSide(color: SC.border),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: Icon(Icons.edit_outlined, size: 16, color: SC.primary),
                      label: Text('Edit', style: sty(12.5, FontWeight.w700, SC.primary)),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Hapus paket',
                      style: IconButton.styleFrom(
                        backgroundColor: SC.errorBg,
                        minimumSize: const Size(40, 40),
                      ),
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: SC.errorText),
                    ),
                    const Spacer(),
                    Text(aktif ? 'Aktif' : 'Nonaktif',
                        style: sty(12, FontWeight.w700,
                            aktif ? accent : SC.inkSecondary)),
                    Switch(
                      value: aktif,
                      onChanged: onToggleAktif,
                      activeThumbColor: isEnterprise ? SC.gold : SC.primary,
                      activeTrackColor:
                          (isEnterprise ? SC.gold : SC.primary).withValues(alpha: 0.35),
                    ),
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

/// Pemisah ribuan langsung saat mengetik harga ("1500000" -> "1.500.000").
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _ribuan(digitsOnly);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}