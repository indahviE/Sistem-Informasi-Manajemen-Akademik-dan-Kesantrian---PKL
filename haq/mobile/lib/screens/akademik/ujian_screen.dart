import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class UjianScreen extends StatefulWidget {
  const UjianScreen({super.key});

  @override
  State<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends State<UjianScreen> {
  List<dynamic> _ujian = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.ujian);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _ujian = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _addUjian() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _FormUjian(),
    );
    if (result != null) {
      try {
        await AppScope.of(context).api.post(ApiUrl.ujian, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ujian berhasil dibuat')));
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
        onPressed: _addUjian,
        tooltip: 'Buat Ujian',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _ujian.isEmpty
                  ? emptyView('Belum ada ujian. Buat ujian untuk mulai menilai.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _ujian.length,
                        itemBuilder: (ctx, i) {
                          final u = _ujian[i] as Map<String, dynamic>;
                          final jenis = (u['jenis'] ?? 'ULANGAN') as String;
                          final count = (u['_count']?['nilais'] as int? ?? 0);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fact_check_outlined, color: Tw.primary),
                              ),
                              title: Text(u['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${u['mapel']?['namaMapel'] ?? 'Umum'} • ${u['kelas']?['namaKelas'] ?? 'Semua kelas'} • $count nilai',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  twBadge(ctx, jenis),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Tw.gray400),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => UjianDetailScreen(ujian: u),
                              )).then((_) => _load()),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FormUjian extends StatefulWidget {
  const _FormUjian();

  @override
  State<_FormUjian> createState() => _FormUjianState();
}

class _FormUjianState extends State<_FormUjian> {
  final _nama = TextEditingController();
  String? _jenis = 'ULANGAN';
  List<dynamic> _mapel = [];
  String? _mapelId;
  bool _loading = true;

  static const jenisOptions = ['ULANGAN', 'UTS', 'UAS', 'TES_TAHFIDZ', 'LAINNYA'];

  @override
  void initState() {
    super.initState();
    _loadMapel();
  }

  Future<void> _loadMapel() async {
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.mapel);
      final items = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (mounted) setState(() {
        _mapel = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) return;
    Navigator.of(context).pop({
      'nama': _nama.text.trim(),
      'jenis': _jenis,
      'mapelId': _mapelId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return TwFormDialog(
      icon: Icons.fact_check_rounded,
      title: 'Buat Ujian',
      fields: [
        TextField(
          controller: _nama,
          decoration: const InputDecoration(labelText: 'Nama Ujian', hintText: 'Contoh: UAS Bahasa Arab'),
        ),
        TwSelect(
          value: _jenis,
          label: 'Jenis',
          options: [for (final j in jenisOptions) DropdownOption(j, j)],
          onChanged: (v) => setState(() => _jenis = v),
        ),
        _loading
            ? const LinearProgressIndicator()
            : TwSelect(
                value: _mapelId ?? '',
                label: 'Mapel (opsional)',
                options: [
                  const DropdownOption('', 'Umum / tidak ada mapel'),
                  for (final m in _mapel) DropdownOption(m['id'] as String, m['namaMapel'] as String),
                ],
                onChanged: (v) => setState(() => _mapelId = v == '' ? null : v),
              ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

class UjianDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ujian;
  const UjianDetailScreen({super.key, required this.ujian});

  @override
  State<UjianDetailScreen> createState() => _UjianDetailScreenState();
}

class _UjianDetailScreenState extends State<UjianDetailScreen> {
  Map<String, dynamic>? _data;
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
      final res = await AppScope.of(context).api.get('${ApiUrl.ujian}/${widget.ujian['id']}');
      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _inputNilai() async {
    final santri = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PilihSantriDialog(),
    );
    if (santri == null) return;
    final nilaiController = TextEditingController();
    final catatanController = TextEditingController();
    final nilai = await showDialog<double>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.edit_note_rounded,
        title: 'Input Nilai',
        subtitle: Text('${santri['nama']} (${santri['nis']})'),
        fields: [
          TextField(
            controller: nilaiController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
          ),
          TextField(
            controller: catatanController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(nilaiController.text);
              if (v == null || v < 0 || v > 100) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (nilai != null) {
      try {
        await AppScope.of(context).api.post('${ApiUrl.ujian}/${widget.ujian['id']}/nilai', {
          'santriId': santri['id'],
          'nilai': nilai,
          'catatan': catatanController.text.trim().isEmpty ? null : catatanController.text.trim(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai tersimpan')));
        _load();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _addRemedial() async {
    final santri = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PilihSantriDialog(),
    );
    if (santri == null) return;
    final ket = TextEditingController();
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.refresh_rounded,
        title: 'Remedial',
        subtitle: Text('${santri['nama']} (${santri['nis']})'),
        fields: [
          TextField(
            controller: ket,
            decoration: const InputDecoration(labelText: 'Keterangan', hintText: 'Contoh: Remedial mapel'),
          ),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Hasil'),
            child: const Text('PROSES'),
          ),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (ket.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(ket.text.trim());
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (hasil != null) {
      try {
        await AppScope.of(context).api.post(ApiUrl.remedial, {
          'santriId': santri['id'],
          'ujianId': widget.ujian['id'],
          'mapelId': widget.ujian['mapel']?['id'],
          'keterangan': hasil,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remedial dicatat')));
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ujian['nama'] as String)),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _buildContent(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addRemedial,
                  icon: const Icon(Icons.replay),
                  label: const Text('Remedial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _inputNilai,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Input Nilai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final u = _data!;
    final nilais = (u['nilais'] as List? ?? []);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    twBadge(context, u['jenis'] as String),
                    const Spacer(),
                    twBadge(context, '${nilais.length} nilai',
                        color: Tw.teal, soft: Tw.tealSoft),
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.menu_book, 'Mapel', u['mapel']?['namaMapel'] ?? 'Umum'),
                _infoRow(Icons.people, 'Kelas', u['kelas']?['namaKelas'] ?? 'Semua kelas'),
                if (u['tanggal'] != null)
                  _infoRow(Icons.event, 'Tanggal',
                      (u['tanggal'] as String).substring(0, 10)),
                if (u['durasiMenit'] != null)
                  _infoRow(Icons.timer, 'Durasi', '${u['durasiMenit']} menit'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Daftar Nilai',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tw.gray900)),
        ),
        if (nilais.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Belum ada nilai diinput.', style: TextStyle(color: Tw.gray500)),
          )
        else
          ...nilais.map((n) {
            final nMap = n as Map<String, dynamic>;
            final santri = nMap['santri'] as Map<String, dynamic>;
            final nilai = (nMap['nilai'] as num).toDouble();
            final color = nilai >= 75 ? Tw.teal : Tw.red;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    nilai.toStringAsFixed(0),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                title: Text(santri['nama'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('NIS ${santri['nis']}${nMap['catatan'] != null ? ' • ${nMap['catatan']}' : ''}',
                    style: const TextStyle(fontSize: 11.5)),
              ),
            );
          }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Tw.gray400),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Tw.gray500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Tw.gray900, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

class _PilihSantriDialog extends StatefulWidget {
  const _PilihSantriDialog();

  @override
  State<_PilihSantriDialog> createState() => _PilihSantriDialogState();
}

class _PilihSantriDialogState extends State<_PilihSantriDialog> {
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
