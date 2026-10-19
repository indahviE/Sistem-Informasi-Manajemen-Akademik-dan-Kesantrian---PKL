// Layar Jurnal Mengajar (mengikuti desain screen.png).
// Taruh di: lib/screens/akademik/jurnal_mengajar_screen.dart
//
// Endpoint (backend NestJS):
//   GET    /jurnal-mengajar?kelasId=       -> array jurnal (+ kelas, mapel, penulis)
//   POST   /jurnal-mengajar                -> {tanggal, kelasId, mapelId?, materi, catatan?}
//   PATCH  /jurnal-mengajar/:id
//   DELETE /jurnal-mengajar/:id
//   GET    /kelas, GET /mapel              -> untuk dropdown (sesuaikan bila ApiUrl-mu beda)
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama dengan dashboard (Deep Emerald + Antique Gold di atas ivory).
class _JC {
  _JC._();
  // Ikut tema tenant (sama dengan _TC di dashboard_screen.dart).
  static Color get primary => SC.primary;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static const bg = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);
  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const errorText = Color(0xFF991B1B);
  static const errorBg = Color(0xFFFEE2E2);
  // Kotak isi materi (lavender lembut seperti di desain)
  static const noteBg = Color(0xFFF1F2FB);
  static const noteChip = Color(0xFFE4E7F7);
}

class JurnalMengajarScreen extends StatefulWidget {
  const JurnalMengajarScreen({super.key});

  @override
  State<JurnalMengajarScreen> createState() => _JurnalMengajarScreenState();
}

