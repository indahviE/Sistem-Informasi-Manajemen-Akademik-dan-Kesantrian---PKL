import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

/// Bar pencarian + filter yang menempel di atas saat digulir.
class _PinnedBar extends SliverPersistentHeaderDelegate {
  _PinnedBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: SC.background,
      height: height,
      alignment: Alignment.topCenter,
      child: ClipRect(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

// ---------------------------------------------------------------------------
// Komponen kecil bersama
// ---------------------------------------------------------------------------

InputDecoration _dec(String hint) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    filled: true,
    fillColor: SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary)),
    );

Widget _errText(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(text, style: sty(11.5, FontWeight.w600, SC.errorText)),
    );

Widget _btnBatal(VoidCallback onTap) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: SC.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
    );

Widget _btnUtama(String label, VoidCallback onTap, {Color? warna}) => FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: warna ?? SC.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, Colors.white)),
    );

Widget _dialogIcon(IconData icon, Color bg, Color fg) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 18, color: fg),
    );

RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));

const _dialogTitlePad = EdgeInsets.fromLTRB(20, 20, 20, 0);
const _dialogContentPad = EdgeInsets.fromLTRB(20, 16, 20, 4);
const _dialogActionsPad = EdgeInsets.fromLTRB(16, 8, 16, 16);

Widget _pill(String label, {Color? bg, Color? fg, IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg ?? SC.mint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: fg ?? SC.primary),
          const SizedBox(width: 4),
        ],
        Text(label, style: sty(10.5, FontWeight.w800, fg ?? SC.primary)),
      ],
    ),
  );
}

Widget _infoRow(IconData icon, String text, {Color? color, FontWeight? weight}) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color ?? SC.inkMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sty(11.5, weight ?? FontWeight.w600, color ?? SC.inkSecondary),
          ),
        ),
      ],
    ),
  );
}

Widget _kosong({required IconData icon, required String judul, required String pesan}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(32, 40, 32, 96),
    child: Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: SC.sage,
            shape: BoxShape.circle,
            border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, size: 36, color: SC.primary),
        ),
        const SizedBox(height: 18),
        Text(judul, textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
        const SizedBox(height: 6),
        Text(
          pesan,
          textAlign: TextAlign.center,
          style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5),
        ),
      ],
    ),
  );
}

Widget _searchBar({
  required TextEditingController controller,
  required String hint,
  required String query,
  required ValueChanged<String> onChanged,
  required VoidCallback onClear,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: sty(14, FontWeight.w600, SC.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
          prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: SC.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: SC.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: SC.primary, width: 1.4),
          ),
        ),
      ),
    ),
  );
}

Widget _glassStrip(List<Widget> stats) {
  final children = <Widget>[];
  for (int i = 0; i < stats.length; i++) {
    if (i > 0) {
      children.add(Container(width: 1, height: 30, color: Colors.white.withOpacity(0.18)));
    }
    children.add(stats[i]);
  }
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.16)),
    ),
    child: Row(children: children),
  );
}

Widget _stat(String value, String label, {bool warn = false}) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: sty(21, FontWeight.w800, warn ? SC.gold : Colors.white, h: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72)),
          ),
        ],
      ),
    );

