import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class PelanggaranScreen extends StatefulWidget {
  const PelanggaranScreen({super.key});

  @override
  State<PelanggaranScreen> createState() => _PelanggaranScreenState();
}

class _PelanggaranScreenState extends State<PelanggaranScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
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
      final res = await api.get(ApiUrl.pelanggaran);
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
    if (_santris.isEmpty) {
      try {
        final api = AppScope.of(context).api;
        final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
        if (mounted) setState(() => _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    final jenis = TextEditingController();
    final poin = TextEditingController();
    final tindak = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.gavel_rounded,
          title: 'Catat Pelanggaran',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TextField(controller: jenis, decoration: const InputDecoration(labelText: 'Jenis Pelanggaran')),
            TextField(controller: poin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poin')),
            TextField(controller: tindak, decoration: const InputDecoration(labelText: 'Tindak Lanjut')),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.pelanggaran, {
        'santriId': santriId,
        'jenisPelanggaran': jenis.text.trim(),
        'poin': int.tryParse(poin.text) ?? 0,
        'tindakLanjut': tindak.text.trim().isEmpty ? null : tindak.text.trim(),
        'tanggal': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggaran dicatat. Wali mendapat notifikasi.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWali = AppScope.of(context).user?.isWali == true;
    return Scaffold(
      floatingActionButton: isWali
          ? null
          : FloatingActionButton(
              onPressed: _add,
              tooltip: 'Catat Pelanggaran',
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada pelanggaran.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i] as Map<String, dynamic>;
                          final santri = (p['santri'] as Map?) ?? {};
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.gavel, color: Colors.white)),
                              title: Text(p['jenisPelanggaran'] as String),
                              subtitle: Text('${santri['nama'] ?? ''} • ${(p['tanggal'] as String).substring(0, 10)}'),
                              trailing: Text('${p['poin']} poin', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}