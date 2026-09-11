import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class KunjunganScreen extends StatefulWidget {
  const KunjunganScreen({super.key});

  @override
  State<KunjunganScreen> createState() => _KunjunganScreenState();
}

class _KunjunganScreenState extends State<KunjunganScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
  List<Map<String, dynamic>> _walis = [];
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
      final res = await api.get(ApiUrl.kunjungan);
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
        final w = await api.get(ApiUrl.wali);
        if (mounted) setState(() {
          _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>();
          _walis = (w as List).cast<Map<String, dynamic>>();
        });
      } catch (_) {}
    }
    final catatan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;
    String? waliId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.groups_rounded,
          title: 'Log Kunjungan Wali',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TwSelect(
              value: waliId ?? '',
              label: 'Wali',
              options: [
                const DropdownOption('', '— tanpa wali —'),
                for (final w in _walis) DropdownOption(w['id'] as String, w['nama'] as String),
              ],
              onChanged: (v) => setLocal(() => waliId = v == '' ? null : v),
            ),
            TextField(controller: catatan, decoration: const InputDecoration(labelText: 'Catatan')),
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
      await api.post(ApiUrl.kunjungan, {
        'santriId': santriId,
        'waliId': waliId,
        'catatan': catatan.text.trim().isEmpty ? null : catatan.text.trim(),
        'tanggal': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunjungan tercatat.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Catat Kunjungan',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada kunjungan wali.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final k = _items[i] as Map<String, dynamic>;
                          final santri = (k['santri'] as Map?) ?? {};
                          final wali = (k['wali'] as Map?) ?? {};
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.people)),
                              title: Text('${santri['nama'] ?? ''} dikunjungi ${wali['nama'] ?? '-'}'),
                              subtitle: Text('${(k['tanggal'] as String).substring(0, 10)}${k['catatan'] != null ? ' • ${k['catatan']}' : ''}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}