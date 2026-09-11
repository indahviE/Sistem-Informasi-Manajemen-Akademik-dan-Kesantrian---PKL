import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class KonselingScreen extends StatefulWidget {
  const KonselingScreen({super.key});

  @override
  State<KonselingScreen> createState() => _KonselingScreenState();
}

class _KonselingScreenState extends State<KonselingScreen> {
  List<dynamic> _list = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.konseling);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _list = items;
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
    final santri = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PilihSantri(),
    );
    if (santri == null) return;
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormKonseling(santri: santri),
    );
    if (result != null) {
      try {
        await AppScope.of(context).api.post(ApiUrl.konseling, {
          ...result,
          'santriId': santri['id'],
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Catatan konseling tersimpan')));
        _load();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan konseling?'),
        content: Text('Catatan konseling ${k['santri']?['nama']} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AppScope.of(context).api.delete('${ApiUrl.konseling}/${k['id']}');
        if (!mounted) return;
        _load();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Catat Konseling',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _list.isEmpty
                  ? emptyView('Belum ada catatan konseling.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final k = _list[i] as Map<String, dynamic>;
                          final tgl = (k['tanggal'] as String? ?? '').substring(0, 10);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ExpansionTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.skySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.support_agent, color: Tw.sky, size: 22),
                              ),
                              title: Text(k['topik'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${k['santri']?['nama'] ?? '-'} • $tgl • ${k['konselor']?['nama'] ?? 'Konselor'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Tw.gray400, size: 20),
                                onPressed: () => _delete(k),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          twBadge(ctx, 'RAHASIA',
                                              color: Tw.red, soft: Tw.redSoft),
                                          const SizedBox(width: 8),
                                          twBadge(ctx, 'NIS ${k['santri']?['nis'] ?? '-'}',
                                              color: Tw.gray600, soft: Tw.gray100),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text('Catatan:',
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Tw.gray900)),
                                      const SizedBox(height: 4),
                                      Text(k['catatan'] as String,
                                          style: const TextStyle(color: Tw.gray700, fontSize: 13.5, height: 1.4)),
                                      if (k['tindakLanjut'] != null) ...[
                                        const SizedBox(height: 10),
                                        Text('Tindak lanjut:',
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: Tw.gray900)),
                                        const SizedBox(height: 4),
                                        Text(k['tindakLanjut'] as String,
                                            style: const TextStyle(
                                                color: Tw.gray700, fontSize: 13.5, height: 1.4)),
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

class _PilihSantri extends StatefulWidget {
  const _PilihSantri();

  @override
  State<_PilihSantri> createState() => _PilihSantriState();
}

class _PilihSantriState extends State<_PilihSantri> {
  List<dynamic> _santri = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.santri);
      final items = (res as Map<String, dynamic>)['items'] as List;
      if (mounted) setState(() {
        _santri = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _query.trim().isEmpty
        ? _santri
        : _santri.where((s) {
            final m = s as Map<String, dynamic>;
            final nama = (m['nama'] as String? ?? '').toLowerCase();
            final nis = (m['nis'] as String? ?? '').toLowerCase();
            final q = _query.trim().toLowerCase();
            return nama.contains(q) || nis.contains(q);
          }).toList();
    return Dialog(
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text('Pilih Santri',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama / NIS…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? loadingView()
                  : list.isEmpty
                      ? emptyView('Santri tidak ditemukan.')
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final s = list[i] as Map<String, dynamic>;
                            return ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Tw.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_rounded, size: 20, color: Tw.primary),
                              ),
                              title: Text(s['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('NIS ${s['nis']} • ${s['kelas']?['namaKelas'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => Navigator.of(context).pop(s),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormKonseling extends StatefulWidget {
  final Map<String, dynamic> santri;
  const _FormKonseling({required this.santri});

  @override
  State<_FormKonseling> createState() => _FormKonselingState();
}

class _FormKonselingState extends State<_FormKonseling> {
  final _topik = TextEditingController();
  final _catatan = TextEditingController();
  final _tindak = TextEditingController();
  bool _privat = true;

  @override
  void dispose() {
    _topik.dispose();
    _catatan.dispose();
    _tindak.dispose();
    super.dispose();
  }

  void _submit() {
    if (_topik.text.trim().isEmpty || _catatan.text.trim().isEmpty) return;
    Navigator.of(context).pop({
      'topik': _topik.text.trim(),
      'catatan': _catatan.text.trim(),
      'tindakLanjut': _tindak.text.trim().isEmpty ? null : _tindak.text.trim(),
      'privat': _privat,
    });
  }

  @override
  Widget build(BuildContext context) {
    return TwFormDialog(
      icon: Icons.support_agent_rounded,
      title: 'Konseling: ${widget.santri['nama']}',
      fields: [
        TextField(
          controller: _topik,
          decoration: const InputDecoration(labelText: 'Topik', hintText: 'Contoh: Motivasi belajar'),
        ),
        TextField(
          controller: _catatan,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Catatan (rahasia)', alignLabelWithHint: true),
        ),
        TextField(
          controller: _tindak,
          decoration: const InputDecoration(labelText: 'Tindak lanjut (opsional)'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Jadikan rahasia', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Hanya dapat diakses pengelola',
              style: TextStyle(fontSize: 12, color: Tw.gray500)),
          value: _privat,
          onChanged: (v) => setState(() => _privat = v),
        ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
