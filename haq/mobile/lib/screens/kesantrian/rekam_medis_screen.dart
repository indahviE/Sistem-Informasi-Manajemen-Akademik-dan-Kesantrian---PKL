import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class RekamMedisScreen extends StatefulWidget {
  const RekamMedisScreen({super.key});

  @override
  State<RekamMedisScreen> createState() => _RekamMedisScreenState();
}

class _RekamMedisScreenState extends State<RekamMedisScreen> {
  List<dynamic> _santri = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.santri);
      final items = (res as Map<String, dynamic>)['items'] as List;
      if (!mounted) return;
      setState(() {
        _santri = items;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _santri.isEmpty
                  ? emptyView('Belum ada santri.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _santri.length,
                        itemBuilder: (ctx, i) {
                          final s = _santri[i] as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Tw.primary),
                              title: Text(s['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('NIS ${s['nis']} • ${s['kelas']?['namaKelas'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, color: Tw.gray400),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => _RekamDetail(santri: s),
                              )),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _RekamDetail extends StatefulWidget {
  final Map<String, dynamic> santri;
  const _RekamDetail({required this.santri});

  @override
  State<_RekamDetail> createState() => _RekamDetailState();
}

class _RekamDetailState extends State<_RekamDetail> {
  Map<String, dynamic> _rm = {};
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;

  final _gol = TextEditingController();
  final _alergi = TextEditingController();
  final _riwayat = TextEditingController();
  final _tinggi = TextEditingController();
  final _berat = TextEditingController();
  final _catatan = TextEditingController();

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
      final sid = widget.santri['id'] as String;
      final rm = await api.get('${ApiUrl.rekamMedis}/$sid') as Map<String, dynamic>;
      final logs = await api.get(ApiUrl.kesehatan, query: {'santriId': sid});
      if (!mounted) return;
      setState(() {
        _rm = rm;
        _logs = (logs as List);
        _gol.text = rm['golonganDarah'] as String? ?? '';
        _alergi.text = rm['alergi'] as String? ?? '';
        _riwayat.text = rm['riwayatPenyakit'] as String? ?? '';
        _tinggi.text = (rm['tinggiBadan'] as int?)?.toString() ?? '';
        _berat.text = (rm['beratBadan'] as int?)?.toString() ?? '';
        _catatan.text = rm['catatanKhusus'] as String? ?? '';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _simpan() async {
    try {
      await AppScope.of(context).api.put(
        '${ApiUrl.rekamMedis}/${widget.santri['id']}',
        {
          'golonganDarah': _gol.text.trim().isEmpty ? null : _gol.text.trim(),
          'alergi': _alergi.text.trim().isEmpty ? null : _alergi.text.trim(),
          'riwayatPenyakit': _riwayat.text.trim().isEmpty ? null : _riwayat.text.trim(),
          'tinggiBadan': int.tryParse(_tinggi.text.trim()),
          'beratBadan': int.tryParse(_berat.text.trim()),
          'catatanKhusus': _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rekam medis disimpan.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.santri['nama'] as String)),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      SectionCard(
                        title: 'Data Medis',
                        children: [
                          _field('Golongan Darah', _gol),
                          _field('Alergi', _alergi),
                          _field('Riwayat Penyakit', _riwayat),
                          Row(
                            children: [
                              Expanded(
                                  child: TextField(controller: _tinggi,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Tinggi (cm)'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextField(controller: _berat,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Berat (kg)'))),
                            ],
                          ),
                          _field('Catatan Khusus', _catatan),
                          const SizedBox(height: 8),
                          FilledButton(onPressed: _simpan, child: const Text('Simpan Rekam Medis')),
                        ],
                      ),
                      SectionCard(
                        title: 'Riwayat Kesehatan (${_logs.length})',
                        children: _logs.isEmpty
                            ? const [Text('Belum ada catatan kesehatan.', style: TextStyle(color: Tw.gray500))]
                            : [
                                for (final l in _logs.reversed)
                                  _logCard(l as Map<String, dynamic>),
                              ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(controller: c, decoration: InputDecoration(labelText: label)),
    );
  }

  Widget _logCard(Map<String, dynamic> l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Tw.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Tw.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l['keluhan'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Tw.gray900)),
                ),
                twBadge(context, l['tempat'] as String? ?? 'UKS', color: Tw.indigo, soft: Tw.indigoSoft),
              ],
            ),
            if (l['diagnosa'] != null)
              Text('Diagnosa: ${l['diagnosa']}', style: const TextStyle(fontSize: 13, color: Tw.gray600)),
            if (l['obat'] != null)
              Text('Obat: ${l['obat']}', style: const TextStyle(fontSize: 13, color: Tw.gray600)),
            if (l['tindakan'] != null)
              Text('Tindakan: ${l['tindakan']}', style: const TextStyle(fontSize: 13, color: Tw.gray600)),
            const SizedBox(height: 4),
            Text(
              '${(l['tanggal'] as String).split('T').first} • ${l['status']}',
              style: const TextStyle(fontSize: 12, color: Tw.gray400),
            ),
          ],
        ),
      ),
    );
  }
}