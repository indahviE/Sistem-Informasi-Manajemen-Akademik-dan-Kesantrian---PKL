import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

// =====================================================================
// Layar utama: hero + tab (Kurikulum / Silabus / RPP)
// =====================================================================
class KurikulumScreen extends StatelessWidget {
  const KurikulumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SC.background,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _hero(),
                _tabBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CrudTab(cfg: _kurikulumCfg),
                      _CrudTab(cfg: _silabusCfg),
                      _CrudTab(cfg: _rppCfg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return HeroShell(
      top: 20,
      bottom: 18,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SC.gold.withOpacity(0.55)),
            ),
            child: const Icon(Icons.folder_copy_rounded, size: 24, color: SC.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kurikulum', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                const SizedBox(height: 3),
                Text(
                  'Kurikulum, silabus, dan RPP pembelajaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.border),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: SC.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: SC.inkSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          splashBorderRadius: BorderRadius.circular(999),
          tabs: const [
            Tab(height: 38, text: 'Kurikulum'),
            Tab(height: 38, text: 'Silabus'),
            Tab(height: 38, text: 'RPP'),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Konfigurasi tiap tab (endpoint, isi form, bentuk data yang dikirim)
// =====================================================================
class _FieldSpec {
  const _FieldSpec({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.numeric = false,
    this.multiline = false,
    this.source,
  });

  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final bool numeric;
  final bool multiline;

  /// Kalau diisi, field tampil sebagai dropdown (nilainya id), bukan kotak teks.
  final _Src? source;
}

class _CrudConfig {
  const _CrudConfig({
    required this.url,
    required this.singular,
    required this.nameKey,
    required this.icon,
    required this.fabIcon,
    required this.fabLabel,
    required this.sectionTitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.formHint,
    required this.fields,
    required this.payload,
    required this.deleteMessage,
    required this.leading,
    required this.subtitle,
  });

  /// Dipanggil setiap kali dipakai (bukan disimpan), supaya selalu ikut ApiUrl terbaru.
  final String Function() url;
  final String singular;
  final String nameKey;
  final IconData icon;
  final IconData fabIcon;
  final String fabLabel;
  final String sectionTitle;
  final String emptyTitle;
  final String emptyMessage;
  final String formHint;
  final List<_FieldSpec> fields;
  final Map<String, dynamic> Function(Map<String, String> v) payload;
  final String Function(Map<String, dynamic> item) deleteMessage;
  final Widget Function(Map<String, dynamic> item, Color fg) leading;
  final Widget? Function(Map<String, dynamic> item) subtitle;
}

String _s(dynamic v) => (v ?? '').toString().trim();

/// Ambil satu kolom dari objek relasi hasil include Prisma (mis. mapel.namaMapel).
String _relName(dynamic rel, String key) => rel is Map ? _s(rel[key]) : '';

/// Sumber pilihan untuk field dropdown.
enum _Src { kurikulum, mapel }

Widget _pill(IconData icon, String text) {
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
        Icon(icon, size: 12, color: SC.goldDark),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sty(11.5, FontWeight.w800, SC.goldDark)),
        ),
      ],
    ),
  );
}

Widget _muted(String text) => Text(text, style: sty(12, FontWeight.w500, SC.inkMuted));

final _kurikulumCfg = _CrudConfig(
  url: () => ApiUrl.kurikulum,
  singular: 'Kurikulum',
  nameKey: 'nama',
  icon: Icons.folder_copy_rounded,
  fabIcon: Icons.create_new_folder_rounded,
  fabLabel: 'Kurikulum baru',
  sectionTitle: 'Daftar Kurikulum',
  emptyTitle: 'Belum ada kurikulum',
  emptyMessage: 'Tambahkan kurikulum pertama lewat tombol "Kurikulum baru" di bawah.',
  formHint: 'Beri nama kurikulum, misalnya Kurikulum Pondok 2025. Deskripsi boleh dikosongkan.',
  fields: const [
    _FieldSpec(
      key: 'nama',
      label: 'Nama Kurikulum',
      hint: 'Contoh: Kurikulum Pondok 2025',
      icon: Icons.folder_copy_outlined,
      required: true,
    ),
    _FieldSpec(
      key: 'deskripsi',
      label: 'Deskripsi',
      hint: 'Ringkasan singkat kurikulum',
      icon: Icons.notes_rounded,
      multiline: true,
    ),
  ],
  payload: (v) => {
    'nama': v['nama'],
    'deskripsi': (v['deskripsi'] ?? '').isEmpty ? null : v['deskripsi'],
  },
  deleteMessage: (k) =>
      'Hapus "${k['nama']}"? Silabus di dalamnya tidak ikut terhapus, hanya jadi tanpa kurikulum.',
  leading: (k, fg) => Icon(Icons.folder_copy_rounded, size: 22, color: fg),
  subtitle: (k) {
    final desk = _s(k['deskripsi']);
    final count = (k['_count'] as Map?)?['silabus'] ?? 0;
    final ta = _relName(k['tahunAjaran'], 'nama');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        desk.isEmpty
            ? _muted('Belum ada deskripsi')
            : Text(desk,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.35)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _pill(Icons.description_outlined, '$count silabus'),
          if (ta.isNotEmpty) _pill(Icons.event_note_outlined, ta),
        ]),
      ],
    );
  },
);

