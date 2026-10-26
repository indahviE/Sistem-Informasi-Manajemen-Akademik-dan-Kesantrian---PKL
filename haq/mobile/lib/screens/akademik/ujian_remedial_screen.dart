import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// Halaman Sesi Remedial (mandiri: tidak bergantung pada file ujian lain).
//
// Aturan (arahan pembimbing):
//  - Nilai akhir = (nilai ujian + nilai remedial) / 2, maksimal KKM.
//  - Tuntas jika rata-rata >= KKM, selain itu BELUM TUNTAS (tidak ada remedial lanjutan).
//  - Status Tuntas/Belum Tuntas dan nilai akhir DITENTUKAN BACKEND; layar ini hanya menampilkan pratinjau.
//  - KKM mengikuti mata pelajaran (backend mengirimnya lewat field `kkm` ujian).
//
// Pimpinan/Mudir: mode baca saja (form, jadwal, dan simpan hasil disembunyikan).
//
// Sumber data:
//  - GET  {ujian}/:id            -> info ujian + nilais (santri di bawah KKM jadi kandidat remedial)
//  - GET  {ujian}/:id/remedial   -> daftar remedial (opsional; kalau belum ada, dianggap kosong)
//  - POST {ujian}/:id/remedial   -> simpan/upsert remedial per santri

class _C {
  // Ikut tema pondok (diatur admin).
  static Color get emerald => SC.primary;

  static const gold = Color(0xFFC5A059);
  static const goldSoft = Color(0xFFFAF5EC);
  static const goldChip = Color(0xFFFDEFD3);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldText = Color(0xFF775A19);
  static const ivory = Color(0xFFFAF9F5);
  static const border = Color(0xFFEAE6DC);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF475569);
  static const chipGray = Color(0xFFEFEEEA);
  static const fieldFill = Color(0xFFF5F4EE);

  static const okBg = Color(0xFFE8F5E9);
  static const okFg = Color(0xFF1B5E20);
  static const okBd = Color(0xFFC8E6C9);
  static const badBg = Color(0xFFFEE2E2);
  static const badFg = Color(0xFF991B1B);
  static const badBd = Color(0xFFFECACA);
  static const badField = Color(0xFFFFF5F5);
}

const double _maxW = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double _kkmDefault = 75;

// ───────────────────────────── HELPER ─────────────────────────────

