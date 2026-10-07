import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

/// Palet sama persis dengan `_WC` di dashboard_screen.dart.
class _KC {
  _KC._();

  static Color get primary => SC.primary;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorText = Color(0xFF991B1B);
}

class KelasListScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (mis. dari dashboard) supaya ada
  /// AppBar + tombol kembali. Kalau dipakai sebagai tab di shell, biarkan false.
  final bool showBack;
  const KelasListScreen({super.key, this.showBack = false});

  @override
  State<KelasListScreen> createState() => _KelasListScreenState();
}

class _KelasListScreenState extends State<KelasListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _tingkatFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.kelas);
      if (!mounted) return;
      setState(() {
        _items = res is List ? res : ((res is Map ? res['items'] : null) as List? ?? []);
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
          _error = 'Gagal memuat daftar kelas.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Daftar ustadz untuk dropdown Wali Kelas. null = gagal dimuat.
  Future<List<Map<String, dynamic>>?> _loadUstadz() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ustadz);
      final list = res is List ? res : ((res is Map ? res['items'] : null) as List? ?? []);
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _add() async {
    final ustadz = await _loadUstadz();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(ustadzList: ustadz),
    );
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.kelas, result);
      _snack('Kelas berhasil ditambah');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _edit(Map<String, dynamic> kelas) async {
    final ustadz = await _loadUstadz();
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(existing: kelas, ustadzList: ustadz),
    );
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.kelas}/${kelas['id']}', result);
      _snack('Kelas berhasil diperbarui');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _delete(Map<String, dynamic> kelas) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _KC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Kelas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
        content: Text(
          'Kelas "${kelas['namaKelas']}" akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, color: _KC.inkSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _KC.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _KC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.kelas}/${kelas['id']}');
      _snack('Kelas dihapus');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  // ---------------------------------------------------------------------
  // Helper data (semua null-safe)
  // ---------------------------------------------------------------------
  List<Map<String, dynamic>> get _all => _items.whereType<Map<String, dynamic>>().toList();

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
  bool get _adaDataWali =>
      _all.any((k) => k.containsKey('waliKelas') || k.containsKey('waliKelasNama'));

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
      if (_tingkatFilter != 'Semua' && (k['tingkat']?.toString().trim() ?? '') != _tingkatFilter) {
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
      backgroundColor: _KC.background,
      appBar: widget.showBack
          ? AppBar(
              backgroundColor: _KC.background,
              foregroundColor: _KC.ink,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text('Rombel & Halaqah',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              _body(),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _add,
                  tooltip: 'Tambah Kelas',
                  backgroundColor: _KC.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Kelas Baru',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_items.isEmpty) return emptyView('Belum ada kelas. Tap "Kelas Baru" untuk menambah.');

    final list = _filtered();
    return RefreshIndicator(
      color: _KC.primary,
      onRefresh: _load,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Tidak ada kelas yang cocok.',
                    style: TextStyle(fontSize: 12.5, color: _KC.inkSecondary)),
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
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: warn ? _KC.gold : Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.72))),
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
          BoxShadow(color: SC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _KC.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('ROMBEL & HALAQAH',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: _KC.gold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('${all.length}', 'Total Kelas'),
              stat('$totalSantri', 'Total Santri'),
              if (_adaDataWali) stat('$tanpaWali', 'Tanpa Wali Kelas', warn: tanpaWali > 0),
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
      style: const TextStyle(fontSize: 13.5, color: _KC.ink),
      decoration: InputDecoration(
        hintText: _adaDataWali ? 'Cari nama kelas atau wali kelas' : 'Cari nama kelas',
        hintStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
        prefixIcon: const Icon(Icons.search, size: 19, color: _KC.inkSecondary),
        filled: true,
        fillColor: _KC.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: b(_KC.border),
        enabledBorder: b(_KC.border),
        focusedBorder: b(_KC.primary, 1.4),
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
                color: selected ? _KC.primary : _KC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _KC.primary : _KC.border),
              ),
              child: Text(
                l == 'Semua' ? l : 'Tingkat $l',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _KC.inkSecondary,
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
      decoration: BoxDecoration(color: bg ?? _KC.mint, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg ?? _KC.primary)),
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

    return Material(
      color: _KC.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _edit(k),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: perluWali ? const Color(0xFFE7D2A7) : _KC.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: perluWali ? _KC.gold : _KC.primary),
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
                                decoration:
                                    BoxDecoration(color: _KC.sage, borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.class_, size: 20, color: _KC.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w800, color: _KC.ink)),
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (tingkat.isNotEmpty) _chip('Tingkat $tingkat'),
                                        if (jenis != null)
                                          _chip(jenis, bg: _KC.goldSurface, fg: const Color(0xFF7A5B10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Aksi',
                                icon: const Icon(Icons.more_vert, size: 20, color: _KC.inkSecondary),
                                color: _KC.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (v) {
                                  if (v == 'edit') _edit(k);
                                  if (v == 'hapus') _delete(k);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit', style: TextStyle(fontSize: 13)),
                                  ),
                                  PopupMenuItem(
                                    value: 'hapus',
                                    child: Text('Hapus',
                                        style: TextStyle(fontSize: 13, color: _KC.errorText)),
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
                                  wali != null ? Icons.person_outline : Icons.person_off_outlined,
                                  size: 15,
                                  color: wali != null ? _KC.inkSecondary : const Color(0xFFB78103),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    wali != null ? 'Wali Kelas: $wali' : 'Belum ada wali kelas',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: wali != null ? FontWeight.w600 : FontWeight.w700,
                                      color: wali != null ? _KC.ink : const Color(0xFFB78103),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.groups_2_outlined, size: 15, color: _KC.inkSecondary),
                              const SizedBox(width: 6),
                              Text(
                                kapasitas != null ? '$jumlah / $kapasitas santri' : '$jumlah santri',
                                style: const TextStyle(fontSize: 12, color: _KC.inkSecondary),
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
                                  backgroundColor: _KC.surfaceDim,
                                  valueColor: AlwaysStoppedAnimation(
                                    jumlah > kapasitas ? _KC.errorText : _KC.primary,
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

  InputDecoration _dec(String hint) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: _KC.inkSecondary),
      filled: true,
      fillColor: _KC.surfaceDim,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(_KC.primary, 1.4),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: _KC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: _KC.sage, shape: BoxShape.circle),
            child: Icon(Icons.meeting_room_rounded, size: 17, color: _KC.primary),
          ),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit Kelas' : 'Tambah Kelas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
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
                style: const TextStyle(fontSize: 14, color: _KC.ink),
                decoration: _dec('Contoh: 7A'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(_err!, style: const TextStyle(fontSize: 11.5, color: _KC.errorText)),
                ),
              ],
              const SizedBox(height: 12),
              _label('Tingkat'),
              TextField(
                controller: _tingkat,
                style: const TextStyle(fontSize: 14, color: _KC.ink),
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
                  dropdownColor: _KC.surface,
                  style: const TextStyle(fontSize: 14, color: _KC.ink),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Belum ditentukan')),
                    for (final u in widget.ustadzList!
                        .where((u) => u['jenis'] != 'MUSYRIF' || u['id']?.toString() == _waliId))
                      DropdownMenuItem<String?>(
                        value: u['id']?.toString(),
                        child: Text(
                          '${u['nama'] ?? '-'}${u['jenis'] == 'MUSYRIF' ? ' (Musyrif)' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _waliId = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _KC.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _KC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: _submit,
          child: const Text('Simpan',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}