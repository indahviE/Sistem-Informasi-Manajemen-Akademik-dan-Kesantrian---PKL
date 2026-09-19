import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  List<dynamic> _santri = [];
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

  Future<void> _generate(Map<String, dynamic> santri) async {
    final periode = TextEditingController(text: '2026/2027 - Ganjil');
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Rapor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${santri['nama']} (${santri['nis']})',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: periode,
              decoration: const InputDecoration(labelText: 'Periode', hintText: 'Contoh: 2026/2027 - Ganjil'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (periode.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(periode.text.trim());
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.raporGenerate, {
        'santriId': santri['id'],
        'periode': confirmed.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rapor berhasil digenerate')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Tw.indigoSoft,
                                child: Icon(Icons.description_outlined, color: Tw.purple, size: 20),
                              ),
                              title: Text(s['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('NIS ${s['nis']} • ${s['kelas']?['namaKelas'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _generate(s),
                                    child: const Text('Generate'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, color: Tw.primary),
                                    tooltip: 'Lihat Rapor',
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => RaporDetailScreen(santri: s),
                                    )),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => RaporDetailScreen(santri: s),
                              )),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class RaporDetailScreen extends StatefulWidget {
  final Map<String, dynamic> santri;
  const RaporDetailScreen({super.key, required this.santri});

  @override
  State<RaporDetailScreen> createState() => _RaporDetailScreenState();
}

class _RaporDetailScreenState extends State<RaporDetailScreen> {
  List<dynamic> _rapors = [];
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
      final res = await AppScope.of(context).api
          .get(ApiUrl.rapor, query: {'santriId': widget.santri['id'] as String});
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _rapors = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _terbit(Map<String, dynamic> r) async {
    try {
      await AppScope.of(context).api.patch('${ApiUrl.rapor}/${r['id']}/terbit');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rapor diterbitkan')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
              : _rapors.isEmpty
                  ? emptyView('Belum ada rapor. Generate rapor dari daftar santri.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _rapors.length,
                      itemBuilder: (ctx, i) {
                        final r = _rapors[i] as Map<String, dynamic>;
                        final ringkasan = (r['ringkasan'] as Map<String, dynamic>?) ?? {};
                        final mapelList = (ringkasan['mapel'] as List? ?? []);
                        final ujianList = (ringkasan['ujian'] as List? ?? []);
                        final kehadiran = (ringkasan['kehadiran'] as Map<String, dynamic>?) ?? {};
                        return Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(r['periode'] as String,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Tw.gray900)),
                                        ),
                                        twBadge(
                                          ctx,
                                          r['status'] as String,
                                          color: r['status'] == 'TERBIT' ? Tw.teal : Tw.gray600,
                                          soft: r['status'] == 'TERBIT' ? Tw.tealSoft : Tw.gray100,
                                        ),
                                      ],
                                    ),
                                    if (r['rataRata'] != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Rata-rata: ${(r['rataRata'] as num).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Tw.primary),
                                      ),
                                    ],
                                    if (mapelList.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Text('Nilai Mapel',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700, color: Tw.gray900)),
                                      const SizedBox(height: 6),
                                      ...mapelList.map((m) {
                                        final mm = m as Map<String, dynamic>;
                                        return _nilaiBar(mm['mapel'].toString(), (mm['rataRata'] as num).toDouble());
                                      }),
                                    ],
                                    if (ujianList.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Text('Nilai Ujian',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700, color: Tw.gray900)),
                                      const SizedBox(height: 6),
                                      ...ujianList.map((m) {
                                        final mm = m as Map<String, dynamic>;
                                        return _nilaiBar(mm['ujian'].toString(), (mm['rataRata'] as num).toDouble());
                                      }),
                                    ],
                                    if (kehadiran['total'] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Kehadiran: ${kehadiran['hadir'] ?? 0}/${kehadiran['total'] ?? 0} hadir',
                                        style: const TextStyle(color: Tw.gray600, fontSize: 13),
                                      ),
                                    ],
                                    if (r['status'] != 'TERBIT') ...[
                                      const SizedBox(height: 14),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton.tonalIcon(
                                          onPressed: () => _terbit(r),
                                          icon: const Icon(Icons.send_outlined, size: 18),
                                          label: const Text('Terbitkan'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }

  Widget _nilaiBar(String label, double nilai) {
    final color = nilai >= 75 ? Tw.teal : Tw.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Tw.gray700, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(nilai.toStringAsFixed(1),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
