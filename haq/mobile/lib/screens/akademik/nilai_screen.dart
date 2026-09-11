import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  List<Map<String, dynamic>> _mapel = [];
  List<Map<String, dynamic>> _santris = [];
  String? _mapelId;
  String? _santriId;
  String _jenis = 'HARIAN';
  final _nilai = TextEditingController();
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
      final m = await api.get(ApiUrl.mapel);
      final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      if (!mounted) return;
      setState(() {
        _mapel = (m as List).cast<Map<String, dynamic>>();
        _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>();
        if (_mapel.isNotEmpty) _mapelId = _mapel.first['id'] as String;
        if (_santris.isNotEmpty) _santriId = _santris.first['id'] as String;
        _loading = false;
      });
      await _loadRiwayat();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRiwayat() async {
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.nilai, query: {
        if (_santriId != null) 'santriId': _santriId!,
        if (_mapelId != null) 'mapelId': _mapelId!,
      });
      if (!mounted) return;
      setState(() => _riwayat = (res as List? ?? []));
    } catch (_) {}
  }

  Future<void> _save() async {
    final n = double.tryParse(_nilai.text.replaceAll(',', '.'));
    if (n == null) {
      setState(() => _error = 'Masukkan nilai yang valid.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.nilai, {
        'santriId': _santriId,
        'mapelId': _mapelId,
        'jenis': _jenis,
        'nilai': n,
        'tanggal': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      _nilai.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai disimpan.')));
      setState(() => _saving = false);
      _loadRiwayat();
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
                  value: _sanitize(_mapelId, _mapel),
                  label: 'Mata Pelajaran',
                  options: [for (final m in _mapel) DropdownOption(m['id'] as String, m['namaMapel'] as String)],
                  onChanged: (v) {
                    setState(() => _mapelId = v);
                    _loadRiwayat();
                  },
                ),
                const SizedBox(height: 10),
                TwSelect(
                  value: _sanitize(_santriId, _santris),
                  label: 'Santri',
                  options: [for (final s in _santris) DropdownOption(s['id'] as String, '${s['nama']} (${s['nis']})')],
                  onChanged: (v) {
                    setState(() => _santriId = v);
                    _loadRiwayat();
                  },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TwSelect(
                      value: _jenis,
                      label: 'Jenis',
                      options: const [
                        DropdownOption('HARIAN', 'Harian'),
                        DropdownOption('ULANGAN', 'Ulangan'),
                        DropdownOption('TAHFIDZ', 'Tahfidz'),
                        DropdownOption('BAHASA_ARAB', 'Bahasa Arab'),
                      ],
                      onChanged: (v) => setState(() => _jenis = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _nilai,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
                    ),
                  ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan Nilai'),
                ),
                const Divider(height: 28),
                Text('Riwayat Nilai', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (_riwayat.isEmpty)
                  emptyView('Belum ada nilai.')
                else
                  ..._riwayat.map((r) {
                    final rr = r as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text((rr['nilai'] as num).toStringAsFixed(0))),
                        title: Text((rr['mapel'] as Map?)?['namaMapel'] ?? ''),
                        subtitle: Text('${rr['jenis']} • ${(rr['tanggal'] as String).substring(0, 10)}'),
                        trailing: Text('${(rr['santri'] as Map?)?['nama'] ?? ''}'),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  String? _sanitize(String? id, List<Map<String, dynamic>> list) {
    if (id != null && list.any((e) => e['id'] == id)) return id;
    return list.isEmpty ? null : list.first['id'] as String;
  }
}