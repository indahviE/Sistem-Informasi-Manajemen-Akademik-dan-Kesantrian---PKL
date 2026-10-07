import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

/// Palet sama dengan layar admin lembaga lainnya (emerald + emas).
class _UsC {
  _UsC._();

  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF7A5B10);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const pendingText = Color(0xFFB78103);
  static const errorText = Color(0xFF991B1B);
}

InputDecoration _dec(String hint, {Widget? suffix}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    hintStyle: const TextStyle(fontSize: 13.5, color: _UsC.inkSecondary),
    filled: true,
    fillColor: _UsC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(_UsC.primary, 1.4),
  );
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _UsC.inkSecondary)),
    );

class UstadzListScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (ada AppBar + tombol kembali).
  final bool showBack;
  const UstadzListScreen({super.key, this.showBack = false});

  @override
  State<UstadzListScreen> createState() => _UstadzListScreenState();
}

class _UstadzListScreenState extends State<UstadzListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA'; // SEMUA | GURU | MUSYRIF
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.ustadz);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar ustadz.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Map<String, dynamic>? _akun(Map<String, dynamic> u) =>
      u['akun'] is Map ? Map<String, dynamic>.from(u['akun'] as Map) : null;

  List<String> _kelasWali(Map<String, dynamic> u) {
    final k = u['kelasDiampu'];
    if (k is! List) return const [];
    return k
        .whereType<Map>()
        .map((e) => '${e['namaKelas'] ?? ''}'.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _tambah() async {
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _UstadzFormDialog(),
    );
    if (res == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.ustadz, res);
      _snack('Ustadz ditambahkan');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _edit(Map<String, dynamic> u) async {
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _UstadzFormDialog(existing: u),
    );
    if (res == null) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.ustadz}/${u['id']}', res);
      _snack('Data ustadz diperbarui');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _hapus(Map<String, dynamic> u) async {
    final punyaKelas = _kelasWali(u).isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _UsC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Ustadz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UsC.ink)),
        content: Text(
          '"${u['nama']}" akan dihapus.'
          '${punyaKelas ? '\nKelas yang dia pegang sebagai wali akan menjadi tanpa wali kelas.' : ''}'
          '${_akun(u) != null ? '\nAkun login-nya tidak ikut terhapus (kelola di menu pengguna).' : ''}',
          style: const TextStyle(fontSize: 13, color: _UsC.inkSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _UsC.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _UsC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _UsC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.ustadz}/${u['id']}');
      _snack('Ustadz dihapus');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _buatAkun(Map<String, dynamic> u) async {
    final jenis = (u['jenis'] ?? 'GURU').toString();
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AkunDialog(nama: '${u['nama'] ?? ''}', jenis: jenis),
    );
    if (res == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.users, {
        'nama': u['nama'],
        'email': res['email'],
        'password': res['password'],
        'role': jenis == 'MUSYRIF' ? 'MUSYRIF' : 'USTADZ',
        'ustadzId': u['id'],
      });
      _snack('Akun untuk ${u['nama']} dibuat');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UsC.background,
      appBar: widget.showBack
          ? AppBar(
              backgroundColor: _UsC.background,
              foregroundColor: _UsC.ink,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text('Ustadz / Guru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UsC.ink)),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              _body(),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _tambah,
                  tooltip: 'Tambah Ustadz',
                  backgroundColor: _UsC.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ustadz Baru',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_items.isEmpty) return emptyView('Belum ada ustadz. Tap "Ustadz Baru" untuk menambah.');

    final q = _q.trim().toLowerCase();
    final list = _items.where((u) {
      if (_filter != 'SEMUA' && (u['jenis'] ?? '').toString() != _filter) return false;
      if (q.isEmpty) return true;
      final email = '${_akun(u)?['email'] ?? ''}'.toLowerCase();
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['noHp'] ?? '').toString().toLowerCase().contains(q) ||
          email.contains(q);
    }).toList();

    return RefreshIndicator(
      color: _UsC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        children: [
          _summaryCard(),
          const SizedBox(height: 14),
          _searchField(),
          const SizedBox(height: 10),
          _filterRow(),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Tidak ada ustadz yang cocok.',
                    style: TextStyle(fontSize: 12.5, color: _UsC.inkSecondary)),
              ),
            )
          else
            for (final u in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ustadzCard(u),
              ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final total = _items.length;
    final tanpaAkun = _items.where((u) => _akun(u) == null).length;
    final waliKelas = _items.where((u) => _kelasWali(u).isNotEmpty).length;

    Widget stat(String value, String label, {bool warn = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: warn ? _UsC.gold : Colors.white)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.72))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_UsC.primary, _UsC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _UsC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _UsC.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('USTADZ / PEMBINA',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: _UsC.gold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('$total', 'Total Ustadz'),
              stat('$waliKelas', 'Wali Kelas'),
              stat('$tanpaAkun', 'Belum Punya Akun', warn: tanpaAkun > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      onChanged: (v) => setState(() => _q = v),
      style: const TextStyle(fontSize: 13.5, color: _UsC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama, no. HP, atau email',
        hintStyle: const TextStyle(fontSize: 13, color: _UsC.inkSecondary),
        prefixIcon: const Icon(Icons.search, size: 19, color: _UsC.inkSecondary),
        filled: true,
        fillColor: _UsC.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: b(_UsC.border),
        enabledBorder: b(_UsC.border),
        focusedBorder: b(_UsC.primary, 1.4),
      ),
    );
  }

  Widget _filterRow() {
    int count(String j) => _items.where((u) => (u['jenis'] ?? '').toString() == j).length;
    Widget chip(String value, String label, int n) {
      final selected = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _UsC.primary : _UsC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? _UsC.primary : _UsC.border),
          ),
          child: Text('$label ($n)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _UsC.inkSecondary,
              )),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('SEMUA', 'Semua', _items.length),
          const SizedBox(width: 8),
          chip('GURU', 'Guru', count('GURU')),
          const SizedBox(width: 8),
          chip('MUSYRIF', 'Musyrif', count('MUSYRIF')),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, FontWeight? weight}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color ?? _UsC.inkSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: color ?? _UsC.inkSecondary, fontWeight: weight)),
          ),
        ],
      ),
    );
  }

  Widget _ustadzCard(Map<String, dynamic> u) {
    final nama = (u['nama'] ?? '-').toString().trim();
    final musyrif = (u['jenis'] ?? 'GURU').toString() == 'MUSYRIF';
    final hp = (u['noHp'] ?? '').toString().trim();
    final akun = _akun(u);
    final aktif = akun != null && (akun['status'] ?? '').toString() == 'AKTIF';
    final kelasWali = _kelasWali(u);
    final inisial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: _UsC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: akun == null ? _UsC.goldBorder : _UsC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: musyrif ? _UsC.goldSurface : _UsC.sage,
                  shape: BoxShape.circle,
                ),
                child: Text(inisial,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: musyrif ? _UsC.gold : _UsC.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _UsC.ink)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: musyrif ? _UsC.goldSurface : _UsC.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(musyrif ? 'Musyrif' : 'Guru',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: musyrif ? _UsC.goldDark : _UsC.primary)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi',
                icon: const Icon(Icons.more_vert, size: 20, color: _UsC.inkSecondary),
                color: _UsC.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') _edit(u);
                  if (v == 'hapus') _hapus(u);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                  PopupMenuItem(
                    value: 'hapus',
                    child: Text('Hapus', style: TextStyle(fontSize: 13, color: _UsC.errorText)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hp.isNotEmpty) _infoRow(Icons.phone_outlined, hp),
          if (kelasWali.isNotEmpty)
            _infoRow(Icons.class_outlined, 'Wali kelas: ${kelasWali.join(', ')}',
                color: _UsC.ink, weight: FontWeight.w600),
          if (akun != null)
            _infoRow(Icons.verified_user_outlined, '${akun['email']} • ${aktif ? 'Aktif' : 'Nonaktif'}')
          else
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined, size: 15, color: _UsC.pendingText),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Belum punya akun login',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _UsC.pendingText)),
                  ),
                  OutlinedButton(
                    onPressed: () => _buatAkun(u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _UsC.primary,
                      side: BorderSide(color: _UsC.primary.withOpacity(0.4)),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Buat Akun',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog tambah/edit ustadz.
class _UstadzFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _UstadzFormDialog({this.existing});

  @override
  State<_UstadzFormDialog> createState() => _UstadzFormDialogState();
}

class _UstadzFormDialogState extends State<_UstadzFormDialog> {
  late final TextEditingController _nama;
  late final TextEditingController _hp;
  late String _jenis;
  String? _err;

  /// Jenis dikunci kalau sudah punya akun, karena role akun (USTADZ/MUSYRIF)
  /// harus sejalan dengan jenisnya.
  bool get _terkunci => widget.existing?['userId'] != null;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?['nama']?.toString() ?? '');
    _hp = TextEditingController(text: widget.existing?['noHp']?.toString() ?? '');
    _jenis = widget.existing?['jenis']?.toString() == 'MUSYRIF' ? 'MUSYRIF' : 'GURU';
  }

  @override
  void dispose() {
    _nama.dispose();
    _hp.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      setState(() => _err = 'Nama wajib diisi.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {
      'nama': _nama.text.trim(),
      'jenis': _jenis,
      'noHp': _hp.text.trim(),
    });
  }

  Widget _jenisChip(String value, String label) {
    final selected = _jenis == value;
    return Expanded(
      child: GestureDetector(
        onTap: _terkunci ? null : () => setState(() => _jenis = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _UsC.primary : _UsC.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _UsC.primary : _UsC.border),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _UsC.inkSecondary,
              )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: _UsC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: _UsC.sage, shape: BoxShape.circle),
            child: Icon(Icons.assignment_ind_rounded, size: 17, color: _UsC.primary),
          ),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit Ustadz' : 'Tambah Ustadz',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UsC.ink)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nama'),
              TextField(
                controller: _nama,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _UsC.ink),
                decoration: _dec('Nama lengkap'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(_err!, style: const TextStyle(fontSize: 11.5, color: _UsC.errorText)),
                ),
              ],
              const SizedBox(height: 12),
              _label('Jenis'),
              Row(
                children: [
                  _jenisChip('GURU', 'Guru'),
                  const SizedBox(width: 8),
                  _jenisChip('MUSYRIF', 'Musyrif'),
                ],
              ),
              if (_terkunci)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 2),
                  child: Text('Jenis dikunci karena sudah punya akun login.',
                      style: TextStyle(fontSize: 11, color: _UsC.inkSecondary)),
                ),
              const SizedBox(height: 12),
              _label('No. HP (opsional)'),
              TextField(
                controller: _hp,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: _UsC.ink),
                decoration: _dec('Contoh: 0812xxxxxxx'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _UsC.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _UsC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _UsC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: _submit,
          child: const Text('Simpan',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}

/// Dialog buat akun login untuk ustadz yang sudah ada datanya.
class _AkunDialog extends StatefulWidget {
  final String nama;
  final String jenis;
  const _AkunDialog({required this.nama, required this.jenis});

  @override
  State<_AkunDialog> createState() => _AkunDialogState();
}

class _AkunDialogState extends State<_AkunDialog> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _show = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Format email tidak valid.');
      return;
    }
    if (_pass.text.length < 6) {
      setState(() => _err = 'Password minimal 6 karakter.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {'email': email, 'password': _pass.text});
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.jenis == 'MUSYRIF' ? 'Musyrif / Pembina' : 'Ustadz / Guru';
    return AlertDialog(
      backgroundColor: _UsC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: _UsC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.lock_person, size: 17, color: _UsC.gold),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Buat Akun Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UsC.ink)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.nama} • $roleLabel',
                  style: const TextStyle(fontSize: 12.5, color: _UsC.inkSecondary)),
              const SizedBox(height: 14),
              _label('Email'),
              TextField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontSize: 14, color: _UsC.ink),
                decoration: _dec('nama@pondok.id'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              const SizedBox(height: 12),
              _label('Password'),
              TextField(
                controller: _pass,
                obscureText: !_show,
                style: const TextStyle(fontSize: 14, color: _UsC.ink),
                decoration: _dec(
                  'Minimal 6 karakter',
                  suffix: IconButton(
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: _UsC.inkSecondary,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(_err!, style: const TextStyle(fontSize: 11.5, color: _UsC.errorText)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _UsC.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _UsC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _UsC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: _submit,
          child: const Text('Buat Akun',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}