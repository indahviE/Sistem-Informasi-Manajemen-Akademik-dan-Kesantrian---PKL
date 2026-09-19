import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class PembinaanKarakterScreen extends StatefulWidget {
  const PembinaanKarakterScreen({super.key});

  @override
  State<PembinaanKarakterScreen> createState() => _PembinaanKarakterScreenState();
}

class _PembinaanKarakterScreenState extends State<PembinaanKarakterScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
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
      final res = await api.get(ApiUrl.pembinaanKarakter);
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
    final kategori = TextEditingController();
    final catatan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.emoji_events_rounded,
          title: 'Catat Pembinaan Karakter',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TextField(
              controller: kategori,
              decoration: const InputDecoration(labelText: 'Kategori', hintText: 'Contoh: Kedisiplinan'),
            ),
            TextField(
              controller: catatan,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan', alignLabelWithHint: true),
            ),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (santriId == null || kategori.text.trim().isEmpty || catatan.text.trim().isEmpty) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.pembinaanKarakter, {
        'santriId': santriId,
        'tanggal':
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'kategori': kategori.text.trim(),
        'catatan': catatan.text.trim(),
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembinaan karakter dicatat.')));
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
              tooltip: 'Catat Pembinaan Karakter',
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada catatan pembinaan karakter.')
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
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: Tw.indigoSoft, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.emoji_events, color: Tw.indigo, size: 22),
                              ),
                              title: Text(p['kategori'] as String),
                              subtitle: Text(
                                '${santri['nama'] ?? ''} • ${(p['tanggal'] as String).substring(0, 10)}\n${p['catatan'] ?? ''}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}