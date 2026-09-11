import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

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
    _load();
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

  Future<void> _add() async {
    final result = await _formKelas();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.kelas, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<Map<String, dynamic>?> _formKelas([Map<String, dynamic>? existing]) async {
    final nama = TextEditingController(text: existing?['namaKelas'] as String? ?? '');
    final tingkat = TextEditingController(text: existing?['tingkat'] as String? ?? '');
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.meeting_room_rounded,
        title: existing == null ? 'Tambah Kelas' : 'Edit Kelas',
        fields: [
          TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Kelas')),
          TextField(controller: tingkat, decoration: const InputDecoration(labelText: 'Tingkat')),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (nama.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'namaKelas': nama.text.trim(), 'tingkat': tingkat.text.trim()});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return hasil;
  }

  Future<void> _edit(Map<String, dynamic> kelas) async {
    final result = await _formKelas(kelas);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.kelas}/${kelas['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas berhasil diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Map<String, dynamic> kelas) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kelas?'),
        content: Text('Kelas "${kelas['namaKelas']}" akan dihapus permanen.'),
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
      await AppScope.of(context).api.delete('${ApiUrl.kelas}/${kelas['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas dihapus')));
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
        tooltip: 'Tambah Kelas',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada kelas.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final k = _items[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.class_, color: Tw.primary),
                              ),
                              title: Text(k['namaKelas'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Tingkat ${k['tingkat']} • ${(k['_count'] as Map)['santris'] ?? 0} santri'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(k),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _delete(k),
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
