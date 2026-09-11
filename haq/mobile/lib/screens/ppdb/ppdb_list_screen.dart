import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class PpdbListScreen extends StatefulWidget {
  const PpdbListScreen({super.key});

  @override
  State<PpdbListScreen> createState() => _PpdbListScreenState();
}

class _PpdbListScreenState extends State<PpdbListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  static const _statusColors = <String, List<Color>>{
    'DIAJUKAN': [Tw.amber, Tw.amberSoft],
    'TES': [Tw.sky, Tw.skySoft],
    'DITERIMA': [Tw.teal, Tw.tealSoft],
    'DITOLAK': [Tw.red, Tw.redSoft],
    'WAITING_LIST': [Tw.indigo, Tw.indigoSoft],
  };

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
      final q = <String, String>{if (_filter.isNotEmpty) 'status': _filter};
      final res = await api.get(ApiUrl.ppdb, query: q);
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

  List<Color> _colors(String status) =>
      _statusColors[status] ?? [Tw.gray600, Tw.gray100];

  void _openDetail(Map<String, dynamic> p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PendaftarDetail(p: p, onChanged: _load),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('', 'Semua'),
                  for (final s in ['DIAJUKAN', 'TES', 'DITERIMA', 'DITOLAK', 'WAITING_LIST'])
                    _chip(s, s),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? loadingView()
                : _error != null
                    ? errorView(_error!, _load)
                    : _items.isEmpty
                        ? emptyView('Belum ada pendaftar.')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) {
                                final p = _items[i] as Map<String, dynamic>;
                                final c = _colors(p['status'] as String);
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: c[1],
                                      child: Icon(Icons.person, color: c[0]),
                                    ),
                                    title: Text(p['nama'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${p['noPendaftaran']} • ${p['jalur'] ?? 'Reguler'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: twBadge(context, p['status'] as String,
                                        color: c[0], soft: c[1]),
                                    onTap: () => _openDetail(p),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: Tw.primary,
        labelStyle: TextStyle(color: active ? Colors.white : Tw.gray600, fontWeight: FontWeight.w600),
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
      ),
    );
  }
}

class _PendaftarDetail extends StatefulWidget {
  final Map<String, dynamic> p;
  final VoidCallback onChanged;
  const _PendaftarDetail({required this.p, required this.onChanged});

  @override
  State<_PendaftarDetail> createState() => _PendaftarDetailState();
}

class _PendaftarDetailState extends State<_PendaftarDetail> {
  late Map<String, dynamic> _p;
  final _testNilai = TextEditingController();
  final _testHasil = TextEditingController();
  final _testCatatan = TextEditingController();

  @override
  void initState() {
    super.initState();
    _p = widget.p;
  }

  Future<void> _simpanTest() async {
    final nilai = double.tryParse(_testNilai.text.trim());
    final body = {
      if (nilai != null) 'nilai': nilai,
      if (_testHasil.text.trim().isNotEmpty) 'hasil': _testHasil.text.trim(),
      if (_testCatatan.text.trim().isNotEmpty) 'catatan': _testCatatan.text.trim(),
    };
    try {
      final api = AppScope.of(context).api;
      final has = _p['ujian'] != null;
      await (has
          ? api.patch('${ApiUrl.ppdb}/${_p['id']}/placement-test', body)
          : api.post('${ApiUrl.ppdb}/${_p['id']}/placement-test', body));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Placement test tersimpan.')));
      _p = await api.get('${ApiUrl.ppdb}/${_p['id']}') as Map<String, dynamic>;
      widget.onChanged();
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Tw.gray500, fontSize: 13))),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ujian = _p['ujian'] as Map<String, dynamic>?;
    final status = _p['status'] as String;
    return Scaffold(
      appBar: AppBar(title: Text(_p['nama'] as String)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Data Pendaftar',
            trailing: twBadge(context, status,
                color: status == 'DITERIMA' ? Tw.teal : status == 'DITOLAK' ? Tw.red : Tw.amber,
                soft: status == 'DITERIMA' ? Tw.tealSoft : status == 'DITOLAK' ? Tw.redSoft : Tw.amberSoft),
            children: [
              _item('No. Pendaftaran', _p['noPendaftaran'] as String),
              _item('Jenis Kelamin', _p['jenisKelamin'] as String == 'L' ? 'Laki-laki' : 'Perempuan'),
              _item('Tgl Lahir', (_p['tanggalLahir'] as String? ?? '').split('T').first),
              _item('Asal Sekolah', _p['asalSekolah'] as String? ?? ''),
              _item('No. HP', _p['noHp'] as String? ?? ''),
              _item('Email', _p['email'] as String? ?? ''),
              _item('Alamat', _p['alamat'] as String? ?? ''),
              _item('Jalur', _p['jalur'] as String? ?? ''),
              _item('Tgl Daftar', (_p['tanggalDaftar'] as String).split('T').first),
            ],
          ),
          SectionCard(
            title: 'Placement Test',
            children: [
              if (ujian != null) ...[
                _item('Nilai', '${ujian['nilai'] ?? '—'}'),
                _item('Rekomendasi', ujian['hasil'] as String? ?? ''),
                _item('Catatan', ujian['catatan'] as String? ?? ''),
              ],
              TextField(
                controller: _testNilai,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nilai (0-100)',
                  hintText: ujian?['nilai']?.toString() ?? '',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _testHasil,
                decoration: InputDecoration(
                  labelText: 'Rekomendasi Kelas',
                  hintText: 'mis. Kelas 1A',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _testCatatan,
                decoration: const InputDecoration(labelText: 'Catatan Ustadz'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: _simpanTest, child: const Text('Simpan Placement Test')),
            ],
          ),
          SectionCard(
            title: 'Keputusan',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: status == 'DITERIMA'
                        ? null
                        : () => _ubahStatus('DITERIMA'),
                    child: const Text('Terima & Buat Santri'),
                  ),
                  OutlinedButton(
                    onPressed: () => _ubahStatus('TES'),
                    child: const Text('Jadwalkan Tes'),
                  ),
                  OutlinedButton(
                    onPressed: () => _ubahStatus('WAITING_LIST'),
                    child: const Text('Waiting List'),
                  ),
                  TextButton(
                    onPressed: () => _ubahStatus('DITOLAK'),
                    style: TextButton.styleFrom(foregroundColor: Tw.red),
                    child: const Text('Tolak'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _ubahStatus(String status) async {
    try {
      await AppScope.of(context).api.patch('${ApiUrl.ppdb}/${_p['id']}', {'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'DITERIMA'
            ? '${_p['nama']} diterima. Santri otomatis dibuat.'
            : 'Status diperbarui ke $status.'),
      ));
      final api = AppScope.of(context).api;
      _p = await api.get('${ApiUrl.ppdb}/${_p['id']}') as Map<String, dynamic>;
      widget.onChanged();
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
