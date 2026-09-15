import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class WaliScreen extends StatefulWidget {
  const WaliScreen({super.key});

  @override
  State<WaliScreen> createState() => _WaliScreenState();
}

class _WaliScreenState extends State<WaliScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _nilai = [];
  bool _loading = true;
  String? _error;
  String? _selectedSantriId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final d = await api.get(ApiUrl.waliMe);
      List<dynamic> n = [];
      final anak = (d['santris'] as List? ?? []);
      if (anak.isNotEmpty) {
        final sid = (anak.first as Map)['id'] as String;
        n = (await api.get(ApiUrl.nilai, query: {'santriId': sid, 'perPage': ''}) as List?) ?? [];
      }
      if (!mounted) return;
      setState(() {
        _data = d as Map<String, dynamic>;
        _nilai = n;
        _selectedSantriId = anak.isNotEmpty ? (anak.first as Map)['id'] as String : null;
        _loading = false;
      });
      } catch (e) {
      if (mounted) setState(() {
        _error = e is ApiException ? e.message : 'Terjadi kesalahan tak terduga: $e';
        _loading = false;
      });
    }
  }

  Future<void> _onSelectSantri(String id) async {
    try {
      final api = AppScope.of(context).api;
      final n = (await api.get(ApiUrl.nilai, query: {'santriId': id}) as List?) ?? [];
      if (mounted) setState(() {
        _selectedSantriId = id;
        _nilai = n;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _data == null
                  ? emptyView('Akun belum terhubung ke data santri.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          SectionCard(
                            title: 'Anak Anda',
                            children: [
                              for (final a in (_data!['santris'] as List).cast<Map<String, dynamic>>())
                                RadioListTile<String>(
                                  value: a['id'] as String,
                                  groupValue: _selectedSantriId,
                                  onChanged: (v) => _onSelectSantri(v!),
                                  title: Text(a['nama'] as String),
                                  subtitle: Text('${a['nis']} • ${(a['kelas'] as Map?)?['namaKelas'] ?? '-'}'),
                                ),
                            ],
                          ),
                          SectionCard(
                            title: 'Nilai',
                            children: _nilai.isEmpty
                                ? [const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada nilai untuk santri ini.'))]
                                : [
                                    for (final n in _nilai)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(child: Text((n['nilai'] as num).toStringAsFixed(0))),
                                        title: Text((n['mapel'] as Map?)?['namaMapel'] ?? ''),
                                        subtitle: Text('${n['jenis']} • ${(n['tanggal'] as String).substring(0, 10)}'),
                                      ),
                                  ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}