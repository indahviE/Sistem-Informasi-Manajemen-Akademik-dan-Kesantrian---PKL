import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

class KelasListScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (mis. dari dashboard) supaya ada
  /// AppBar + tombol kembali. Kalau dipakai sebagai tab di shell, biarkan false.
  final bool showBack;
  const KelasListScreen({super.key, this.showBack = false});

  @override
  State<KelasListScreen> createState() => _KelasListScreenState();
}

class _KelasListScreenState extends State<KelasListScreen> {
  /// Pimpinan/Mudir hanya memantau: tombol tambah/ubah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<dynamic> _items = [];
  bool _loading = true;
  bool _busy = false; // true selama simpan/hapus/muat daftar ustadz berjalan
  String? _error;
  String _query = '';
  String _tingkatFilter = 'Semua';

  /// Banner notifikasi inline (di atas daftar), hilang otomatis.
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

  /// [silent] = true: tidak menampilkan spinner layar penuh (dipakai setelah
  /// simpan/hapus supaya daftar tidak berkedip).
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.kelas);
      if (!mounted) return;
      setState(() {
        _items = res is List
            ? res
            : ((res is Map ? res['items'] : null) as List? ?? []);
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (silent) {
        _toast(e.message, error: true);
      } else {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (silent) {
        _toast('Gagal memuat ulang daftar kelas.', error: true);
      } else {
        setState(() {
          _error = 'Gagal memuat daftar kelas.';
          _loading = false;
        });
      }
    }
  }

  /// Satu pola untuk semua aksi tulis: kunci tombol, tampilkan progress di atas,
  /// tangkap error, lalu muat ulang daftar tanpa spinner penuh.
  Future<void> _jalankan(
    Future<void> Function() aksi,
    String sukses, {
    String? sub,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await aksi();
      _toast(sukses, subtitle: sub);
      await _load(silent: true);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Daftar ustadz untuk dropdown Wali Kelas. null = gagal dimuat.
  Future<List<Map<String, dynamic>>?> _loadUstadz() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ustadz);
      final list = res is List
          ? res
          : ((res is Map ? res['items'] : null) as List? ?? []);
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  /// Muat daftar ustadz sambil menampilkan progress di atas layar.
  Future<List<Map<String, dynamic>>?> _loadUstadzDenganProgress() async {
    setState(() => _busy = true);
    final ustadz = await _loadUstadz();
    if (mounted) setState(() => _busy = false);
    return ustadz;
  }

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
    await _jalankan(
      () async {
        await api.post(ApiUrl.kelas, result);
      },
      'Kelas ditambahkan',
      sub: result['namaKelas']?.toString(),
    );
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
    await _jalankan(
      () async {
        await api.patch('${ApiUrl.kelas}/${kelas['id']}', result);
      },
      'Kelas diperbarui',
      sub: result['namaKelas']?.toString(),
    );
  }

  Future<void> _delete(Map<String, dynamic> kelas) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: SC.errorBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: SC.errorText,
            size: 26,
          ),
        ),
        title: Text(
          'Hapus kelas?',
          textAlign: TextAlign.center,
          style: sty(17, FontWeight.w800, SC.ink),
        ),
        content: Text(
          'Kelas "${kelas['namaKelas']}" akan dihapus permanen.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: sty(13, FontWeight.w700, SC.inkSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SC.errorText,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, hapus',
              style: sty(13, FontWeight.w700, Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(
      () async {
        await api.delete('${ApiUrl.kelas}/${kelas['id']}');
      },
      'Kelas dihapus',
      sub: kelas['namaKelas']?.toString(),
    );
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
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: error ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error
                      ? SC.errorText.withOpacity(0.25)
                      : SC.gold.withOpacity(0.5),
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
                          Text(
                            _bannerSub!,
                            style: sty(
                              11.5,
                              FontWeight.w500,
                              fg.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: fg.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Helper data (semua null-safe)
  // ---------------------------------------------------------------------
  List<Map<String, dynamic>> get _all =>
      _items.whereType<Map<String, dynamic>>().toList();

  int _santriCount(Map<String, dynamic> k) {
    final c = k['_count'];
    if (c is Map) {
      final v = c['santris'];
      if (v is num) return v.toInt();
    }
    final j = k['jumlahSantri'];
    return j is num ? j.toInt() : 0;
  }

  String? _wali(Map<String, dynamic> k) {
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

  /// Backend sudah kirim info wali kelas atau belum. Kalau belum, baris wali
  /// disembunyikan supaya tidak muncul "Belum ada wali" di semua kartu.
  bool get _adaDataWali => _all.any(
    (k) => k.containsKey('waliKelas') || k.containsKey('waliKelasNama'),
  );

  int? _kapasitas(Map<String, dynamic> k) {
    final v = k['kapasitas'];
    return (v is num && v > 0) ? v.toInt() : null;
  }

  String? _jenis(Map<String, dynamic> k) {
    final v = k['jenis']?.toString().toUpperCase();
    if (v == 'TAHFIDZ') return 'Tahfidz';
    if (v == 'DINIYAH') return 'Diniyah';
    return null;
  }

  List<String> _tingkatList() {
    final set = <String>{};
    for (final k in _all) {
      final t = k['tingkat']?.toString().trim() ?? '';
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<Map<String, dynamic>> _filtered() {
    final q = _query.trim().toLowerCase();
    return _all.where((k) {
      if (_tingkatFilter != 'Semua' &&
          (k['tingkat']?.toString().trim() ?? '') != _tingkatFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final nama = (k['namaKelas']?.toString() ?? '').toLowerCase();
      final wali = (_wali(k) ?? '').toLowerCase();
      return nama.contains(q) || wali.contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------
  // UI
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
              Column(
                children: [
                  _banner(),
                  Expanded(child: _body()),
                ],
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
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: SC.gold,
                    ),
                    label: Text(
                      'Kelas baru',
                      style: sty(13, FontWeight.w700, Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bungkus tampilan loading/error/kosong supaya tombol kembali tetap ada.
  Widget _withBack(Widget child) {
    if (!widget.showBack) return child;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: SC.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.border),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: SC.ink,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_items.isEmpty)
      return emptyView(
        _readOnly
            ? 'Belum ada kelas.'
            : 'Belum ada kelas. Tap "Kelas baru" untuk menambah.',
      );
    if (_loading) return _withBack(loadingView());
    if (_error != null) return _withBack(errorView(_error!, _load));
    if (_items.isEmpty) {
      return _withBack(
        emptyView('Belum ada kelas. Tap "Kelas baru" untuk menambah.'),
      );
    }

    final list = _filtered();
    return RefreshIndicator(
      color: SC.primary,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        children: [
          _summaryCard(),
          const SizedBox(height: 14),
          _searchField(),
          const SizedBox(height: 10),
          _tingkatChips(),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Tidak ada kelas yang cocok.',
                  style: sty(12.5, FontWeight.w500, SC.inkSecondary),
                ),
              ),
            )
          else
            for (final k in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _kelasCard(k),
              ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final all = _all;
    final totalSantri = all.fold<int>(0, (s, k) => s + _santriCount(k));
    final tanpaWali = all.where((k) => _wali(k) == null).length;

    Widget stat(String value, String label, {bool warn = false}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: sty(22, FontWeight.w800, warn ? SC.gold : Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: sty(11, FontWeight.w500, Colors.white.withOpacity(0.72)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SC.primary, SC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SC.primary.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBack) ...[
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SC.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Rombel & Halaqah',
                style: sty(11.5, FontWeight.w700, SC.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('${all.length}', 'Total Kelas'),
              stat('$totalSantri', 'Total Santri'),
              if (_adaDataWali)
                stat('$tanpaWali', 'Tanpa Wali Kelas', warn: tanpaWali > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      style: sty(13.5, FontWeight.w600, SC.ink),
      decoration: InputDecoration(
        hintText: _adaDataWali
            ? 'Cari nama kelas atau wali kelas'
            : 'Cari nama kelas',
        hintStyle: sty(13, FontWeight.w500, SC.inkMuted),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: SC.primary),
        filled: true,
        fillColor: SC.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: b(SC.border),
        enabledBorder: b(SC.border),
        focusedBorder: b(SC.primary, 1.4),
      ),
    );
  }

  Widget _tingkatChips() {
    final tingkat = _tingkatList();
    if (tingkat.length < 2) return const SizedBox.shrink();
    final labels = ['Semua', ...tingkat];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final l = labels[i];
          final selected = _tingkatFilter == l;
          return GestureDetector(
            onTap: () => setState(() => _tingkatFilter = l),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? SC.primary : SC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? SC.primary : SC.border),
              ),
              child: Text(
                l == 'Semua' ? l : 'Tingkat $l',
                style: sty(
                  12,
                  FontWeight.w700,
                  selected ? Colors.white : SC.inkSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, {Color? bg, Color? fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? SC.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: sty(10, FontWeight.w700, fg ?? SC.primary)),
    );
  }

  Widget _kelasCard(Map<String, dynamic> k) {
    final nama = k['namaKelas']?.toString() ?? '-';
    final tingkat = k['tingkat']?.toString().trim() ?? '';
    final jumlah = _santriCount(k);
    final wali = _wali(k);
    final jenis = _jenis(k);
    final kapasitas = _kapasitas(k);
    final adaWali = _adaDataWali;
    final perluWali = adaWali && wali == null;

    return Container(
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softShadow,
      ),
      child: Material(
        color: SC.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (_busy || _readOnly) ? null : () => _edit(k),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: perluWali ? SC.gold.withOpacity(0.5) : SC.border,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      color: perluWali ? SC.gold : SC.primary,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: SC.sage,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.class_,
                                    size: 20,
                                    color: SC.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: sty(15, FontWeight.w800, SC.ink),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (tingkat.isNotEmpty)
                                            _chip('Tingkat $tingkat'),
                                          if (jenis != null)
                                            _chip(
                                              jenis,
                                              bg: SC.goldSurface,
                                              fg: SC.goldDark,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_readOnly)
                                  PopupMenuButton<String>(
                                    tooltip: 'Opsi',
                                    enabled: !_busy,
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                      color: SC.inkSecondary,
                                    ),
                                    color: SC.surface,
                                    surfaceTintColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    onSelected: (v) {
                                      if (v == 'edit') _edit(k);
                                      if (v == 'hapus') _delete(k);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: SC.ink,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Edit data',
                                              style: sty(
                                                13,
                                                FontWeight.w600,
                                                SC.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'hapus',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: SC.errorText,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Hapus',
                                              style: sty(
                                                13,
                                                FontWeight.w600,
                                                SC.errorText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (adaWali) ...[
                              Row(
                                children: [
                                  Icon(
                                    wali != null
                                        ? Icons.person_outline
                                        : Icons.person_off_outlined,
                                    size: 15,
                                    color: wali != null
                                        ? SC.inkSecondary
                                        : SC.goldDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      wali != null
                                          ? 'Wali Kelas: $wali'
                                          : 'Belum ada wali kelas',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(
                                        12,
                                        wali != null
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        wali != null ? SC.ink : SC.goldDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.groups_2_outlined,
                                  size: 15,
                                  color: SC.inkSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  kapasitas != null
                                      ? '$jumlah / $kapasitas santri'
                                      : '$jumlah santri',
                                  style: sty(
                                    12,
                                    FontWeight.w500,
                                    SC.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (kapasitas != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: (jumlah / kapasitas).clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: SC.surfaceDim,
                                    valueColor: AlwaysStoppedAnimation(
                                      jumlah > kapasitas
                                          ? SC.errorText
                                          : SC.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
}

/// Dialog tambah/edit kelas. Dibuat sebagai widget sendiri supaya controller-nya
/// di-dispose dengan aman (tidak error saat animasi dialog menutup).
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
    _nama = TextEditingController(
      text: widget.existing?['namaKelas']?.toString() ?? '',
    );
    _tingkat = TextEditingController(
      text: widget.existing?['tingkat']?.toString() ?? '',
    );
    final w =
        widget.existing?['waliKelasId'] ??
        (widget.existing?['waliKelas'] is Map
            ? widget.existing!['waliKelas']['id']
            : null);
    final id = w?.toString();
    final ada =
        widget.ustadzList?.any((u) => u['id']?.toString() == id) ?? false;
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
  /// null = ustadz masih bebas (atau hanya memegang kelas yang sedang diedit).
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SC.sage,
              shape: BoxShape.circle,
              border: Border.all(color: SC.gold.withOpacity(0.45)),
            ),
            child: Icon(
              Icons.meeting_room_rounded,
              size: 18,
              color: SC.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isEdit ? 'Edit kelas' : 'Tambah kelas',
            style: sty(16, FontWeight.w800, SC.ink),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nama Kelas'),
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
              if (_err != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    _err!,
                    style: sty(11.5, FontWeight.w600, SC.errorText),
                  ),
                ),
              ],
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
              if (widget.ustadzList != null) ...[
                const SizedBox(height: 12),
                _label('Wali Kelas'),
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
                      (u) =>
                          u['jenis'] != 'MUSYRIF' ||
                          u['id']?.toString() == _waliId,
                    ))
                      _ustadzItem(u),
                  ],
                  onChanged: (v) => setState(() => _waliId = v),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    'Satu ustadz hanya bisa jadi wali satu kelas.',
                    style: sty(11, FontWeight.w500, SC.inkSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: SC.border),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: sty(13, FontWeight.w700, SC.inkSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SC.primary,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: _submit,
          child: Text('Simpan', style: sty(13, FontWeight.w700, Colors.white)),
        ),
      ],
    );
  }

  /// Item dropdown ustadz. Ustadz yang sudah jadi wali kelas lain ditampilkan
  /// redup dan tidak bisa dipilih, lengkap dengan nama kelasnya.
  DropdownMenuItem<String?> _ustadzItem(Map<String, dynamic> u) {
    final lain = _kelasLain(u);
    final label =
        '${u['nama'] ?? '-'}${u['jenis'] == 'MUSYRIF' ? ' (Musyrif)' : ''}'
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
