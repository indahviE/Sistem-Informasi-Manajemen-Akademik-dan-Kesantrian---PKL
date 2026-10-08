import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import 'santri_detail_screen.dart';
import 'santri_form_screen.dart';
import 'santri_ui.dart';

/// Satu baris di list: judul seksi (kelas) atau santri.
class _Entry {
  const _Entry.header(this.title, this.count, {this.unassigned = false}) : santri = null;
  const _Entry.santri(this.santri)
      : title = null,
        count = 0,
        unassigned = false;

  final String? title;
  final int count;
  final bool unassigned;
  final Map<String, dynamic>? santri;

  bool get isHeader => santri == null;
}

/// Bar pencarian + chip yang menempel di atas saat digulir.
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

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  static const _tanpaKelas = '__tanpa_kelas__';

  /// Pimpinan/Mudir hanya memantau: tombol tambah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  Timer? _debounce;

  /// null = semua, [_tanpaKelas] = santri tanpa kelas, selain itu = nama kelas.
  String? _kelasFilter;

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
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
    _debounce?.cancel();
    _bannerTimer?.cancel();
    _search.dispose();
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
      final api = AppScope.of(context).api;
      final res = await api.get(
        ApiUrl.santri,
        query: {'search': _search.text.trim(), 'perPage': '50'},
      );
      if (!mounted) return;
      final raw = (res['items'] as List? ?? []);
      setState(() {
        _items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
        _error = null;
        if (_kelasFilter != null &&
            _kelasFilter != _tanpaKelas &&
            !_kelasList.contains(_kelasFilter)) {
          _kelasFilter = null;
        }
        if (_kelasFilter == _tanpaKelas && !_adaTanpaKelas) _kelasFilter = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(spinner: false);
    });
  }

  String? _kelasOf(Map<String, dynamic> s) {
    final v = (s['kelas'] as Map?)?['namaKelas']?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  List<String> get _kelasList {
    final set = <String>{};
    for (final s in _items) {
      final k = _kelasOf(s);
      if (k != null) set.add(k);
    }
    return set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  bool get _adaTanpaKelas => _items.any((s) => _kelasOf(s) == null);

  int _countKelas(String? key) {
    if (key == null) return _items.length;
    if (key == _tanpaKelas) return _items.where((s) => _kelasOf(s) == null).length;
    return _items.where((s) => _kelasOf(s) == key).length;
  }

  int get _totalAktif =>
      _items.where((s) => (s['status']?.toString().toUpperCase() ?? 'AKTIF') == 'AKTIF').length;

  List<Map<String, dynamic>> get _filtered {
    if (_kelasFilter == null) return _items;
    if (_kelasFilter == _tanpaKelas) return _items.where((s) => _kelasOf(s) == null).toList();
    return _items.where((s) => _kelasOf(s) == _kelasFilter).toList();
  }

  List<_Entry> _buildEntries() {
    final groups = <String, List<Map<String, dynamic>>>{};
    final tanpa = <Map<String, dynamic>>[];
    for (final s in _filtered) {
      final k = _kelasOf(s);
      if (k == null) {
        tanpa.add(s);
      } else {
        groups.putIfAbsent(k, () => []).add(s);
      }
    }
    final names = groups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    int byNama(Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['nama']?.toString() ?? '')
            .toLowerCase()
            .compareTo((b['nama']?.toString() ?? '').toLowerCase());

    final out = <_Entry>[];
    for (final n in names) {
      final list = groups[n]!..sort(byNama);
      out.add(_Entry.header(n, list.length));
      out.addAll(list.map(_Entry.santri));
    }
    if (tanpa.isNotEmpty) {
      tanpa.sort(byNama);
      out.add(_Entry.header('Belum ada kelas', tanpa.length, unassigned: true));
      out.addAll(tanpa.map(_Entry.santri));
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  /// Notifikasi inline: tampil sebagai banner di bawah hero, tidak menimpa apa pun.
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

  Future<void> _hapus(Map<String, dynamic> s) async {
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
        title: Text('Hapus santri?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          '"${s['nama']}" (NIS ${s['nis']}) beserta semua datanya akan dihapus dan tidak bisa dikembalikan.',
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
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.santri}/${s['id']}');
      if (!mounted) return;
      _toast('${s['nama']} dihapus');
      _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menghapus santri.', error: true);
    }
  }

  void _buka(Map<String, dynamic> s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: s['id'] as String)),
    ).then((_) {
      if (mounted) _load(spinner: false);
    });
  }

  Future<void> _tambah() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SantriFormScreen()),
    );
    if (created == true) {
      _toast('Santri baru ditambahkan');
      _load(spinner: false);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showChips = !_loading && _error == null && _items.isNotEmpty;

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
                        height: showChips ? 108 : 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _searchBar(),
                            if (showChips) _kelasChips(),
                          ],
                        ),
                      ),
                    ),
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
                  onPressed: _tambah,
                  tooltip: 'Tambah santri',
                  backgroundColor: SC.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: SC.gold.withOpacity(0.6)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: SC.gold),
                  label: Text('Santri baru', style: sty(13, FontWeight.w700, Colors.white)),
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
      ringkasan = 'Belum ada santri terdaftar';
    } else {
      ringkasan = 'Ketuk santri untuk melihat profil lengkap';
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.groups_2_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daftar Santri', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
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
              _glass(Icons.badge_outlined, v(_items.length), 'Santri'),
              const SizedBox(width: 8),
              _glass(Icons.verified_outlined, v(_totalAktif), 'Aktif'),
              const SizedBox(width: 8),
              _glass(Icons.class_outlined, v(_kelasList.length), 'Kelas'),
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _search,
          onChanged: _onSearchChanged,
          onSubmitted: (_) {
            _debounce?.cancel();
            _load(spinner: false);
          },
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari nama atau NIS',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                      _debounce?.cancel();
                      _load(spinner: false);
                    },
                  ),
            filled: true,
            fillColor: SC.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: SC.border),
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

  Widget _kelasChips() {
    final kelas = _kelasList;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        children: [
          _chip(null, 'Semua', _countKelas(null)),
          for (final k in kelas) _chip(k, k, _countKelas(k)),
          if (_adaTanpaKelas) _chip(_tanpaKelas, 'Tanpa kelas', _countKelas(_tanpaKelas)),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label, int count) {
    final active = _kelasFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _kelasFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.only(left: 13, right: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? SC.primary : SC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? SC.primary : SC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: sty(12, FontWeight.w700, active ? Colors.white : SC.inkSecondary),
              ),
              const SizedBox(width: 7),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? SC.gold : SC.surfaceDim,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: sty(10.5, FontWeight.w800, active ? SC.primary : SC.inkSecondary),
                ),
              ),
            ],
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
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }
    if (_items.isEmpty) {
      final mencari = _search.text.trim().isNotEmpty;
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: mencari ? Icons.search_off_rounded : Icons.groups_2_outlined,
            judul: mencari ? 'Tidak ada hasil' : 'Belum ada data santri',
            pesan: mencari
                ? 'Tidak ada santri dengan nama atau NIS "${_search.text.trim()}". Coba kata kunci lain.'
                : (_readOnly
                    ? 'Belum ada santri terdaftar.'
                    : 'Tambahkan santri lewat tombol di bawah, atau terima pendaftar dari menu PPDB.'),
          ),
        ),
      ];
    }

    final entries = _buildEntries();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final e = entries[i];
              if (e.isHeader) {
                return _sectionHeader(e.title!, e.count, unassigned: e.unassigned, first: i == 0);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _santriTile(e.santri!),
              );
            },
            childCount: entries.length,
          ),
        ),
      ),
    ];
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
          Text(judul,
              textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(pesan,
              textAlign: TextAlign.center,
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, {bool unassigned = false, bool first = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, first ? 6 : 16, 2, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: unassigned ? SC.surfaceDim : SC.sage,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(unassigned ? Icons.help_outline_rounded : Icons.class_rounded,
                size: 14, color: unassigned ? SC.inkSecondary : SC.primary),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(14, FontWeight.w800, SC.ink)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: SC.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SC.gold.withOpacity(0.4)),
            ),
            child: Text('$count', style: sty(11, FontWeight.w800, SC.goldDark)),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1, thickness: 1, color: SC.border)),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SC.inkMuted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
        ),
      ],
    );
  }

  Widget _santriTile(Map<String, dynamic> s) {
    final nama = (s['nama'] as String?)?.trim() ?? '-';
    final nis = s['nis']?.toString() ?? '-';
    final asrama = s['asrama']?.toString().trim() ?? '';
    final jk = s['jenisKelamin']?.toString().toUpperCase();
    final status = s['status'] is String ? (s['status'] as String) : null;
    final nonAktif = status != null && status.toUpperCase() != 'AKTIF';

    return Container(
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
          onTap: () => _buka(s),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
            child: Row(
              children: [
                SantriAvatar(name: nama, gender: jk, size: 50, badge: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(14.5, FontWeight.w800, SC.ink),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _meta(Icons.tag_rounded, nis),
                          if (asrama.isNotEmpty) _meta(Icons.bed_outlined, asrama),
                          if (nonAktif)
                            SPill(status,
                                bg: statusColors(status).bg, fg: statusColors(status).fg, size: 10),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opsi',
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: SC.inkSecondary),
                  color: SC.surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (v) {
                    if (v == 'detail') _buka(s);
                    if (v == 'hapus') _hapus(s);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(children: [
                        const Icon(Icons.visibility_outlined, size: 18, color: SC.ink),
                        const SizedBox(width: 10),
                        Text('Lihat profil', style: sty(13, FontWeight.w600, SC.ink)),
                      ]),
                    ),
                    if (!_readOnly)
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
      ),
    );
  }
}