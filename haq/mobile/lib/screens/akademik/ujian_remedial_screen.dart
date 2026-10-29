import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

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

const double _maxW = 480;

/// KKM bawaan, dipakai bila ujian belum punya nilai kkm.
const double _kkmDefault = 75;

// Warna status (hijau tidak ada di SC; merah ikut SC.errorBg/errorText)
const _kOkBg = Color(0xFFE8F5E9);
const _kOkFg = Color(0xFF1B5E20);
const _kOkBd = Color(0xFFC8E6C9);
const _kGoldChip = Color(0xFFFDEFD3);

Color get _badBd => SC.errorText.withOpacity(0.25);

/// Bar pencarian + filter yang menempel di atas saat digulir.
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
Widget _pill(String text,
    {required Color bg, required Color fg, Color? bd, IconData? icon}) {
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

Widget _btnUtama(String label, VoidCallback onTap) => FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: SC.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, Colors.white)),
    );

InputDecoration _dec(String hint) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    filled: true,
    fillColor: SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
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
      return const _St(_kOkBg, _kOkFg, _kOkBd, 'TUNTAS', 'Tuntas');
    case 'BELUM_TUNTAS':
      return _St(SC.errorBg, SC.errorText, _badBd, 'BELUM TUNTAS', 'Belum Tuntas');
    case 'PROSES':
      return _St(SC.goldSurface, SC.goldDark, SC.gold.withOpacity(0.4), 'PROSES', 'Menunggu Sesi');
    default:
      return _St(SC.errorBg, SC.errorText, _badBd, 'BELUM TES', 'Belum Tes');
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
  String _query = '';
  final _searchC = TextEditingController();
  final _scroll = ScrollController();

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

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  IconData? _bannerIcon;
  Timer? _bannerTimer;

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
    _bannerTimer?.cancel();
    _searchC.dispose();
    _scroll.dispose();
    _ketCtrl.dispose();
    _nilaiCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Banner inline (sama dengan halaman Ustadz)
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false, IconData? icon}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
      _bannerIcon = icon;
    });
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
                      _bannerIcon ?? (error ? Icons.error_outline : Icons.check_rounded),
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
  // Data
  // ---------------------------------------------------------------------
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
        _error = null;
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
        catatanNilai:
            kosong ? 'Nilai ujian utama belum diinput' : '${n['catatan'] ?? ''}'.trim(),
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

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
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
      backgroundColor: SC.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        _toast('Jadwal tersimpan',
            subtitle: '$ok santri • ${_tglPendek(jadwal)}',
            icon: Icons.event_available_outlined);
      } else {
        _toast('$ok dari ${target.length} santri tersimpan',
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
                child: Text(label, style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
              ),
              Expanded(
                child: Text(value, style: sty(13, FontWeight.w800, warna ?? SC.ink)),
              ),
            ],
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: _dialogIcon(
            v != null ? Icons.lock_outline_rounded : Icons.fact_check_outlined,
            SC.goldSurface,
            SC.goldDark),
        title: Text('Periksa sebelum menyimpan',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              baris('Santri', r.nama),
              baris('Nilai Awal', _fmtNum(r.awal), warna: SC.errorText),
              if (v != null) ...[
                baris('Nilai Perbaikan', _fmtNum(v)),
                baris('Nilai Akhir', _fmtNum(akhir), warna: st.fg),
                baris('Status', st.label, warna: st.fg),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SC.goldSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SC.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, size: 15, color: SC.goldDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Setelah disimpan, hasil remedial dikunci dan tidak bisa diubah lagi.',
                            style: sty(12, FontWeight.w600, SC.goldDark, h: 1.35)),
                      ),
                    ],
                  ),
                ),
              ] else
                Text(
                    'Nilai perbaikan belum diisi. Yang disimpan hanya keterangan materi, catatan, dan jadwal.',
                    style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.35)),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(ctx, false), label: 'Periksa Lagi'),
          _btnUtama('Ya, Simpan', () => Navigator.pop(ctx, true)),
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
          backgroundColor: SC.surface,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape,
          icon: _dialogIcon(Icons.event_outlined, SC.goldSurface, SC.goldDark),
          title: Text('Sesi belum berlangsung',
              textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
          content: Text(
            'Sesi dijadwalkan ${_tglLengkap(_jadwal!)}${_adaJam(_jadwal!) ? ' • ${_jam(_jadwal!)}' : ''}. Tetap simpan hasil sekarang?',
            textAlign: TextAlign.center,
            style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            _btnBatal(() => Navigator.pop(c, false)),
            _btnUtama('Lanjut', () => Navigator.pop(c, true)),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }

    if (!await _konfirmasiSimpan(r, v)) return;
    if (!mounted) return;

    // Status Tuntas / Belum Tuntas ditentukan backend dari nilai perbaikan.
    // Dari layar ini hanya BELUM_TES atau PROSES yang dikirim.
    final kirimStatus =
        (v != null || _status == 'PROSES' || _isFinal(_status)) ? 'PROSES' : 'BELUM_TES';

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

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _rows.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxW),
          child: RefreshIndicator(
            color: SC.primary,
            onRefresh: () => _load(silent: true),
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _banner()),
                if (!_loading && _error == null) ...[
                  if (_terkunci) SliverToBoxAdapter(child: _kunciInfo()),
                  SliverToBoxAdapter(child: _jadwalCard(_rows)),
                ],
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
        ),
      ),
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    final rows = loaded ? _rows : const <_Rem>[];
    final aktif = rows.where((r) => !_isFinal(r.status)).length;
    final tuntas = rows.where((r) => r.status == 'TUNTAS').length;
    final belum = rows.where((r) => r.status == 'BELUM_TUNTAS').length;

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

    Widget stat(IconData icon, String value, String lbl, {bool gold = false}) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: gold ? SC.gold : Colors.white.withOpacity(0.7)),
              const SizedBox(height: 5),
              Text(value,
                  style: sty(20, FontWeight.w800, gold ? SC.gold : Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(lbl,
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
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.replay_rounded, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sesi Remedial $label',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(20, FontWeight.w800, Colors.white, h: 1.15)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78))),
                    ],
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
                stat(Icons.hourglass_top_rounded, loaded ? '$aktif' : '–', 'Aktif',
                    gold: loaded && aktif > 0),
                garis(),
                stat(Icons.task_alt_rounded, loaded ? '$tuntas' : '–', 'Tuntas'),
                garis(),
                stat(Icons.highlight_off_rounded, loaded ? '$belum' : '–', 'Belum tuntas'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('KKM $_kkmText • Nilai akhir = rata-rata, maksimal KKM',
                  style: sty(11.5, FontWeight.w600, Colors.white.withOpacity(0.85))),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Info kunci
  // ---------------------------------------------------------------------
  Widget _kunciInfo() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SC.goldSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SC.gold.withOpacity(0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: SC.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nilai ujian ini sudah dikunci. Saat terkunci, remedial hanya bisa diisi untuk santri hasil ujian susulan. Untuk mengubah yang lain, buka kunci di halaman Detail Ujian (alasan wajib diisi).',
                  style: sty(12, FontWeight.w600, SC.goldDark, h: 1.35),
                ),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------
  // Jadwal sesi terdekat
  // ---------------------------------------------------------------------
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: SC.primary, shape: BoxShape.circle),
              child: const Icon(Icons.event_repeat_outlined, size: 21, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('JADWAL SESI TERDEKAT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sty(10, FontWeight.w800, SC.goldDark)),
                      ),
                      if (sisa != null) ...[
                        const SizedBox(width: 6),
                        _pill(sisa, bg: SC.errorBg, fg: SC.errorText, bd: _badBd),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    j == null
                        ? 'Belum ada jadwal sesi'
                        : '${_tglPendek(j)} ${j.year}${_adaJam(j) ? ' • ${_jam(j)}' : ''}',
                    style: sty(j == null ? 14 : 16, FontWeight.w800,
                        j == null ? SC.inkSecondary : SC.ink),
                  ),
                  if (next != null && next.ruang.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(Icons.meeting_room_outlined,
                              size: 14, color: SC.inkSecondary),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(next.ruang,
                              style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.3)),
                        ),
                      ],
                    ),
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
  // Pencarian & filter
  // ---------------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _searchC,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari nama atau NIS santri',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () {
                      _searchC.clear();
                      setState(() => _query = '');
                    },
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

  /// Kontrol segmen Semua / Menunggu / Dinilai.
  Widget _segmented() {
    final rows = _rows;
    final wait = rows.where((r) => !_isFinal(r.status)).length;
    final done = rows.length - wait;

    Widget seg(String value, String label, int n) {
      final active = _tab == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = value),
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
            seg('ALL', 'Semua', rows.length),
            seg('WAIT', 'Menunggu', wait),
            seg('DONE', 'Dinilai', done),
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

    final rows = _rows;
    if (rows.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.verified_outlined,
            judul: 'Tidak ada remedial',
            pesan: 'Belum ada santri yang perlu remedial.',
          ),
        ),
      ];
    }

    final q = _query.trim().toLowerCase();
    final filtered = rows.where((r) {
      if (_tab == 'WAIT' && _isFinal(r.status)) return false;
      if (_tab == 'DONE' && !_isFinal(r.status)) return false;
      if (q.isEmpty) return true;
      return '${r.nama} ${r.nis}'.toLowerCase().contains(q);
    }).toList();
    final list = _sorted(filtered);

    return [
      SliverToBoxAdapter(child: _listHeader(rows.length)),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada santri yang cocok dengan pencarian atau filter ini.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
                _daftarKelas(list, menyaring: q.isNotEmpty || _tab != 'ALL')),
          ),
        ),
    ];
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 96),
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
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: SC.sage.withOpacity(0.55)),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: SC.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
                  ),
                  child: Icon(icon, size: 38, color: SC.primary),
                ),
                Positioned(
                    top: 8, right: 14, child: Icon(Icons.star_rounded, size: 17, color: SC.gold)),
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
  // Form remedial (pop up)
  // ---------------------------------------------------------------------
  Widget _label(String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Row(
          children: [
            Expanded(child: Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary))),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _formCard(_Rem r) {
    final v = _nilaiVal;
    final awalBelow = r.awal != null && r.awal! < _kkm;

    // Pratinjau aturan backend: nilai akhir = min((awal + perbaikan) / 2, KKM)
    final double? rata = (v != null && r.awal != null) ? (r.awal! + v) / 2 : null;
    final double? akhirPrev = rata == null ? null : (rata < _kkm ? rata : _kkm);
    final prevStatus = _statusPreview(r);
    final st = _stOf(prevStatus);

    final statusBox = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(14),
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
                style: sty(12.5, FontWeight.w800, st.fg)),
          ),
          Icon(_isFinal(prevStatus) ? Icons.check_circle_outline : Icons.schedule,
              size: 18, color: st.fg),
        ],
      ),
    );

    return Container(
      key: _formKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + tutup
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: SC.goldDark, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('INPUT HASIL', style: sty(10, FontWeight.w800, SC.goldDark)),
              const Spacer(),
              InkWell(
                onTap: _saving ? null : () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SC.surfaceDim,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.border),
                  ),
                  child: const Icon(Icons.close_rounded, size: 17, color: SC.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Identitas + nilai awal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SC.surfaceDim, shape: BoxShape.circle),
                child: Text(_initials(r.nama), style: sty(15, FontWeight.w800, SC.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(15, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 2),
                    Text('NIS: ${r.nis}${_kelasNama.isEmpty ? '' : ' • $_kelasNama'}',
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Nilai Awal', style: sty(11, FontWeight.w500, SC.inkSecondary)),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: _fmtNum(r.awal),
                        style: sty(20, FontWeight.w800, awalBelow ? SC.errorText : SC.ink)),
                    TextSpan(
                        text: ' / $_kkmText',
                        style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ])),
                  if (r.awal != null)
                    Text(
                        awalBelow
                            ? "${_predikat(r.awal!, _kkm)} (Di bawah KKM)"
                            : _predikat(r.awal!, _kkm),
                        style: sty(10.5, FontWeight.w700,
                            awalBelow ? SC.errorText : _kOkFg)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Keterangan materi
          _label('Keterangan materi remedial',
              trailing: Text('*Wajib', style: sty(11, FontWeight.w800, SC.errorText))),
          TextField(
            controller: _ketCtrl,
            minLines: 3,
            maxLines: 5,
            style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
            decoration: _dec("Contoh: Pengulangan tes bab Mu'tal…"),
          ),
          const SizedBox(height: 14),

          // Nilai perbaikan + status sesi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nilai perbaikan'),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nilaiCtrl,
                              // Status tidak lagi diatur dari sini; cukup segarkan pratinjau.
                              onChanged: (_) => _rebuild(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              style: sty(18, FontWeight.w800, SC.ink),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: sty(18, FontWeight.w800, SC.inkMuted),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (v != null)
                            Text(_predikat(v, _kkm),
                                style: sty(11, FontWeight.w800,
                                    v >= _kkm ? SC.goldDark : SC.errorText)),
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
                    _label('Status sesi'),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: st.bd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(
                    style: sty(12.5, FontWeight.w500, SC.inkSecondary),
                    children: [
                      const TextSpan(text: 'Nilai Akhir (pratinjau): '),
                      TextSpan(
                          text: _fmtNum(akhirPrev),
                          style: sty(12.5, FontWeight.w800, st.fg)),
                      TextSpan(
                          text: ' • ${st.label}', style: sty(12.5, FontWeight.w800, st.fg)),
                    ],
                  )),
                  const SizedBox(height: 3),
                  Text(
                    '(Nilai Awal ${_fmtNum(r.awal)} + Nilai Perbaikan ${_fmtNum(v)}) ÷ 2 = ${_fmtNum(rata)}, maksimal KKM $_kkmText',
                    style: sty(11, FontWeight.w500, SC.inkSecondary, h: 1.3),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Catatan pembimbing
          _label('Catatan pembimbing / asatidz'),
          TextField(
            controller: _catCtrl,
            minLines: 2,
            maxLines: 4,
            style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
            decoration: _dec('Tulis catatan perkembangan santri…'),
          ),

          if (_formErr != null) ...[
            const SizedBox(height: 12),
            Text(_formErr!, style: sty(12, FontWeight.w700, SC.errorText)),
          ],

          if (_jadwal != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 15, color: SC.goldDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Jadwal: ${_tglLengkap(_jadwal!)}${_adaJam(_jadwal!) ? ' • ${_jam(_jadwal!)}' : ''}',
                    style: sty(12, FontWeight.w700, SC.goldDark),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _pickJadwal,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SC.border),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: Icon(Icons.calendar_month_outlined, size: 17, color: SC.primary),
                  label: Text(r.jadwal != null ? 'Jadwalkan Ulang' : 'Atur Jadwal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w700, SC.primary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: SC.primary,
                    disabledBackgroundColor: SC.primary.withOpacity(0.5),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 17, color: Colors.white),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan Hasil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w700, Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Daftar santri & riwayat
  // ---------------------------------------------------------------------
  Widget _listHeader(int total) {
    const labels = {'STATUS': 'Status', 'NAMA': 'Nama', 'NILAI': 'Nilai Awal'};
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
      child: Row(
        children: [
          Text('Daftar Santri', style: sty(15, FontWeight.w800, SC.ink)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
            child: Text('$total', style: sty(10.5, FontWeight.w800, SC.primary)),
          ),
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
                          size: 16, color: _sort == e.key ? SC.primary : Colors.transparent),
                      const SizedBox(width: 8),
                      Text(e.value),
                    ],
                  ),
                ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Urutkan', style: sty(12.5, FontWeight.w800, SC.goldDark)),
                const SizedBox(width: 4),
                Icon(Icons.swap_vert, size: 16, color: SC.goldDark),
              ],
            ),
          ),
        ],
      ),
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
            Text(label, style: sty(11, FontWeight.w500, SC.inkSecondary)),
            Text.rich(TextSpan(children: [
              TextSpan(text: nilai, style: sty(16, FontWeight.w800, warna)),
              if (extra != null)
                TextSpan(text: ' ($extra)', style: sty(11, FontWeight.w600, SC.goldDark)),
            ])),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              kolom('Awal', _fmtNum(r.awal), SC.errorText),
              kolom('Remedial', _fmtNum(r.hasil), SC.ink, align: CrossAxisAlignment.center),
              kolom('Nilai Akhir', _fmtNum(akhir), tuntas ? _kOkFg : SC.errorText,
                  align: CrossAxisAlignment.end,
                  extra: akhir == null ? null : _predikat(akhir, _kkm)),
            ],
          ),
        ),
        if (!tuntas) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline, size: 14, color: SC.errorText),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Belum tuntas setelah remedial. Tidak ada remedial lanjutan.',
                    style: sty(11.5, FontWeight.w600, SC.errorText, h: 1.3)),
              ),
            ],
          ),
        ],
        if (r.catatan.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('"${r.catatan}"',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: SC.inkSecondary,
                  height: 1.35)),
        ],
      ],
    );
  }

  List<Widget> _daftarKelas(List<_Rem> list, {required bool menyaring}) {
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
    return [for (final k in names) _kelasCard(k, groups[k]!, paksaBuka: menyaring)];
  }

  Widget _kelasCard(String nama, List<_Rem> items, {required bool paksaBuka}) {
    // Angka di judul dihitung dari semua santri kelas ini, bukan hasil filter.
    final semua = _rows.where((r) => (r.kelas ?? _tanpaKelas) == nama).toList();
    final menunggu = semua.where((r) => !_isFinal(r.status)).toList();
    final belumJadwal = menunggu.where((r) => r.jadwal == null).length;
    final lewat = menunggu.where((r) => r.jadwal != null && _sudahLewat(r.jadwal!)).length;
    final terjadwal = menunggu.length - belumJadwal - lewat;
    final selesai = semua.length - menunggu.length;

    final buka = paksaBuka || _terbuka.contains(nama);
    final tanpaKelas = nama == _tanpaKelas;
    final bisa = items.where(_bisaDiisi).toList();
    final dipilih = bisa.where(_dipilihR).toList();
    final bisaAtur = !_readOnly && bisa.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: paksaBuka
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
                      color: tanpaKelas ? SC.surfaceDim : SC.sage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tanpaKelas ? Icons.help_outline_rounded : Icons.class_rounded,
                      size: 20,
                      color: tanpaKelas ? SC.inkSecondary : SC.primary,
                    ),
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
                                  style: sty(15, FontWeight.w800, SC.ink)),
                            ),
                            const SizedBox(width: 8),
                            _pill('${semua.length} remedial',
                                bg: SC.errorBg, fg: SC.errorText, bd: _badBd),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (belumJadwal > 0)
                              _pill('$belumJadwal belum dijadwalkan',
                                  bg: SC.goldSurface,
                                  fg: SC.goldDark,
                                  bd: SC.gold.withOpacity(0.4)),
                            if (terjadwal > 0)
                              _pill('$terjadwal terjadwal',
                                  bg: SC.surfaceDim, fg: SC.inkSecondary, bd: SC.border),
                            if (lewat > 0)
                              _pill('$lewat lewat jadwal',
                                  bg: SC.errorBg, fg: SC.errorText, bd: _badBd),
                            if (selesai > 0)
                              _pill('$selesai selesai', bg: _kOkBg, fg: _kOkFg, bd: _kOkBd),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(buka ? Icons.expand_less : Icons.expand_more,
                      size: 24, color: SC.inkSecondary),
                ],
              ),
            ),
          ),
          if (buka) ...[
            const Divider(height: 1, thickness: 1, color: SC.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  if (bisaAtur)
                    Row(
                      children: [
                        Checkbox(
                          value: dipilih.length == bisa.length,
                          activeColor: SC.primary,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) => _pilihSemua(bisa, v == true),
                        ),
                        Text('Pilih semua (${bisa.length})',
                            style: sty(12.5, FontWeight.w700, SC.inkSecondary)),
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
                                      activeColor: SC.primary,
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
                    FilledButton.icon(
                      onPressed: (dipilih.isEmpty || _saving)
                          ? null
                          : () => _aturJadwalMassal(nama, dipilih),
                      style: FilledButton.styleFrom(
                        backgroundColor: SC.primary,
                        disabledBackgroundColor: SC.primary.withOpacity(0.4),
                        minimumSize: const Size.fromHeight(48),
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calendar_month_outlined,
                              size: 17, color: Colors.white),
                      label: Text('Atur jadwal (${dipilih.length} santri)',
                          style: sty(12.5, FontWeight.w700, Colors.white)),
                    ),
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
        final lewat = j != null && _sudahLewat(j);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text.rich(TextSpan(
                    style: sty(12, FontWeight.w500, SC.inkSecondary),
                    children: [
                      const TextSpan(text: 'Nilai Awal: '),
                      TextSpan(
                          text: _fmtNum(r.awal),
                          style: sty(12, FontWeight.w800, SC.errorText)),
                    ],
                  )),
                  const Spacer(),
                  Icon(Icons.event_outlined, size: 14, color: SC.inkSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      j == null
                          ? 'Belum dijadwalkan'
                          : '${lewat ? 'Lewat jadwal • ' : ''}${_tglPendek(j)}${r.ruang.isEmpty ? '' : ' • ${r.ruang}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12, lewat ? FontWeight.w800 : FontWeight.w500,
                          lewat ? SC.errorText : SC.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (!_readOnly) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _select(r),
                style: FilledButton.styleFrom(
                  backgroundColor: SC.primary,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.edit_note, size: 17, color: Colors.white),
                label: Text('Input Hasil', style: sty(12, FontWeight.w700, Colors.white)),
              ),
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
                  color: SC.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(
                    style: sty(12, FontWeight.w500, SC.inkSecondary),
                    children: [
                      const TextSpan(text: 'Nilai Ujian Utama: '),
                      TextSpan(
                          text: r.awal == null
                              ? '-'
                              : '${_fmtNum(r.awal)} (${_predikat(r.awal!, _kkm)})',
                          style: sty(12, FontWeight.w800, SC.errorText)),
                    ],
                  )),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(Icons.info_outline, size: 14, color: SC.inkSecondary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            r.catatanNilai.isEmpty
                                ? 'Perlu bimbingan sebelum sesi remedial'
                                : r.catatanNilai,
                            style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.3)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (r.tenggat != null) ...[
              const SizedBox(height: 10),
              Text('Tenggat: ${_tglRingkas(r.tenggat!)}',
                  style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
            ],
          ],
        );
    }

    // Pembeda card: krem = belum ada nilai, merah muda = perlu remedial, putih = final
    final perluTindakan = !_isFinal(r.status);
    final bgCard =
        r.belumNilai ? SC.goldSurface : (perluTindakan ? SC.errorBg.withOpacity(0.4) : SC.surface);
    final aksen = r.belumNilai
        ? SC.gold
        : (perluTindakan ? SC.errorText : (tuntas ? _kOkFg : SC.errorText));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isSel || r.belumNilai ? SC.gold.withOpacity(0.6) : SC.border,
            width: isSel ? 1.5 : 1),
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
                              ? _kOkBg
                              : (belumTuntas ? SC.errorBg : SC.surfaceDim),
                          shape: BoxShape.circle,
                        ),
                        child: Text(_initials(r.nama),
                            style: sty(13, FontWeight.w800,
                                tuntas ? _kOkFg : (belumTuntas ? SC.errorText : SC.ink))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sty(14, FontWeight.w800, SC.ink)),
                            const SizedBox(height: 2),
                            Text(sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        r.belumNilai ? 'BELUM ADA NILAI' : st.pill,
                        bg: r.belumNilai ? SC.goldSurface : st.bg,
                        fg: r.belumNilai ? SC.goldDark : st.fg,
                        bd: r.belumNilai ? SC.gold.withOpacity(0.4) : st.bd,
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

  // ---------------------------------------------------------------------
  // Bar bawah: progres kelas
  // ---------------------------------------------------------------------
  Widget _bottomBar() {
    final rows = _rows;
    final aktif = rows.where((r) => !_isFinal(r.status)).length;
    final tuntas = rows.where((r) => r.status == 'TUNTAS').length;
    final belum = rows.where((r) => r.status == 'BELUM_TUNTAS').length;
    final selesai = tuntas + belum;
    final progress =
        rows.isEmpty ? 0.0 : (selesai / rows.length).clamp(0.0, 1.0).toDouble();

    Widget item(Color c, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(text, style: sty(13, FontWeight.w800, SC.ink)),
          ],
        );

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxW),
        child: Container(
          decoration: BoxDecoration(
            color: SC.surface,
            border: const Border(top: BorderSide(color: SC.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Progres kelas',
                            style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                      ),
                      Text('${(progress * 100).round()}%',
                          style: sty(13, FontWeight.w800, SC.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      item(SC.goldDark, '$aktif Aktif'),
                      item(_kOkFg, '$tuntas Tuntas'),
                      item(SC.errorText, '$belum Belum'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: SC.border,
                      valueColor: AlwaysStoppedAnimation(SC.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet jadwal massal
// ---------------------------------------------------------------------------
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
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: SC.surfaceDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: SC.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(13, FontWeight.w700, SC.ink)),
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
      padding:
          EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: SC.border, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SC.goldSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.gold.withOpacity(0.45)),
                  ),
                  child: Icon(Icons.event_available_outlined, size: 20, color: SC.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Atur jadwal remedial', style: sty(16, FontWeight.w800, SC.ink)),
                      const SizedBox(height: 1),
                      Text('${widget.kelas} • $n santri',
                          style: sty(12, FontWeight.w500, SC.inkSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ringkas, style: sty(12, FontWeight.w500, SC.inkSecondary)),
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
              style: sty(13.5, FontWeight.w500, SC.ink, h: 1.35),
              decoration: _dec(widget.perluKet
                  ? 'Keterangan materi remedial'
                  : 'Keterangan materi (kosongkan untuk memakai yang sudah ada)'),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(_err!, style: sty(12, FontWeight.w700, SC.errorText)),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SC.border),
                      minimumSize: const Size.fromHeight(48),
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: SC.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _ok,
                    child: Text('Simpan jadwal', style: sty(13, FontWeight.w700, Colors.white)),
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