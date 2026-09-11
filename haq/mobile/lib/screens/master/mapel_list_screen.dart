import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class MapelListScreen extends StatefulWidget {
  const MapelListScreen({super.key});

  @override
  State<MapelListScreen> createState() => _MapelListScreenState();
}

class _MapelListScreenState extends State<MapelListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.mapel);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) async {
    final nama = TextEditingController(text: existing?['namaMapel'] as String? ?? '');
    final kode = TextEditingController(text: existing?['kode'] as String? ?? '');
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.book_rounded,
        title: existing == null ? 'Tambah Mata Pelajaran' : 'Edit Mata Pelajaran',
        fields: [
          TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Mapel')),
          TextField(controller: kode, decoration: const InputDecoration(labelText: 'Kode (opsional)')),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (nama.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'namaMapel': nama.text.trim(),
                'kode': kode.text.trim().isEmpty ? null : kode.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return hasil;
  }

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.mapel, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mapel berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(Map<String, dynamic> mapel) async {
    final result = await _form(mapel);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.mapel}/${mapel['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mapel diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Map<String, dynamic> mapel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus mapel?'),
        content: Text('Mapel "${mapel['namaMapel']}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.mapel}/${mapel['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mapel dihapus')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Tambah',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada mata pelajaran.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final m = _items[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.indigoSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.menu_book, color: Tw.purple),
                              ),
                              title: Text(m['namaMapel'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${m['kode'] ?? ''}'.trim().isEmpty ? '—' : 'Kode ${m['kode']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _delete(m),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
