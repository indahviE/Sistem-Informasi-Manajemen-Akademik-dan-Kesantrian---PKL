import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class PembinaanIbadahScreen extends StatefulWidget {
  const PembinaanIbadahScreen({super.key});

  @override
  State<PembinaanIbadahScreen> createState() => _PembinaanIbadahScreenState();
}

class _PembinaanIbadahScreenState extends State<PembinaanIbadahScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
  bool _loading = true;
  String? _error;

  static const _statusOptions = [
    DropdownOption('HADIR', 'Hadir'),
    DropdownOption('IZIN', 'Izin'),
    DropdownOption('ALPA', 'Alpa'),
  ];

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
      final res = await api.get(ApiUrl.pembinaanIbadah);
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
    final jenisIbadah = TextEditingController();
    final catatan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;
    String status = 'HADIR';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.mosque_rounded,
          title: 'Catat Pembinaan Ibadah',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TextField(
              controller: jenisIbadah,
              decoration: const InputDecoration(labelText: 'Jenis Ibadah', hintText: 'Contoh: Sholat Subuh berjamaah'),
            ),
            TwSelect(
              value: status,
              label: 'Status',
              options: _statusOptions,
              onChanged: (v) => setLocal(() => status = v ?? 'HADIR'),
            ),
            TextField(controller: catatan, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (santriId == null || jenisIbadah.text.trim().isEmpty) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.pembinaanIbadah, {
        'santriId': santriId,
        'jenisIbadah': jenisIbadah.text.trim(),
        'tanggal':
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'status': status,
        'catatan': catatan.text.trim().isEmpty ? null : catatan.text.trim(),
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rekap ibadah tersimpan.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'HADIR':
        return Tw.teal;
      case 'IZIN':
        return Tw.amber;
      default:
        return Tw.red;
    }
  }

  Color _statusSoft(String s) {
    switch (s) {
      case 'HADIR':
        return Tw.tealSoft;
      case 'IZIN':
        return Tw.amberSoft;
      default:
        return Tw.redSoft;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'HADIR':
        return 'Hadir';
      case 'IZIN':
        return 'Izin';
      default:
        return 'Alpa';
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
              tooltip: 'Catat Pembinaan Ibadah',
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada rekap pembinaan ibadah.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i] as Map<String, dynamic>;
                          final santri = (p['santri'] as Map?) ?? {};
                          final status = p['status'] as String? ?? 'HADIR';
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: _statusSoft(status), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.mosque, color: _statusColor(status), size: 22),
                              ),
                              title: Text(p['jenisIbadah'] as String),
                              subtitle: Text('${santri['nama'] ?? ''} • ${(p['tanggal'] as String).substring(0, 10)}'),
                              trailing: twBadge(context, _statusLabel(status), color: _statusColor(status), soft: _statusSoft(status)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}