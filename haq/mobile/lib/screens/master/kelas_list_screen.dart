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
  const KelasListScreen({super.key});

  @override
  State<KelasListScreen> createState() => _KelasListScreenState();
}

class _KelasListScreenState extends State<KelasListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _add() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _KelasFormDialog(),
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(existing: kelas),
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

  int _santriCount(Map<String, dynamic> k) {
    final c = k['_count'];
    if (c is Map) {
      final v = c['santris'];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _KC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Sama seperti dashboard: dibatasi 480 supaya di web tetap proporsional.
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Column(
                children: [
                  if (!_loading && _error == null) _header(),
                  Expanded(child: _body()),
                ],
              ),
              // Posisi relatif ke kolom 480px, jadi di web tetap nempel di konten.
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Data Kelas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _KC.sage, borderRadius: BorderRadius.circular(999)),
            child: Text('${_items.length} Kelas',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _KC.primary)),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_items.isEmpty) return emptyView('Belum ada kelas.');
    return RefreshIndicator(
      color: _KC.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: _items.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _kelasCard(_items[i] as Map<String, dynamic>),
        ),
      ),
    );
  }

  Widget _kelasCard(Map<String, dynamic> k) {
    final nama = k['namaKelas']?.toString() ?? '-';
    final tingkat = k['tingkat']?.toString().trim() ?? '';
    final jumlah = _santriCount(k);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: _KC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _KC.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _KC.sage, borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _KC.ink)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (tingkat.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _KC.mint, borderRadius: BorderRadius.circular(999)),
                        child: Text('Tingkat $tingkat',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700, color: _KC.primary)),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_2_outlined, size: 14, color: _KC.inkSecondary),
                        const SizedBox(width: 4),
                        Text('$jumlah santri',
                            style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: _KC.inkSecondary),
            tooltip: 'Edit',
            onPressed: () => _edit(k),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: _KC.errorText),
            tooltip: 'Hapus',
            onPressed: () => _delete(k),
          ),
        ],
      ),
    );
  }
}

/// Dialog tambah/edit kelas. Dibuat sebagai widget sendiri supaya controller-nya
/// di-dispose dengan aman (tidak error saat animasi dialog menutup).
class _KelasFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _KelasFormDialog({this.existing});

  @override
  State<_KelasFormDialog> createState() => _KelasFormDialogState();
}

class _KelasFormDialogState extends State<_KelasFormDialog> {
  late final TextEditingController _nama;
  late final TextEditingController _tingkat;
  String? _err;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?['namaKelas']?.toString() ?? '');
    _tingkat = TextEditingController(text: widget.existing?['tingkat']?.toString() ?? '');
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
    Navigator.pop(context, {
      'namaKelas': _nama.text.trim(),
      'tingkat': _tingkat.text.trim(),
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
              ),
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