final _silabusCfg = _CrudConfig(
  url: () => ApiUrl.silabus,
  singular: 'Silabus',
  nameKey: 'judul',
  icon: Icons.description_rounded,
  fabIcon: Icons.note_add_rounded,
  fabLabel: 'Silabus baru',
  sectionTitle: 'Daftar Silabus',
  emptyTitle: 'Belum ada silabus',
  emptyMessage: 'Tambahkan silabus pertama lewat tombol "Silabus baru" di bawah.',
  formHint: 'Judul wajib diisi. Bagian lain boleh dikosongkan dan dilengkapi nanti.',
  fields: const [
    _FieldSpec(
      key: 'judul',
      label: 'Judul Silabus',
      hint: 'Contoh: Silabus Fiqih Kelas 7',
      icon: Icons.description_outlined,
      required: true,
    ),
    _FieldSpec(
      key: 'kurikulumId',
      label: 'Kurikulum',
      hint: 'Pilih kurikulum',
      icon: Icons.folder_copy_outlined,
      source: _Src.kurikulum,
    ),
    _FieldSpec(
      key: 'mapelId',
      label: 'Mata Pelajaran',
      hint: 'Pilih mata pelajaran',
      icon: Icons.school_outlined,
      source: _Src.mapel,
    ),
    _FieldSpec(
      key: 'kompetensiDasar',
      label: 'Kompetensi Dasar',
      hint: 'Kemampuan yang ingin dicapai',
      icon: Icons.flag_outlined,
      multiline: true,
    ),
    _FieldSpec(
      key: 'materiPokok',
      label: 'Materi Pokok',
      hint: 'Pokok bahasan utama',
      icon: Icons.menu_book_outlined,
      multiline: true,
    ),
    _FieldSpec(
      key: 'alokasiWaktu',
      label: 'Alokasi Waktu',
      hint: 'Contoh: 2 x 40 menit',
      icon: Icons.schedule_rounded,
    ),
  ],
  payload: (v) => {
    'judul': v['judul'],
    'kurikulumId': (v['kurikulumId'] ?? '').isEmpty ? null : v['kurikulumId'],
    'mapelId': (v['mapelId'] ?? '').isEmpty ? null : v['mapelId'],
    'kompetensiDasar': (v['kompetensiDasar'] ?? '').isEmpty ? null : v['kompetensiDasar'],
    'materiPokok': (v['materiPokok'] ?? '').isEmpty ? null : v['materiPokok'],
    'alokasiWaktu': (v['alokasiWaktu'] ?? '').isEmpty ? null : v['alokasiWaktu'],
  },
  deleteMessage: (s) => 'Hapus "${s['judul']}"?',
  leading: (s, fg) => Icon(Icons.description_rounded, size: 22, color: fg),
  subtitle: (s) {
    final kd = _s(s['kompetensiDasar']);
    final waktu = _s(s['alokasiWaktu']);
    final mapel = _relName(s['mapel'], 'namaMapel');
    final kur = _relName(s['kurikulum'], 'nama');
    final tags = <Widget>[
      if (mapel.isNotEmpty) _pill(Icons.school_outlined, mapel),
      if (kur.isNotEmpty) _pill(Icons.folder_copy_outlined, kur),
      if (waktu.isNotEmpty) _pill(Icons.schedule_rounded, waktu),
    ];
    if (kd.isEmpty && tags.isEmpty) return _muted('Belum ada detail');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kd.isNotEmpty)
          Text(kd,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.35)),
        if (kd.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 6),
        if (tags.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: tags),
      ],
    );
  },
);

