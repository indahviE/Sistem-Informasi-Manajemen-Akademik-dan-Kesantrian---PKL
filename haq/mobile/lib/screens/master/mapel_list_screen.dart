import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

/// KKM bawaan untuk mapel baru.
const double _kkmDefault = 75;

String _fmtKkm(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

class MapelListScreen extends StatefulWidget {
  const MapelListScreen({super.key});

  @override
  State<MapelListScreen> createState() => _MapelListScreenState();
}

class _MapelListScreenState extends State<MapelListScreen> {
  /// Pimpinan/Mudir hanya memantau: tombol tambah/ubah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  /// Banner notifikasi inline (di bawah hero), hilang otomatis. Tidak mengambang.
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
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data (logic API tidak diubah)
  // ---------------------------------------------------------------------
  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.mapel);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// Buka halaman form (tambah / edit). Mengembalikan data yang akan dikirim ke server.
  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => _MapelFormScreen(existing: existing)),
    );
  }

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.mapel, result);
      if (!mounted) return;
      _toast('Mapel berhasil ditambah', subtitle: '"${result['namaMapel']}" masuk ke daftar');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> mapel) async {
    final result = await _form(mapel);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.mapel}/${mapel['id']}', result);
      if (!mounted) return;
      _toast('Mapel diperbarui', subtitle: '"${result['namaMapel']}" berhasil disimpan');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> mapel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
        ),
        title: Text('Hapus mapel?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          'Mapel "${mapel['namaMapel']}" akan dihapus permanen.',
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SC.border),
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
      await AppScope.of(context).api.delete('${ApiUrl.mapel}/${mapel['id']}');
      if (!mounted) return;
      _toast('Mapel dihapus', subtitle: '"${mapel['namaMapel']}" sudah dihapus permanen');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Notifikasi inline (gaya absensi, tapi menempel di halaman, tidak melayang)
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
                        if (_bannerSub != null) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
  // Helper
  // ---------------------------------------------------------------------
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  bool _hasKode(dynamic item) {
    final k = (item as Map)['kode']?.toString().trim() ?? '';
    return k.isNotEmpty;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (!_readOnly)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _add,
                  tooltip: 'Tambah mapel',
                  backgroundColor: SC.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: SC.gold.withOpacity(0.6)),
                  ),
                  icon: const Icon(Icons.library_add_rounded, size: 18, color: SC.gold),
                  label: Text('Mapel baru', style: sty(13, FontWeight.w700, Colors.white)),
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
      ringkasan = 'Belum ada mata pelajaran';
    } else {
      ringkasan = _readOnly
          ? 'Daftar mata pelajaran lembaga'
          : 'Ketuk mapel untuk mengubah nama, kode, atau KKM';
    }
    String v(int n) => loaded ? '$n' : '–';
    final berkode = _items.where(_hasKode).length;

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
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mata Pelajaran', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
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
          Row(
            children: [
              _glass(Icons.menu_book_outlined, v(_items.length), 'Mapel'),
              const SizedBox(width: 8),
              _glass(Icons.tag_rounded, v(berkode), 'Berkode'),
              const SizedBox(width: 8),
              _glass(Icons.edit_note_rounded, v(_items.length - berkode), 'Tanpa kode'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glass(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
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
                  Text(value, style: sty(18, FontWeight.w800, Colors.white, h: 1.1)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
          ],
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
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }
    if (_items.isEmpty) {
      return [SliverToBoxAdapter(child: _kosong())];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              if (i == 0) return _sectionHeader();
              final m = _items[i - 1] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _mapelTile(i - 1, m),
              );
            },
            childCount: _items.length + 1,
          ),
        ),
      ),
    ];
  }

  Widget _kosong() {
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
            child: Icon(Icons.menu_book_outlined, size: 36, color: SC.primary),
          ),
          const SizedBox(height: 18),
          Text('Belum ada mata pelajaran',
              textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(
              _readOnly
                  ? 'Mata pelajaran belum ditambahkan oleh admin.'
                  : 'Tambahkan mapel pertama lewat tombol "Mapel baru" di bawah.',
              textAlign: TextAlign.center,
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: SC.sage, borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.menu_book_rounded, size: 14, color: SC.primary),
          ),
          const SizedBox(width: 9),
          Text('Daftar Mata Pelajaran', style: sty(14, FontWeight.w800, SC.ink)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: SC.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SC.gold.withOpacity(0.4)),
            ),
            child: Text('${_items.length}', style: sty(11, FontWeight.w800, SC.goldDark)),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1, thickness: 1, color: SC.border)),
        ],
      ),
    );
  }

  static Widget _kodeBadge(String? kode) {
    final has = (kode ?? '').trim().isNotEmpty;
    if (!has) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline, size: 13, color: SC.inkMuted),
          const SizedBox(width: 4),
          Text('Belum ada kode', style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: SC.goldSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag_rounded, size: 12, color: SC.goldDark),
          const SizedBox(width: 3),
          Text(kode!.trim(), style: sty(11.5, FontWeight.w800, SC.goldDark)),
        ],
      ),
    );
  }

  /// Lencana KKM mapel (batas tuntas). Kosong bila belum diatur.
  static Widget _kkmBadge(dynamic kkm) {
    final has = kkm is num;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: SC.sage,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SC.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 12, color: SC.primary),
          const SizedBox(width: 3),
          Text(has ? 'KKM ${_fmtKkm(kkm)}' : 'KKM belum diatur',
              style: sty(11.5, FontWeight.w800, SC.primary)),
        ],
      ),
    );
  }

  /// Kartu bergaya "punggung buku": garis warna di sisi kiri, selang-seling emerald dan emas.
  Widget _mapelTile(int index, Map<String, dynamic> m) {
    final nama = (m['namaMapel'] as String?)?.trim() ?? '-';
    final even = index.isEven;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _readOnly ? null : () => _edit(m),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: even ? SC.primary : SC.gold),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: even ? SC.sage : SC.goldSurface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _initials(nama),
                            style: sty(15, FontWeight.w800, even ? SC.primary : SC.gold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: sty(14.5, FontWeight.w800, SC.ink, h: 1.25),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _kodeBadge(m['kode'] as String?),
                                  _kkmBadge(m['kkm']),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!_readOnly)
                        PopupMenuButton<String>(
                          tooltip: 'Opsi',
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: SC.inkSecondary),
                          color: SC.surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (v) {
                            if (v == 'edit') _edit(m);
                            if (v == 'hapus') _delete(m);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                const Icon(Icons.edit_outlined, size: 18, color: SC.ink),
                                const SizedBox(width: 10),
                                Text('Edit mapel', style: sty(13, FontWeight.w600, SC.ink)),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'hapus',
                              child: Row(children: [
                                const Icon(Icons.delete_outline, size: 18, color: SC.errorText),
                                const SizedBox(width: 10),
                                Text('Hapus', style: sty(13, FontWeight.w600, SC.errorText)),
                              ]),
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Halaman form tambah / edit mapel
// ---------------------------------------------------------------------
class _MapelFormScreen extends StatefulWidget {
  const _MapelFormScreen({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_MapelFormScreen> createState() => _MapelFormScreenState();
}

class _MapelFormScreenState extends State<_MapelFormScreen> {
  late final TextEditingController _nama =
      TextEditingController(text: widget.existing?['namaMapel'] as String? ?? '');
  late final TextEditingController _kode =
      TextEditingController(text: widget.existing?['kode'] as String? ?? '');
  late final TextEditingController _kkm = TextEditingController(
      text: _fmtKkm(widget.existing?['kkm'] is num
          ? widget.existing!['kkm'] as num
          : _kkmDefault));
  String? _namaError;
  String? _kkmError;

  bool get _editing => widget.existing != null;

  double? get _kkmVal {
    final v = double.tryParse(_kkm.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  @override
  void dispose() {
    _nama.dispose();
    _kode.dispose();
    _kkm.dispose();
    super.dispose();
  }

  void _submit() {
    final namaBad = _nama.text.trim().isEmpty;
    final kkm = _kkmVal;
    if (namaBad || kkm == null) {
      setState(() {
        _namaError = namaBad ? 'Nama mapel wajib diisi' : null;
        _kkmError = kkm == null ? 'KKM harus angka 0 – 100' : null;
      });
      return;
    }
    Navigator.pop(context, {
      'namaMapel': _nama.text.trim(),
      'kode': _kode.text.trim().isEmpty ? null : _kode.text.trim(),
      'kkm': kkm == kkm.roundToDouble() ? kkm.toInt() : kkm,
    });
  }

  /// Usulan kode dari nama: "Ilmu Pengetahuan Alam" -> IPA, "Matematika" -> MAT.
  String _suggestKode(String nama) {
    const skip = {'dan', 'di', 'ke', 'yang', 'dengan'};
    final words = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !skip.contains(w.toLowerCase()))
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final w = words.first;
      return (w.length > 3 ? w.substring(0, 3) : w).toUpperCase();
    }
    return words.take(5).map((w) => w[0]).join().toUpperCase();
  }

  InputDecoration _deco({required String hint, required IconData icon, String? error}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
      errorText: error,
      errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
      prefixIcon: Icon(icon, size: 20, color: SC.primary),
      filled: true,
      fillColor: SC.background,
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SC.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.errorText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.errorText, width: 1.5),
      ),
    );
  }

  Widget _label(String text, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(text, style: sty(12.5, FontWeight.w800, SC.ink)),
          if (note != null) ...[
            const SizedBox(width: 6),
            Text(note, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _hero() {
    return HeroShell(
      top: MediaQuery.of(context).padding.top + 16,
      bottom: 20,
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.14),
            shape: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_editing ? 'Edit Mata Pelajaran' : 'Mapel Baru',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(20, FontWeight.w800, Colors.white, h: 1.15)),
                const SizedBox(height: 3),
                Text(
                  _editing
                      ? 'Perbarui nama, kode, atau KKM mapel'
                      : 'Tambahkan mata pelajaran ke kurikulum',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SC.gold.withOpacity(0.55)),
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 22, color: SC.gold),
          ),
        ],
      ),
    );
  }

  /// Pratinjau kartu mapel, berubah langsung saat mengetik.
  Widget _preview() {
    final nama = _nama.text.trim();
    final has = nama.isNotEmpty;

    return Container(
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
            Container(width: 5, color: SC.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SC.sage,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        has ? _MapelListScreenState._initials(nama) : '?',
                        style: sty(15, FontWeight.w800, SC.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            has ? nama : 'Nama mapel',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sty(14.5, FontWeight.w800, has ? SC.ink : SC.inkMuted, h: 1.25),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _MapelListScreenState._kodeBadge(_kode.text),
                              _MapelListScreenState._kkmBadge(_kkmVal),
                            ],
                          ),
                        ],
                      ),
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

  Widget _kodeSuggestion() {
    final saran = _suggestKode(_nama.text);
    final show = saran.isNotEmpty && _kode.text.trim().isEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _kode.text = saran),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: SC.goldSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: SC.gold.withOpacity(0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_fix_high, size: 14, color: SC.goldDark),
                        const SizedBox(width: 6),
                        Text('Pakai kode $saran', style: sty(12, FontWeight.w700, SC.goldDark)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              _hero(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 15, color: SC.primary),
                          const SizedBox(width: 6),
                          Text('Pratinjau', style: sty(12.5, FontWeight.w800, SC.ink)),
                          const SizedBox(width: 8),
                          Text('tampil seperti ini di daftar',
                              style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                        ],
                      ),
                    ),
                    _preview(),
                    const SizedBox(height: 20),
                    Container(
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
                          _label('Nama mapel'),
                          TextField(
                            controller: _nama,
                            autofocus: !_editing,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: sty(14, FontWeight.w600, SC.ink),
                            onChanged: (_) => setState(() {
                              if (_namaError != null) _namaError = null;
                            }),
                            decoration: _deco(
                              hint: 'Contoh: Matematika',
                              icon: Icons.menu_book_outlined,
                              error: _namaError,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _label('Kode', note: '(opsional)'),
                          TextField(
                            controller: _kode,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            style: sty(14, FontWeight.w600, SC.ink),
                            onChanged: (_) => setState(() {}),
                            decoration: _deco(hint: 'Contoh: MTK', icon: Icons.tag_rounded),
                          ),
                          _kodeSuggestion(),
                          const SizedBox(height: 18),
                          _label('KKM', note: '(batas tuntas, 0 – 100)'),
                          TextField(
                            controller: _kkm,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            style: sty(14, FontWeight.w600, SC.ink),
                            onChanged: (_) => setState(() {
                              if (_kkmError != null) _kkmError = null;
                            }),
                            decoration: _deco(
                              hint: 'Contoh: 75',
                              icon: Icons.flag_outlined,
                              error: _kkmError,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dipakai semua ujian pada mapel ini untuk menentukan santri tuntas atau perlu remedial.',
                            style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: const BoxDecoration(
                    color: SC.surface,
                    border: Border(top: BorderSide(color: SC.border)),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SC.inkSecondary,
                          side: const BorderSide(color: SC.border),
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: SC.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            icon: const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                            label: Text(_editing ? 'Simpan Perubahan' : 'Simpan Mapel',
                                style: sty(14, FontWeight.w700, Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}