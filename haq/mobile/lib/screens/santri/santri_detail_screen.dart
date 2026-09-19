import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class SantriDetailScreen extends StatefulWidget {
  final String santriId;
  const SantriDetailScreen({super.key, required this.santriId});

  @override
  State<SantriDetailScreen> createState() => _SantriDetailScreenState();
}

class _SantriDetailScreenState extends State<SantriDetailScreen> {
  Map<String, dynamic>? _data;
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
      _error = null;
      _data = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.santri}/${widget.santriId}');
      if (mounted) setState(() => _data = res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat detail.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Santri')),
      body: _error != null
          ? errorView(_error!, _load)
          : _data == null
              ? loadingView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      SectionCard(
                        title: 'Identitas',
                        children: [
                          _row('NIS', '${_data!['nis']}'),
                          _row('Nama', '${_data!['nama']}'),
                          _row('Jenis Kelamin', '${_data!['jenisKelamin']}'),
                          _row('Kelas', (_data!['kelas'] as Map?)?['namaKelas'] ?? '-'),
                          _row('Tahun Masuk', '${_data!['tahunMasuk']}'),
                          _row('Wali', (_data!['wali'] as Map?)?['nama'] ?? '-'),
                        ],
                      ),
                      SectionCard(
                        title: 'Capaian Tahfidz',
                        children: _data!['capaianTahfidzs'] != null && (_data!['capaianTahfidzs'] as List).isNotEmpty
                            ? [
                                for (final c in (_data!['capaianTahfidzs'] as List).cast<Map<String, dynamic>>())
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Juz ${c['juz']} • Halaman ${c['halaman']}'),
                                    subtitle: Text('${c['catatanUstadz'] ?? ''}'),
                                    trailing: Text('${(c['tanggalSetor'] as String).substring(0, 10)}', style: Theme.of(context).textTheme.bodySmall),
                                  ),
                              ]
                            : [const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada capaian tahfidz.'))],
                      ),
                      SectionCard(
                        title: 'Pelanggaran',
                        children: _data!['pelanggarans'] != null && (_data!['pelanggarans'] as List).isNotEmpty
                            ? [
                                for (final p in (_data!['pelanggarans'] as List).cast<Map<String, dynamic>>())
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.gavel, color: Colors.red),
                                    title: Text(p['jenisPelanggaran'] as String),
                                    subtitle: Text('${p['poin']} poin'),
                                  ),
                              ]
                            : [const Padding(padding: EdgeInsets.all(8), child: Text('Tidak ada pelanggaran.'))],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}