import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';
import 'santri_detail_screen.dart';
import 'santri_form_screen.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'search': q ?? '', 'perPage': '50'});
      if (!mounted) return;
      setState(() {
        _items = (res['items'] as List? ?? []);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _hapus(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Santri'),
        content: Text('Hapus "${s['nama']}" (NIS ${s['nis']}) beserta semua datanya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.santri}/${s['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Santri dihapus')));
      _load(q: _search.text);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const SantriFormScreen()));
          if (created == true) _load(q: _search.text);
        },
        tooltip: 'Tambah Santri',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onSubmitted: (v) => _load(q: v),
              decoration: InputDecoration(
                hintText: 'Cari nama / NIS',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _search.clear();
                        _load();
                      }),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, () => _load(q: _search.text));
    if (_items.isEmpty) return emptyView('Belum ada data santri.');
    return RefreshIndicator(
      onRefresh: () => _load(q: _search.text),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final s = _items[i] as Map<String, dynamic>;
          final kelas = (s['kelas'] as Map?)?['namaKelas'];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${s['nama']}'.substring(0, 1).toUpperCase())),
              title: Text(s['nama'] as String),
              subtitle: Text('NIS ${s['nis']}${kelas != null ? ' • $kelas' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Tw.red, size: 20),
                    tooltip: 'Hapus',
                    onPressed: () => _hapus(s),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: s['id'] as String))),
            ),
          );
        },
      ),
    );
  }
}