class _JurnalMengajarScreenState extends State<JurnalMengajarScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  String _filterKelasId = '';
  String _periode = 'semua'; // semua | minggu | bulan
  String _q = '';
  final _searchC = TextEditingController();
  bool _loading = true;
  String? _error;

  static const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMaster();
        _load();
      }
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  // ---- peran & kepemilikan ----
  dynamic get _user => AppScope.of(context).user;
  bool get _isAdmin => _user?.isAdmin == true;

  /// Pimpinan/Mudir hanya memantau jurnal: tidak bisa menambah, mengubah, atau menghapus.
  bool get _readOnly => _user?.isPimpinan == true;

  bool get _canWrite => !_readOnly && (_isAdmin || _user?.isUstadz == true);

  String? get _myId {
    final dynamic u = _user;
    for (final g in <dynamic Function()>[() => u.id, () => u.userId]) {
      try {
        final v = g();
        if (v is String) return v;
      } catch (_) {}
    }
    return null;
  }

  bool _canEdit(Map<String, dynamic> j) =>
      !_readOnly && (_isAdmin || (_myId != null && j['inputOleh'] == _myId));

  // ---- data ----
  Future<void> _loadMaster() async {
    try {
      final api = AppScope.of(context).api;
      final k = await api.get('/kelas');
      final m = await api.get('/mapel');
      if (!mounted) return;
      setState(() {
        _kelas = (k as List).cast<Map<String, dynamic>>();
        _mapel = (m as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(
        ApiUrl.jurnalMengajar,
        query: _filterKelasId.isEmpty ? null : {'kelasId': _filterKelasId},
      );
      if (!mounted) return;
      setState(() {
        _items = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // ---- helper ----
  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _parseTanggal(dynamic v) {
    final s = '$v';
    if (s.length >= 10) {
      final d = DateTime.tryParse(s.substring(0, 10));
      if (d != null) return d;
    }
    return DateTime.now();
  }

  String _tglPanjang(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

  String _diserahkan(dynamic createdAt) {
    final c = DateTime.tryParse('$createdAt')?.toLocal();
    if (c == null) return '-';
    final hh = c.hour.toString().padLeft(2, '0');
    final mm = c.minute.toString().padLeft(2, '0');
    return '${c.day} ${_bulan[c.month - 1]}, $hh.$mm WIB';
  }

  bool _dalamPeriode(DateTime d, String p) {
    final now = DateTime.now();
    if (p == 'minggu') {
      final awal = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      return !d.isBefore(awal);
    }
    if (p == 'bulan') return d.year == now.year && d.month == now.month;
    return true;
  }

  int _hitung(String p) => _items.where((j) => _dalamPeriode(_parseTanggal(j['tanggal']), p)).length;

  List<Map<String, dynamic>> get _tampil {
    final q = _q.toLowerCase();
    return _items.where((j) {
      if (!_dalamPeriode(_parseTanggal(j['tanggal']), _periode)) return false;
      if (q.isEmpty) return true;
      final hay = '${j['materi']} ${j['catatan'] ?? ''} '
              '${(j['kelas'] as Map?)?['namaKelas'] ?? ''} ${(j['mapel'] as Map?)?['namaMapel'] ?? ''}'
          .toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  String? get _namaKelasFilter {
    for (final k in _kelas) {
      if (k['id'] == _filterKelasId) return '${k['namaKelas']}';
    }
    return null;
  }

  /// Notifikasi melayang bertema, sama dengan _toast di absensi_screen.dart
  /// (sukses = warna tema + border emas, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _JC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _JC.errorBg : _JC.primary,
          elevation: 6,
          // angka 88 = jarak dari bawah supaya tidak menutupi tombol "Jurnal Baru"
          margin: EdgeInsets.fromLTRB(side, 0, side, 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _JC.errorText.withOpacity(0.25) : _JC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _JC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _JC.errorText : _JC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---- filter kelas ----
  Future<void> _pilihKelas() async {
    if (_kelas.isEmpty) await _loadMaster();
    if (!mounted) return;
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _JC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text('Filter Kelas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _JC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Semua Kelas'),
                    trailing: _filterKelasId.isEmpty ? Icon(Icons.check, color: _JC.primary) : null,
                    onTap: () => Navigator.pop(ctx, ''),
                  ),
                  for (final k in _kelas)
                    ListTile(
                      title: Text('${k['namaKelas']}'),
                      trailing: _filterKelasId == k['id'] ? Icon(Icons.check, color: _JC.primary) : null,
                      onTap: () => Navigator.pop(ctx, k['id'] as String),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (v != null && v != _filterKelasId) {
      setState(() => _filterKelasId = v);
      _load();
    }
  }

  // ---- dekorasi field form ----
  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13, color: _JC.inkSecondary),
      hintStyle: const TextStyle(fontSize: 13, color: _JC.inkSecondary),
      floatingLabelStyle: TextStyle(fontSize: 13, color: _JC.primary, fontWeight: FontWeight.w700),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: _JC.inkSecondary),
      filled: true,
      fillColor: _JC.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(_JC.border),
      enabledBorder: b(_JC.border),
      focusedBorder: b(_JC.primary, 1.5),
      counterStyle: const TextStyle(fontSize: 10.5, color: _JC.inkSecondary),
    );
  }

  // ---- form tambah / ubah ----
  Future<void> _form([Map<String, dynamic>? old]) async {
    if (_readOnly) return;
    if (_kelas.isEmpty) await _loadMaster();
    if (_kelas.isEmpty) {
      _toast('Belum ada data kelas', error: true);
      return;
    }

    final materi = TextEditingController(text: (old?['materi'] ?? '') as String);
    final catatan = TextEditingController(text: (old?['catatan'] ?? '') as String);
    String kelasId = (old?['kelasId'] ?? _kelas.first['id']) as String;
    String mapelId = (old?['mapelId'] ?? '') as String;
    DateTime tanggal = old != null ? _parseTanggal(old['tanggal']) : DateTime.now();
    String? err;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _JC.bg,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: _JC.border, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: _JC.sage, borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.cast_for_education_outlined, size: 22, color: _JC.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(old == null ? 'Jurnal Baru' : 'Ubah Jurnal',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _JC.ink)),
                            const SizedBox(height: 2),
                            const Text('Catat kegiatan belajar mengajar hari ini',
                                style: TextStyle(fontSize: 12, color: _JC.inkSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: tanggal,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (p != null) setLocal(() => tanggal = p);
                    },
                    child: InputDecorator(
                      decoration: _dec('Tanggal', icon: Icons.calendar_today_outlined),
                      child: Text(_tglPanjang(tanggal),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _JC.ink)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: kelasId,
                    isExpanded: true,
                    decoration: _dec('Kelas', icon: Icons.groups_2_outlined),
                    borderRadius: BorderRadius.circular(14),
                    style: const TextStyle(fontSize: 13.5, color: _JC.ink),
                    items: [
                      for (final k in _kelas)
                        DropdownMenuItem(value: k['id'] as String, child: Text('${k['namaKelas']}')),
                    ],
                    onChanged: (v) => setLocal(() => kelasId = v ?? kelasId),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mapelId,
                    isExpanded: true,
                    decoration: _dec('Mata Pelajaran', icon: Icons.menu_book_outlined),
                    borderRadius: BorderRadius.circular(14),
                    style: const TextStyle(fontSize: 13.5, color: _JC.ink),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('— tanpa mapel —')),
                      for (final m in _mapel)
                        DropdownMenuItem(value: m['id'] as String, child: Text('${m['namaMapel']}')),
                    ],
                    onChanged: (v) => setLocal(() => mapelId = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: materi,
                    maxLength: 500,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontSize: 13.5, color: _JC.ink),
                    decoration: _dec('Materi yang disampaikan', hint: 'Tulis materi yang diajarkan...'),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: catatan,
                    maxLength: 300,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(fontSize: 13.5, color: _JC.ink),
                    decoration: _dec('Catatan / kendala (opsional)', hint: 'Misalnya: sebagian santri belum hafal'),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 15, color: _JC.errorText),
                        const SizedBox(width: 6),
                        Text(err!, style: const TextStyle(color: _JC.errorText, fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _JC.inkSecondary,
                            side: const BorderSide(color: _JC.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _JC.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            if (materi.text.trim().isEmpty) {
                              setLocal(() => err = 'Materi wajib diisi.');
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: Text(old == null ? 'Simpan Jurnal' : 'Simpan Perubahan',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;

    final body = {
      'tanggal': _ymd(tanggal),
      'kelasId': kelasId,
      'mapelId': mapelId.isEmpty ? null : mapelId,
      'materi': materi.text.trim(),
      'catatan': catatan.text.trim(),
    };
    try {
      final api = AppScope.of(context).api;
      if (old == null) {
        await api.post(ApiUrl.jurnalMengajar, body);
      } else {
        await api.patch('${ApiUrl.jurnalMengajar}/${old['id']}', body);
      }
      final namaKelas =
          _kelas.firstWhere((k) => k['id'] == kelasId, orElse: () => <String, dynamic>{})['namaKelas'];
      _toast(old == null ? 'Jurnal tersimpan' : 'Jurnal diperbarui',
          subtitle: '${namaKelas ?? '-'} • ${_tglPanjang(tanggal)}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _hapus(Map<String, dynamic> j) async {
    if (_readOnly) return;
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _JC.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: _JC.errorBg, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delete_outline, size: 22, color: _JC.errorText),
                ),
                const SizedBox(height: 14),
                const Text('Hapus jurnal?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _JC.ink)),
                const SizedBox(height: 4),
                const Text('Jurnal yang dihapus tidak bisa dikembalikan.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: _JC.inkSecondary)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _JC.inkSecondary,
                          side: const BorderSide(color: _JC.border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _JC.errorText,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (yakin != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.jurnalMengajar}/${j['id']}');
      _toast('Jurnal dihapus');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  // ---- detail ----
  void _detail(Map<String, dynamic> j) {
    final d = _parseTanggal(j['tanggal']);
    final kelas = '${(j['kelas'] as Map?)?['namaKelas'] ?? '-'}';
    final mapel = (j['mapel'] as Map?)?['namaMapel'] as String?;
    final penulis = (j['penulis'] as Map?)?['nama'] as String?;
    final catatan = ((j['catatan'] as String?) ?? '').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _JC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: _JC.inkSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_tglPanjang(d),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _JC.inkSecondary)),
                    ),
                    _statusPill(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(mapel ?? 'Jurnal $kelas',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _JC.ink, height: 1.25)),
                const SizedBox(height: 6),
                _metaRow(kelas, penulis),
                const SizedBox(height: 16),
                const Text('MATERI',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _JC.inkSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _JC.noteBg, borderRadius: BorderRadius.circular(14)),
                  child: Text('${j['materi']}', style: const TextStyle(fontSize: 13.5, height: 1.5, color: _JC.ink)),
                ),
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('CATATAN / KENDALA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _JC.inkSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _JC.goldSurface, borderRadius: BorderRadius.circular(14)),
                    child: Text(catatan, style: const TextStyle(fontSize: 13, height: 1.45, color: _JC.ink)),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: _JC.inkSecondary),
                    const SizedBox(width: 6),
                    Text('Diserahkan ${_diserahkan(j['createdAt'])}',
                        style: const TextStyle(fontSize: 11.5, color: _JC.inkSecondary)),
                  ],
                ),
                if (_canEdit(j)) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _JC.errorText,
                            side: const BorderSide(color: Color(0xFFF1B8B8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Hapus'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _hapus(j);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _JC.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Ubah Jurnal'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _form(j);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- komponen tampilan ----
  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _JC.successBg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline, size: 13, color: _JC.successText),
          SizedBox(width: 4),
          Text('Terisi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _JC.successText)),
        ],
      ),
    );
  }

  Widget _metaRow(String kelas, String? penulis) {
    Widget item(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _JC.inkSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _JC.inkSecondary)),
            ),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item(Icons.groups_2_outlined, kelas),
        if (penulis != null) item(Icons.person_outline, penulis),
      ],
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jurnal Mengajar',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _JC.ink, height: 1.2)),
              SizedBox(height: 3),
              Text('Catatan harian kegiatan belajar mengajar',
                  style: TextStyle(fontSize: 12, color: _JC.inkSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: _JC.sage, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.cast_for_education_outlined, size: 22, color: _JC.primary),
        ),
      ],
    );
  }

  Widget _searchBar() {
    final aktif = _filterKelasId.isNotEmpty;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: _JC.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _JC.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: _JC.inkSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchC,
              onChanged: (v) => setState(() => _q = v.trim()),
              style: const TextStyle(fontSize: 13, color: _JC.ink),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Cari materi, kelas, atau mapel...',
                hintStyle: TextStyle(fontSize: 13, color: _JC.inkSecondary),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filter kelas',
            onPressed: _pilihKelas,
            icon: Icon(Icons.tune_rounded, size: 20, color: aktif ? _JC.goldDark : _JC.inkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap, {IconData? icon, int? badge}) {
    final fg = selected ? Colors.white : _JC.inkSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _JC.primary : _JC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? _JC.primary : _JC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.2) : _JC.sage,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$badge',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : _JC.primary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    final namaKelas = _namaKelasFilter;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pill('Semua', _periode == 'semua', () => setState(() => _periode = 'semua'), badge: _items.length),
          _pill('Minggu Ini', _periode == 'minggu', () => setState(() => _periode = 'minggu'),
              icon: Icons.calendar_today_outlined),
          _pill('Bulan Ini', _periode == 'bulan', () => setState(() => _periode = 'bulan')),
          if (_filterKelasId.isNotEmpty)
            _pill('Kelas: ${namaKelas ?? '-'}  ✕', true, () {
              setState(() => _filterKelasId = '');
              _load();
            }),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _JC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _JC.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _JC.inkSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _stat('Total Jurnal', '${_items.length}', _JC.ink),
        const SizedBox(width: 10),
        _stat('Minggu Ini', '${_hitung('minggu')}', _JC.primary),
        const SizedBox(width: 10),
        _stat('Bulan Ini', '${_hitung('bulan')}', _JC.goldDark),
      ],
    );
  }

  Widget _card(Map<String, dynamic> j) {
    final d = _parseTanggal(j['tanggal']);
    final kelas = '${(j['kelas'] as Map?)?['namaKelas'] ?? '-'}';
    final mapel = (j['mapel'] as Map?)?['namaMapel'] as String?;
    final penulis = (j['penulis'] as Map?)?['nama'] as String?;
    final catatan = ((j['catatan'] as String?) ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _JC.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _detail(j),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _JC.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: _JC.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 13, color: _JC.inkSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_tglPanjang(d),
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _JC.ink)),
                                ),
                                _statusPill(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(mapel ?? 'Jurnal $kelas',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _JC.ink, height: 1.25)),
                            const SizedBox(height: 5),
                            _metaRow(kelas, penulis),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: _JC.noteBg, borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${j['materi']}',
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, height: 1.45, color: _JC.ink)),
                                  if (catatan.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(color: _JC.noteChip, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 1),
                                            child: Icon(Icons.info_outline, size: 13, color: _JC.inkSecondary),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(catatan,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: _JC.ink)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, size: 14, color: _JC.inkSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Diserahkan ${_diserahkan(j['createdAt'])}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: _JC.inkSecondary)),
                                ),
                                const Text('Lihat Detail',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _JC.ink)),
                                const Icon(Icons.chevron_right, size: 16, color: _JC.ink),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String judul, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _JC.sage, shape: BoxShape.circle),
            child: Icon(Icons.cast_for_education_outlined, size: 30, color: _JC.primary),
          ),
          const SizedBox(height: 14),
          Text(judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _JC.ink)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _JC.inkSecondary)),
        ],
      ),
    );
  }

  Widget _tombolBaru() {
    return Material(
      color: _JC.primary,
      elevation: 6,
      shadowColor: Colors.black45,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _form(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: _JC.gold, shape: BoxShape.circle),
                child: Icon(Icons.add, size: 17, color: _JC.primary),
              ),
              const SizedBox(width: 10),
              const Text('Jurnal Baru',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: _JC.bg, body: loadingView());
    if (_error != null) return Scaffold(backgroundColor: _JC.bg, body: errorView(_error!, _load));

    final tampil = _tampil;
    return Scaffold(
      backgroundColor: _JC.bg,
      // Seluruh konten (termasuk tombol "Jurnal Baru") berada di dalam kolom
      // tengah selebar maks. 480, jadi di layar lebar tetap rata tengah.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _searchBar(),
                    const SizedBox(height: 12),
                    _filterRow(),
                    const SizedBox(height: 14),
                    _statsRow(),
                    const SizedBox(height: 16),
                    if (_items.isEmpty)
                      _empty('Belum ada jurnal mengajar',
                          _canWrite ? 'Tekan "Jurnal Baru" untuk mencatat kegiatan mengajar.' : 'Belum ada catatan dari ustadz.')
                    else if (tampil.isEmpty)
                      _empty('Tidak ada jurnal yang cocok', 'Coba ubah kata kunci atau filter.')
                    else
                      for (final j in tampil) _card(j),
                  ],
                ),
              ),
              if (_canWrite) Positioned(right: 16, bottom: 20, child: _tombolBaru()),
            ],
          ),
        ),
      ),
    );
  }
}