final _rppCfg = _CrudConfig(
  url: () => ApiUrl.rpp,
  singular: 'RPP',
  nameKey: 'judul',
  icon: Icons.menu_book_rounded,
  fabIcon: Icons.post_add_rounded,
  fabLabel: 'RPP baru',
  sectionTitle: 'Daftar RPP',
  emptyTitle: 'Belum ada RPP',
  emptyMessage: 'Tambahkan RPP pertama lewat tombol "RPP baru" di bawah.',
  formHint: 'Isi judul dan pertemuan ke berapa. Kalau pertemuan dikosongkan, tersimpan sebagai pertemuan 1.',
  fields: const [
    _FieldSpec(
      key: 'judul',
      label: 'Judul RPP',
      hint: 'Contoh: Pengenalan Thaharah',
      icon: Icons.menu_book_outlined,
      required: true,
    ),
    _FieldSpec(
      key: 'mapelId',
      label: 'Mata Pelajaran',
      hint: 'Pilih mata pelajaran',
      icon: Icons.school_outlined,
      source: _Src.mapel,
    ),
    _FieldSpec(
      key: 'pertemuan',
      label: 'Pertemuan ke-',
      hint: 'Contoh: 1',
      icon: Icons.tag_rounded,
      numeric: true,
    ),
    _FieldSpec(
      key: 'tujuan',
      label: 'Tujuan',
      hint: 'Tujuan pembelajaran',
      icon: Icons.flag_outlined,
      multiline: true,
    ),
    _FieldSpec(
      key: 'kegiatan',
      label: 'Kegiatan Pembelajaran',
      hint: 'Langkah kegiatan di kelas',
      icon: Icons.groups_2_outlined,
      multiline: true,
    ),
    _FieldSpec(
      key: 'penilaian',
      label: 'Penilaian',
      hint: 'Cara menilai hasil belajar',
      icon: Icons.fact_check_outlined,
      multiline: true,
    ),
  ],
  payload: (v) => {
    'judul': v['judul'],
    'mapelId': (v['mapelId'] ?? '').isEmpty ? null : v['mapelId'],
    'pertemuan': int.tryParse(v['pertemuan'] ?? '') ?? 1,
    'tujuan': (v['tujuan'] ?? '').isEmpty ? null : v['tujuan'],
    'kegiatan': (v['kegiatan'] ?? '').isEmpty ? null : v['kegiatan'],
    'penilaian': (v['penilaian'] ?? '').isEmpty ? null : v['penilaian'],
  },
  deleteMessage: (r) => 'Hapus "${r['judul']}"?',
  leading: (r, fg) => Text(
    'P${r['pertemuan'] ?? '-'}',
    style: sty(15, FontWeight.w800, fg),
  ),
  subtitle: (r) {
    final tujuan = _s(r['tujuan']);
    final kegiatan = _s(r['kegiatan']);
    final mapel = _relName(r['mapel'], 'namaMapel');
    if (tujuan.isEmpty && kegiatan.isEmpty && mapel.isEmpty) return _muted('Belum ada detail');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mapel.isNotEmpty) ...[
          _pill(Icons.school_outlined, mapel),
          if (tujuan.isNotEmpty || kegiatan.isNotEmpty) const SizedBox(height: 6),
        ],
        if (tujuan.isNotEmpty)
          Text(tujuan,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sty(12, FontWeight.w600, SC.inkSecondary, h: 1.35)),
        if (tujuan.isNotEmpty && kegiatan.isNotEmpty) const SizedBox(height: 3),
        if (kegiatan.isNotEmpty)
          Text(kegiatan,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sty(12, FontWeight.w500, SC.inkMuted, h: 1.35)),
      ],
    );
  },
);

// =====================================================================
// Banner notifikasi inline (gaya absensi, menempel di halaman, tidak mengambang)
// =====================================================================
mixin _BannerMixin<T extends StatefulWidget> on State<T> {
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  void toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
    _bannerTimer = Timer(Duration(seconds: error ? 5 : 3), closeBanner);
  }

  void closeBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerTitle = null);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Widget bannerWidget() {
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
              margin: const EdgeInsets.only(top: 6, bottom: 8),
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
                    onPressed: closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, size: 18, color: fg.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
    );
  }
}

// =====================================================================
// Satu tab (dipakai untuk Kurikulum, Silabus, dan RPP)
// =====================================================================
class _CrudTab extends StatefulWidget {
  const _CrudTab({required this.cfg});

  final _CrudConfig cfg;

  @override
  State<_CrudTab> createState() => _CrudTabState();
}