Widget _heroCircleBtn(IconData icon, VoidCallback onTap, {String? tooltip}) {
  return Tooltip(
    message: tooltip ?? '',
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Helper data kelas (dipakai daftar & detail)
// ---------------------------------------------------------------------------

int _santriCountOf(Map<String, dynamic> k) {
  final c = k['_count'];
  if (c is Map) {
    final v = c['santris'];
    if (v is num) return v.toInt();
  }
  final j = k['jumlahSantri'];
  if (j is num) return j.toInt();
  final s = k['santris'];
  if (s is List) return s.length;
  return 0;
}

String? _waliOf(Map<String, dynamic> k) {
  final w = k['waliKelas'];
  if (w is Map) {
    for (final key in const ['nama', 'namaLengkap', 'namaUstadz']) {
      final v = w[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  if (w is String && w.trim().isNotEmpty) return w.trim();
  final n = k['waliKelasNama'];
  if (n is String && n.trim().isNotEmpty) return n.trim();
  return null;
}

int? _kapasitasOf(Map<String, dynamic> k) {
  final v = k['kapasitas'];
  return (v is num && v > 0) ? v.toInt() : null;
}

String? _jenisOf(Map<String, dynamic> k) {
  final v = k['jenis']?.toString().toUpperCase();
  if (v == 'TAHFIDZ') return 'Tahfidz';
  if (v == 'DINIYAH') return 'Diniyah';
  return null;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _badgeKelas(String nama) {
  final n = nama.trim();
  if (n.isEmpty) return '?';
  return n.length > 3 ? n.substring(0, 3).toUpperCase() : n.toUpperCase();
}

// ---------------------------------------------------------------------------
// Layar daftar kelas
// ---------------------------------------------------------------------------

class KelasListScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (ada tombol kembali).
  final bool showBack;
  const KelasListScreen({super.key, this.showBack = false});

  @override
  State<KelasListScreen> createState() => _KelasListScreenState();
}

class _KelasListScreenState extends State<KelasListScreen> {
  /// Pimpinan/Mudir hanya memantau: tombol tambah/ubah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String _tingkatFilter = 'Semua';
  bool _hanyaTanpaWali = false;
  String _q = '';
  final _searchC = TextEditingController();

  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.kelas);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
        _error = null;
        if (_hanyaTanpaWali && _tanpaWaliCount == 0) _hanyaTanpaWali = false;
        if (_tingkatFilter != 'Semua' && !_tingkatList().contains(_tingkatFilter)) {
          _tingkatFilter = 'Semua';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      } else {
        _toast(e.message, error: true);
      }
    } catch (_) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = 'Gagal memuat daftar kelas.';
          _loading = false;
        });
      } else {
        _toast('Gagal memuat ulang daftar kelas.', error: true);
      }
    }
  }

  Future<void> _jalankan(Future<void> Function() aksi, String sukses, {String? sub}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await aksi();
      _toast(sukses, subtitle: sub);
      await _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<Map<String, dynamic>>?> _loadUstadz() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ustadz);
      final list = res is List ? res : ((res is Map ? res['items'] : null) as List? ?? []);
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _loadUstadzDenganProgress() async {
    setState(() => _busy = true);
    final ustadz = await _loadUstadz();
    if (mounted) setState(() => _busy = false);
    return ustadz;
  }

  int get _totalSantri => _items.fold<int>(0, (s, k) => s + _santriCountOf(k));
  int get _tanpaWaliCount => _items.where((k) => _waliOf(k) == null).length;

  /// Backend sudah kirim info wali kelas atau belum.
  bool get _adaDataWali => _items.any(
        (k) => k.containsKey('waliKelas') || k.containsKey('waliKelasNama'),
      );

  List<String> _tingkatList() {
    final set = <String>{};
    for (final k in _items) {
      final t = k['tingkat']?.toString().trim() ?? '';
      if (t.isNotEmpty) set.add(t);
    }
    return set.toList()..sort((a, b) => a.compareTo(b));
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    final out = _items.where((k) {
      if (_tingkatFilter != 'Semua' &&
          (k['tingkat']?.toString().trim() ?? '') != _tingkatFilter) {
        return false;
      }
      if (_hanyaTanpaWali && _waliOf(k) != null) return false;
      if (q.isEmpty) return true;
      final nama = (k['namaKelas']?.toString() ?? '').toLowerCase();
      final wali = (_waliOf(k) ?? '').toLowerCase();
      return nama.contains(q) || wali.contains(q);
    }).toList();
    out.sort((a, b) => (a['namaKelas'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['namaKelas'] ?? '').toString().toLowerCase()));
    return out;
  }

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _add() async {
    if (_busy) return;
    final ustadz = await _loadUstadzDenganProgress();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(ustadzList: ustadz),
    );
    if (result == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.post(ApiUrl.kelas, result);
    }, 'Kelas ditambahkan', sub: result['namaKelas']?.toString());
  }

  Future<void> _edit(Map<String, dynamic> kelas) async {
    if (_busy) return;
    final ustadz = await _loadUstadzDenganProgress();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(existing: kelas, ustadzList: ustadz),
    );
    if (result == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.patch('${ApiUrl.kelas}/${kelas['id']}', result);
    }, 'Kelas diperbarui', sub: result['namaKelas']?.toString());
  }

  Future<void> _delete(Map<String, dynamic> kelas) async {
    if (_busy) return;
    final jumlah = _santriCountOf(kelas);
    final catatan = <String>[
      'Kelas "${kelas['namaKelas']}" akan dihapus permanen.',
      if (jumlah > 0) 'Kelas ini masih berisi $jumlah santri.',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
          child: Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
        ),
        title: Text('Hapus kelas?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          catatan.join('\n\n'),
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(ctx, false)),
          _btnUtama('Ya, hapus', () => Navigator.pop(ctx, true), warna: SC.errorText),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.delete('${ApiUrl.kelas}/${kelas['id']}');
    }, 'Kelas dihapus', sub: kelas['namaKelas']?.toString());
  }

  /// Buka halaman detail. Detail bisa mengembalikan 'edit' / 'hapus'.
  Future<void> _openDetail(Map<String, dynamic> kelas) async {
    final act = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KelasDetailScreen(kelas: kelas, readOnly: _readOnly),
      ),
    );
    if (!mounted) return;
    if (act == 'edit') {
      await _edit(kelas);
    } else if (act == 'hapus') {
      await _delete(kelas);
    }
  }

  // ---------------------------------------------------------------------
  // Banner inline
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
    _bannerTimer = Timer(Duration(seconds: error ? 5 : 3), _closeBanner);
  }

  void _closeBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerTitle = null);
  }

  Widget _banner() {
    final title = _bannerTitle;
    final error = _bannerError;
    final fg = error ? SC.errorText : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: title == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: error ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: error ? Colors.white : SC.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      error ? Icons.error_outline : Icons.check_rounded,
                      size: 18,
                      color: error ? SC.errorText : SC.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: sty(13.5, FontWeight.w800, fg)),
                        if (_bannerSub != null && _bannerSub!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!,
                              style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75))),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, size: 18, color: fg.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _items.isNotEmpty;
    final showChips = showControls && _tingkatList().length >= 2;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              RefreshIndicator(
                color: SC.primary,
                onRefresh: () => _load(spinner: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedBar(
                        height: showChips ? 118 : 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _searchBar(
                              controller: _searchC,
                              hint: _adaDataWali
                                  ? 'Cari nama kelas atau wali kelas'
                                  : 'Cari nama kelas',
                              query: _q,
                              onChanged: (v) => setState(() => _q = v),
                              onClear: () {
                                _searchC.clear();
                                setState(() => _q = '');
                              },
                            ),
                            if (showChips) _tingkatBar(),
                          ],
                        ),
                      ),
                    ),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (_busy)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: SC.gold,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (!_readOnly)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: _busy ? null : _add,
                    tooltip: 'Tambah kelas',
                    backgroundColor: SC.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: SC.gold.withOpacity(0.6)),
                    ),
                    icon: Icon(Icons.add_rounded, size: 18, color: SC.gold),
                    label: Text('Kelas baru', style: sty(13, FontWeight.w700, Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final loaded = !_loading && _error == null;
    String ringkasan;
    if (_error != null) {
      ringkasan = 'Data tidak dapat dimuat';
    } else if (!loaded) {
      ringkasan = 'Memuat data...';
    } else if (_items.isEmpty) {
      ringkasan = 'Belum ada kelas terdaftar';
    } else {
      ringkasan = '${_items.length} kelas  •  $_totalSantri santri';
    }
    String v(int n) => loaded ? '$n' : '–';

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBack) ...[
                _heroCircleBtn(
                  Icons.arrow_back_ios_new_rounded,
                  () => Navigator.of(context).maybePop(),
                  tooltip: 'Kembali',
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: Icon(Icons.meeting_room_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelas & Halaqah',
                        style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      ringkasan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _glassStrip([
            _stat(v(_items.length), 'Total kelas'),
            _stat(v(_totalSantri), 'Total santri'),
            if (_adaDataWali)
              _stat(v(_tanpaWaliCount), 'Tanpa wali',
                  warn: loaded && _tanpaWaliCount > 0)
            else
              _stat(v(_tingkatList().length), 'Tingkat'),
          ]),
        ],
      ),
    );
  }

  /// Baris chip tingkat (Semua / 7 / 8 / 9 ...).
  Widget _tingkatBar() {
    final labels = ['Semua', ..._tingkatList()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final l = labels[i];
            final active = _tingkatFilter == l;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tingkatFilter = l),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active ? SC.primary : SC.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: active ? SC.primary : SC.border),
                ),
                child: Text(
                  l == 'Semua' ? 'Semua (${_items.length})' : 'Tingkat $l',
                  style: sty(12, FontWeight.w700, active ? Colors.white : SC.inkSecondary),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Pengingat: muncul hanya kalau ada kelas tanpa wali.
  Widget _noticeWali() {
    final n = _tanpaWaliCount;
    if (!_adaDataWali || n == 0 || _readOnly) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Material(
        color: SC.goldSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: SC.gold.withOpacity(0.4)),
        ),
        child: InkWell(
          onTap: () => setState(() => _hanyaTanpaWali = !_hanyaTanpaWali),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, size: 18, color: SC.goldDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _hanyaTanpaWali
                        ? 'Menampilkan $n kelas tanpa wali kelas'
                        : '$n kelas belum punya wali kelas',
                    style: sty(12, FontWeight.w700, SC.goldDark),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_hanyaTanpaWali ? 'Semua' : 'Lihat',
                    style: sty(12, FontWeight.w800, SC.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bodySlivers() {
    if (_loading) {
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: loadingView()))];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(height: 320, child: errorView(_error!, () => _load())),
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.meeting_room_outlined,
            judul: 'Belum ada kelas',
            pesan: _readOnly
                ? 'Belum ada kelas terdaftar.'
                : 'Tambahkan kelas lewat tombol "Kelas baru" di bawah.',
          ),
        ),
      ];
    }

    final list = _filtered;
    return [
      SliverToBoxAdapter(child: _noticeWali()),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada kelas yang cocok dengan pencarian atau filter ini.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _kelasTile(list[i]),
              ),
              childCount: list.length,
            ),
          ),
        ),
    ];
  }

  Widget _kelasTile(Map<String, dynamic> k) {
    final nama = (k['namaKelas'] ?? '-').toString().trim();
    final tingkat = k['tingkat']?.toString().trim() ?? '';
    final jumlah = _santriCountOf(k);
    final wali = _waliOf(k);
    final jenis = _jenisOf(k);
    final kapasitas = _kapasitasOf(k);
    final perluWali = _adaDataWali && wali == null;

    return Container(
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: perluWali ? SC.gold.withOpacity(0.5) : SC.border),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(k),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SC.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.primary.withOpacity(0.18)),
                  ),
                  child: Text(
                    _badgeKelas(nama),
                    style: sty(nama.length > 2 ? 13 : 16, FontWeight.w800, SC.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Kelas $nama',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sty(14.5, FontWeight.w800, SC.ink),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (tingkat.isNotEmpty) _pill('Tingkat $tingkat'),
                          if (jenis != null)
                            _pill(jenis, bg: SC.goldSurface, fg: SC.goldDark),
                        ],
                      ),
                      if (_adaDataWali)
                        _infoRow(
                          wali != null ? Icons.person_outline : Icons.person_off_outlined,
                          wali != null ? 'Wali kelas $wali' : 'Belum ada wali kelas',
                          color: wali != null ? SC.ink : SC.goldDark,
                          weight: wali != null ? FontWeight.w700 : FontWeight.w800,
                        ),
                      _infoRow(
                        Icons.groups_2_outlined,
                        kapasitas != null ? '$jumlah / $kapasitas santri' : '$jumlah santri',
                      ),
                      if (kapasitas != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (jumlah / kapasitas).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: SC.surfaceDim,
                              valueColor: AlwaysStoppedAnimation(
                                jumlah > kapasitas ? SC.errorText : SC.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_readOnly)
                  PopupMenuButton<String>(
                    tooltip: 'Opsi',
                    enabled: !_busy,
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: SC.inkSecondary),
                    color: SC.surface,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (v) {
                      if (v == 'detail') _openDetail(k);
                      if (v == 'edit') _edit(k);
                      if (v == 'hapus') _delete(k);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(children: [
                          Icon(Icons.groups_2_outlined, size: 18, color: SC.ink),
                          const SizedBox(width: 10),
                          Text('Lihat santri', style: sty(13, FontWeight.w600, SC.ink)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18, color: SC.ink),
                          const SizedBox(width: 10),
                          Text('Edit data', style: sty(13, FontWeight.w600, SC.ink)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'hapus',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 18, color: SC.errorText),
                          const SizedBox(width: 10),
                          Text('Hapus', style: sty(13, FontWeight.w600, SC.errorText)),
                        ]),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 8),
                    child: Icon(Icons.chevron_right_rounded, color: SC.inkMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layar detail kelas + daftar santri
// ---------------------------------------------------------------------------

class KelasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final bool readOnly;
  const KelasDetailScreen({super.key, required this.kelas, this.readOnly = false});

  @override
  State<KelasDetailScreen> createState() => _KelasDetailScreenState();
}

class _KelasDetailScreenState extends State<KelasDetailScreen> {
  late Map<String, dynamic> _kelas;
  List<Map<String, dynamic>> _santri = [];
  bool _loading = true;
  String? _error;
  String _q = '';
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kelas = Map<String, dynamic>.from(widget.kelas);
    final pre = _extractSantri(_kelas);
    if (pre != null) {
      _santri = pre;
      _loading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  /// Ambil daftar santri dari beberapa kemungkinan bentuk respons backend.
  List<Map<String, dynamic>>? _extractSantri(Map<String, dynamic> k) {
    for (final key in const ['santris', 'santri', 'siswa', 'murid']) {
      final v = k[key];
      if (v is List) {
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner && _santri.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get('${ApiUrl.kelas}/${_kelas['id']}');
      if (!mounted) return;
      if (res is Map) {
        final m = Map<String, dynamic>.from(res);
        final list = _extractSantri(m);
        setState(() {
          _kelas = {..._kelas, ...m};
          if (list != null) _santri = list;
          _loading = false;
          _error = null;
        });
      } else {
        setState(() => _loading = false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar santri.';
        _loading = false;
      });
    }
  }

  String _namaSantri(Map<String, dynamic> s) {
    for (final key in const ['nama', 'namaLengkap', 'namaSantri']) {
      final v = s[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '-';
  }

  String? _nomorInduk(Map<String, dynamic> s) {
    for (final key in const ['nis', 'nisn', 'nomorInduk']) {
      final v = s[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return '${key.toUpperCase()} ${v.toString().trim()}';
      }
    }
    return null;
  }

  /// true = laki-laki, false = perempuan, null = tidak diketahui.
  bool? _isLaki(Map<String, dynamic> s) {
    final v = (s['jenisKelamin'] ?? s['gender'] ?? s['jk'])?.toString().toUpperCase().trim();
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('L') || v.startsWith('M')) return true;
    if (v.startsWith('P') || v.startsWith('F')) return false;
    return null;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    final out = _santri.where((s) {
      if (q.isEmpty) return true;
      return _namaSantri(s).toLowerCase().contains(q) ||
          (_nomorInduk(s) ?? '').toLowerCase().contains(q);
    }).toList();
    out.sort((a, b) => _namaSantri(a).toLowerCase().compareTo(_namaSantri(b).toLowerCase()));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = _santri.length > 6;
    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: () => _load(spinner: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _infoCards()),
                SliverToBoxAdapter(child: _santriHeader()),
                if (showSearch)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedBar(
                      height: 64,
                      child: _searchBar(
                        controller: _searchC,
                        hint: 'Cari nama santri',
                        query: _q,
                        onChanged: (v) => setState(() => _q = v),
                        onClear: () {
                          _searchC.clear();
                          setState(() => _q = '');
                        },
                      ),
                    ),
                  ),
                ..._santriSlivers(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final nama = (_kelas['namaKelas'] ?? '-').toString().trim();
    final tingkat = _kelas['tingkat']?.toString().trim() ?? '';
    final jenis = _jenisOf(_kelas);
    final jumlah = _santri.isNotEmpty ? _santri.length : _santriCountOf(_kelas);
    final kapasitas = _kapasitasOf(_kelas);
    final laki = _santri.where((s) => _isLaki(s) == true).length;
    final perempuan = _santri.where((s) => _isLaki(s) == false).length;
    final adaGender = laki + perempuan > 0;

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _heroCircleBtn(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.of(context).maybePop(),
                tooltip: 'Kembali',
              ),
              const Spacer(),
              if (!widget.readOnly) ...[
                _heroCircleBtn(Icons.edit_outlined, () => Navigator.of(context).pop('edit'),
                    tooltip: 'Edit kelas'),
                const SizedBox(width: 8),
                _heroCircleBtn(
                    Icons.delete_outline_rounded, () => Navigator.of(context).pop('hapus'),
                    tooltip: 'Hapus kelas'),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: Text(
                  _badgeKelas(nama),
                  style: sty(nama.length > 2 ? 16 : 20, FontWeight.w800, SC.gold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelas $nama',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (tingkat.isNotEmpty)
                          _pill('Tingkat $tingkat',
                              bg: Colors.white.withOpacity(0.16), fg: Colors.white),
                        if (jenis != null)
                          _pill(jenis, bg: SC.gold.withOpacity(0.22), fg: SC.gold),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _glassStrip([
            _stat(_loading && _santri.isEmpty ? '–' : '$jumlah', 'Santri'),
            if (adaGender) ...[
              _stat('$laki', 'Putra'),
              _stat('$perempuan', 'Putri'),
            ] else if (kapasitas != null) ...[
              _stat('$kapasitas', 'Kapasitas'),
              _stat('${(kapasitas - jumlah).clamp(0, kapasitas)}', 'Sisa'),
            ] else
              _stat(_waliOf(_kelas) != null ? '1' : '0', 'Wali kelas'),
          ]),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? SC.border),
        boxShadow: softShadow,
      ),
      child: child,
    );
  }

  Widget _infoCards() {
    final wali = _waliOf(_kelas);
    final adaInfo = _kelas.containsKey('waliKelas') || _kelas.containsKey('waliKelasNama');
    final kapasitas = _kapasitasOf(_kelas);
    final jumlah = _santri.isNotEmpty ? _santri.length : _santriCountOf(_kelas);

    final children = <Widget>[];

    if (adaInfo) {
      final ada = wali != null;
      children.add(_card(
        border: ada ? null : SC.gold.withOpacity(0.5),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ada ? SC.sage : SC.goldSurface,
                shape: BoxShape.circle,
              ),
              child: ada
                  ? Text(_initials(wali), style: sty(15, FontWeight.w800, SC.primary))
                  : Icon(Icons.person_off_outlined, size: 22, color: SC.goldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wali kelas', style: sty(11, FontWeight.w600, SC.inkSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    ada ? wali : 'Belum ditentukan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(14.5, FontWeight.w800, ada ? SC.ink : SC.goldDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    if (kapasitas != null) {
      final penuh = jumlah > kapasitas;
      final persen = ((jumlah / kapasitas) * 100).round();
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(_card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Kapasitas kelas', style: sty(13, FontWeight.w800, SC.ink)),
                const Spacer(),
                Text('$jumlah / $kapasitas',
                    style: sty(13, FontWeight.w800, penuh ? SC.errorText : SC.primary)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (jumlah / kapasitas).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: SC.surfaceDim,
                valueColor: AlwaysStoppedAnimation(penuh ? SC.errorText : SC.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              penuh ? 'Melebihi kapasitas ($persen%)' : 'Terisi $persen% dari kapasitas',
              style: sty(11, FontWeight.w500, SC.inkSecondary),
            ),
          ],
        ),
      ));
    }

    if (children.isEmpty) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(children: children),
    );
  }

  Widget _santriHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Icon(Icons.groups_2_rounded, size: 20, color: SC.primary),
          const SizedBox(width: 8),
          Text('Daftar santri', style: sty(15, FontWeight.w800, SC.ink)),
          const SizedBox(width: 8),
          _pill('${_santri.length}', bg: SC.sage, fg: SC.primary),
          const Spacer(),
          if (_q.isNotEmpty)
            Text('${_filtered.length} hasil',
                style: sty(11, FontWeight.w600, SC.inkSecondary)),
        ],
      ),
    );
  }

  List<Widget> _santriSlivers() {
    if (_loading && _santri.isEmpty) {
      return [SliverToBoxAdapter(child: SizedBox(height: 240, child: loadingView()))];
    }
    if (_error != null && _santri.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: errorView(_error!, () => _load()),
          ),
        ),
      ];
    }
    if (_santri.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.person_add_alt_1_outlined,
            judul: 'Belum ada santri',
            pesan: 'Santri yang ditempatkan ke kelas ini akan tampil di sini.',
          ),
        ),
      ];
    }
    final list = _filtered;
    if (list.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada santri yang cocok dengan pencarian ini.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _santriTile(i + 1, list[i]),
            ),
            childCount: list.length,
          ),
        ),
      ),
    ];
  }

  Widget _santriTile(int no, Map<String, dynamic> s) {
    final nama = _namaSantri(s);
    final induk = _nomorInduk(s);
    final laki = _isLaki(s);
    final putri = laki == false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: putri ? SC.goldSurface : SC.sage,
              shape: BoxShape.circle,
              border: Border.all(
                color: putri ? SC.gold.withOpacity(0.55) : SC.primary.withOpacity(0.18),
              ),
            ),
            child: Text(
              _initials(nama),
              style: sty(14, FontWeight.w800, putri ? SC.goldDark : SC.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(14, FontWeight.w800, SC.ink),
                ),
                if (induk != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      induk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(11.5, FontWeight.w500, SC.inkSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (laki != null)
            _pill(
              laki ? 'Putra' : 'Putri',
              bg: putri ? SC.goldSurface : SC.mint,
              fg: putri ? SC.goldDark : SC.primary,
              icon: laki ? Icons.male_rounded : Icons.female_rounded,
            )
          else
            Text('$no', style: sty(11.5, FontWeight.w700, SC.inkMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog tambah/edit kelas
// ---------------------------------------------------------------------------

class _KelasFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>>? ustadzList;
  const _KelasFormDialog({this.existing, this.ustadzList});

  @override
  State<_KelasFormDialog> createState() => _KelasFormDialogState();
}

class _KelasFormDialogState extends State<_KelasFormDialog> {
  late final TextEditingController _nama;
  late final TextEditingController _tingkat;
  String? _waliId;
  String? _err;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?['namaKelas']?.toString() ?? '');
    _tingkat = TextEditingController(text: widget.existing?['tingkat']?.toString() ?? '');
    final w = widget.existing?['waliKelasId'] ??
        (widget.existing?['waliKelas'] is Map ? widget.existing!['waliKelas']['id'] : null);
    final id = w?.toString();
    final ada = widget.ustadzList?.any((u) => u['id']?.toString() == id) ?? false;
    _waliId = ada ? id : null;
  }

  @override
  void dispose() {
    _nama.dispose();
    _tingkat.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      setState(() => _err = 'Nama kelas wajib diisi.');
      return;
    }
    if (_tingkat.text.trim().isEmpty) {
      setState(() => _err = 'Tingkat wajib diisi.');
      return;
    }
    Navigator.pop(context, {
      'namaKelas': _nama.text.trim(),
      'tingkat': _tingkat.text.trim(),
      // null = kosongkan wali kelas. Tidak dikirim kalau daftar ustadz gagal dimuat.
      if (widget.ustadzList != null) 'waliKelasId': _waliId,
    });
  }

  /// Nama kelas LAIN yang sudah dipegang ustadz ini sebagai wali.
  String? _kelasLain(Map<String, dynamic> u) {
    final k = u['kelasDiampu'];
    if (k is! List) return null;
    final selfId = widget.existing?['id']?.toString();
    final nama = k
        .whereType<Map>()
        .where((e) => e['id']?.toString() != selfId)
        .map((e) => '${e['namaKelas'] ?? ''}'.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return nama.isEmpty ? null : nama.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      titlePadding: _dialogTitlePad,
      contentPadding: _dialogContentPad,
      actionsPadding: _dialogActionsPad,
      title: Row(
        children: [
          _dialogIcon(Icons.meeting_room_rounded, SC.sage, SC.primary),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit kelas' : 'Tambah kelas',
              style: sty(16, FontWeight.w800, SC.ink)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nama kelas'),
              TextField(
                controller: _nama,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Contoh: 7A'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              const SizedBox(height: 12),
              _label('Tingkat'),
              TextField(
                controller: _tingkat,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Contoh: 7'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) _errText(_err!),
              if (widget.ustadzList != null) ...[
                const SizedBox(height: 12),
                _label('Wali kelas'),
                DropdownButtonFormField<String?>(
                  value: _waliId,
                  isExpanded: true,
                  decoration: _dec('Pilih ustadz'),
                  dropdownColor: SC.surface,
                  style: sty(14, FontWeight.w600, SC.ink),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Belum ditentukan'),
                    ),
                    for (final u in widget.ustadzList!.where(
                      (u) => u['jenis'] != 'MUSYRIF' || u['id']?.toString() == _waliId,
                    ))
                      _ustadzItem(u),
                  ],
                  onChanged: (v) => setState(() => _waliId = v),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text('Satu ustadz hanya bisa jadi wali satu kelas.',
                      style: sty(11, FontWeight.w500, SC.inkSecondary)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        _btnBatal(() => Navigator.pop(context)),
        _btnUtama('Simpan', _submit),
      ],
    );
  }

  DropdownMenuItem<String?> _ustadzItem(Map<String, dynamic> u) {
    final lain = _kelasLain(u);
    final label = '${u['nama'] ?? '-'}${u['jenis'] == 'MUSYRIF' ? ' (Musyrif)' : ''}'
        '${lain != null ? '  •  wali $lain' : ''}';
    return DropdownMenuItem<String?>(
      value: u['id']?.toString(),
      enabled: lain == null,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: sty(
          14,
          FontWeight.w600,
          lain == null ? SC.ink : SC.inkSecondary.withOpacity(0.6),
        ),
      ),
    );
  }
}