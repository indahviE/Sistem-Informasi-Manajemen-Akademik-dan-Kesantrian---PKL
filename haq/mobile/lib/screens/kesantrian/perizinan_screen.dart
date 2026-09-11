import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class PerizinanScreen extends StatefulWidget {
  const PerizinanScreen({super.key});

  @override
  State<PerizinanScreen> createState() => _PerizinanScreenState();
}

class _PerizinanScreenState extends State<PerizinanScreen> {
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
      final res = await api.get(ApiUrl.perizinan);
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
    final alasan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;
    String jenis = 'KELUAR';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Ajukan Perizinan',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TwSelect(
              value: jenis,
              label: 'Jenis',
              options: const [
                DropdownOption('KELUAR', 'Izin Keluar'),
                DropdownOption('PULANG', 'Pulang'),
              ],
              onChanged: (v) => setLocal(() => jenis = v!),
            ),
            TextField(controller: alasan, decoration: const InputDecoration(labelText: 'Alasan')),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajukan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.perizinan, {
        'santriId': santriId,
        'jenis': jenis,
        'alasan': alasan.text.trim(),
        'tanggalKeluar': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perizinan diajukan.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _action(Map<String, dynamic> p, String status) async {
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.patch('${ApiUrl.perizinan}/${p['id']}', {
        'statusApproval': status,
        if (status == 'KEMBALI' || status == 'TELAT')
          'tanggalKembali': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
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
              tooltip: 'Ajukan Izin',
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada perizinan.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i] as Map<String, dynamic>;
                          final santri = (p['santri'] as Map?) ?? {};
                          final status = p['statusApproval'] as String;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text('${santri['nama'] ?? ''} • ${p['jenis']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    _statusChip(status),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(p['alasan'] as String),
                                  Text('${(p['tanggalKeluar'] as String).substring(0, 10)}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  if (status == 'DIAJUKAN') ...[
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      OutlinedButton(
                                        onPressed: () => _action(p, 'DISETUJUI'),
                                        child: const Text('Setujui'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _action(p, 'DITOLAK'),
                                        child: const Text('Tolak'),
                                      ),
                                    ]),
                                  ],
                                  if (status == 'DISETUJUI') ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () => _action(p, 'KEMBALI'),
                                      child: const Text('Tandai Kembali'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _statusChip(String status) {
    Color c = Colors.blueGrey;
    if (status == 'DIAJUKAN') c = Colors.orange;
    if (status == 'DISETUJUI') c = Colors.green;
    if (status == 'DITOLAK') c = Colors.red;
    if (status == 'TELAT') c = Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}