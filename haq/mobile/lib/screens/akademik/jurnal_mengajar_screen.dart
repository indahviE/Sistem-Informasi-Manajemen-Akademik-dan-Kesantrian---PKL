import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

// Layar Jurnal Mengajar.
//
// Endpoint (backend NestJS):
//   GET    /jurnal-mengajar?kelasId=       -> array jurnal (+ kelas, mapel, penulis)
//   POST   /jurnal-mengajar                -> {tanggal, kelasId, mapelId?, materi, catatan?}
//   PATCH  /jurnal-mengajar/:id
//   DELETE /jurnal-mengajar/:id
//   GET    /kelas, GET /mapel              -> untuk dropdown
//   GET    /mengajar/saya                  -> penugasan ustadz (kelasId, mapelId)
//
// Pimpinan/Mudir: mode baca saja (tanpa tambah, ubah, hapus).

const double _maxW = 480;

// Warna status (hijau tidak ada di SC; merah ikut SC.errorBg/errorText)
const _kOkBg = Color(0xFFE8F5E9);
const _kOkFg = Color(0xFF1B5E20);
const _kOkBd = Color(0xFFC8E6C9);

Color get _badBd => SC.errorText.withOpacity(0.25);

/// Bar pencarian + filter periode yang menempel di atas saat digulir.
class _PinnedBar extends SliverPersistentHeaderDelegate {
  _PinnedBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: SC.background,
      height: height,
      alignment: Alignment.topCenter,
      child: ClipRect(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
Widget _pill(String text, {required Color bg, required Color fg, Color? bd, IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: bd == null ? null : Border.all(color: bd),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(10.5, FontWeight.w800, fg)),
        ),
      ],
    ),
  );
}

// Dialog bertema (sama dengan halaman Ustadz)
RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

Widget _dialogIcon(IconData icon, Color bg, Color fg) => Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 26, color: fg),
    );

Widget _btnBatal(VoidCallback onTap, {String label = 'Batal'}) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: SC.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, SC.inkSecondary)),
    );

Widget _btnUtama(String label, VoidCallback onTap, {Color? warna}) => FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: warna ?? SC.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, Colors.white)),
    );

class JurnalMengajarScreen extends StatefulWidget {
  const JurnalMengajarScreen({super.key});

  @override
  State<JurnalMengajarScreen> createState() => _JurnalMengajarScreenState();
}