/// Notifikasi melayang bertema (sama seperti di layar absensi):
/// sukses = warna tema + ikon emas, gagal = merah lembut.
/// Snackbar melayang otomatis muncul di atas bar bawah (bottomNavigationBar).
void _toast(
  BuildContext context,
  String title, {
  String? subtitle,
  bool error = false,
  IconData? icon,
}) {
  final w = MediaQuery.of(context).size.width;
  final side = w > _maxW + 24 ? (w - (_maxW - 40)) / 2 : 16.0;
  final fg = error ? _C.badFg : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? _C.badBg : _C.emerald,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(side, 0, side, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: Duration(seconds: error ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: error ? _C.badFg.withOpacity(0.25) : _C.gold.withOpacity(0.5),
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: error ? Colors.white : _C.gold.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (error ? Icons.error_outline : Icons.check_rounded),
                size: 18,
                color: error ? _C.badFg : _C.gold,
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

BoxDecoration _cardDeco({double radius = 16}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    );

Widget _pill(String text, Color bg, Color fg,
        {Color? bd, double fs = 10.5, IconData? icon, EdgeInsets? pad}) =>
    Container(
      padding: pad ?? const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: bd == null ? null : Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fs + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: fg, fontSize: fs, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ],
      ),
    );

String _fmtNum(double? v) {
  if (v == null) return '-';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

double? _numOf(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

List<Map<String, dynamic>> _listOf(dynamic v) => ((v as List?) ?? [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();
    
String _initials(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

/// Predikat nilai (Mumtaz / Jayyid Jiddan / Jayyid / Dha'if).
String _predikat(double n, double kkm) {
  if (n >= 85) return 'Mumtaz';
  if (n >= 80) return 'Jayyid Jiddan';
  if (n >= kkm) return 'Jayyid';
  return "Dha'if";
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _tglLengkap(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
String _tglPendek(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';
String _tglRingkas(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';
bool _adaJam(DateTime d) => d.hour != 0 || d.minute != 0;
String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';
/// Jadwal belum tiba. Tanpa jam, dihitung per hari.
bool _belumTiba(DateTime j) {
  final now = DateTime.now();
  if (_adaJam(j)) return now.isBefore(j);
  return DateTime(now.year, now.month, now.day).isBefore(DateTime(j.year, j.month, j.day));
}

/// Jadwal sudah lewat. Tanpa jam, lewat bila harinya sudah lalu.
bool _sudahLewat(DateTime j) {
  final now = DateTime.now();
  if (_adaJam(j)) return now.isAfter(j);
  return DateTime(now.year, now.month, now.day).isAfter(DateTime(j.year, j.month, j.day));
}

// Status sesi remedial
class _St {
  final Color bg;
  final Color fg;
  final Color bd;
  final String pill;
  final String label;
  const _St(this.bg, this.fg, this.bd, this.pill, this.label);
}

_St _stOf(String s) {
  switch (s) {
    case 'TUNTAS':
      return const _St(_C.okBg, _C.okFg, _C.okBd, 'TUNTAS', 'Tuntas');
    case 'BELUM_TUNTAS':
      return const _St(_C.badBg, _C.badFg, _C.badBd, 'BELUM TUNTAS', 'Belum Tuntas');
    case 'PROSES':
      return const _St(_C.goldChip, _C.goldText, _C.goldBorder, 'PROSES', 'Menunggu Sesi');
    default:
      return const _St(_C.badBg, _C.badFg, _C.badBd, 'BELUM TES', 'Belum Tes');
  }
}

String _normStatus(dynamic s) {
  final v = '${s ?? ''}'.toUpperCase();
  if (v == 'TUNTAS') return 'TUNTAS';
  if (v == 'BELUM_TUNTAS') return 'BELUM_TUNTAS';
  if (v == 'PROSES') return 'PROSES';
  return 'BELUM_TES';
}

/// Status final: remedial sudah dinilai dan hasilnya sudah ditentukan backend.
bool _isFinal(String s) => s == 'TUNTAS' || s == 'BELUM_TUNTAS';

/// Santri yang boleh diisi remedialnya: belum final DAN nilai ujian utamanya sudah ada.
bool _bisaDiisi(_Rem r) => !_isFinal(r.status) && !r.belumNilai;

/// Satu baris santri dalam sesi remedial.
class _Rem {
  final dynamic santriId;
  final String nama;
  final String nis;
  final double? awal; // nilai ujian awal
  final double? hasil; // nilai perbaikan (remedial)
  final double? akhir; // nilai akhir dari backend = min((awal + remedial) / 2, KKM)
  final String status; // BELUM_TES | PROSES | TUNTAS | BELUM_TUNTAS
  final String keterangan;
  final String ruang;
  final String catatan; // catatan pembimbing
  final String catatanNilai; // catatan dari nilai ujian utama
  final DateTime? jadwal;
  final DateTime? tenggat;
  final bool belumNilai; // nilai ujian utama belum diinput
  final String? kelas; // nama kelas santri (null bila tidak diketahui)

  const _Rem({
    required this.santriId,
    required this.nama,
    required this.nis,
    required this.awal,
    required this.hasil,
    required this.akhir,
    required this.status,
    required this.keterangan,
    required this.ruang,
    required this.catatan,
    required this.catatanNilai,
    required this.jadwal,
    required this.tenggat,
    this.belumNilai = false,
    this.kelas,
  });
}

/// Halaman Sesi Remedial.
class UjianRemedialScreen extends StatefulWidget {
  final Map<String, dynamic> ujian;
  const UjianRemedialScreen({super.key, required this.ujian});

  @override
  State<UjianRemedialScreen> createState() => _UjianRemedialScreenState();
}

class _UjianRemedialScreenState extends State<UjianRemedialScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _remedials = [];
  bool _loading = true;
  String? _error;

  String _tab = 'ALL'; // ALL | WAIT | DONE
  String _sort = 'STATUS'; // STATUS | NAMA | NILAI

  // Form remedial (santri terpilih)
  dynamic _selId;
  final _ketCtrl = TextEditingController();
  final _nilaiCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  String _status = 'BELUM_TES';
  DateTime? _jadwal;
  bool _saving = false;

  // Tampilan per kelas + jadwal massal
  final Set<String> _terbuka = {};
  bool _kelasAwalDiatur = false;
  final Set<dynamic> _tidakDipilih = {}; // santri yang centangnya dilepas (bawaan: semua tercentang)
    bool _formOpen = false;
  StateSetter? _dialogSet; // untuk menyegarkan isi pop up saat state berubah
  String? _formErr; // pesan kesalahan yang tampil di dalam form
  Map<dynamic, String> _kelasBySantri = {}; // santriId -> nama kelas
  static const _tanpaKelas = 'Belum ada kelas';

  final _formKey = GlobalKey();

  /// Pimpinan/Mudir hanya memantau: tidak bisa mengisi hasil atau menjadwalkan remedial.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  dynamic get _id => widget.ujian['id'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _ketCtrl.dispose();
    _nilaiCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────── DATA ─────────────────────────────

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.ujian}/$_id');

      var rem = <Map<String, dynamic>>[];
      try {
        final rr = await api.get('${ApiUrl.ujian}/$_id/remedial');
        rem = _listOf(rr is Map ? (rr['data'] ?? rr['remedials'] ?? rr['items']) : rr);
      } on ApiException {
        // Endpoint remedial belum ada: pakai santri dengan nilai di bawah KKM saja.
      }

      // Peta santri -> kelas (sekali saja), sama seperti halaman Input Nilai.
      var peta = _kelasBySantri;
      if (peta.isEmpty) {
        try {
          final sr = await api.get(ApiUrl.santri);
          final raw = sr is Map ? (sr['data'] ?? sr['santris'] ?? sr['items']) : sr;
          final m = <dynamic, String>{};
          for (final s in ((raw as List?) ?? []).whereType<Map>()) {
            final k = s['kelas'];
            final nama = k is Map ? '${k['namaKelas'] ?? ''}'.trim() : '';
            if (nama.isNotEmpty) m[s['id']] = nama;
          }
          peta = m;
        } on ApiException {
          // Gagal: kelas jatuh ke nama kelas ujian.
        }
      }

      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _remedials = rem;
        _kelasBySantri = peta;
        _loading = false;
        _aturKelasAwal();
      });

    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _ujian => {...widget.ujian, ...?_data};

  /// KKM milik ujian ini (dikirim backend, mengikuti mata pelajaran; jatuh ke bawaan bila belum ada).
double get _kkm =>
    _numOf(_ujian['kkm']) ?? _numOf(_ujian['mapel']?['kkm']) ?? _kkmDefault;
    
  String get _kkmText =>
      _kkm == _kkm.roundToDouble() ? _kkm.toStringAsFixed(0) : _kkm.toStringAsFixed(1);

  bool get _terkunci => _ujian['dikunciPada'] != null;

  List<Map<String, dynamic>> get _nilais => _listOf(_data?['nilais']);

  String get _kelasNama => '${_ujian['kelas']?['namaKelas'] ?? ''}';
  String get _mapelNama => '${_ujian['mapel']?['namaMapel'] ?? ''}';
    /// Nama kelas santri: dari data santri, lalu peta kelas, lalu kelas ujian.
  String? _kelasSantri(dynamic id, Map<String, dynamic> s) {
    final k = s['kelas'];
    final v = k is Map ? '${k['namaKelas'] ?? ''}'.trim() : '';
    if (v.isNotEmpty) return v;
    return _kelasBySantri[id] ?? (_kelasNama.isEmpty ? null : _kelasNama);
  }

  /// Buka otomatis kelas yang masih punya remedial belum final (sekali saja).
  void _aturKelasAwal() {
    if (_kelasAwalDiatur) return;
    _kelasAwalDiatur = true;
    for (final r in _rows) {
      if (!_isFinal(r.status)) _terbuka.add(r.kelas ?? _tanpaKelas);
    }
  }

  bool _dipilihR(_Rem r) => !_tidakDipilih.contains(r.santriId);

  void _pilihSemua(List<_Rem> daftar, bool pilih) => setState(() {
        for (final r in daftar) {
          pilih ? _tidakDipilih.remove(r.santriId) : _tidakDipilih.add(r.santriId);
        }
      });

  /// Gabungan: santri dengan nilai < KKM (dasar) ditimpa data remedial dari backend.
  List<_Rem> get _rows {
    final byId = <dynamic, _Rem>{};

for (final n in _nilais) {
  final v = _numOf(n['nilai']);
  final kosong = v == null;
  if (!kosong && v >= _kkm) continue; // sudah lulus: lewati
  final s = (n['santri'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  final id = n['santriId'] ?? s['id'];
  byId[id] = _Rem(
    santriId: id,
    nama: '${s['nama'] ?? '-'}',
    nis: '${s['nis'] ?? ''}',
    awal: v,
    hasil: null,
    akhir: null,
    status: 'BELUM_TES',
    keterangan: '',
    ruang: '',
    catatan: '',
    catatanNilai: kosong
        ? 'Nilai ujian utama belum diinput'
        : '${n['catatan'] ?? ''}'.trim(),
    jadwal: null,
    tenggat: null,
    belumNilai: kosong,
    kelas: _kelasSantri(id, s),
  );
}

    for (final r in _remedials) {
      final s = (r['santri'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final id = r['santriId'] ?? s['id'];
      final base = byId[id];
      byId[id] = _Rem(
        santriId: id,
        nama: '${s['nama'] ?? base?.nama ?? '-'}',
        nis: '${s['nis'] ?? base?.nis ?? ''}',
        awal: _numOf(r['nilaiAwal']) ?? base?.awal,
        hasil: _numOf(r['nilaiRemedial']),
        akhir: _numOf(r['nilaiAkhir']),
        status: _normStatus(r['status']),
        keterangan: '${r['keterangan'] ?? ''}'.trim(),
        ruang: '${r['ruang'] ?? ''}'.trim(),
        catatan: '${r['catatan'] ?? ''}'.trim(),
        catatanNilai: base?.catatanNilai ?? '',
        jadwal: _dt(r['jadwal']),
        tenggat: _dt(r['tenggat']),
        belumNilai: false, // sudah punya data remedial = sudah dinilai
        kelas: base?.kelas ?? _kelasSantri(id, s),
      );
    }

    return byId.values.toList();
  }

  int _statusOrder(String s) {
    switch (s) {
      case 'PROSES':
        return 0;
      case 'BELUM_TES':
        return 1;
      case 'BELUM_TUNTAS':
        return 2;
      default:
        return 3; // TUNTAS
    }
  }

  List<_Rem> _sorted(List<_Rem> list) {
    final l = [...list];
    switch (_sort) {
      case 'NAMA':
        l.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        break;
      case 'NILAI':
        l.sort((a, b) => (a.awal ?? 0).compareTo(b.awal ?? 0));
        break;
      default:
        l.sort((a, b) {
          final c = _statusOrder(a.status).compareTo(_statusOrder(b.status));
          return c != 0 ? c : a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
        });
    }
    return l;
  }

  _Rem? get _selected {
    for (final r in _rows) {
      if (r.santriId == _selId) return r;
    }
    return null;
  }

  // ───────────────────────────── AKSI ─────────────────────────────

  void _fillForm(_Rem r) {
    _selId = r.santriId;
    _ketCtrl.text = r.keterangan;
    _nilaiCtrl.text = r.hasil == null ? '' : _fmtNum(r.hasil);
    _catCtrl.text = r.catatan;
    _status = r.status;
    _jadwal = r.jadwal;
  }

    /// Segarkan halaman sekaligus isi pop up (kalau sedang terbuka).
  void _rebuild() {
    if (mounted) setState(() {});
    _dialogSet?.call(() {});
  }

  Future<void> _bukaForm() async {
    if (_formOpen) return;
    _formOpen = true;
    _formErr = null;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          _dialogSet = setD;
          final r = _selected;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxW),
              child: r == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(child: _formCard(r)),
            ),
          );
        },
      ),
    );
    _formOpen = false;
    _dialogSet = null;
    if (mounted) setState(() => _selId = null);
  }

  void _select(_Rem r) {
    if (_readOnly || !_bisaDiisi(r)) return; // final / belum ada nilai: tidak bisa diisi
    setState(() => _fillForm(r));
    _bukaForm();
  }

  double? get _nilaiVal {
    final v = double.tryParse(_nilaiCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  /// Status yang ditampilkan di form. Kalau nilai perbaikan sudah diisi, ini PRATINJAU
  /// dari aturan backend: rata-rata (awal + perbaikan) / 2 dibandingkan dengan KKM.
  String _statusPreview(_Rem r) {
    final v = _nilaiVal;
    if (v != null && r.awal != null) {
      return ((r.awal! + v) / 2 >= _kkm) ? 'TUNTAS' : 'BELUM_TUNTAS';
    }
    return _status == 'PROSES' ? 'PROSES' : 'BELUM_TES';
  }

  Future<void> _pickJadwal() async {
    if (_readOnly) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final init = (_jadwal != null && !_jadwal!.isBefore(today)) ? _jadwal! : today;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _jadwal != null && _adaJam(_jadwal!)
          ? TimeOfDay.fromDateTime(_jadwal!)
          : const TimeOfDay(hour: 15, minute: 30),
    );
    if (!mounted) return;
    _jadwal = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    if (_status == 'BELUM_TES') _status = 'PROSES';
    _rebuild();
  }

    /// Atur satu jadwal untuk beberapa santri sekaligus (satu kelas).
  Future<void> _aturJadwalMassal(String kelas, List<_Rem> target) async {
    if (_readOnly || _saving || target.isEmpty) return;

    final hasil = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _JadwalMassalSheet(
        kelas: kelas,
        nama: target.map((r) => r.nama).toList(),
        perluKet: target.any((r) => r.keterangan.isEmpty),
      ),
    );
    if (hasil == null || !mounted) return;

    final jadwal = hasil['jadwal'] as DateTime;
    final ket = hasil['ket'] as String;
    final gagal = <String>[];

    _saving = true;
    _rebuild();
    try {
      final api = AppScope.of(context).api;
      await Future.wait(target.map((r) async {
        try {
          await api.post('${ApiUrl.ujian}/$_id/remedial', {
            'santriId': r.santriId,
            // Kosong = pakai keterangan yang sudah ada milik santri itu.
            'keterangan': ket.isEmpty ? r.keterangan : ket,
            'status': 'PROSES',
            'catatan': r.catatan,
            'jadwal': jadwal.toIso8601String(),
          });
        } catch (_) {
          gagal.add(r.nama);
        }
      }));
      await _load(silent: true);
      if (!mounted) return;

      final ok = target.length - gagal.length;
      if (gagal.isEmpty) {
        _toast(context, 'Jadwal tersimpan',
            subtitle: '$ok santri • ${_tglPendek(jadwal)}',
            icon: Icons.event_available_outlined);
      } else {
        _toast(context, '$ok dari ${target.length} santri tersimpan',
            subtitle: 'Gagal: ${gagal.join(', ')}', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

    /// Dialog "sudah benar?" sebelum menyimpan. Kalau nilai perbaikan terisi,
  /// hasilnya final dan tidak bisa diubah lagi, jadi ditampilkan lengkap.
  Future<bool> _konfirmasiSimpan(_Rem r, double? v) async {
    final awal = r.awal;
    final double? rata = (v != null && awal != null) ? (awal + v) / 2 : null;
    final double? akhir = rata == null ? null : (rata < _kkm ? rata : _kkm);
    final st = _stOf(_statusPreview(r));

    Widget baris(String label, String value, {Color? warna}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: Text(label, style: const TextStyle(fontSize: 12.5, color: _C.ink2)),
              ),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: warna ?? _C.ink)),
              ),
            ],
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Periksa sebelum menyimpan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              baris('Santri', r.nama),
              baris('Nilai Awal', _fmtNum(r.awal), warna: _C.badFg),
              if (v != null) ...[
                baris('Nilai Perbaikan', _fmtNum(v)),
                baris('Nilai Akhir', _fmtNum(akhir), warna: st.fg),
                baris('Status', st.label, warna: st.fg),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.goldSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.goldBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, size: 15, color: _C.goldText),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Setelah disimpan, hasil remedial dikunci dan tidak bisa diubah lagi.',
                            style: TextStyle(fontSize: 12, height: 1.35, color: _C.goldText)),
                      ),
                    ],
                  ),
                ),
              ] else
                const Text(
                    'Nilai perbaikan belum diisi. Yang disimpan hanya keterangan materi, catatan, dan jadwal.',
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: _C.ink2)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Periksa Lagi',
                style: TextStyle(fontWeight: FontWeight.w700, color: _C.ink2)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _C.emerald,
              shape: const StadiumBorder(),
            ),
            child: const Text('Ya, Simpan',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (_readOnly) return;
    final r = _selected;
    if (r == null) return;
    _formErr = null;

    final ket = _ketCtrl.text.trim();
    if (ket.isEmpty) {
      _formErr = 'Keterangan materi wajib diisi.';
      _rebuild();
      return;
    }
    final raw = _nilaiCtrl.text.trim();
    final v = _nilaiVal;
    if (raw.isNotEmpty && v == null) {
      _formErr = 'Nilai perbaikan harus angka antara 0 – 100.';
      _rebuild();
      return;
    }

    // Jadwal sesi belum tiba: tanya dulu sebelum menyimpan hasil.
    if (v != null && _jadwal != null && _belumTiba(_jadwal!)) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Sesi belum berlangsung'),
          content: Text(
              'Sesi dijadwalkan ${_tglLengkap(_jadwal!)}${_adaJam(_jadwal!) ? ' • ${_jam(_jadwal!)}' : ''}. Tetap simpan hasil sekarang?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Lanjut')),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }

    if (!await _konfirmasiSimpan(r, v)) return;
    if (!mounted) return;

    // Status Tuntas / Belum Tuntas ditentukan backend dari nilai perbaikan.
    // Dari layar ini hanya BELUM_TES atau PROSES yang dikirim.
    final kirimStatus = (v != null || _status == 'PROSES' || _isFinal(_status)) ? 'PROSES' : 'BELUM_TES';

    setState(() => _saving = true);
    try {
      final res = await AppScope.of(context).api.post('${ApiUrl.ujian}/$_id/remedial', {
        'santriId': r.santriId,
        'keterangan': ket,
        'status': kirimStatus,
        'catatan': _catCtrl.text.trim(),
        if (v != null) 'nilaiRemedial': v,
        if (_jadwal != null) 'jadwal': _jadwal!.toIso8601String(),
      });
      await _load(silent: true);
      if (!mounted) return;
      if (_formOpen) Navigator.of(context).pop(); // tutup pop up

      var hasilTxt = '';
      if (res is Map) {
        final st = '${res['status'] ?? ''}'.toUpperCase();
        final ak = _numOf(res['nilaiAkhir']);
        if (st == 'TUNTAS') {
          hasilTxt = 'Tuntas, nilai akhir ${_fmtNum(ak)}';
        } else if (st == 'BELUM_TUNTAS') {
          hasilTxt = 'Belum tuntas, nilai akhir ${_fmtNum(ak)}';
        }
      }
      _toast(
        context,
        'Hasil remedial tersimpan',
        subtitle: hasilTxt.isEmpty ? r.nama : '${r.nama} • $hasilTxt',
      );
    } on ApiException catch (e) {
      _formErr = e.message;
    } catch (_) {
      _formErr = 'Gagal menyimpan hasil remedial.';
    } finally {
      if (mounted) {
        _saving = false;
        _rebuild();
      }
    }
  }

  // ───────────────────────────── BUILD ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.ivory,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxW),
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : RefreshIndicator(onRefresh: _load, child: _buildContent()),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

  Widget _topBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: _C.border),
          right: BorderSide(color: _C.border),
          bottom: BorderSide(color: _C.border),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: _C.ink),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('Kembali ke Detail Ujian',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.ink)),
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

  Widget _buildContent() {
    final rows = _rows;
    final wait = rows.where((r) => !_isFinal(r.status)).length;
    final done = rows.length - wait;

    final filtered = rows.where((r) {
      if (_tab == 'WAIT') return !_isFinal(r.status);
      if (_tab == 'DONE') return _isFinal(r.status);
      return true;
    }).toList();
    final list = _sorted(filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
      children: [
        _titleBlock(),
        const SizedBox(height: 14),
        if (_terkunci) ...[_kunciInfo(), const SizedBox(height: 14)],
        _jadwalCard(rows),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tabChip('Semua Remedial', rows.length, 'ALL'),
              _tabChip('Menunggu Ujian', wait, 'WAIT'),
              _tabChip('Sudah Dinilai', done, 'DONE'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: _cardDeco(),
            child: const Center(
              child: Text('Belum ada santri yang perlu remedial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: _C.ink2)),
            ),
          )
        else ...[
          _listHeader(rows.length),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('Tidak ada data pada filter ini.',
                      style: TextStyle(fontSize: 12.5, color: _C.ink2))),
            )
          else
            ..._daftarKelas(list),
        ],
      ],
    );
  }

  // ── Judul sesi ──
  Widget _titleBlock() {
    final jenis = '${_ujian['jenis'] ?? 'ULANGAN'}';
    final label = switch (jenis) {
      'UAS' => 'UAS',
      'UTS' => 'UTS',
      'TES_TAHFIDZ' => 'Tes Tahfidz',
      'LAINNYA' => 'Penilaian',
      _ => 'Ulangan',
    };
    final sub = [
      if (_mapelNama.isNotEmpty) _mapelNama else '${_ujian['nama'] ?? ''}',
      if (_kelasNama.isNotEmpty) _kelasNama,
    ].where((e) => e.isNotEmpty).join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Sesi Remedial $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: _C.ink)),
            ),
            const SizedBox(width: 8),
            _pill('KKM: $_kkmText', const Color(0xFFFED488), _C.goldText,
                fs: 13, pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
          ],
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 13, color: _C.ink2)),
        ],
      ],
    );
  }

  // ── Jadwal sesi terdekat ──
  _Rem? _nextSession(List<_Rem> rows) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = rows
        .where((r) => !_isFinal(r.status) && r.jadwal != null && !r.jadwal!.isBefore(today))
        .toList()
      ..sort((a, b) => a.jadwal!.compareTo(b.jadwal!));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Widget _jadwalCard(List<_Rem> rows) {
    final next = _nextSession(rows);
    final j = next?.jadwal;

    String? sisa;
    if (j != null) {
      final now = DateTime.now();
      final d = DateTime(j.year, j.month, j.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      sisa = d <= 0 ? 'Hari ini' : (d == 1 ? 'Besok' : '$d Hari Lagi');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: _C.emerald, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_repeat_outlined, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('JADWAL SESI TERDEKAT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: _C.goldText)),
                    ),
                    if (sisa != null) ...[
                      const SizedBox(width: 6),
                      _pill(sisa, _C.badBg, _C.badFg, bd: _C.badBd, fs: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  j == null
                      ? 'Belum ada jadwal sesi'
                      : '${_tglPendek(j)} ${j.year}${_adaJam(j) ? ' • ${_jam(j)}' : ''}',
                  style: TextStyle(
                      fontSize: j == null ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: j == null ? _C.ink2 : _C.ink),
                ),
                if (next != null && next.ruang.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.meeting_room_outlined, size: 14, color: _C.ink2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(next.ruang,
                            style: const TextStyle(fontSize: 12, color: _C.ink2, height: 1.3)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int count, String value) {
    final sel = _tab == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? _C.emerald : _C.chipGray,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$label ($count)',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? Colors.white : _C.ink2)),
        ),
      ),
    );
  }

  // ── Kartu form remedial (santri terpilih) ──
  Widget _formCard(_Rem r) {
    final v = _nilaiVal;
    final awalBelow = r.awal != null && r.awal! < _kkm;

    // Pratinjau aturan backend: nilai akhir = min((awal + perbaikan) / 2, KKM)
    final double? rata = (v != null && r.awal != null) ? (r.awal! + v) / 2 : null;
    final double? akhirPrev = rata == null ? null : (rata < _kkm ? rata : _kkm);
    final prevStatus = _statusPreview(r);
    final st = _stOf(prevStatus);

    final statusBox = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: st.bd),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: st.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(st.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: st.fg)),
          ),
          Icon(_isFinal(prevStatus) ? Icons.check_circle_outline : Icons.schedule,
              size: 18, color: st.fg),
        ],
      ),
    );

    return Container(
      key: _formKey,
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco(),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identitas + nilai awal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _C.chipGray, borderRadius: BorderRadius.circular(12)),
                          child: Text(_initials(r.nama),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800, color: _C.ink)),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _C.goldText,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.edit, size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
                          const SizedBox(height: 2),
                          Text(
                              'NIS: ${r.nis}${_kelasNama.isEmpty ? '' : ' • $_kelasNama'}',
                              style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Nilai Awal',
                            style: TextStyle(fontSize: 11, color: _C.ink2)),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: _fmtNum(r.awal),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: awalBelow ? _C.badFg : _C.ink)),
                          TextSpan(
                              text: ' / $_kkmText',
                              style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                        ])),
                        if (r.awal != null)
                          Text(
                              awalBelow
                                  ? "${_predikat(r.awal!, _kkm)} (Di bawah KKM)"
                                  : _predikat(r.awal!, _kkm),
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: awalBelow ? _C.badFg : _C.okFg)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Keterangan materi
                Row(
                  children: const [
                    Expanded(
                      child: Text('Keterangan Materi Remedial',
                          style: TextStyle(fontSize: 12, color: _C.ink2)),
                    ),
                    Text('*Wajib',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _C.badFg)),
                  ],
                ),
                const SizedBox(height: 6),
                _textArea(_ketCtrl, 'Contoh: Pengulangan tes bab Mu\'tal…', lines: 3),
                const SizedBox(height: 14),

                // Nilai perbaikan + status sesi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nilai Perbaikan',
                              style: TextStyle(fontSize: 12, color: _C.ink2)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                                color: _C.fieldFill, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nilaiCtrl,
                                    // Status tidak lagi diatur dari sini; cukup segarkan pratinjau.
                                    onChanged: (_) => _rebuild(),
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _C.ink),
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(color: _C.ink2),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                if (v != null)
                                  Text(_predikat(v, _kkm),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: v >= _kkm ? _C.goldText : _C.badFg)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Sesi',
                              style: TextStyle(fontSize: 12, color: _C.ink2)),
                          const SizedBox(height: 6),
                          // Nilai perbaikan kosong: status bisa dipilih (Belum Tes / Menunggu Sesi).
                          // Nilai perbaikan terisi: status ditentukan sistem (Tuntas / Belum Tuntas).
                          if (v == null)
                            PopupMenuButton<String>(
                              onSelected: (s) {
                                _status = s;
                                _rebuild();
                              },
                              itemBuilder: (_) => [
                                for (final s in ['BELUM_TES', 'PROSES'])
                                  PopupMenuItem(value: s, child: Text(_stOf(s).label)),
                              ],
                              child: statusBox,
                            )
                          else
                            statusBox,
                        ],
                      ),
                    ),
                  ],
                ),

                // Pratinjau nilai akhir
                if (akhirPrev != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: st.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: st.bd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: _C.ink2),
                          children: [
                            const TextSpan(text: 'Nilai Akhir (pratinjau): '),
                            TextSpan(
                                text: _fmtNum(akhirPrev),
                                style: TextStyle(fontWeight: FontWeight.w800, color: st.fg)),
                            TextSpan(
                                text: ' • ${st.label}',
                                style: TextStyle(fontWeight: FontWeight.w700, color: st.fg)),
                          ],
                        )),
                        const SizedBox(height: 3),
                        Text(
                          '(Nilai Awal ${_fmtNum(r.awal)} + Nilai Perbaikan ${_fmtNum(v)}) ÷ 2 = ${_fmtNum(rata)}, maksimal KKM $_kkmText',
                          style: const TextStyle(fontSize: 11, height: 1.3, color: _C.ink2),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Catatan pembimbing
                const Text('Catatan Pembimbing / Asatidz',
                    style: TextStyle(fontSize: 12, color: _C.ink2)),
                const SizedBox(height: 6),
                _textArea(_catCtrl, 'Tulis catatan perkembangan santri…', lines: 2),

                if (_jadwal != null) ...[
                                  if (_formErr != null) ...[
                  const SizedBox(height: 12),
                  Text(_formErr!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _C.badFg)),
                ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 15, color: _C.goldText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jadwal: ${_tglLengkap(_jadwal!)}${_adaJam(_jadwal!) ? ' • ${_jam(_jadwal!)}' : ''}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _C.goldText),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _btn(r.jadwal != null ? 'Jadwalkan Ulang' : 'Atur Jadwal',
                          icon: Icons.calendar_month_outlined,
                          onTap: _saving ? null : _pickJadwal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _btn('Simpan Hasil',
                          primary: true,
                          icon: Icons.check_circle_outline,
                          loading: _saving,
                          onTap: _saving ? null : _save),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Garis aksen kiri
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: _C.emerald),
          ),
        ],
      ),
    );
  }

  // ── Daftar santri & riwayat ──
  Widget _listHeader(int total) {
    const labels = {'STATUS': 'Status', 'NAMA': 'Nama', 'NILAI': 'Nilai Awal'};
    return Row(
      children: [
        const Text('Daftar Santri & Riwayat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
        const SizedBox(width: 8),
        _pill('$total Total', _C.chipGray, _C.ink2, fs: 10.5),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Urutkan',
          onSelected: (s) => setState(() => _sort = s),
          itemBuilder: (_) => [
            for (final e in labels.entries)
              PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    Icon(Icons.check,
                        size: 16, color: _sort == e.key ? _C.emerald : Colors.transparent),
                    const SizedBox(width: 8),
                    Text(e.value),
                  ],
                ),
              ),
          ],
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Urutkan',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.goldText)),
              SizedBox(width: 4),
              Icon(Icons.swap_vert, size: 16, color: _C.goldText),
            ],
          ),
        ),
      ],
    );
  }

  /// Ringkasan hasil remedial (Awal → Remedial → Nilai Akhir) untuk status final.
  Widget _hasilBody(_Rem r, {required bool tuntas}) {
    final akhir = r.akhir ?? r.hasil;

    Widget kolom(String label, String nilai, Color warna,
            {CrossAxisAlignment align = CrossAxisAlignment.start, String? extra}) =>
        Column(
          crossAxisAlignment: align,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _C.ink2)),
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: nilai,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: warna)),
              if (extra != null)
                TextSpan(
                    text: ' ($extra)',
                    style: const TextStyle(fontSize: 11, color: _C.goldText)),
            ])),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration:
              BoxDecoration(color: _C.fieldFill, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              kolom('Awal', _fmtNum(r.awal), _C.badFg),
              kolom('Remedial', _fmtNum(r.hasil), _C.ink, align: CrossAxisAlignment.center),
              kolom('Nilai Akhir', _fmtNum(akhir), tuntas ? _C.okFg : _C.badFg,
                  align: CrossAxisAlignment.end,
                  extra: akhir == null ? null : _predikat(akhir, _kkm)),
            ],
          ),
        ),
        if (!tuntas) ...[
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline, size: 14, color: _C.badFg),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text('Belum tuntas setelah remedial. Tidak ada remedial lanjutan.',
                    style: TextStyle(fontSize: 11.5, color: _C.badFg, height: 1.3)),
              ),
            ],
          ),
        ],
        if (r.catatan.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('"${r.catatan}"',
              style: const TextStyle(
                  fontSize: 12, fontStyle: FontStyle.italic, color: _C.ink2, height: 1.35)),
        ],
      ],
    );
  }

    List<Widget> _daftarKelas(List<_Rem> list) {
    final groups = <String, List<_Rem>>{};
    for (final r in list) {
      groups.putIfAbsent(r.kelas ?? _tanpaKelas, () => []).add(r);
    }
    final names = groups.keys.toList()
      ..sort((a, b) {
        if (a == _tanpaKelas) return 1;
        if (b == _tanpaKelas) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [for (final k in names) _kelasCard(k, groups[k]!)];
  }

  Widget _kelasCard(String nama, List<_Rem> items) {
    // Angka di judul dihitung dari semua santri kelas ini, bukan hasil filter.
    final semua = _rows.where((r) => (r.kelas ?? _tanpaKelas) == nama).toList();
    final menunggu = semua.where((r) => !_isFinal(r.status)).toList();
    final belumJadwal = menunggu.where((r) => r.jadwal == null).length;
    final lewat =
        menunggu.where((r) => r.jadwal != null && _sudahLewat(r.jadwal!)).length;
    final terjadwal = menunggu.length - belumJadwal - lewat;
    final selesai = semua.length - menunggu.length;

    final buka = _tab != 'ALL' || _terbuka.contains(nama);
    final bisa = items.where(_bisaDiisi).toList();
    final dipilih = bisa.where(_dipilihR).toList();
    final bisaAtur = !_readOnly && bisa.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDeco(radius: 18),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _tab != 'ALL'
                ? null
                : () => setState(() {
                      if (!_terbuka.remove(nama)) _terbuka.add(nama);
                    }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: _C.chipGray, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.class_rounded, size: 20, color: _C.emerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _C.ink)),
                            ),
                            const SizedBox(width: 8),
                            _pill('${semua.length} remedial', _C.badBg, _C.badFg,
                                bd: _C.badBd, fs: 10.5),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (belumJadwal > 0)
                              _pill('$belumJadwal belum dijadwalkan', _C.goldChip,
                                  _C.goldText, bd: _C.goldBorder, fs: 10),
                            if (terjadwal > 0)
                              _pill('$terjadwal terjadwal', _C.chipGray, _C.ink2, fs: 10),
                            if (lewat > 0)
                              _pill('$lewat lewat jadwal', _C.badBg, _C.badFg,
                                  bd: _C.badBd, fs: 10),
                            if (selesai > 0)
                              _pill('$selesai selesai', _C.okBg, _C.okFg,
                                  bd: _C.okBd, fs: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(buka ? Icons.expand_less : Icons.expand_more,
                      size: 24, color: _C.ink2),
                ],
              ),
            ),
          ),
          if (buka) ...[
            const Divider(height: 1, thickness: 1, color: _C.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  if (bisaAtur)
                    Row(
                      children: [
                        Checkbox(
                          value: dipilih.length == bisa.length,
                          activeColor: _C.emerald,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) => _pilihSemua(bisa, v == true),
                        ),
                        Text('Pilih semua (${bisa.length})',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _C.ink2)),
                      ],
                    ),
                  for (final r in items)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_readOnly)
                          SizedBox(
                            width: 40,
                            child: _bisaDiisi(r)
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Checkbox(
                                      value: _dipilihR(r),
                                      activeColor: _C.emerald,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) => setState(() {
                                        if (v == true) {
                                          _tidakDipilih.remove(r.santriId);
                                        } else {
                                          _tidakDipilih.add(r.santriId);
                                        }
                                      }),
                                    ),
                                  )
                                : null,
                          ),
                        Expanded(child: _riwayatTile(r)),
                      ],
                    ),
                  if (bisaAtur) ...[
                    const SizedBox(height: 2),
                    _btn('Atur jadwal (${dipilih.length} santri)',
                        primary: true,
                        icon: Icons.calendar_month_outlined,
                        loading: _saving,
                        onTap: (dipilih.isEmpty || _saving)
                            ? null
                            : () => _aturJadwalMassal(nama, dipilih)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _riwayatTile(_Rem r) {
    final st = _stOf(r.status);
    final isSel = !_readOnly && _bisaDiisi(r) && r.santriId == _selId;
    final tuntas = r.status == 'TUNTAS';
    final belumTuntas = r.status == 'BELUM_TUNTAS';
    final sub = r.keterangan.isNotEmpty
        ? r.keterangan
        : (_mapelNama.isNotEmpty ? _mapelNama : 'Belum ada materi remedial');

    Widget body;
    switch (r.status) {
      case 'TUNTAS':
        body = _hasilBody(r, tuntas: true);
        break;
      case 'BELUM_TUNTAS':
        body = _hasilBody(r, tuntas: false);
        break;
      case 'PROSES':
        final j = r.jadwal;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration:
                  BoxDecoration(color: _C.fieldFill, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 12, color: _C.ink2),
                    children: [
                      const TextSpan(text: 'Nilai Awal: '),
                      TextSpan(
                          text: _fmtNum(r.awal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: _C.badFg)),
                    ],
                  )),
                  const Spacer(),
                  const Icon(Icons.event_outlined, size: 14, color: _C.ink2),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      j == null
                          ? 'Belum dijadwalkan'
                          : '${_sudahLewat(j) ? 'Lewat jadwal • ' : ''}${_tglPendek(j)}${r.ruang.isEmpty ? '' : ' • ${r.ruang}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: (j != null && _sudahLewat(j))
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: (j != null && _sudahLewat(j)) ? _C.badFg : _C.ink2),
                    ),
                  ),
                ],
              ),
            ),
            if (!_readOnly) ...[
              const SizedBox(height: 10),
              _smallBtn('Input Hasil', Icons.edit_note, primary: true, onTap: () => _select(r)),
            ],
          ],
        );
        break;
      default:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 12, color: _C.ink2),
                    children: [
                      const TextSpan(text: 'Nilai Ujian Utama: '),
                      TextSpan(
                          text: r.awal == null
                              ? '-'
                              : '${_fmtNum(r.awal)} (${_predikat(r.awal!, _kkm)})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: _C.badFg)),
                    ],
                  )),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.info_outline, size: 14, color: _C.ink2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            r.catatanNilai.isEmpty
                                ? 'Perlu bimbingan sebelum sesi remedial'
                                : r.catatanNilai,
                            style: const TextStyle(
                                fontSize: 11.5, color: _C.ink2, height: 1.3)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (r.tenggat != null) ...[
              const SizedBox(height: 10),
              Text('Tenggat: ${_tglRingkas(r.tenggat!)}',
                  style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
            ],
          ],
        );
    }

    // Pembeda card: krem = belum ada nilai, merah muda = perlu remedial, putih = final
    final perluTindakan = !_isFinal(r.status);
    final bgCard = r.belumNilai ? _C.goldSoft : (perluTindakan ? _C.badField : Colors.white);
    final aksen = r.belumNilai
        ? _C.gold
        : (perluTindakan ? _C.badFg : (tuntas ? _C.okFg : _C.badFg));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSel ? _C.goldBorder : (r.belumNilai ? _C.goldBorder : _C.border),
            width: isSel ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: _C.emerald.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: (_readOnly || !_bisaDiisi(r)) ? null : () => _select(r),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tuntas
                              ? const Color(0xFFCDE8DC)
                              : (belumTuntas ? _C.badBg : _C.chipGray),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_initials(r.nama),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: tuntas ? _C.okFg : (belumTuntas ? _C.badFg : _C.ink))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: _C.ink)),
                            const SizedBox(height: 2),
                            Text(sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: _C.ink2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        r.belumNilai ? 'BELUM ADA NILAI' : st.pill,
                        r.belumNilai ? _C.goldChip : st.bg,
                        r.belumNilai ? _C.goldText : st.fg,
                        bd: r.belumNilai ? _C.goldBorder : st.bd,
                        fs: 10,
                        icon: _stIcon(r.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  body,
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: aksen),
          ),
        ],
      ),
    );
  }

  IconData? _stIcon(String s) {
    switch (s) {
      case 'TUNTAS':
        return Icons.check_circle_outline;
      case 'BELUM_TUNTAS':
        return Icons.cancel_outlined;
      case 'BELUM_TES':
        return Icons.circle;
      default:
        return null;
    }
  }

  Widget _kunciInfo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.goldSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.goldBorder),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: _C.goldText),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Nilai ujian ini sudah dikunci. Saat terkunci, remedial hanya bisa diisi untuk santri hasil ujian susulan. Untuk mengubah yang lain, buka kunci di halaman Detail Ujian (alasan wajib diisi).',
                  style: TextStyle(fontSize: 12, height: 1.35, color: _C.goldText)),
            ),
          ],
        ),
      );

  // ── Komponen kecil ──
  Widget _smallBtn(String label, IconData icon,
      {bool primary = false, required VoidCallback onTap}) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: primary ? _C.emerald : _C.chipGray,
        foregroundColor: primary ? Colors.white : _C.ink,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _textArea(TextEditingController c, String hint, {int lines = 3}) => TextField(
        controller: c,
        minLines: lines,
        maxLines: lines + 2,
        style: const TextStyle(fontSize: 13, color: _C.ink, height: 1.35),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
          filled: true,
          fillColor: _C.fieldFill,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _C.emerald, width: 2)),
        ),
      );

  Widget _btn(String label,
      {bool primary = false, IconData? icon, bool loading = false, VoidCallback? onTap}) {
    final style = FilledButton.styleFrom(
      backgroundColor: primary ? _C.emerald : _C.chipGray,
      foregroundColor: primary ? Colors.white : _C.ink,
      minimumSize: const Size.fromHeight(46),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
    );
    if (loading) {
      return FilledButton(
        style: style,
        onPressed: onTap,
        child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }
    return FilledButton.icon(
      style: style,
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
    );
  }

  // ── Bar bawah: progres kelas + cetak rekap ──
  Widget _bottomBar() {
    final rows = _rows;
    final aktif = rows.where((r) => !_isFinal(r.status)).length;
    final tuntas = rows.where((r) => r.status == 'TUNTAS').length;
    final belum = rows.where((r) => r.status == 'BELUM_TUNTAS').length;

    Widget dot(Color c) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );

    Widget item(Color c, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(c),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink)),
          ],
        );

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: _C.border),
              left: BorderSide(color: _C.border),
              right: BorderSide(color: _C.border),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                  color: _C.emerald.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Progres Kelas',
                            style: TextStyle(fontSize: 11, color: _C.ink2)),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            item(_C.goldText, '$aktif Aktif'),
                            item(_C.okFg, '$tuntas Tuntas'),
                            item(_C.badFg, '$belum Belum'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JadwalMassalSheet extends StatefulWidget {
  final String kelas;
  final List<String> nama;
  final bool perluKet; // ada santri yang belum punya keterangan materi
  const _JadwalMassalSheet({
    required this.kelas,
    required this.nama,
    required this.perluKet,
  });

  @override
  State<_JadwalMassalSheet> createState() => _JadwalMassalSheetState();
}

class _JadwalMassalSheetState extends State<_JadwalMassalSheet> {
  final _ket = TextEditingController();
  DateTime? _tgl;
  TimeOfDay _waktu = const TimeOfDay(hour: 15, minute: 30);
  String? _err;

  @override
  void dispose() {
    _ket.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _tgl ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _tgl = d);
  }

  Future<void> _pilihJam() async {
    final t = await showTimePicker(context: context, initialTime: _waktu);
    if (t != null) setState(() => _waktu = t);
  }

  void _ok() {
    if (_tgl == null) {
      setState(() => _err = 'Pilih tanggal dulu.');
      return;
    }
    final ket = _ket.text.trim();
    if (ket.isEmpty && widget.perluKet) {
      setState(() => _err = 'Isi keterangan materi dulu.');
      return;
    }
    Navigator.pop(context, {
      'jadwal': DateTime(_tgl!.year, _tgl!.month, _tgl!.day, _waktu.hour, _waktu.minute),
      'ket': ket,
    });
  }

  Widget _kotak(IconData icon, String text, VoidCallback onTap) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
                color: _C.fieldFill, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, size: 17, color: _C.ink2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink)),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = widget.nama.length;
    final ringkas = widget.nama.take(3).join(', ') + (n > 3 ? ' +${n - 3} lainnya' : '');
    final jamTxt =
        '${_waktu.hour.toString().padLeft(2, '0')}.${_waktu.minute.toString().padLeft(2, '0')} WIB';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atur jadwal remedial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.ink)),
            const SizedBox(height: 4),
            Text('${widget.kelas} • $n santri',
                style: const TextStyle(fontSize: 12.5, color: _C.ink2)),
            const SizedBox(height: 2),
            Text(ringkas, style: const TextStyle(fontSize: 12, color: _C.ink2)),
            const SizedBox(height: 14),
            Row(
              children: [
                _kotak(Icons.event_outlined,
                    _tgl == null ? 'Pilih tanggal' : _tglLengkap(_tgl!), _pilihTanggal),
                const SizedBox(width: 10),
                _kotak(Icons.schedule, jamTxt, _pilihJam),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ket,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: _C.ink),
              decoration: InputDecoration(
                hintText: widget.perluKet
                    ? 'Keterangan materi remedial'
                    : 'Keterangan materi (kosongkan untuk memakai yang sudah ada)',
                hintStyle: const TextStyle(fontSize: 13, color: _C.ink2),
                filled: true,
                fillColor: _C.fieldFill,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_err!,
                    style: const TextStyle(fontSize: 12, color: _C.badFg)),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.chipGray,
                      foregroundColor: _C.ink,
                      minimumSize: const Size.fromHeight(46),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _ok,
                    child: const Text('Simpan jadwal',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}