class _CrudTabState extends State<_CrudTab>
    with _BannerMixin<_CrudTab>, AutomaticKeepAliveClientMixin<_CrudTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  _CrudConfig get c => widget.cfg;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
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
      final res = await AppScope.of(context).api.get(c.url());
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

  Future<List<Map<String, String>>> _loadOptions(_Src src) async {
    try {
      final res = await AppScope.of(context).api.get(
            src == _Src.mapel ? ApiUrl.mapel : ApiUrl.kurikulum,
          );
      final List<dynamic> list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : <dynamic>[]);
      return [
        for (final e in list)
          if (e is Map)
            <String, String>{
              'id': _s(e['id']),
              'label': _s(src == _Src.mapel ? e['namaMapel'] : e['nama']),
            },
      ];
    } on ApiException {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) async {
    final initial = {
      for (final f in c.fields) f.key: (existing?[f.key] ?? '').toString(),
    };
    final options = <_Src, List<Map<String, String>>>{};
    for (final src in {for (final f in c.fields) if (f.source != null) f.source!}) {
      options[src] = await _loadOptions(src);
    }
    if (!mounted) return null;
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _FormScreen(
          title: existing == null ? 'Tambah ${c.singular}' : 'Edit ${c.singular}',
          subtitle: existing == null ? 'Lengkapi data lalu simpan' : 'Perbarui data lalu simpan',
          icon: c.icon,
          hint: c.formHint,
          saveLabel: existing == null ? 'Simpan ${c.singular}' : 'Simpan Perubahan',
          autofocusFirst: existing == null,
          fields: c.fields,
          options: options,
          initial: initial,
          payload: c.payload,
        ),
      ),
    );
  }

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(c.url(), result);
      if (!mounted) return;
      toast('${c.singular} berhasil ditambah', subtitle: '"${result[c.nameKey]}" masuk ke daftar');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) toast(e.message, error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final result = await _form(item);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${c.url()}/${item['id']}', result);
      if (!mounted) return;
      toast('${c.singular} diperbarui', subtitle: '"${result[c.nameKey]}" berhasil disimpan');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) toast(e.message, error: true);
    }
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Hapus ${c.singular}?',
        message: c.deleteMessage(item),
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${c.url()}/${item['id']}');
      if (!mounted) return;
      toast('${c.singular} dihapus', subtitle: '"${item[c.nameKey]}" sudah dihapus');
      _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) toast(e.message, error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        RefreshIndicator(
          color: SC.primary,
          onRefresh: () => _load(spinner: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              bannerWidget(),
              ..._body(),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: _add,
            tooltip: 'Tambah ${c.singular}',
            backgroundColor: SC.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: SC.gold.withOpacity(0.6)),
            ),
            icon: Icon(c.fabIcon, size: 18, color: SC.gold),
            label: Text(c.fabLabel, style: sty(13, FontWeight.w700, Colors.white)),
          ),
        ),
      ],
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return [SizedBox(height: 280, child: loadingView())];
    }
    if (_error != null) {
      return [SizedBox(height: 280, child: errorView(_error!, () => _load()))];
    }
    if (_items.isEmpty) {
      return [_EmptyState(icon: c.icon, title: c.emptyTitle, message: c.emptyMessage)];
    }
    return [
      _SectionHeader(icon: c.icon, title: c.sectionTitle, count: _items.length),
      for (int i = 0; i < _items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _itemTile(i, _items[i] as Map<String, dynamic>),
        ),
    ];
  }

  Widget _itemTile(int index, Map<String, dynamic> item) {
    final even = index.isEven;
    final fg = even ? SC.primary : SC.gold;

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
          onTap: () => _edit(item),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: even ? SC.primary : SC.gold),
                Expanded(
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
                            color: even ? SC.sage : SC.goldSurface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: c.leading(item, fg),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _s(item[c.nameKey]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: sty(14.5, FontWeight.w800, SC.ink, h: 1.25),
                                ),
                                if (c.subtitle(item) != null) ...[
                                  const SizedBox(height: 6),
                                  c.subtitle(item)!,
                                ],
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Opsi',
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: SC.inkSecondary),
                          color: SC.surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (v) {
                            if (v == 'edit') _edit(item);
                            if (v == 'hapus') _hapus(item);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                const Icon(Icons.edit_outlined, size: 18, color: SC.ink),
                                const SizedBox(width: 10),
                                Text('Edit ${c.singular}', style: sty(13, FontWeight.w600, SC.ink)),
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

// =====================================================================
// Komponen bersama
// =====================================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, required this.count});

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: SC.sage, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 14, color: SC.primary),
          ),
          const SizedBox(width: 9),
          Text(title, style: sty(14, FontWeight.w800, SC.ink)),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
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
          Text(title, textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
        child: const Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
      ),
      title: Text(title, textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
      content: Text(
        message,
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
          onPressed: () => Navigator.pop(context, false),
          child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SC.errorText,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text('Ya, hapus', style: sty(13, FontWeight.w700, Colors.white)),
        ),
      ],
    );
  }
}

