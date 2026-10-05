import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama persis dengan `_AC` di absensi_screen.dart dan `_WC` di dashboard_screen.dart.
class _KC {
  _KC._();

  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

enum _KFilter { semua, aktif, sembuh }

/// Nilai status yang dikirim ke backend. Sesuaikan dengan enum di Prisma.
const _kStatusAktif = 'RAWAT_JALAN';
const _kStatusSembuh = 'SEMBUH';

class KesehatanScreen extends StatefulWidget {
  const KesehatanScreen({super.key});

  @override
  State<KesehatanScreen> createState() => _KesehatanScreenState();
}

class _KesehatanScreenState extends State<KesehatanScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
  bool _loading = true;
  String? _error;
  _KFilter _filter = _KFilter.semua;
  String? _updatingId; // id catatan yang statusnya sedang diubah

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  bool _isSembuh(dynamic status) => (status ?? '').toString().toUpperCase().contains('SEMBUH');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.kesehatan);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat catatan kesehatan.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSantri() async {
    if (_santris.isNotEmpty) return;
    try {
      final api = AppScope.of(context).api;
      final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      if (mounted) {
        setState(() => _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _add() async {
    await _loadSantri();
    if (!mounted) return;

    final res = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CatatSheet(santris: _santris),
    );
    if (res == null || !mounted) return;

    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.kesehatan, {
        'santriId': res['santriId'],
        'keluhan': res['keluhan'],
        'tindakan': res['tindakan'],
        'tanggal': _iso(now),
      });
      if (!mounted) return;
      _toast('Catatan kesehatan tersimpan', subtitle: 'Wali santri mendapat notifikasi');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menyimpan catatan.', error: true);
    }
  }

  /// Ubah status satu catatan. Kalau sukses, status di list diganti langsung
  /// (tanpa _load) supaya layar tidak berkedip.
  Future<void> _ubahStatus(String id, bool sembuh) async {
    if (_updatingId != null) return;
    setState(() => _updatingId = id);
    final baru = sembuh ? _kStatusSembuh : _kStatusAktif;
    try {
      final api = AppScope.of(context).api;
      await api.patch('${ApiUrl.kesehatan}/$id', {'status': baru});
      if (!mounted) return;
      setState(() {
        for (final e in _items) {
          if (e is Map && e['id']?.toString() == id) e['status'] = baru;
        }
      });
      _toast(
        sembuh ? 'Santri ditandai sembuh' : 'Status dikembalikan',
        subtitle: 'Status kesehatan diperbarui',
      );
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal memperbarui status.', error: true);
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  // ---------------------------------------------------------------------
  // Util
  // ---------------------------------------------------------------------
  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtIso(String raw) {
    if (raw.length < 10) return raw;
    final p = raw.substring(0, 10).split('-');
    if (p.length != 3) return raw.substring(0, 10);
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final m = int.tryParse(p[1]) ?? 0;
    final d = int.tryParse(p[2]) ?? 0;
    if (m < 1 || m > 12) return raw.substring(0, 10);
    return '$d ${months[m]} ${p[0]}';
  }

  /// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _KC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _KC.errorBg : _KC.primary,
          elevation: 6,
          margin: EdgeInsets.fromLTRB(side, 0, side, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _KC.errorText.withOpacity(0.25) : _KC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _KC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _KC.errorText : _KC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _KC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _KC.border),
      ),
      child: child,
    );
  }

  Widget _header() {
    final n = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kesehatan Santri',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _KC.ink)),
        const SizedBox(height: 2),
        Text('Catatan sakit & tindakan • ${_fmtIso(_iso(n))}',
            style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
      ],
    );
  }

  Widget _counter(IconData icon, String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _items.length;
    final sembuh = _items.where((e) => _isSembuh((e as Map)['status'])).length;
    final aktif = total - sembuh;
    final pct = total > 0 ? sembuh / total : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_KC.primary, _KC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _KC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _KC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RINGKASAN KESEHATAN',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text('$total Catatan Kesehatan',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _counter(Icons.assignment_outlined, 'Total', total),
                    const SizedBox(width: 8),
                    _counter(Icons.healing_outlined, 'Belum Sembuh', aktif),
                    const SizedBox(width: 8),
                    _counter(Icons.favorite_border_rounded, 'Sembuh', sembuh),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tingkat Pemulihan',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8))),
                    Text('${(pct * 100).toStringAsFixed(1)}% Sembuh',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_KC.mint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_KFilter f, String label, int count) {
    final selected = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _KC.primary : _KC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _KC.primary : _KC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _KC.inkSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : _KC.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _KC.inkSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    final sembuh = _items.where((e) => _isSembuh((e as Map)['status'])).length;
    final aktif = _items.length - sembuh;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(_KFilter.semua, 'Semua', _items.length),
          const SizedBox(width: 8),
          _filterChip(_KFilter.aktif, 'Belum Sembuh', aktif),
          const SizedBox(width: 8),
          _filterChip(_KFilter.sembuh, 'Sembuh', sembuh),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: _KC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined, color: _KC.gold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _KC.inkSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _itemCard(int index, Map<String, dynamic> k) {
    final santri = (k['santri'] as Map?) ?? {};
    final nama = (santri['nama'] ?? '-').toString().trim();
    final nis = santri['nis']?.toString() ?? '';
    final keluhan = (k['keluhan'] ?? '-').toString();
    final tindakan = (k['tindakan'] ?? '').toString().trim();
    final status = (k['status'] ?? '-').toString();
    final sembuh = _isSembuh(status);
    final tanggal = _fmtIso((k['tanggal'] ?? '').toString());
    final inisial = nama.isNotEmpty && nama != '-' ? nama.substring(0, 1).toUpperCase() : '?';
    final even = index.isEven;

    final pillBg = sembuh ? const Color(0xFFD2E4DC) : const Color(0xFFF3E2B8);
    final pillFg = sembuh ? const Color(0xFF0F3A2E) : _KC.goldDark;
    final dot = sembuh ? const Color(0xFF0F3A2E) : const Color(0xFFB78103);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: even ? _KC.sage : _KC.goldSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(inisial,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: even ? _KC.primary : _KC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _KC.ink)),
                    const SizedBox(height: 2),
                    Text(nis.isEmpty ? tanggal : 'NIS $nis • $tanggal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pillFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sick_outlined, size: 15, color: _KC.inkSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Keluhan: $keluhan',
                      style: const TextStyle(fontSize: 12, height: 1.35, color: _KC.ink)),
                ),
              ],
            ),
          ),
          if (tindakan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: _KC.goldSurface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 15, color: _KC.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Tindakan: $tindakan',
                        style: const TextStyle(fontSize: 12, height: 1.35, color: _KC.goldDark)),
                  ),
                ],
              ),
            ),
          ],
          if (k['id'] != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _updatingId == null ? () => _ubahStatus(k['id'].toString(), !sembuh) : null,
                icon: _updatingId == k['id'].toString()
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _KC.primary),
                      )
                    : Icon(sembuh ? Icons.undo_rounded : Icons.check_circle_outline, size: 18),
                label: Text(
                  sembuh ? 'Tandai Belum Sembuh' : 'Tandai Sembuh',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: sembuh ? _KC.inkSecondary : _KC.primary,
                  side: BorderSide(color: sembuh ? _KC.border : _KC.primary.withOpacity(0.4)),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((e) {
      final sembuh = _isSembuh((e as Map)['status']);
      switch (_filter) {
        case _KFilter.aktif:
          return !sembuh;
        case _KFilter.sembuh:
          return sembuh;
        case _KFilter.semua:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: _KC.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        tooltip: 'Catat Sakit',
        backgroundColor: _KC.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Sakit', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: RefreshIndicator(
                      color: _KC.primary,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        children: [
                          _header(),
                          const SizedBox(height: 14),
                          if (_items.isEmpty)
                            _emptyCard('Belum ada catatan kesehatan.\nKetuk "Catat Sakit" untuk menambah.')
                          else ...[
                            _summaryCard(),
                            const SizedBox(height: 14),
                            _filterRow(),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Riwayat Kesehatan Santri',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
                                Text('${filtered.length} catatan',
                                    style: const TextStyle(fontSize: 11, color: _KC.inkSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (filtered.isEmpty)
                              _emptyCard('Tidak ada catatan pada filter ini.')
                            else
                              for (int i = 0; i < filtered.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _itemCard(i, filtered[i] as Map<String, dynamic>),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: catat kesehatan santri
// ---------------------------------------------------------------------
class _CatatSheet extends StatefulWidget {
  final List<Map<String, dynamic>> santris;
  const _CatatSheet({required this.santris});

  @override
  State<_CatatSheet> createState() => _CatatSheetState();
}

class _CatatSheetState extends State<_CatatSheet> {
  final _keluhan = TextEditingController();
  final _tindakan = TextEditingController();
  String? _santriId;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.santris.isNotEmpty) _santriId = widget.santris.first['id'] as String;
  }

  @override
  void dispose() {
    _keluhan.dispose();
    _tindakan.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selected {
    for (final s in widget.santris) {
      if (s['id'] == _santriId) return s;
    }
    return null;
  }

  Future<void> _pickSantri() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SantriPicker(santris: widget.santris, selectedId: _santriId),
    );
    if (id != null && mounted) setState(() => _santriId = id);
  }

  void _submit() {
    if (_santriId == null) {
      setState(() => _err = 'Pilih santri terlebih dahulu.');
      return;
    }
    final k = _keluhan.text.trim();
    if (k.isEmpty) {
      setState(() => _err = 'Keluhan wajib diisi.');
      return;
    }
    final t = _tindakan.text.trim();
    Navigator.pop<Map<String, String?>>(context, {
      'santriId': _santriId,
      'keluhan': k,
      'tindakan': t.isEmpty ? null : t,
    });
  }

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
        labelStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
        filled: true,
        fillColor: _KC.surfaceDim,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final s = _selected;
    final nama = (s?['nama'] ?? 'Belum ada santri').toString();
    final nis = s?['nis']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: _KC.goldSurface, shape: BoxShape.circle),
                    child: const Icon(Icons.medical_services_rounded, size: 18, color: _KC.gold),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Catat Kesehatan Santri',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _KC.ink)),
                        Text('Wali santri akan mendapat notifikasi',
                            style: TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: widget.santris.isEmpty ? null : _pickSantri,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: _KC.sage, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.person_outline_rounded, size: 19, color: _KC.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SANTRI',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                    fontWeight: FontWeight.w700,
                                    color: _KC.inkSecondary)),
                            const SizedBox(height: 2),
                            Text(nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14.5, fontWeight: FontWeight.w800, color: _KC.ink)),
                            if (nis != null)
                              Text('NIS $nis',
                                  style: const TextStyle(fontSize: 11, color: _KC.inkSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.unfold_more_rounded, size: 18, color: _KC.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keluhan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: _KC.ink),
                decoration: _dec('Keluhan', 'Contoh: Demam, batuk, sakit perut'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tindakan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: _KC.ink),
                decoration: _dec('Tindakan (opsional)', 'Contoh: Diberi obat, istirahat di poskestren'),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _KC.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: _KC.errorText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_err!, style: const TextStyle(fontSize: 12.5, color: _KC.errorText)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _KC.inkSecondary,
                      side: const BorderSide(color: _KC.border),
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: widget.santris.isEmpty ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _KC.primary,
                          disabledBackgroundColor: _KC.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                        label: const Text('Simpan Catatan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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

// ---------------------------------------------------------------------
// Bottom sheet: pilih santri (dengan pencarian)
// ---------------------------------------------------------------------
class _SantriPicker extends StatefulWidget {
  final List<Map<String, dynamic>> santris;
  final String? selectedId;
  const _SantriPicker({required this.santris, required this.selectedId});

  @override
  State<_SantriPicker> createState() => _SantriPickerState();
}

class _SantriPickerState extends State<_SantriPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = widget.santris.where((s) {
      if (q.isEmpty) return true;
      return (s['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (s['nis'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('Pilih Santri',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _KC.ink)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: const TextStyle(fontSize: 14, color: _KC.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau NIS',
                    hintStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _KC.inkSecondary),
                    filled: true,
                    fillColor: _KC.surfaceDim,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('Santri tidak ditemukan.',
                            style: TextStyle(fontSize: 13, color: _KC.inkSecondary)),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final s = list[i];
                          final id = s['id'] as String;
                          final nama = (s['nama'] ?? '-').toString();
                          final nis = s['nis']?.toString() ?? '-';
                          final sel = id == widget.selectedId;
                          return ListTile(
                            title: Text(nama,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                                  color: _KC.ink,
                                )),
                            subtitle: Text('NIS $nis',
                                style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                            trailing: sel ? Icon(Icons.check_circle, color: _KC.primary, size: 20) : null,
                            onTap: () => Navigator.pop(context, id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}