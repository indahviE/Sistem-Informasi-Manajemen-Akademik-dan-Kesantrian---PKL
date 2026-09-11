import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class UstadzListScreen extends StatefulWidget {
  const UstadzListScreen({super.key});

  @override
  State<UstadzListScreen> createState() => _UstadzListScreenState();
}

class _UstadzListScreenState extends State<UstadzListScreen> {
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
      final res = await api.get(ApiUrl.ustadz);
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
    final nama = TextEditingController(text: existing?['nama'] as String? ?? '');
    final noHp = TextEditingController(text: existing?['noHp'] as String? ?? '');
    String jenis = existing?['jenis'] as String? ?? 'GURU';
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.person_rounded,
          title: existing == null ? 'Tambah Ustadz / Pembina' : 'Edit Ustadz / Pembina',
          fields: [
            TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: noHp, decoration: const InputDecoration(labelText: 'No HP')),
            TwSelect(
              value: jenis,
              label: 'Jenis',
              options: const [
                DropdownOption('GURU', 'Guru'),
                DropdownOption('MUSYRIF', 'Musyrif / Pembina'),
              ],
              onChanged: (v) => setLocal(() => jenis = v!),
            ),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nama.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'nama': nama.text.trim(),
                  'noHp': noHp.text.trim().isEmpty ? null : noHp.text.trim(),
                  'jenis': jenis,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    return hasil;
  }

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.ustadz, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ustadz berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(Map<String, dynamic> ustadz) async {
    final result = await _form(ustadz);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.ustadz}/${ustadz['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ustadz diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Map<String, dynamic> ustadz) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus ustadz?'),
        content: Text('Ustadz "${ustadz['nama']}" akan dihapus permanen.'),
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
      await AppScope.of(context).api.delete('${ApiUrl.ustadz}/${ustadz['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ustadz dihapus')));
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
                  ? emptyView('Belum ada ustadz / pembina.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final u = _items[i] as Map<String, dynamic>;
                          final isMusyrif = u['jenis'] == 'MUSYRIF';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isMusyrif ? Tw.tealSoft : Tw.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(isMusyrif ? Icons.home_rounded : Icons.person,
                                    color: isMusyrif ? Tw.teal : Tw.primary),
                              ),
                              title: Text(u['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                isMusyrif ? 'Musyrif / Pembina' : 'Guru',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _delete(u),
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
