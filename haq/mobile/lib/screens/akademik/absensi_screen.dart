import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  List<Map<String, dynamic>> _kelas = [];
  String? _kelasId;
  String? _mapelId;
  List<Map<String, dynamic>> _mapel = [];
  List<dynamic> _santris = [];
  final Map<String, String> _status = {}; // santriId -> status
  String? _tanggal;
  bool _loadingMeta = true;
  bool _loadingSantri = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tegTanggal();
    _init();
  }

  void _tegTanggal() {
    final now = DateTime.now();
    _tanggal = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    try {
      final api = AppScope.of(context).api;
      final k = await api.get(ApiUrl.kelas);
      final m = await api.get(ApiUrl.mapel);
      if (!mounted) return;
      setState(() {
        _kelas = (k as List).cast<Map<String, dynamic>>();
        _mapel = (m as List).cast<Map<String, dynamic>>();
        _loadingMeta = false;
        if (_kelas.isNotEmpty) _kelasId = _kelas.first['id'] as String;
        if (_mapel.isNotEmpty) _mapelId = _mapel.first['id'] as String;
      });
      await _loadSantri();
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _loadSantri() async {
    if (_kelasId == null) return;
    setState(() {
      _loadingSantri = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'kelasId': _kelasId!, 'perPage': '100'});
      if (!mounted) return;
      setState(() {
        _santris = (res['items'] as List? ?? []);
        for (final s in _santris) {
          _status.putIfAbsent(s['id'] as String, () => 'HADIR');
        }
        _loadingSantri = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loadingSantri = false;
      });
    }
  }

  Future<void> _save() async {
    if (_santris.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.post('${ApiUrl.absensi}/bulk', {
        'kelasId': _kelasId,
        'mapelId': _mapelId,
        'tanggal': _tanggal,
        'items': [
          for (final s in _santris)
            {'santriId': s['id'], 'status': _status[s['id']] ?? 'HADIR'},
        ],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absensi disimpan.')));
      setState(() => _saving = false);
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
      bottomNavigationBar: _santris.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan Absensi'),
                ),
              ),
            ),
      body: _loadingMeta
          ? loadingView()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(children: [
                  Expanded(
                    child: TwSelect(
                      value: _kelasId,
                      label: 'Kelas',
                      options: [
                        for (final k in _kelas) DropdownOption(k['id'] as String, k['namaKelas'] as String),
                      ],
                      onChanged: (v) {
                        setState(() => _kelasId = v);
                        _loadSantri();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TwSelect(
                      value: _mapelId,
                      label: 'Mapel',
                      options: [
                        for (final m in _mapel) DropdownOption(m['id'] as String, m['namaMapel'] as String),
                      ],
                      onChanged: (v) => setState(() => _mapelId = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Tanggal: $_tanggal'),
                  trailing: TextButton(onPressed: _pickDate, child: const Text('Ubah')),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 4),
                if (_loadingSantri)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (_santris.isEmpty)
                  emptyView('Kelas ini belum punya santri.')
                else
                  ..._santris.map((s) {
                    final id = s['id'] as String;
                    return Card(
                      child: ListTile(
                        title: Text(s['nama'] as String),
                        subtitle: Text('NIS ${s['nis']}'),
                        trailing: DropdownButton<String>(
                          value: _status[id],
                          items: const [
                            DropdownMenuItem(value: 'HADIR', child: Text('Hadir')),
                            DropdownMenuItem(value: 'SAKIT', child: Text('Sakit')),
                            DropdownMenuItem(value: 'IZIN', child: Text('Izin')),
                            DropdownMenuItem(value: 'ALPA', child: Text('Alpa')),
                          ],
                          onChanged: (v) => setState(() => _status[id] = v!),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_tanggal!),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (day != null) {
      setState(() {
        _tanggal = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      });
    }
  }
}