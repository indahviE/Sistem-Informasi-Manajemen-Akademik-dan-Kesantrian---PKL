import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

const predikatOptions = ['MEMUASKAN', 'HONOUR', 'CUM_LAUDE', 'SUMMA_CUM_LAUDE'];

class KelulusanScreen extends StatefulWidget {
  const KelulusanScreen({super.key});

  @override
  State<KelulusanScreen> createState() => _KelulusanScreenState();
}

class _KelulusanScreenState extends State<KelulusanScreen> {
  List<dynamic> _kelulusan = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.kelulusan);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _kelulusan = items;
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
      builder: (_) => _FormKelulusan(santri: santri),
    );
    if (result != null) {
      try {
        await AppScope.of(context).api.post(ApiUrl.kelulusan, {
          ...result,
          'santriId': santri['id'],
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Kelulusan tercatat')));
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
        title: const Text('Hapus data kelulusan?'),
        content: Text('Data kelulusan ${k['santri']?['nama']} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AppScope.of(context).api.delete('${ApiUrl.kelulusan}/${k['id']}');
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
        tooltip: 'Catat Kelulusan',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _kelulusan.isEmpty
                  ? emptyView('Belum ada santri yang dicatat lulus/wisuda tahfidz.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _kelulusan.length,
                        itemBuilder: (ctx, i) {
                          final k = _kelulusan[i] as Map<String, dynamic>;
                          final juz = k['juzYangDiHafal'] as int?;
                          final predikat = k['predikat'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.peachSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.military_tech, color: Tw.peach, size: 22),
                              ),
                              title: Text(k['santri']?['nama'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                'NIS ${k['santri']?['nis'] ?? '-'} • ${k['santri']?['kelas']?['namaKelas'] ?? '-'}'
                                '${juz != null ? ' • $juz juz' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (predikat != null)
                                    twBadge(ctx, predikat,
                                        color: Tw.purple, soft: Tw.indigoSoft),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.gray400, size: 20),
                                    onPressed: () => _delete(k),
                                  ),
                                ],
                              ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
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

class _FormKelulusan extends StatefulWidget {
  final Map<String, dynamic> santri;
  const _FormKelulusan({required this.santri});

  @override
  State<_FormKelulusan> createState() => _FormKelulusanState();
}

class _FormKelulusanState extends State<_FormKelulusan> {
  final _juz = TextEditingController();
  final _catatan = TextEditingController();
  String? _predikat;

  @override
  void dispose() {
    _juz.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop({
      'predikat': _predikat,
      'juzYangDiHafal': _juz.text.trim().isEmpty ? null : int.tryParse(_juz.text.trim()),
      'catatan': _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return TwFormDialog(
      icon: Icons.workspace_premium_rounded,
      title: 'Kelulusan: ${widget.santri['nama']}',
      fields: [
        TwSelect(
          value: _predikat,
          label: 'Predikat Tahfidz',
          options: [for (final p in predikatOptions) DropdownOption(p, p)],
          onChanged: (v) => setState(() => _predikat = v),
        ),
        TextField(
          controller: _juz,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Juz yang dihafal', hintText: 'Contoh: 30'),
        ),
        TextField(
          controller: _catatan,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
        ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