// =====================================================================
// Halaman form tambah / edit (dipakai ketiga tab)
// =====================================================================
class _FormScreen extends StatefulWidget {
  const _FormScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hint,
    required this.saveLabel,
    required this.autofocusFirst,
    required this.fields,
    required this.initial,
    required this.options,
    required this.payload,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String hint;
  final String saveLabel;
  final bool autofocusFirst;
  final List<_FieldSpec> fields;
  final Map<String, String> initial;
  final Map<_Src, List<Map<String, String>>> options;
  final Map<String, dynamic> Function(Map<String, String> v) payload;

  @override
  State<_FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<_FormScreen> {
  late final Map<String, TextEditingController> _c = {
    for (final f in widget.fields) f.key: TextEditingController(text: widget.initial[f.key] ?? ''),
  };
  final Map<String, String> _err = {};

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    _err.clear();
    for (final f in widget.fields) {
      if (f.required && _c[f.key]!.text.trim().isEmpty) {
        _err[f.key] = '${f.label} wajib diisi';
      }
    }
    if (_err.isNotEmpty) {
      setState(() {});
      return;
    }
    Navigator.pop(context, widget.payload({
      for (final e in _c.entries) e.key: e.value.text.trim(),
    }));
  }

  InputDecoration _deco(_FieldSpec f) {
    return InputDecoration(
      hintText: f.hint,
      hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
      errorText: _err[f.key],
      errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
      prefixIcon: f.multiline ? null : Icon(f.icon, size: 20, color: SC.primary),
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
                Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(20, FontWeight.w800, Colors.white, h: 1.15)),
                const SizedBox(height: 3),
                Text(widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78))),
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
            child: Icon(widget.icon, size: 22, color: SC.gold),
          ),
        ],
      ),
    );
  }

  Widget _picker(_FieldSpec f) {
    final opts = widget.options[f.source] ?? const <Map<String, String>>[];
    final raw = _c[f.key]!.text;
    final current = opts.any((o) => o['id'] == raw) ? raw : '';
    return InputDecorator(
      decoration: _deco(f),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: SC.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: SC.inkSecondary),
          style: sty(14, FontWeight.w600, SC.ink),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: '',
              child: Text('Belum dipilih', style: sty(14, FontWeight.w500, SC.inkMuted)),
            ),
            for (final o in opts)
              DropdownMenuItem(
                value: o['id']!,
                child: Text(
                  o['label']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(14, FontWeight.w600, SC.ink),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _c[f.key]!.text = v ?? ''),
        ),
      ),
    );
  }

  Widget _field(int index, _FieldSpec f) {
    final last = index == widget.fields.length - 1;
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Text(f.label, style: sty(12.5, FontWeight.w800, SC.ink)),
                if (!f.required) ...[
                  const SizedBox(width: 6),
                  Text('(opsional)', style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                ],
              ],
            ),
          ),
          f.source != null ? _picker(f) : TextField(
            controller: _c[f.key],
            autofocus: widget.autofocusFirst && index == 0,
            keyboardType: f.numeric
                ? TextInputType.number
                : (f.multiline ? TextInputType.multiline : TextInputType.text),
            textCapitalization:
                f.numeric ? TextCapitalization.none : TextCapitalization.sentences,
            textInputAction: f.multiline
                ? TextInputAction.newline
                : (last ? TextInputAction.done : TextInputAction.next),
            minLines: f.multiline ? 2 : 1,
            maxLines: f.multiline ? 4 : 1,
            onSubmitted: (!f.multiline && last) ? (_) => _submit() : null,
            style: sty(14, FontWeight.w600, SC.ink),
            onChanged: (_) {
              if (_err.containsKey(f.key)) setState(() => _err.remove(f.key));
            },
            decoration: _deco(f),
          ),
        ],
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SC.goldSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SC.gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: SC.surface, shape: BoxShape.circle),
                            child: Icon(widget.icon, size: 20, color: SC.gold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(widget.hint,
                                style: sty(12, FontWeight.w500, SC.goldDark, h: 1.4)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SC.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SC.border),
                        boxShadow: softShadow,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < widget.fields.length; i++) _field(i, widget.fields[i]),
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
                            label: Text(widget.saveLabel, style: sty(14, FontWeight.w700, Colors.white)),
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