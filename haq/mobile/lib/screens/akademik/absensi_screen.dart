import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama persis dengan `_WC` di dashboard_screen.dart.
class _AC {
  _AC._();

  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

class _StatusStyle {
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final Color dot;
  const _StatusStyle(this.value, this.label, this.bg, this.fg, this.dot);
}

const _kStatus = [
  _StatusStyle('HADIR', 'Hadir', Color(0xFFD2E4DC), Color(0xFF0F3A2E), Color(0xFF0F3A2E)),
  _StatusStyle('IZIN', 'Izin', Color(0xFFF3E2B8), Color(0xFF7A5B10), Color(0xFFB78103)),
  _StatusStyle('SAKIT', 'Sakit', Color(0xFFE6E4DB), Color(0xFF0F172A), Color(0xFF94A3B8)),
  _StatusStyle('ALPA', 'Alpa', Color(0xFFFEE2E2), Color(0xFF991B1B), Color(0xFF991B1B)),
];

/// Batas panjang keterangan (kolom `catatan` di database bertipe VARCHAR(191)).
const _kMaxCatatan = 150;

/// Hanya Izin dan Sakit yang boleh punya keterangan.
bool _needsCatatan(String status) => status == 'IZIN' || status == 'SAKIT';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  List<dynamic> _santris = [];
  String? _kelasId;
  String? _mapelId;
  final Map<String, String> _status = {}; // santriId -> status
  final Map<String, String> _catatan = {}; // santriId -> keterangan (hanya Izin/Sakit)
  DateTime _date = DateTime.now();
  bool _loadingMeta = true;
  bool _loadingSantri = false;
  bool _saving = false;
  bool _saved = false; // true = rekap untuk kelas+mapel+tanggal ini sudah ada di server
  bool _editing = false; // true = admin membuka kunci ("Ubah Rekap")
  int _seq = 0; // penanda request terbaru, supaya respons lama diabaikan
  String? _error;

  /// Terkunci = sudah direkap dan belum dibuka untuk diubah.
  bool get _locked => _saved && !_editing;

