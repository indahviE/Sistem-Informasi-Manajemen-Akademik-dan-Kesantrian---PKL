import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class KeadaanDaruratScreen extends StatefulWidget {
  const KeadaanDaruratScreen({super.key});

  @override
  State<KeadaanDaruratScreen> createState() => _KeadaanDaruratScreenState();
}

class _KeadaanDaruratScreenState extends State<KeadaanDaruratScreen> {
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
      final res = await api.get(ApiUrl.keadaanDarurat);
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

  Future<void> _lapor() async {
    if (_santris.isEmpty) {
      try {
        final api = AppScope.of(context).api;
        final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
        if (mounted) setState(() => _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    final jenis = TextEditingController();
    final lokasi = TextEditingController();
    final deskripsi = TextEditingController();
    String? santriId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.emergency_rounded,
          title: 'Lapor Keadaan Darurat',
          subtitle: const Text('Admin dan Pimpinan akan mendapat notifikasi segera.'),
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri (opsional)',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TextField(
              controller: jenis,
              decoration: const InputDecoration(labelText: 'Jenis Kedaruratan', hintText: 'Contoh: Kecelakaan, sakit mendadak'),
            ),
            TextField(controller: lokasi, decoration: const InputDecoration(labelText: 'Lokasi (opsional)')),
            TextField(
              controller: deskripsi,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
            ),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kirim Laporan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (jenis.text.trim().isEmpty || deskripsi.text.trim().isEmpty) return;
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.keadaanDarurat, {
        'santriId': santriId,
        'jenis': jenis.text.trim(),
        'lokasi': lokasi.text.trim().isEmpty ? null : lokasi.text.trim(),
        'deskripsi': deskripsi.text.trim(),
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan darurat dikirim.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _tangani(Map<String, dynamic> item) async {
    String status = (item['status'] as String?) ?? 'BARU';
    final tindak = TextEditingController(text: item['tindakLanjut'] as String? ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Tindak Lanjuti Laporan',
          fields: [
            TwSelect(
              value: status,
              label: 'Status',
              options: const [
                DropdownOption('BARU', 'Baru'),
                DropdownOption('DITANGANI', 'Ditangani'),
                DropdownOption('SELESAI', 'Selesai'),
              ],
              onChanged: (v) => setLocal(() => status = v ?? 'BARU'),
            ),
            TextField(
              controller: tindak,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Tindak Lanjut', alignLabelWithHint: true),
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
    try {
      final api = AppScope.of(context).api;
      await api.patch('${ApiUrl.keadaanDarurat}/${item['id']}', {
        'status': status,
        'tindakLanjut': tindak.text.trim().isEmpty ? null : tindak.text.trim(),
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status laporan diperbarui.')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DITANGANI':
        return Tw.amber;
      case 'SELESAI':
        return Tw.teal;
      default:
        return Tw.red;
    }
  }

  Color _statusSoft(String s) {
    switch (s) {
      case 'DITANGANI':
        return Tw.amberSoft;
      case 'SELESAI':
        return Tw.tealSoft;
      default:
        return Tw.redSoft;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'DITANGANI':
        return 'Ditangani';
      case 'SELESAI':
        return 'Selesai';
      default:
        return 'Baru';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    final bisaTangani = user?.isAdmin == true || user?.isPimpinan == true;
    final bisaLapor = user?.isWali != true;
    return Scaffold(
      floatingActionButton: bisaLapor
          ? FloatingActionButton(
              onPressed: _lapor,
              tooltip: 'Lapor Keadaan Darurat',
              backgroundColor: Tw.red,
              child: const Icon(Icons.add_alert_rounded),
            )
          : null,
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada laporan keadaan darurat.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final d = _items[i] as Map<String, dynamic>;
                          final santri = (d['santri'] as Map?) ?? {};
                          final status = (d['status'] as String?) ?? 'BARU';
                          final tgl = (d['tanggal'] as String? ?? '').substring(0, 10);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ExpansionTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: _statusSoft(status), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.emergency, color: _statusColor(status), size: 22),
                              ),
                              title: Text(d['jenis'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${santri.isEmpty ? 'Umum' : santri['nama']} • $tgl',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: twBadge(context, _statusLabel(status), color: _statusColor(status), soft: _statusSoft(status)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (d['lokasi'] != null) ...[
                                        Text('Lokasi: ${d['lokasi']}', style: const TextStyle(color: Tw.gray700, fontSize: 13.5)),
                                        const SizedBox(height: 6),
                                      ],
                                      const Text('Deskripsi:',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Tw.gray900)),
                                      const SizedBox(height: 4),
                                      Text(d['deskripsi'] as String,
                                          style: const TextStyle(color: Tw.gray700, fontSize: 13.5, height: 1.4)),
                                      if (d['tindakLanjut'] != null) ...[
                                        const SizedBox(height: 10),
                                        const Text('Tindak lanjut:',
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Tw.gray900)),
                                        const SizedBox(height: 4),
                                        Text(d['tindakLanjut'] as String,
                                            style: const TextStyle(color: Tw.gray700, fontSize: 13.5, height: 1.4)),
                                      ],
                                      if (bisaTangani) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: FilledButton.tonalIcon(
                                            onPressed: () => _tangani(d),
                                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                                            label: const Text('Tindak Lanjuti'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}