class _JurnalMengajarScreenState extends State<JurnalMengajarScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  List<Map<String, dynamic>> _diampu = []; // kelasDiampu milik ustadz login
  String _filterKelasId = '';
  String _periode = 'semua'; // semua | minggu | bulan
  String _q = '';
  final _searchC = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  String? _error;

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

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
    _bannerTimer?.cancel();
    _searchC.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Peran & kepemilikan
  // ---------------------------------------------------------------------
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

  /// Admin & Pimpinan/Mudir melihat semua jurnal; ustadz hanya miliknya sendiri.
  bool get _lihatSemua => _isAdmin || _readOnly;

  List<Map<String, dynamic>> get _itemsSaya => _lihatSemua
      ? _items
      : _items.where((j) => _myId != null && j['inputOleh'] == _myId).toList();

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
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

    // Ustadz (bukan admin): ambil kelas & mapel yang diampu.
    if (!_isAdmin && mounted) {
      try {
        final res = await AppScope.of(context).api.get('/mengajar/saya');
        final list = res is List ? res : const [];
        if (!mounted) return;
        setState(() => _diampu = list.whereType<Map<String, dynamic>>().toList());
      } catch (_) {}
    }
  }

  /// Admin: semua kelas. Ustadz: hanya kelas yang ada di penugasan mengajarnya.
  List<Map<String, dynamic>> get _kelasBoleh {
    if (_isAdmin) return _kelas;
    final ids = _diampu.map((d) => '${d['kelasId']}').toSet();
    return _kelas.where((k) => ids.contains('${k['id']}')).toList();
  }

  /// Admin: semua mapel. Ustadz: hanya mapel yang ditugaskan di kelas tsb.
  List<Map<String, dynamic>> _mapelBoleh(String kelasId) {
    if (_isAdmin) return _mapel;
    final ids = _diampu
        .where((d) => '${d['kelasId']}' == kelasId)
        .map((d) => '${d['mapelId']}')
        .toSet();
    return _mapel.where((m) => ids.contains('${m['id']}')).toList();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
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
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      } else {
        _toast(e.message, error: true);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------
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

  int _hitung(String p) => _itemsSaya.where((j) => _dalamPeriode(_parseTanggal(j['tanggal']), p)).length;

  List<Map<String, dynamic>> get _tampil {
    final q = _q.toLowerCase();
    return _itemsSaya.where((j) {
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

  // ---------------------------------------------------------------------
  // Banner inline (sama dengan halaman Ustadz)
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
    // Banner ada di bawah hero, jadi gulir ke atas supaya kelihatan.
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _bannerTimer = Timer(Duration(seconds: error ? 5 : 3), _closeBanner);
  }

  void _closeBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerTitle = null);
  }

  Widget _banner() {
    final title = _bannerTitle;
    final error = _bannerError;
    final fg = error ? SC.errorText : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: title == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: error ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: error ? Colors.white : SC.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      error ? Icons.error_outline : Icons.check_rounded,
                      size: 18,
                      color: error ? SC.errorText : SC.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: sty(13.5, FontWeight.w800, fg)),
                        if (_bannerSub != null && _bannerSub!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!, style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75))),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, size: 18, color: fg.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Filter kelas
  // ---------------------------------------------------------------------
  Future<void> _pilihKelas() async {
    if (_kelas.isEmpty) await _loadMaster();
    if (!mounted) return;
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SC.surface,
      constraints: const BoxConstraints(maxWidth: _maxW),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text('Filter Kelas', style: sty(15, FontWeight.w800, SC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text('Semua Kelas',
                        style: sty(14, _filterKelasId.isEmpty ? FontWeight.w800 : FontWeight.w500, SC.ink)),
                    trailing: _filterKelasId.isEmpty
                        ? Icon(Icons.check_circle, color: SC.primary, size: 20)
                        : null,
                    onTap: () => Navigator.pop(ctx, ''),
                  ),
                  for (final k in _kelasBoleh)
                    ListTile(
                      title: Text('${k['namaKelas']}',
                          style: sty(14, _filterKelasId == k['id'] ? FontWeight.w800 : FontWeight.w500, SC.ink)),
                      trailing: _filterKelasId == k['id']
                          ? Icon(Icons.check_circle, color: SC.primary, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, k['id'] as String),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (v != null && v != _filterKelasId) {
      setState(() => _filterKelasId = v);
      _load();
    }
  }

  // ---------------------------------------------------------------------
  // Form tambah / ubah
  // ---------------------------------------------------------------------
  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: sty(13, FontWeight.w500, SC.inkSecondary),
      hintStyle: sty(13, FontWeight.w500, SC.inkMuted),
      floatingLabelStyle: sty(13, FontWeight.w700, SC.primary),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: SC.inkSecondary),
      filled: true,
      fillColor: SC.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(SC.border),
      enabledBorder: b(SC.border),
      focusedBorder: b(SC.primary, 1.4),
      counterStyle: sty(10.5, FontWeight.w500, SC.inkSecondary),
    );
  }

  Future<void> _form([Map<String, dynamic>? old]) async {
    if (_readOnly) return;
    if (_kelas.isEmpty || (!_isAdmin && _diampu.isEmpty)) await _loadMaster();
    if (_kelasBoleh.isEmpty) {
      _toast('Belum ada kelas yang Anda ampu', error: true);
      return;
    }

    final materi = TextEditingController(text: (old?['materi'] ?? '') as String);
    final catatan = TextEditingController(text: (old?['catatan'] ?? '') as String);
    final boleh = _kelasBoleh;
    String kelasId = (old?['kelasId'] ?? boleh.first['id']) as String;
    if (!boleh.any((k) => k['id'] == kelasId)) kelasId = boleh.first['id'] as String;
    String mapelId = (old?['mapelId'] ?? '') as String;
    {
      final mb = _mapelBoleh(kelasId);
      if (!mb.any((m) => m['id'] == mapelId)) {
        mapelId = (!_isAdmin && mb.isNotEmpty) ? mb.first['id'] as String : '';
      }
    }
    DateTime tanggal = old != null ? _parseTanggal(old['tanggal']) : DateTime.now();
    String? err;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SC.background,
      constraints: const BoxConstraints(maxWidth: _maxW),
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
                      decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SC.goldSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: SC.gold.withOpacity(0.45)),
                        ),
                        child: Icon(Icons.cast_for_education_outlined, size: 21, color: SC.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(old == null ? 'Jurnal Baru' : 'Ubah Jurnal',
                                style: sty(19, FontWeight.w800, SC.ink)),
                            const SizedBox(height: 2),
                            Text('Catat kegiatan belajar mengajar hari ini',
                                style: sty(12, FontWeight.w500, SC.inkSecondary)),
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
                      child: Text(_tglPanjang(tanggal), style: sty(13.5, FontWeight.w600, SC.ink)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: kelasId,
                    isExpanded: true,
                    decoration: _dec('Kelas', icon: Icons.groups_2_outlined),
                    borderRadius: BorderRadius.circular(14),
                    style: sty(13.5, FontWeight.w600, SC.ink),
                    items: [
                      for (final k in boleh)
                        DropdownMenuItem(value: k['id'] as String, child: Text('${k['namaKelas']}')),
                    ],
                    onChanged: (v) => setLocal(() {
                      kelasId = v ?? kelasId;
                      // mapel ikut menyesuaikan kelas yang dipilih
                      final mb = _mapelBoleh(kelasId);
                      if (!mb.any((m) => m['id'] == mapelId)) {
                        mapelId = (!_isAdmin && mb.isNotEmpty) ? mb.first['id'] as String : '';
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mapelId,
                    isExpanded: true,
                    decoration: _dec('Mata Pelajaran', icon: Icons.menu_book_outlined),
                    borderRadius: BorderRadius.circular(14),
                    style: sty(13.5, FontWeight.w600, SC.ink),
                    items: [
                      if (_isAdmin || _mapelBoleh(kelasId).isEmpty)
                        const DropdownMenuItem(value: '', child: Text('— tanpa mapel —')),
                      for (final m in _mapelBoleh(kelasId))
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
                    style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
                    decoration: _dec('Materi yang disampaikan', hint: 'Tulis materi yang diajarkan...'),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: catatan,
                    maxLength: 300,
                    maxLines: 3,
                    minLines: 2,
                    style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
                    decoration: _dec('Catatan / kendala (opsional)', hint: 'Misalnya: sebagian santri belum hafal'),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 15, color: SC.errorText),
                        const SizedBox(width: 6),
                        Text(err!, style: sty(12, FontWeight.w700, SC.errorText)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: SC.border),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: SC.primary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () {
                            if (materi.text.trim().isEmpty) {
                              setLocal(() => err = 'Materi wajib diisi.');
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: Text(old == null ? 'Simpan Jurnal' : 'Simpan Perubahan',
                              style: sty(13, FontWeight.w800, Colors.white)),
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
      _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _hapus(Map<String, dynamic> j) async {
    if (_readOnly) return;
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: _dialogIcon(Icons.delete_outline_rounded, SC.errorBg, SC.errorText),
        title: Text('Hapus jurnal?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text('Jurnal yang dihapus tidak bisa dikembalikan.',
            textAlign: TextAlign.center,
            style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(ctx, false)),
          _btnUtama('Hapus', () => Navigator.pop(ctx, true), warna: SC.errorText),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.jurnalMengajar}/${j['id']}');
      _toast('Jurnal dihapus');
      _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Detail
  // ---------------------------------------------------------------------
  void _detail(Map<String, dynamic> j) {
    final d = _parseTanggal(j['tanggal']);
    final kelas = '${(j['kelas'] as Map?)?['namaKelas'] ?? '-'}';
    final mapel = (j['mapel'] as Map?)?['namaMapel'] as String?;
    final penulis = (j['penulis'] as Map?)?['nama'] as String?;
    final catatan = ((j['catatan'] as String?) ?? '').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SC.surface,
      constraints: const BoxConstraints(maxWidth: _maxW),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
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
                    decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: SC.inkSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_tglPanjang(d), style: sty(12, FontWeight.w700, SC.inkSecondary)),
                    ),
                    _statusPill(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(mapel ?? 'Jurnal $kelas', style: sty(19, FontWeight.w800, SC.ink, h: 1.25)),
                const SizedBox(height: 6),
                _metaRow(kelas, penulis),
                const SizedBox(height: 16),
                Text('MATERI', style: sty(10, FontWeight.w800, SC.inkSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                  child: Text('${j['materi']}', style: sty(13.5, FontWeight.w500, SC.ink, h: 1.5)),
                ),
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('CATATAN / KENDALA', style: sty(10, FontWeight.w800, SC.inkSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SC.goldSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SC.gold.withOpacity(0.4)),
                    ),
                    child: Text(catatan, style: sty(13, FontWeight.w500, SC.ink, h: 1.45)),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: SC.inkSecondary),
                    const SizedBox(width: 6),
                    Text('Diserahkan ${_diserahkan(j['createdAt'])}',
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
                if (_canEdit(j)) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SC.errorText,
                            side: BorderSide(color: _badBd),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text('Hapus', style: sty(13, FontWeight.w700, SC.errorText)),
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
                            backgroundColor: SC.primary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                          label: Text('Ubah Jurnal', style: sty(13, FontWeight.w700, Colors.white)),
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

  // ---------------------------------------------------------------------
  // Komponen tampilan
  // ---------------------------------------------------------------------
  Widget _statusPill() =>
      _pill('Terisi', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd, icon: Icons.check_circle_outline);

  Widget _metaRow(String kelas, String? penulis) {
    Widget item(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: SC.inkMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12, FontWeight.w600, SC.inkSecondary)),
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

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    String v(int n) => loaded ? '$n' : '–';

    Widget stat(IconData icon, String value, String label, {bool gold = false}) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: gold ? SC.gold : Colors.white.withOpacity(0.7)),
              const SizedBox(height: 5),
              Text(value, style: sty(20, FontWeight.w800, gold ? SC.gold : Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72))),
            ],
          ),
        );

    Widget garis() => Container(width: 1, height: 44, color: Colors.white.withOpacity(0.18));

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.cast_for_education_outlined, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jurnal Mengajar', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      'Catatan harian kegiatan belajar mengajar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                stat(Icons.menu_book_rounded, v(_itemsSaya.length), 'Total jurnal'),
                garis(),
                stat(Icons.date_range_rounded, v(_hitung('minggu')), 'Minggu ini', gold: true),
                garis(),
                stat(Icons.calendar_month_rounded, v(_hitung('bulan')), 'Bulan ini'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pencarian & filter periode
  // ---------------------------------------------------------------------
  Widget _searchBar() {
    final aktif = _filterKelasId.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _searchC,
          onChanged: (v) => setState(() => _q = v.trim()),
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari materi, kelas, atau mapel',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_q.isNotEmpty)
                  IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () {
                      _searchC.clear();
                      setState(() => _q = '');
                    },
                  ),
                IconButton(
                  tooltip: 'Filter kelas',
                  onPressed: _pilihKelas,
                  icon: Icon(Icons.tune_rounded,
                      size: 20, color: aktif ? SC.goldDark : SC.inkSecondary),
                ),
              ],
            ),
            filled: true,
            fillColor: SC.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: SC.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: SC.primary, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  /// Kontrol segmen Semua / Minggu Ini / Bulan Ini.
  Widget _segmented() {
    Widget seg(String value, String label, int n) {
      final active = _periode == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _periode = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? SC.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$label ($n)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, FontWeight.w700, active ? Colors.white : SC.inkSecondary)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: SC.surfaceDim,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.border),
        ),
        child: Row(
          children: [
            seg('semua', 'Semua', _itemsSaya.length),
            seg('minggu', 'Minggu Ini', _hitung('minggu')),
            seg('bulan', 'Bulan Ini', _hitung('bulan')),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Isi daftar
  // ---------------------------------------------------------------------
  List<Widget> _bodySlivers() {
    if (_loading) {
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: loadingView()))];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }

    if (_itemsSaya.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            judul: 'Belum ada jurnal mengajar',
            pesan: _canWrite
                ? 'Tekan "Jurnal Baru" untuk mencatat kegiatan mengajar.'
                : 'Belum ada catatan dari ustadz.',
          ),
        ),
      ];
    }

    final tampil = _tampil;
    final namaKelas = _namaKelasFilter;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
          child: Row(
            children: [
              Text('Daftar Jurnal', style: sty(15, FontWeight.w800, SC.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('${tampil.length}', style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
              const Spacer(),
              if (_filterKelasId.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() => _filterKelasId = '');
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
                    decoration: BoxDecoration(
                      color: SC.goldSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: SC.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_2_outlined, size: 13, color: SC.goldDark),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(namaKelas ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sty(11, FontWeight.w800, SC.goldDark)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close_rounded, size: 14, color: SC.goldDark),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (tampil.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            judul: 'Tidak ada jurnal yang cocok',
            pesan: 'Coba ubah kata kunci atau filter.',
            icon: Icons.search_off_rounded,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([for (final j in tampil) _card(j)]),
          ),
        ),
    ];
  }

  Widget _kosong({required String judul, required String pesan, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 120),
      child: Column(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: SC.sage.withOpacity(0.55)),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: SC.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(icon ?? Icons.cast_for_education_outlined, size: 38, color: SC.primary),
                ),
                Positioned(top: 8, right: 14, child: Icon(Icons.star_rounded, size: 17, color: SC.gold)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(judul, textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(pesan,
              textAlign: TextAlign.center,
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu jurnal
  // ---------------------------------------------------------------------
  Widget _card(Map<String, dynamic> j) {
    final d = _parseTanggal(j['tanggal']);
    final kelas = '${(j['kelas'] as Map?)?['namaKelas'] ?? '-'}';
    final mapel = (j['mapel'] as Map?)?['namaMapel'] as String?;
    final penulis = (j['penulis'] as Map?)?['nama'] as String?;
    final catatan = ((j['catatan'] as String?) ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _detail(j),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: SC.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 13, color: SC.inkSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_tglPanjang(d),
                                      style: sty(11.5, FontWeight.w700, SC.ink)),
                                ),
                                _statusPill(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(mapel ?? 'Jurnal $kelas',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: sty(16.5, FontWeight.w800, SC.ink, h: 1.25)),
                            const SizedBox(height: 5),
                            _metaRow(kelas, penulis),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${j['materi']}',
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(13, FontWeight.w500, SC.ink, h: 1.45)),
                                  if (catatan.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: SC.goldSurface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: SC.gold.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 1),
                                            child: Icon(Icons.info_outline,
                                                size: 13, color: SC.goldDark),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(catatan,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: sty(11, FontWeight.w600, SC.goldDark)),
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
                                Icon(Icons.verified_user_outlined, size: 14, color: SC.inkMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Diserahkan ${_diserahkan(j['createdAt'])}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sty(11, FontWeight.w500, SC.inkSecondary)),
                                ),
                                Text('Lihat Detail', style: sty(11.5, FontWeight.w800, SC.primary)),
                                Icon(Icons.chevron_right, size: 16, color: SC.primary),
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

  Widget _tombolBaru() {
    return Material(
      color: SC.primary,
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
                decoration: const BoxDecoration(color: SC.gold, shape: BoxShape.circle),
                child: Icon(Icons.add, size: 17, color: SC.primary),
              ),
              const SizedBox(width: 10),
              Text('Jurnal Baru', style: sty(14, FontWeight.w800, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _itemsSaya.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      // Seluruh konten (termasuk tombol "Jurnal Baru") berada di dalam kolom
      // tengah selebar maks. 480, jadi di layar lebar tetap rata tengah.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxW),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefreshIndicator(
                color: SC.primary,
                onRefresh: () => _load(spinner: false),
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedBar(
                        height: showControls ? 118 : 0.0,
                        child: showControls
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [_searchBar(), _segmented()],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (_canWrite && !_loading && _error == null)
                Positioned(right: 16, bottom: 20, child: _tombolBaru()),
            ],
          ),
        ),
      ),
    );
  }
}