  /// SESUAIKAN: ambil role dari session/auth yang Anda pakai.
  bool get _isUstadz {
    final role = AppScope.of(context).user?.role; // ganti sesuai AuthState
    return role == 'USTADZ';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _asList(dynamic res) {
    final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
    return (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _init() async {
    final api = AppScope.of(context).api;
    String? err;
    try {
      // Ustadz hanya mendapat kelas yang ia menjadi wali kelasnya (difilter server).
      _kelas = _asList(await api.get(ApiUrl.kelas, query: {
        if (_isUstadz) 'diampu': 'true',
      }));
    } catch (_) {
      err = 'Gagal memuat daftar kelas.';
    }
    try {
      _mapel = _asList(await api.get(ApiUrl.mapel));
    } catch (_) {
      err ??= 'Gagal memuat daftar mapel.';
    }
    if (!mounted) return;
    setState(() {
      _loadingMeta = false;
      _error = err;
      if (_kelas.isNotEmpty) _kelasId = _kelas.first['id'] as String;
      if (_mapel.isNotEmpty) _mapelId = _mapel.first['id'] as String;
    });
    await _loadSantri();
  }

  /// Muat daftar santri kelas terpilih, lalu muat rekap yang sudah tersimpan.
  Future<void> _loadSantri() async {
    if (_kelasId == null) return;
    final seq = ++_seq;
    setState(() {
      _loadingSantri = true;
      _error = null;
      _saved = false;
      _editing = false;
      _santris = [];
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'kelasId': _kelasId!, 'perPage': '100'});
      if (!mounted || seq != _seq) return;
      setState(() => _santris = (res['items'] as List? ?? []));
      await _fetchSaved(seq);
      if (!mounted || seq != _seq) return;
      setState(() => _loadingSantri = false);
    } on ApiException catch (e) {
      if (mounted && seq == _seq) {
        setState(() {
          _error = e.message;
          _loadingSantri = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) {
        setState(() {
          _error = 'Gagal memuat daftar santri.';
          _loadingSantri = false;
        });
      }
    }
  }

  /// Muat ulang rekap tersimpan (dipakai saat mapel/tanggal berganti atau "Batal").
  Future<void> _reloadSaved() async {
    if (_kelasId == null) return;
    final seq = ++_seq;
    setState(() {
      _loadingSantri = true;
      _error = null;
      _saved = false;
      _editing = false;
    });
    await _fetchSaved(seq);
    if (!mounted || seq != _seq) return;
    setState(() => _loadingSantri = false);
  }

  /// Ambil absensi yang sudah tersimpan untuk kelas + mapel + tanggal terpilih.
  /// Ada data -> status + keterangan diisi dari server dan rekap terkunci.
  /// Tidak ada -> semua santri default HADIR (Draft Rekap).
  Future<void> _fetchSaved(int seq) async {
    final savedStatus = <String, String>{};
    final savedCatatan = <String, String>{};
    String? err;
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.absensi, query: {
        'kelasId': _kelasId!,
        if (_mapelId != null) 'mapelId': _mapelId!,
        'startDate': _iso(_date),
        'endDate': _iso(_date),
      });
      for (final r in _asList(res)) {
        final sid = r['santriId']?.toString();
        final st = r['status']?.toString();
        if (sid == null || st == null) continue;
        savedStatus[sid] = st;
        final cat = r['catatan']?.toString().trim() ?? '';
        if (cat.isNotEmpty) savedCatatan[sid] = cat;
      }
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Gagal memuat rekap tersimpan.';
    }
    if (!mounted || seq != _seq) return;
    setState(() {
      _catatan.clear();
      for (final s in _santris) {
        final id = s['id'] as String;
        final st = savedStatus[id] ?? 'HADIR';
        _status[id] = st;
        final cat = savedCatatan[id];
        if (cat != null && _needsCatatan(st)) _catatan[id] = cat;
      }
      _saved = savedStatus.isNotEmpty;
      _editing = false;
      if (err != null) _error = err;
    });
  }

  /// Ubah status satu santri. Pindah ke Hadir/Alpa otomatis menghapus keterangan.
  void _setStatus(String id, String value) {
    setState(() {
      _status[id] = value;
      if (!_needsCatatan(value)) _catatan.remove(id);
    });
  }

  /// Bentuk data satu santri yang dikirim ke server.
  Map<String, dynamic> _itemPayload(String id) {
    final st = _status[id] ?? 'HADIR';
    final cat = _needsCatatan(st) ? (_catatan[id] ?? '').trim() : '';
    // catatan null = kosongkan keterangan lama di server
    return {'santriId': id, 'status': st, 'catatan': cat.isEmpty ? null : cat};
  }

  Future<void> _save() async {
    if (_santris.isEmpty || _saving) return;
    final wasEditing = _editing;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.post('${ApiUrl.absensi}/bulk', {
        'kelasId': _kelasId,
        'mapelId': _mapelId,
        'tanggal': _iso(_date),
        'items': [
          for (final s in _santris) _itemPayload(s['id'] as String),
        ],
      });
      if (!mounted) return;
      _toast(
        wasEditing ? 'Perubahan rekap disimpan' : 'Absensi berhasil direkap',
        subtitle: '${_santris.length} santri • ${_fmtDate(_date)}',
      );
      setState(() {
        _saving = false;
        _saved = true;
        _editing = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast(e.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('Gagal menyimpan absensi.', error: true);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Notifikasi
  // ---------------------------------------------------------------------
  /// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _AC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _AC.errorBg : _AC.primary,
          elevation: 6,
          // angka 88 = jarak dari bawah supaya tidak menutupi bar simpan
          margin: EdgeInsets.fromLTRB(side, 0, side, 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _AC.errorText.withOpacity(0.25) : _AC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _AC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _AC.errorText : _AC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Keterangan (Izin / Sakit)
  // ---------------------------------------------------------------------
  Future<void> _editCatatan(String id, String status) async {
    final s = _santris.firstWhere((x) => x['id'] == id, orElse: () => <String, dynamic>{});
    final nama = (s['nama'] ?? '').toString().trim();
    final label = status == 'SAKIT' ? 'Sakit' : 'Izin';

    final res = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _AC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CatatanSheet(
        title: nama.isEmpty ? 'Keterangan $label' : 'Keterangan $label • $nama',
        hint: status == 'SAKIT'
            ? 'Contoh: Demam, rawat di poskestren'
            : 'Contoh: Surat izin pulang, keperluan keluarga',
        initial: _catatan[id] ?? '',
      ),
    );

    // null = sheet ditutup tanpa menyimpan
    if (res == null || !mounted) return;
    setState(() {
      final t = res.trim();
      if (t.isEmpty) {
        _catatan.remove(id);
      } else {
        _catatan[id] = t;
      }
    });
  }

  // ---------------------------------------------------------------------
  // Tanggal
  // ---------------------------------------------------------------------
  bool get _isToday {
    final n = DateTime.now();
    return _date.year == n.year && _date.month == n.month && _date.day == n.day;
  }

  void _shiftDate(int days) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + days);
    });
    _reloadSaved();
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _AC.primary),
        ),
        child: child!,
      ),
    );
    if (day != null) {
      setState(() => _date = day);
      _reloadSaved();
    }
  }

  String _fmtDate(DateTime d) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  String _nameOf(List<Map<String, dynamic>> list, String? id, String key) {
    if (id == null) return '-';
    for (final e in list) {
      if (e['id'] == id) return e[key]?.toString() ?? '-';
    }
    return '-';
  }

  // ---------------------------------------------------------------------
  // Pemilih (bottom sheet)
  // ---------------------------------------------------------------------
  Future<void> _showPicker({
    required String title,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required String? selectedId,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: _AC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _AC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in items)
                    ListTile(
                      title: Text('${it[labelKey]}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: it['id'] == selectedId ? FontWeight.w800 : FontWeight.w500,
                            color: _AC.ink,
                          )),
                      trailing: it['id'] == selectedId
                          ? Icon(Icons.check_circle, color: _AC.primary, size: 20)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelect(it['id'] as String);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AC.border),
      ),
      child: child,
    );
  }

  Widget _header() {
    final mulai = _date.month >= 7 ? _date.year : _date.year - 1;
    final smt = _date.month >= 7 ? 'Ganjil' : 'Genap';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Presensi Harian Santri',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _AC.ink)),
        const SizedBox(height: 2),
        Text('T.A. $mulai/${mulai + 1} • Semester $smt',
            style: const TextStyle(fontSize: 12, color: _AC.inkSecondary)),
      ],
    );
  }

  Widget _pickerRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _AC.surfaceDim, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 19, color: _AC.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: _AC.inkSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _AC.ink)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _AC.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ganti',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _AC.primary)),
                  SizedBox(width: 2),
                  Icon(Icons.unfold_more_rounded, size: 14, color: _AC.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateRow() {
    return Container(
      decoration: BoxDecoration(color: _AC.surfaceDim, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftDate(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: _AC.ink),
            tooltip: 'Hari sebelumnya',
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 15, color: _AC.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_fmtDate(_date),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _AC.ink)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isToday ? null : () => _shiftDate(1),
            icon: Icon(Icons.chevron_right_rounded, color: _isToday ? _AC.border : _AC.ink),
            tooltip: 'Hari berikutnya',
          ),
        ],
      ),
    );
  }

  Widget _selectorCard() {
    return _card(
      child: Column(
        children: [
          _pickerRow(
            icon: Icons.groups_2_outlined,
            label: 'KELAS',
            value: _nameOf(_kelas, _kelasId, 'namaKelas'),
            onTap: _kelas.isEmpty
                ? null
                : () => _showPicker(
                      title: 'Pilih Kelas',
                      items: _kelas,
                      labelKey: 'namaKelas',
                      selectedId: _kelasId,
                      onSelect: (v) {
                        setState(() => _kelasId = v);
                        _loadSantri();
                      },
                    ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _AC.border),
          ),
          _pickerRow(
            icon: Icons.menu_book_outlined,
            label: 'MATA PELAJARAN',
            value: _nameOf(_mapel, _mapelId, 'namaMapel'),
            onTap: _mapel.isEmpty
                ? null
                : () => _showPicker(
                      title: 'Pilih Mata Pelajaran',
                      items: _mapel,
                      labelKey: 'namaMapel',
                      selectedId: _mapelId,
                      onSelect: (v) {
                        setState(() => _mapelId = v);
                        _reloadSaved();
                      },
                    ),
          ),
          const SizedBox(height: 12),
          _dateRow(),
        ],
      ),
    );
  }

  Widget _counter(IconData icon, String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required int hadir,
    required int izin,
    required int sakit,
    required int alpa,
    required double pct,
  }) {
    final badge = _locked ? 'Tersimpan' : (_editing ? 'Mode Ubah' : 'Draft Rekap');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AC.primary, _AC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _AC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _AC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KALKULASI KEHADIRAN',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.7))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _AC.gold.withOpacity(0.5)),
                      ),
                      child: Text(badge,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _AC.gold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$total Santri Terdata',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _counter(Icons.check_circle_outline, 'Hadir', hadir),
                    const SizedBox(width: 8),
                    _counter(Icons.mail_outline, 'Izin', izin),
                    const SizedBox(width: 8),
                    _counter(Icons.shield_outlined, 'Sakit', sakit),
                    const SizedBox(width: 8),
                    _counter(Icons.highlight_off, 'Alpa', alpa),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tingkat Kehadiran',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8))),
                    Text('${(pct * 100).toStringAsFixed(1)}% Hadir',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_AC.mint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoCard() {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: _AC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.auto_fix_high, size: 17, color: _AC.gold),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Otomasi Entri',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _AC.ink)),
                Text('Tandai semua santri hadir sebagai default',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _AC.inkSecondary, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() {
              for (final s in _santris) {
                _status[s['id'] as String] = 'HADIR';
              }
              _catatan.clear();
            }),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _AC.mint, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_all, size: 14, color: _AC.primary),
                  SizedBox(width: 4),
                  Text('Set Semua Hadir',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _AC.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSelector(String id, String cur, bool locked) {
    return Opacity(
      opacity: locked ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: _AC.surfaceDim, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            for (final o in _kStatus)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: locked ? null : () => _setStatus(id, o.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cur == o.value ? o.bg : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cur == o.value) ...[
                          Icon(Icons.check, size: 13, color: o.fg),
                          const SizedBox(width: 3),
                        ],
                        Flexible(
                          child: Text(
                            o.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: cur == o.value ? FontWeight.w700 : FontWeight.w600,
                              color: cur == o.value ? o.fg : _AC.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Baris keterangan di bawah selector status (hanya untuk Izin/Sakit).
  Widget _catatanRow(String id, String cur) {
    if (!_needsCatatan(cur)) return const SizedBox.shrink();
    final cat = (_catatan[id] ?? '').trim();
    final locked = _locked;
    // Terkunci dan tidak ada keterangan -> tidak perlu ditampilkan
    if (cat.isEmpty && locked) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: locked ? null : () => _editCatatan(id, cur),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(color: _AC.surfaceDim, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(
                cur == 'SAKIT' ? Icons.medical_services_outlined : Icons.description_outlined,
                size: 15,
                color: _AC.inkSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.isEmpty ? 'Tambah keterangan (opsional)' : 'Ket: $cat',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: cat.isEmpty ? _AC.inkSecondary : _AC.ink,
                  ),
                ),
              ),
              if (!locked) ...[
                const SizedBox(width: 8),
                Text(cat.isEmpty ? 'Isi' : 'Ubah',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _AC.goldDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _santriCard(int index, Map<String, dynamic> s) {
    final id = s['id'] as String;
    final nama = (s['nama'] as String?)?.trim() ?? '-';
    final nis = s['nis']?.toString() ?? '-';
    final asrama = s['asrama']?.toString().trim() ?? '';
    final cur = _status[id] ?? 'HADIR';
    final st = _kStatus.firstWhere((e) => e.value == cur, orElse: () => _kStatus.first);
    final inisial = nama.isNotEmpty && nama != '-' ? nama.substring(0, 1).toUpperCase() : '?';
    final even = index.isEven;

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: even ? _AC.sage : _AC.goldSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(inisial,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: even ? _AC.primary : _AC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _AC.ink)),
                    const SizedBox(height: 2),
                    Text(asrama.isEmpty ? 'NIS $nis' : 'NIS $nis • $asrama',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _AC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: st.dot, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statusSelector(id, cur, _locked),
          _catatanRow(id, cur),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _AC.errorBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: _AC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(fontSize: 12.5, color: _AC.errorText, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(int total, double pct) {
    if (_locked) return _lockedBar(total, pct);
    return _saveBar(total, pct);
  }

  /// Bar saat rekap sudah tersimpan dan terkunci.
  Widget _lockedBar(int total, double pct) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: _AC.surface,
        border: Border(top: BorderSide(color: _AC.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: _AC.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Absensi sudah direkap',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _AC.ink)),
                const SizedBox(height: 2),
                Text('$total Santri • ${(pct * 100).toStringAsFixed(1)}% Hadir',
                    style: const TextStyle(fontSize: 11.5, color: _AC.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Ubah Rekap',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AC.primary,
              side: const BorderSide(color: _AC.border),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ],
      ),
    );
  }

  /// Bar saat draft baru, atau saat mode ubah.
  Widget _saveBar(int total, double pct) {
    final editing = _editing;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: _AC.surface,
        border: Border(top: BorderSide(color: _AC.border)),
      ),
      child: Row(
        children: [
          if (!editing) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Siap Simpan', style: TextStyle(fontSize: 11, color: _AC.inkSecondary)),
                const SizedBox(height: 2),
                Text('$total Santri • ${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _AC.ink)),
              ],
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _AC.primary,
                  disabledBackgroundColor: _AC.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                label: Text(
                  _saving ? 'Menyimpan...' : (editing ? 'Simpan Perubahan' : 'Simpan Rekap'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
          if (editing) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _saving ? null : _reloadSaved,
              style: OutlinedButton.styleFrom(
                foregroundColor: _AC.inkSecondary,
                side: const BorderSide(color: _AC.border),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final total = _santris.length;
    int count(String s) => _santris.where((x) => _status[x['id']] == s).length;
    final hadir = count('HADIR');
    final izin = count('IZIN');
    final sakit = count('SAKIT');
    final alpa = count('ALPA');
    final pct = total > 0 ? hadir / total : 0.0;

    return Scaffold(
      backgroundColor: _AC.background,
      body: _loadingMeta
          ? loadingView()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        children: [
                          _header(),
                          const SizedBox(height: 14),
                          _selectorCard(),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _errorBox(_error!),
                          ],
                          const SizedBox(height: 14),
                          if (_loadingSantri)
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator(color: _AC.primary)),
                            )
                          else if (_isUstadz && _kelas.isEmpty)
                            emptyView('Anda bukan wali kelas di kelas mana pun.')
                          else if (total == 0)
                            emptyView('Kelas ini belum punya santri.')
                          else ...[
                            _summaryCard(
                              total: total,
                              hadir: hadir,
                              izin: izin,
                              sakit: sakit,
                              alpa: alpa,
                              pct: pct,
                            ),
                            if (!_locked) ...[
                              const SizedBox(height: 12),
                              _autoCard(),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daftar Kehadiran Santri',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _AC.ink)),
                                Text(_locked ? 'Rekap terkunci' : 'Ketuk status untuk mengganti',
                                    style: const TextStyle(fontSize: 11, color: _AC.inkSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (int i = 0; i < _santris.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _santriCard(i, _santris[i] as Map<String, dynamic>),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (!_loadingSantri && total > 0) _bottomBar(total, pct),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet input keterangan
// ---------------------------------------------------------------------
class _CatatanSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;

  const _CatatanSheet({required this.title, required this.hint, required this.initial});

  @override
  State<_CatatanSheet> createState() => _CatatanSheetState();
}

class _CatatanSheetState extends State<_CatatanSheet> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // naik mengikuti keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _AC.ink)),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                autofocus: true,
                maxLength: _kMaxCatatan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: _AC.ink),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(fontSize: 13, color: _AC.inkSecondary),
                  filled: true,
                  fillColor: _AC.surfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.initial.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('Hapus',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _AC.errorText)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _c.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: _AC.primary,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Simpan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}