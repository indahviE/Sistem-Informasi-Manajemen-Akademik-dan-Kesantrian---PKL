import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class KurikulumScreen extends StatefulWidget {
  const KurikulumScreen({super.key});

  @override
  State<KurikulumScreen> createState() => _KurikulumScreenState();
}

class _KurikulumScreenState extends State<KurikulumScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Tw.white,
            elevation: 1,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                tabs: const [
                  Tab(text: 'Kurikulum'),
                  Tab(text: 'Silabus'),
                  Tab(text: 'RPP'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KurikulumTab(),
                _SilabusTab(),
                _RppTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KurikulumTab extends StatefulWidget {
  @override
  State<_KurikulumTab> createState() => _KurikulumTabState();
}

class _KurikulumTabState extends State<_KurikulumTab> {
  List<dynamic> _items = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.kurikulum);
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

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.kurikulum, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kurikulum berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) async {
    final nama = TextEditingController(text: existing?['nama'] as String? ?? '');
    final deskripsi = TextEditingController(text: existing?['deskripsi'] as String? ?? '');
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.folder_copy_rounded,
        title: existing == null ? 'Tambah Kurikulum' : 'Edit Kurikulum',
        fields: [
          TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Kurikulum')),
          TextField(controller: deskripsi, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (nama.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'nama': nama.text.trim(),
                'deskripsi': deskripsi.text.trim().isEmpty ? null : deskripsi.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return hasil;
  }

  Future<void> _edit(Map<String, dynamic> k) async {
    final result = await _form(k);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.kurikulum}/${k['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kurikulum diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hapus(Map<String, dynamic> k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kurikulum'),
        content: Text('Hapus "${k['nama']}" beserta silabus terkait?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.kurikulum}/${k['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kurikulum dihapus')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Tambah',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada kurikulum.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final k = _items[i] as Map<String, dynamic>;
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
                                child: const Icon(Icons.folder_copy, color: Tw.primary),
                              ),
                              title: Text(k['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${k['deskripsi'] ?? '—'} • ${(k['_count'] as Map)['silabus'] ?? 0} silabus',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(k),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _hapus(k),
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

class _SilabusTab extends StatefulWidget {
  @override
  State<_SilabusTab> createState() => _SilabusTabState();
}

class _SilabusTabState extends State<_SilabusTab> {
  List<dynamic> _items = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.silabus);
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

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.silabus, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silabus berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) async {
    final judul = TextEditingController(text: existing?['judul'] as String? ?? '');
    final kd = TextEditingController(text: existing?['kompetensiDasar'] as String? ?? '');
    final materi = TextEditingController(text: existing?['materiPokok'] as String? ?? '');
    final alokasi = TextEditingController(text: existing?['alokasiWaktu'] as String? ?? '');
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.description_rounded,
        title: existing == null ? 'Tambah Silabus' : 'Edit Silabus',
        fields: [
          TextField(controller: judul, decoration: const InputDecoration(labelText: 'Judul Silabus')),
          TextField(controller: kd, decoration: const InputDecoration(labelText: 'Kompetensi Dasar')),
          TextField(controller: materi, decoration: const InputDecoration(labelText: 'Materi Pokok')),
          TextField(controller: alokasi, decoration: const InputDecoration(labelText: 'Alokasi Waktu')),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (judul.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'judul': judul.text.trim(),
                'kompetensiDasar': kd.text.trim().isEmpty ? null : kd.text.trim(),
                'materiPokok': materi.text.trim().isEmpty ? null : materi.text.trim(),
                'alokasiWaktu': alokasi.text.trim().isEmpty ? null : alokasi.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return hasil;
  }

  Future<void> _edit(Map<String, dynamic> s) async {
    final result = await _form(s);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.silabus}/${s['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silabus diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hapus(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Silabus'),
        content: Text('Hapus "${s['judul']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.silabus}/${s['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silabus dihapus')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Tambah',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada silabus.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final s = _items[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Tw.skySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.description, color: Tw.sky),
                              ),
                              title: Text(s['judul'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${s['kompetensiDasar'] ?? ''}'
                                '${s['alokasiWaktu'] != null ? ' • ${s['alokasiWaktu']}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _hapus(s),
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

class _RppTab extends StatefulWidget {
  @override
  State<_RppTab> createState() => _RppTabState();
}

class _RppTabState extends State<_RppTab> {
  List<dynamic> _items = [];
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
      final res = await AppScope.of(context).api.get(ApiUrl.rpp);
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

  Future<void> _add() async {
    final result = await _form();
    if (result == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.rpp, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RPP berhasil ditambah')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<Map<String, dynamic>?> _form([Map<String, dynamic>? existing]) async {
    final judul = TextEditingController(text: existing?['judul'] as String? ?? '');
    final pertemuan = TextEditingController(text: '${existing?['pertemuan'] ?? ''}');
    final tujuan = TextEditingController(text: existing?['tujuan'] as String? ?? '');
    final kegiatan = TextEditingController(text: existing?['kegiatan'] as String? ?? '');
    final penilaian = TextEditingController(text: existing?['penilaian'] as String? ?? '');
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TwFormDialog(
        icon: Icons.menu_book_rounded,
        title: existing == null ? 'Tambah RPP' : 'Edit RPP',
        fields: [
          TextField(controller: judul, decoration: const InputDecoration(labelText: 'Judul RPP')),
          TextField(controller: pertemuan,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pertemuan ke-')),
          TextField(controller: tujuan, decoration: const InputDecoration(labelText: 'Tujuan')),
          TextField(controller: kegiatan, decoration: const InputDecoration(labelText: 'Kegiatan Pembelajaran')),
          TextField(controller: penilaian, decoration: const InputDecoration(labelText: 'Penilaian')),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (judul.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'judul': judul.text.trim(),
                'pertemuan': int.tryParse(pertemuan.text.trim()) ?? 1,
                'tujuan': tujuan.text.trim().isEmpty ? null : tujuan.text.trim(),
                'kegiatan': kegiatan.text.trim().isEmpty ? null : kegiatan.text.trim(),
                'penilaian': penilaian.text.trim().isEmpty ? null : penilaian.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return hasil;
  }

  Future<void> _edit(Map<String, dynamic> r) async {
    final result = await _form(r);
    if (result == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.rpp}/${r['id']}', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RPP diperbarui')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hapus(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus RPP'),
        content: Text('Hapus "${r['judul']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.rpp}/${r['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RPP dihapus')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Tambah',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada RPP.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final r = _items[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Tw.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('P${r['pertemuan']}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Tw.primary)),
                              ),
                              title: Text(r['judul'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${r['tujuan'] ?? ''}'
                                '${r['kegiatan'] != null ? '\n${r['kegiatan']}' : ''}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Tw.gray600, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Tw.red, size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _hapus(r),
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
