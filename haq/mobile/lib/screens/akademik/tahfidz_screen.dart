import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class TahfidzScreen extends StatefulWidget {
  const TahfidzScreen({super.key});

  @override
  State<TahfidzScreen> createState() => _TahfidzScreenState();
}

class _TahfidzScreenState extends State<TahfidzScreen> {
  List<Map<String, dynamic>> _santris = [];
  String? _santriId;
  final _juz = TextEditingController();
  final _halaman = TextEditingController();
  final _catatan = TextEditingController();
  List<dynamic> _riwayat = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final api = AppScope.of(context).api;
      final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      if (!mounted) return;
      setState(() {
        _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>();
        if (_santris.isNotEmpty) _santriId = _santris.first['id'] as String;
        _loading = false;
      });
      await _load();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.tahfidz, query: {if (_santriId != null) 'santriId': _santriId!});
      if (!mounted) return;
      setState(() => _riwayat = (res as List? ?? []));
    } catch (_) {}
  }

  Future<void> _save() async {
    final j = int.tryParse(_juz.text);
    final h = int.tryParse(_halaman.text);
    if (j == null || h == null || _santriId == null) {
      setState(() => _error = 'Isi juz dan halaman (angka).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.tahfidz, {
        'santriId': _santriId,
        'juz': j,
        'halaman': h,
        'catatanUstadz': _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
        'tanggalSetor': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      _juz.clear();
      _halaman.clear();
      _catatan.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capaian tahfidz disimpan.')));
      setState(() => _saving = false);
      _load();
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TwSelect(
                  value: _santriId,
                  label: 'Santri',
                  options: [for (final s in _santris) DropdownOption(s['id'] as String, '${s['nama']} (${s['nis']})')],
                  onChanged: (v) {
                    setState(() => _santriId = v);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(controller: _juz, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Juz')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(controller: _halaman, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Halaman')),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(controller: _catatan, decoration: const InputDecoration(labelText: 'Catatan Ustadz')),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan Setoran'),
                ),
                const Divider(height: 28),
                Text('Riwayat Setoran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (_riwayat.isEmpty)
                  emptyView('Belum ada setoran.')
                else
                  ..._riwayat.map((r) {
                    final rr = r as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.auto_stories)),
                        title: Text('Juz ${rr['juz']} • Halaman ${rr['halaman']}'),
                        subtitle: Text('${rr['catatanUstadz'] ?? ''}'.trim().isEmpty ? '${(rr['santri'] as Map?)?['nama'] ?? ''}' : '${rr['catatanUstadz']} • ${(rr['santri'] as Map?)?['nama'] ?? ''}'),
                        trailing: Text('${(rr['tanggalSetor'] as String).substring(0, 10)}', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}