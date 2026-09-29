import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

// ---------------------------------------------------------------------------
// Token desain SIMPesantren Ustadz (DESIGN.md referensi Stitch)
// ---------------------------------------------------------------------------

class _C {
  static const canvas = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF0F3A2E);
  static const primaryContainer = Color(0xFF1B4D3E);
  static const onPrimaryContainer = Color(0xFF7AA494);
  static const tertiaryFixed = Color(0xFFD5E7DF);
  static const tertiaryFixedDim = Color(0xFFB9CAC3);
  static const secondary = Color(0xFF775A19);
  static const secondaryContainer = Color(0xFFFED488);
  static const secondaryFixed = Color(0xFFFFDEA5);
  static const onSecondaryFixed = Color(0xFF261900);
  static const container = Color(0xFFEAEDFF);
  static const surfaceVariant = Color(0xFFDAE2FD);
  static const outline = Color(0xFF717975);
  static const outlineVariant = Color(0xFFC0C8C3);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF414845);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const scrim = Color(0x73283044);

  static Color get cardBorder => surfaceVariant.withOpacity(0.4);
  static Color get divider => surfaceVariant.withOpacity(0.3);
}

// Plus Jakarta Sans: judul, nama, isi. Inter: label kecil, NIS, badge, angka.
TextStyle _t(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

TextStyle _lb(double size, FontWeight w, Color c, {double ls = 0.3}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: c, letterSpacing: ls);

// ---------------------------------------------------------------------------
// Helper kecil
// ---------------------------------------------------------------------------

class _Kualitas {
  final String kode;
  final String label;
  final String range;
  const _Kualitas(this.kode, this.label, this.range);
}

const _kualitasOptions = <_Kualitas>[
  _Kualitas('MUMTAZ', 'Mumtaz', '95 - 100 (Sempurna)'),
  _Kualitas('JAYYID_JIDDAN', 'Jayyid Jiddan', '85 - 94 (Sangat Baik)'),
  _Kualitas('JAYYID', 'Jayyid', '75 - 84 (Baik)'),
  _Kualitas('MAQBUL', 'Maqbul', '65 - 74 (Cukup)'),
];

String _kualitasLabel(String? kode) {
  for (final k in _kualitasOptions) {
    if (k.kode == kode) return k.label;
  }
  return '';
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _bulanPendek = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _tglPendek(String iso) {
  final p = iso.substring(0, 10).split('-');
  return '${int.parse(p[2])} ${_bulanPendek[int.parse(p[1])]}';
}

/// "Kemarin (12 Feb)", "3 hari lalu (25 Sep)"
String _relatif(String iso) {
  final d = DateTime.parse(iso.substring(0, 10));
  final n = DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  final tgl = _tglPendek(iso);
  if (diff <= 0) return 'Hari ini ($tgl)';
  if (diff == 1) return 'Kemarin ($tgl)';
  return '$diff hari lalu ($tgl)';
}

String _tglLengkap(DateTime dt) {
  const hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
  const bulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${hari[dt.weekday % 7]}, ${dt.day} ${bulan[dt.month]} ${dt.year}';
}

String _inisial(String nama) {
  final p = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p[0][0].toUpperCase();
  return (p[0][0] + p[1][0]).toUpperCase();
}

String _angkaArab(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return '$n'.split('').map((c) => d[int.parse(c)]).join();
}

/// Jam setor dari createdAt, mis. "07.15 WIB" (WIB hanya jika zona perangkat +07).
String _jam(dynamic iso) {
  final dt = DateTime.tryParse('$iso');
  if (dt == null) return '';
  final l = dt.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '$hh.$mm${l.timeZoneOffset.inHours == 7 ? ' WIB' : ''}';
}

const _bulanHijriah = [
  '', 'Muharram', 'Safar', "Rabiul Awal", "Rabiul Akhir", 'Jumadil Awal', 'Jumadil Akhir',
  'Rajab', "Sya'ban", 'Ramadhan', 'Syawal', "Dzulqa'dah", 'Dzulhijjah',
];

/// Kalender Hijriah tabular (bisa berbeda ±1 hari dari penetapan resmi).
List<int> _hijriah(DateTime g) { // [hari, bulan, tahun]
  final a = (14 - g.month) ~/ 12;
  final yy = g.year + 4800 - a;
  final mm = g.month + 12 * a - 3;
  final jd = g.day + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
  var l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
  final m = (24 * l) ~/ 709;
  final d = l - (709 * m) ~/ 24;
  return [d, m, 30 * n + j - 30];
}

String _tglHijriah(DateTime g) {
  final h = _hijriah(g);
  return '${h[0]} ${_bulanHijriah[h[1]]} ${h[2]} H';
}

// Metadata Al-Qur'an (Mushaf Madinah): awal tiap juz.
const _awalJuz = <String>[
  '', "Al-Fatihah : 1", "Al-Baqarah : 142", "Al-Baqarah : 253", "Ali 'Imran : 92", "An-Nisa' : 24",
  "An-Nisa' : 148", "Al-Ma'idah : 82", "Al-An'am : 111", "Al-A'raf : 88", "Al-Anfal : 41",
  "At-Taubah : 93", "Hud : 6", "Yusuf : 53", "Al-Hijr : 1", "Al-Isra' : 1", "Al-Kahf : 75",
  "Al-Anbiya' : 1", "Al-Mu'minun : 1", "Al-Furqan : 21", "An-Naml : 56", "Al-'Ankabut : 46",
  "Al-Ahzab : 31", "Ya-Sin : 22", "Az-Zumar : 32", "Fussilat : 47", "Al-Ahqaf : 1",
  "Adz-Dzariyat : 31", "Al-Mujadilah : 1", "Al-Mulk : 1", "An-Naba' : 1",
];

/// Halaman mushaf Madinah: juz 1 mulai hal. 1, juz n (n>=2) mulai hal. 2 + 20(n-1).
/// CATATAN: ini perkiraan berbasis standar Mushaf Madinah (604 halaman). Cetakan
/// mushaf lain (mis. Kemenag) bisa berbeda jumlah halaman per juz-nya, sehingga
/// nomor halaman di banner ini sifatnya ESTIMASI, bukan angka pasti untuk semua
/// jenis mushaf.
int _halMushaf(int juz, int halaman) {
  final awal = juz <= 1 ? 1 : 2 + 20 * (juz - 1);
  return (awal + halaman - 1).clamp(1, 604).toInt();
}

/// Ringkasan capaian per santri, dihitung di sisi client dari GET /tahfidz.
int _skor(int juz, int hal) => juz * 100 + hal;

/// "3" kalau satu halaman, "3–5" kalau rentang. Data lama (tanpa halamanMulai) tetap aman.
String _rentang(Map<String, dynamic> r) {
  final s = (r['halamanSelesai'] ?? r['halaman']) as num;
  final m = (r['halamanMulai'] ?? s) as num;
  return m == s ? '$s' : '$m–$s';
}

String _jenisLabel(dynamic j) => j == 'MURAJAAH' ? "Muroja'ah" : 'Ziyadah';

class _Ringkas {
  Map<String, dynamic>? terakhir; // setoran paling baru (untuk nilai & tanggal)
  Map<String, dynamic>? maju; // setoran paling jauh (juz, halaman) → progres
  final Set<int> juzTuntas = {};
  bool setorHariIni = false;
}

// ---------------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------------

class TahfidzScreen extends StatefulWidget {
  const TahfidzScreen({super.key});

  @override
  State<TahfidzScreen> createState() => _TahfidzScreenState();
}

class _TahfidzScreenState extends State<TahfidzScreen> {
  List<Map<String, dynamic>> _santris = [];
  List<Map<String, dynamic>> _capaian = [];
  Map<String, _Ringkas> _ringkas = {};
  Map<String, dynamic>? _khatamTerbaru;
  final Map<String, int> _khatamJuzPerSantri = {};
  int _khatamPekanIni = 0;

  bool _loading = true;
  String? _error;
  String _query = '';
  String _filter = 'semua'; // semua | belum | sudah
  String _urut = 'progres'; // progres | nama
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = AppScope.of(context).api;
      final s = await api.get(ApiUrl.santri, query: {'perPage': '100', 'binaan': 'true'});
      final t = await api.get(ApiUrl.tahfidz);
      if (!mounted) return;
      setState(() {
        _santris = ((s['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _capaian = ((t as List?) ?? const []).cast<Map<String, dynamic>>();
        _hitung();
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Gagal memuat data tahfidz: $e'; _loading = false; });
    }
  }

  void _hitung() {
    final now = DateTime.now();
    final today = _isoDate(now);
    final batas = _isoDate(now.subtract(const Duration(days: 6)));

    final sorted = List<Map<String, dynamic>>.of(_capaian)
      ..sort((a, b) => '${b['tanggalSetor']}${b['createdAt']}'.compareTo('${a['tanggalSetor']}${a['createdAt']}'));

    final res = <String, _Ringkas>{};
    _khatamJuzPerSantri.clear();
    final khatamUnik = <String>{}; // satu juz per santri dihitung sekali
    Map<String, dynamic>? khatamTerbaru;

    for (final r in sorted) {
      final id = (r['santriId'] ?? (r['santri'] as Map?)?['id'])?.toString();
      if (id == null) continue;
      final e = res.putIfAbsent(id, () => _Ringkas());
      e.terakhir ??= r;

      final tgl = '${r['tanggalSetor']}'.substring(0, 10);
      final juz = (r['juz'] as num).toInt();
      final hal = (r['halaman'] as num).toInt();
      if (tgl == today) e.setorHariIni = true;

      // Muroja'ah tidak menggeser progres hafalan maupun khatam
      if (r['jenis'] == 'MURAJAAH') continue;

      // Progres = titik terjauh, bukan setoran terakhir (muroja'ah juz lama tidak memundurkan progres).
      final mj = e.maju;
      if (mj == null || _skor(juz, hal) > _skor((mj['juz'] as num).toInt(), (mj['halaman'] as num).toInt())) {
        e.maju = r;
      }

      if (hal >= 20) {
        e.juzTuntas.add(juz);
        if (tgl.compareTo(batas) >= 0 && khatamUnik.add('$id:$juz')) {
          khatamTerbaru ??= r;
          _khatamJuzPerSantri.putIfAbsent(id, () => juz);
        }
      }
    }
    _ringkas = res;
    _khatamPekanIni = khatamUnik.length;
    _khatamTerbaru = khatamTerbaru;
  }

  bool _sudahSetor(Map<String, dynamic> s) => _ringkas['${s['id']}']?.setorHariIni ?? false;

  double _progres(Map<String, dynamic> s) {
    final m = _ringkas['${s['id']}']?.maju;
    if (m == null) return -1;
    return _skor((m['juz'] as num).toInt(), (m['halaman'] as num).toInt()).toDouble();
  }

  List<Map<String, dynamic>> get _tampil {
    final q = _query.trim().toLowerCase();
    final list = _santris.where((s) {
      if (q.isNotEmpty &&
          !('${s['nama']}'.toLowerCase().contains(q) || '${s['nis']}'.toLowerCase().contains(q))) {
        return false;
      }
      if (_filter == 'sudah') return _sudahSetor(s);
      if (_filter == 'belum') return !_sudahSetor(s);
      return true;
    }).toList();

    if (_urut == 'nama') {
      list.sort((a, b) => '${a['nama']}'.toLowerCase().compareTo('${b['nama']}'.toLowerCase()));
    } else {
      list.sort((a, b) => _progres(b).compareTo(_progres(a)));
    }
    return list;
  }

  Future<void> _bukaSheet(Map<String, dynamic> santri) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _C.scrim,
      constraints: const BoxConstraints(maxWidth: 448),
      builder: (_) => _SetoranSheet(santri: santri, terakhir: _ringkas['${santri['id']}']?.maju),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setoran tahfidz disimpan.')));
      _load();
    }
  }

  void _segera(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fitur segera hadir.')));
  }

  void _detail(Map<String, dynamic> santri) {
    final t = _ringkas['${santri['id']}']?.terakhir;
    Widget baris(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(k, style: _lb(11.5, FontWeight.w500, _C.onSurfaceVariant))),
              Expanded(child: Text(v, style: _t(13, FontWeight.w600, _C.onSurface))),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${santri['nama'] ?? '-'}', style: _t(17, FontWeight.w700, _C.onSurface)),
        content: t == null
            ? Text('Belum ada setoran.', style: _t(13, FontWeight.w400, _C.onSurfaceVariant))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  baris('Tanggal', _relatif('${t['tanggalSetor']}')),
                  if (_jam(t['createdAt']).isNotEmpty) baris('Jam', _jam(t['createdAt'])),
                  baris('Jenis', _jenisLabel(t['jenis'])),
                  baris('Juz / Halaman', 'Juz ${t['juz']} • Halaman ${_rentang(t)} dari 20'),
                  baris('Kualitas', _kualitasLabel(t['kualitas'] as String?).isEmpty ? '-' : _kualitasLabel(t['kualitas'] as String?)),
                  if ('${t['catatanUstadz'] ?? ''}'.trim().isNotEmpty) baris('Catatan', '${t['catatanUstadz']}'),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tutup', style: _t(13, FontWeight.w600, _C.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, () {
      setState(() { _loading = true; _error = null; });
      _load();
    });

    final total = _santris.length;
    final sudah = _santris.where(_sudahSetor).length;
    final belum = total - sudah;
    final tampil = _tampil;

    // "Sedang Berlangsung": santri pertama di daftar yang belum setor hari ini.
    String? giliranId;
    for (final s in tampil) {
      if (!_sudahSetor(s)) {
        giliranId = '${s['id']}';
        break;
      }
    }

    return Container(
      color: _C.canvas,
      child: RefreshIndicator(
        color: _C.primary,
        onRefresh: _load,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _hero(total, sudah),
                if (_khatamTerbaru != null) ...[
                  const SizedBox(height: 16),
                  _khatamBanner(_khatamTerbaru!),
                ],
                const SizedBox(height: 16),
                _searchBar(),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('Semua ($total)', 'semua'),
                      const SizedBox(width: 8),
                      _chip('Belum Setor ($belum)', 'belum'),
                      const SizedBox(width: 8),
                      _chip('Sudah Setor ($sudah)', 'sudah'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(tampil.length),
                const SizedBox(height: 12),
                if (tampil.isEmpty)
                  emptyView(_santris.isEmpty ? 'Belum ada data santri.' : 'Tidak ada santri yang cocok.')
                else
                  for (final s in tampil)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12, top: '${s['id']}' == giliranId ? 8 : 0),
                      child: _SantriCard(
                        santri: s,
                        ringkas: _ringkas['${s['id']}'],
                        khatamJuz: _khatamJuzPerSantri['${s['id']}'],
                        giliran: '${s['id']}' == giliranId,
                        onInput: () => _bukaSheet(s),
                        onDetail: () => _detail(s),
                        onSegera: _segera,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Hero halaqah ----
  Widget _hero(int total, int sudah) {
    // Juz yang sudah ditempuh per santri = (juz - 1) + halaman/20, lalu dirata-rata.
    final ditempuh = _ringkas.values.where((r) => r.maju != null).map((r) {
      final j = (r.maju!['juz'] as num).toDouble();
      final f = ((r.maju!['halaman'] as num).toDouble() / 20).clamp(0.0, 1.0).toDouble();
      return (j - 1) + f;
    }).toList();
    final rata = ditempuh.isEmpty ? '-' : (ditempuh.reduce((a, b) => a + b) / ditempuh.length).toStringAsFixed(1);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _C.onSurface.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarLatticePainter())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: _C.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 14, color: _C.primary),
                          const SizedBox(width: 6),
                          Text('Bimbingan Halaqah Tahfidz', style: _lb(11, FontWeight.w600, _C.primary)),
                        ],
                      ),
                    ),
                    Text('${_bulanHijriah[_hijriah(DateTime.now())[1]]} ${_hijriah(DateTime.now())[2]} H',
                        style: _lb(10.5, FontWeight.w500, _C.onPrimaryContainer)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Halaqah Tahfidz', style: _t(22, FontWeight.w700, Colors.white, ls: -0.3)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: _C.secondaryFixed, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$total Santri Terdaftar', style: _t(13, FontWeight.w400, _C.onPrimaryContainer)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                            label: 'Rata-rata',
                            value: rata,
                            suffix: rata == '-' ? '' : ' Juz',
                            valueColor: _C.secondaryFixed),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroMetric(
                            label: 'Setor Hari Ini', value: '$sudah', suffix: '/$total', valueColor: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroMetric(
                            label: 'Khatam Pekan Ini',
                            value: '$_khatamPekanIni',
                            valueColor: _C.secondaryFixed,
                            trailingIcon: Icons.verified_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Banner khatam juz ----
  Widget _khatamBanner(Map<String, dynamic> r) {
    final sid = (r['santriId'] ?? (r['santri'] as Map?)?['id'])?.toString();
    var nama = (r['santri'] as Map?)?['nama']?.toString() ?? '';
    if (nama.isEmpty) {
      for (final sn in _santris) {
        if ('${sn['id']}' == sid) nama = '${sn['nama']}';
      }
    }
    if (nama.isEmpty) nama = 'Santri';
    final juz = r['juz'];
    final kualitas = _kualitasLabel(r['kualitas'] as String?);
    final tgl = _tglPendek('${r['tanggalSetor']}');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.secondary.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: _C.secondary.withOpacity(0.1), shape: BoxShape.circle),
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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: _C.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 14, color: _C.onSecondaryFixed),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text('ALHAMDULILLAH • KHATAM JUZ',
                                  overflow: TextOverflow.ellipsis,
                                  style: _lb(10.5, FontWeight.w700, _C.onSecondaryFixed)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tgl, style: _lb(11, FontWeight.w500, _C.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$nama Baru Saja Menyelesaikan Juz $juz!',
                    style: _t(17, FontWeight.w700, _C.onSurface, h: 1.25)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: _t(13, FontWeight.w400, _C.onSurfaceVariant, h: 1.4),
                    children: [
                      TextSpan(text: 'Disahkan pada $tgl${_jam(r['createdAt']).isEmpty ? '' : ' pukul ${_jam(r['createdAt'])}'} (20 halaman tuntas).'),
                      if (kualitas.isNotEmpty) ...[
                        const TextSpan(text: ' Predikat: '),
                        TextSpan(text: kualitas, style: _t(13, FontWeight.w600, _C.secondary)),
                        const TextSpan(text: '.'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _segera('Unduh syahadah'),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _C.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_outlined, size: 15, color: _C.secondary),
                            const SizedBox(width: 6),
                            Text('Unduh Syahadah Juz', style: _lb(11, FontWeight.w600, _C.secondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _segera('Kirim ucapan'),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_border, size: 15, color: _C.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Kirim Ucapan', style: _lb(11, FontWeight.w500, _C.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.surfaceVariant.withOpacity(0.4)),
    );
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: _t(13, FontWeight.w400, _C.onSurface),
      decoration: InputDecoration(
        hintText: 'Cari nama santri atau NIS...',
        hintStyle: _t(13, FontWeight.w400, _C.outline.withOpacity(0.7)),
        prefixIcon: const Icon(Icons.search, size: 20, color: _C.outline),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.cancel_outlined, size: 16, color: _C.outline),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: _C.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primary),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _C.primaryContainer : _C.surface,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: _C.surfaceVariant.withOpacity(0.3)),
        ),
        child: Text(label,
            style: _lb(11.5, selected ? FontWeight.w700 : FontWeight.w600,
                selected ? Colors.white : _C.onSurfaceVariant)),
      ),
    );
  }

  Widget _sectionTitle(int jumlah) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Daftar Santri', style: _t(17, FontWeight.w700, _C.onSurface)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _C.container, borderRadius: BorderRadius.circular(999)),
                child: Text('$jumlah', style: _lb(11, FontWeight.w600, _C.onSurfaceVariant)),
              ),
            ],
          ),
          PopupMenuButton<String>(
            initialValue: _urut,
            onSelected: (v) => setState(() => _urut = v),
            color: _C.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'progres', child: Text('Progres', style: _t(13, FontWeight.w500, _C.onSurface))),
              PopupMenuItem(value: 'nama', child: Text('Nama', style: _t(13, FontWeight.w500, _C.onSurface))),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Urutkan: ${_urut == 'nama' ? 'Nama' : 'Progres'}',
                    style: _lb(11, FontWeight.w600, _C.primary)),
                const Icon(Icons.expand_more, size: 16, color: _C.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Watermark bintang 8 sudut (Rub el Hizb), putih 3%
// ---------------------------------------------------------------------------

class _StarLatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    const cell = 56.0;
    const r = 20.0;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        for (final rot in [0.0, math.pi / 4]) {
          final path = Path();
          for (int i = 0; i < 4; i++) {
            final a = rot + i * math.pi / 2 + math.pi / 4;
            final p = Offset(x + r * math.cos(a), y + r * math.sin(a));
            if (i == 0) {
              path.moveTo(p.dx, p.dy);
            } else {
              path.lineTo(p.dx, p.dy);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color valueColor;
  final IconData? trailingIcon;
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.suffix = '',
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _lb(10.5, FontWeight.w600, _C.onPrimaryContainer)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: _t(18, FontWeight.w700, valueColor)),
              if (suffix.isNotEmpty)
                Text(suffix,
                    style: _lb(12, FontWeight.w500,
                        valueColor == Colors.white ? _C.onPrimaryContainer : valueColor)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 15, color: valueColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu santri (mengikuti referensi; semua angka & teks dari data API)
//  * giliran : santri pertama yang belum setor hari ini → "Sedang Berlangsung"
//  * selesai : khatam dalam 7 hari + sudah setor hari ini
//  * sudah   : sudah setor hari ini
//  * belum   : belum setor hari ini
// Seluruh kartu bisa diketuk untuk membuka form input setoran.
// ---------------------------------------------------------------------------

class _SantriCard extends StatelessWidget {
  final Map<String, dynamic> santri;
  final _Ringkas? ringkas;
  final int? khatamJuz;
  final bool giliran;
  final VoidCallback onInput;
  final VoidCallback onDetail;
  final void Function(String fitur) onSegera;
  const _SantriCard({
    required this.santri,
    required this.ringkas,
    required this.khatamJuz,
    required this.giliran,
    required this.onInput,
    required this.onDetail,
    required this.onSegera,
  });

  @override
  Widget build(BuildContext context) {
    final nama = '${santri['nama'] ?? '-'}';
    final nis = '${santri['nis'] ?? '-'}';
    final kelas = (santri['kelas'] as Map?)?['namaKelas']?.toString();
    final t = ringkas?.terakhir; // nilai, tanggal, jam
    final m = ringkas?.maju; // progres (titik terjauh)
    final sudah = ringkas?.setorHariIni ?? false;
    final khatam = khatamJuz != null;

    final juz = (m?['juz'] as num?)?.toInt();
    final hal = ((m?['halaman'] as num?)?.toInt() ?? 0).clamp(0, 20).toInt();
    final persen = (hal / 20 * 100).round();
    final kualitas = _kualitasLabel(t?['kualitas'] as String?);
    final tuntas = (ringkas?.juzTuntas.toList() ?? <int>[])..sort();
    final selesai = !giliran && sudah && khatam;
    final jam = t == null ? '' : _jam(t['createdAt']);

    Color avatarBg;
    Color avatarFg;
    if (khatam) {
      avatarBg = _C.secondaryContainer.withOpacity(0.4);
      avatarFg = _C.secondary;
    } else if (giliran) {
      avatarBg = _C.tertiaryFixed;
      avatarFg = _C.primary;
    } else if (sudah) {
      avatarBg = _C.container;
      avatarFg = _C.onSurfaceVariant;
    } else {
      avatarBg = _C.errorContainer.withOpacity(0.3);
      avatarFg = _C.error;
    }

    String pillLabel;
    IconData pillIcon;
    Color pillBg;
    Color pillFg;
    if (giliran) {
      pillLabel = 'Giliran Setor';
      pillIcon = Icons.schedule;
      pillBg = _C.secondaryContainer.withOpacity(0.4);
      pillFg = _C.secondary;
    } else if (selesai) {
      pillLabel = 'Selesai';
      pillIcon = Icons.check_circle_outline;
      pillBg = _C.tertiaryFixed;
      pillFg = _C.primary;
    } else if (sudah) {
      pillLabel = 'Setor Hari Ini';
      pillIcon = Icons.check;
      pillBg = _C.tertiaryFixed;
      pillFg = _C.primary;
    } else {
      pillLabel = 'Belum Setor';
      pillIcon = Icons.warning_amber_rounded;
      pillBg = _C.errorContainer;
      pillFg = _C.onErrorContainer;
    }

    final showDivider = giliran || selesai;

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: avatarBg, borderRadius: BorderRadius.circular(16)),
                    child: Text(_inisial(nama), style: _t(17, FontWeight.w700, avatarFg)),
                  ),
                  if (khatam)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.secondaryFixed,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.surface, width: 2),
                        ),
                        child: const Icon(Icons.star_rounded, size: 9, color: _C.secondary),
                      ),
                    ),
                ],
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
                              style: _t(16, FontWeight.w700, _C.onSurface, h: 1.25, ls: -0.2)),
                        ),
                        if (khatam) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.secondaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Khatam Juz $khatamJuz', style: _lb(10.5, FontWeight.w600, _C.secondary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('NIS: $nis${kelas != null ? ' • $kelas' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _lb(11, FontWeight.w500, _C.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pillIcon, size: 14, color: pillFg),
                    const SizedBox(width: 4),
                    Text(pillLabel, style: _lb(11, FontWeight.w600, pillFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Progres ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(juz != null ? 'Juz $juz • Halaman $hal dari 20' : 'Belum ada setoran',
                  style: _lb(11, FontWeight.w500, _C.onSurface)),
              Text(
                juz == null ? '' : (giliran ? '$persen% Selesai' : '$persen%'),
                style: _lb(11, giliran ? FontWeight.w700 : FontWeight.w600,
                    (giliran || sudah) ? _C.primary : _C.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (giliran)
            Row(
              children: [
                for (int i = 0; i < 10; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      margin: EdgeInsets.only(right: i == 9 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: i < (hal / 2).ceil() ? _C.primaryContainer : _C.container,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hal / 20,
                minHeight: 8,
                backgroundColor: _C.container,
                valueColor: AlwaysStoppedAnimation(sudah ? _C.primaryContainer : _C.outline),
              ),
            ),

          // --- Juz tuntas (di kartu aktif, seperti referensi) ---
          if (giliran && tuntas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Juz Tuntas:', style: _lb(11, FontWeight.w500, _C.onSurfaceVariant)),
                for (final j in tuntas.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.secondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Juz $j', style: _lb(10.5, FontWeight.w700, _C.secondary)),
                  ),
                if (tuntas.length > 6)
                  Text('+${tuntas.length - 6}', style: _lb(11, FontWeight.w500, _C.onSurfaceVariant)),
              ],
            ),
          ],

          // --- Footer ---
          SizedBox(height: showDivider ? 12 : 10),
          if (showDivider) ...[
            Container(height: 1, color: _C.divider),
            const SizedBox(height: 10),
          ],
          if (giliran)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onInput,
                icon: const Icon(Icons.post_add, size: 18),
                label: Text('+ Input Setoran Santri', style: _t(13.5, FontWeight.w700, Colors.white)),
                style: FilledButton.styleFrom(
                  backgroundColor: _C.primaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
              ),
            )
          else if (selesai)
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 15, color: _C.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _lb(11, FontWeight.w400, _C.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: t == null
                              ? ''
                              : (t['jenis'] == 'MURAJAAH'
                                  ? "Muroja'ah • Juz ${t['juz']} • Hal. ${_rentang(t)} • "
                                  : 'Juz ${t['juz']} • Hal. ${_rentang(t)} • '),
                        ),
                        TextSpan(
                            text: kualitas.isEmpty ? '-' : kualitas,
                            style: _lb(11, FontWeight.w700, _C.onSurface)),
                        if (jam.isNotEmpty) TextSpan(text: ' ($jam)'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => onSegera("Mutaba'ah"),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 6, top: 5, bottom: 5),
                    decoration: BoxDecoration(color: _C.container, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Mutaba'ah", style: _lb(11, FontWeight.w500, _C.primary)),
                        const Icon(Icons.chevron_right, size: 14, color: _C.primary),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else if (sudah)
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _lb(11, FontWeight.w400, _C.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'Nilai: '),
                        TextSpan(
                            text: kualitas.isEmpty ? '-' : kualitas,
                            style: _lb(11, FontWeight.w700, _C.primary)),
                        if (t != null)
                        TextSpan(
                          text: t['jenis'] == 'MURAJAAH'
                              ? " • Muroja'ah • Juz ${t['juz']} hal. ${_rentang(t)}"
                              : ' • Juz ${t['juz']} hal. ${_rentang(t)}',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDetail,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Detail', style: _lb(11, FontWeight.w700, _C.onSurface)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward, size: 14, color: _C.onSurface),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    t == null ? 'Belum pernah setor' : 'Terakhir setor: ${_relatif('${t['tanggalSetor']}')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _lb(11, FontWeight.w500, _C.error),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => onSegera('Panggil santri'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: _C.tertiaryFixed, borderRadius: BorderRadius.circular(999)),
                    child: Text('Panggil Santri', style: _lb(11, FontWeight.w600, _C.primary)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: giliran
            ? Border.all(color: _C.primary.withOpacity(0.2), width: 2)
            : Border.all(color: _C.cardBorder),
        boxShadow: [BoxShadow(color: _C.onSurface.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onInput,
          child: body,
        ),
      ),
    );

    if (!giliran) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -10,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _C.primaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Text('Sedang Berlangsung', style: _lb(11, FontWeight.w600, Colors.white)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet "Input Setoran Hafalan"
// ---------------------------------------------------------------------------

class _SetoranSheet extends StatefulWidget {
  final Map<String, dynamic> santri;
  final Map<String, dynamic>? terakhir;
  const _SetoranSheet({required this.santri, required this.terakhir});

  @override
  State<_SetoranSheet> createState() => _SetoranSheetState();
}

class _SetoranSheetState extends State<_SetoranSheet> {
  late int _juz;
  late int _juzAktif;
  late int _halMulai;
  late int _halSelesai;
  String _jenis = 'ZIYADAH';
  String? _kualitas;

  // Controller terpisah untuk field ketik manual, supaya kursor & fokus
  // tidak direset tiap kali widget rebuild (beda dengan bikin controller
  // baru di dalam build()).
  late final TextEditingController _halMulaiCtrl;
  late final TextEditingController _halSelesaiCtrl;

  String get _rentangTeks => _halMulai == _halSelesai ? '$_halMulai' : '$_halMulai–$_halSelesai';
  final _catatan = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Saran awal: lanjut dari setoran terakhir santri ini.
    var juz = (widget.terakhir?['juz'] as num?)?.toInt() ?? 1;
    var hal = (widget.terakhir?['halaman'] as num?)?.toInt() ?? 0;
    if (hal >= 20 && juz < 30) {
      juz++;
      hal = 0;
    }
    _juz = juz.clamp(1, 30).toInt();
    _juzAktif = _juz;
    _halMulai = (hal + 1).clamp(1, 20).toInt();
    _halSelesai = _halMulai;
    _halMulaiCtrl = TextEditingController(text: '$_halMulai');
    _halSelesaiCtrl = TextEditingController(text: '$_halSelesai');
  }

  @override
  void dispose() {
    _catatan.dispose();
    _halMulaiCtrl.dispose();
    _halSelesaiCtrl.dispose();
    super.dispose();
  }

  void _setHalMulai(int v) {
    setState(() {
      _halMulai = v.clamp(1, 20).toInt();
      if (_halSelesai < _halMulai) _halSelesai = _halMulai;
      _halMulaiCtrl.text = '$_halMulai';
      _halSelesaiCtrl.text = '$_halSelesai';
    });
  }

  void _setHalSelesai(int v) {
    setState(() {
      _halSelesai = v.clamp(1, 20).toInt();
      if (_halMulai > _halSelesai) _halMulai = _halSelesai;
      _halMulaiCtrl.text = '$_halMulai';
      _halSelesaiCtrl.text = '$_halSelesai';
    });
  }

  Future<void> _simpan() async {
    if (_kualitas == null) {
      setState(() => _error = 'Pilih kualitas setoran dulu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.tahfidz, {
        'santriId': widget.santri['id'],
        'juz': _juz,
        'halamanMulai': _halMulai,
        'halamanSelesai': _halSelesai,
        'jenis': _jenis,
        'kualitas': _kualitas,
        'catatanUstadz': _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _saving = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Gagal menyimpan: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = '${widget.santri['nama'] ?? '-'}';
    final nis = '${widget.santri['nis'] ?? '-'}';

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _C.cardBorder)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: _C.tertiaryFixedDim.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Input Setoran Hafalan', style: _t(18, FontWeight.w700, _C.onSurface, ls: -0.2)),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: nama, style: _lb(11.5, FontWeight.w600, _C.primary)),
                          TextSpan(text: '  • NIS $nis', style: _lb(11.5, FontWeight.w500, _C.onSurfaceVariant)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _saving ? null : () => Navigator.of(context).pop(false),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: _C.container, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18, color: _C.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Jenis setoran ---
            const _FieldLabel('Jenis Setoran'),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final j in const [
                  ['ZIYADAH', 'Ziyadah (Baru)'],
                  ['MURAJAAH', "Muroja'ah (Ulang)"],
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: j[0] == 'ZIYADAH' ? 8 : 0),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            j[1],
                            textAlign: TextAlign.center,
                            style: _lb(12, FontWeight.w600, _jenis == j[0] ? Colors.white : _C.onSurface),
                          ),
                        ),
                        selected: _jenis == j[0],
                        // Warna lebih tegas (hijau tua solid) supaya jelas dibedakan
                        // dari warna tidak-terpilih, tidak pucat seperti sebelumnya.
                        selectedColor: _C.primaryContainer,
                        backgroundColor: _C.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _jenis == j[0] ? _C.primaryContainer : _C.outlineVariant.withOpacity(0.6),
                          ),
                        ),
                        onSelected: _saving ? null : (_) => setState(() => _jenis = j[0]),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Juz ---
            const _FieldLabel('Juz'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _juz,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, size: 18, color: _C.outline),
              decoration: _inputDeco(),
              style: _t(13, FontWeight.w600, _C.onSurface),
              items: [
                for (int i = 1; i <= 30; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(i == _juzAktif ? 'Juz $i (Aktif)' : 'Juz $i',
                        style: _t(13, FontWeight.w600, _C.onSurface)),
                  ),
              ],
              onChanged: _saving ? null : (v) => setState(() => _juz = v ?? _juz),
            ),
            const SizedBox(height: 14),

            // --- Halaman mulai & selesai (bisa diketik manual + tombol +/-) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepper(
                  label: 'Halaman Mulai',
                  controller: _halMulaiCtrl,
                  value: _halMulai,
                  onMinus: _halMulai > 1 && !_saving ? () => _setHalMulai(_halMulai - 1) : null,
                  onPlus: _halMulai < 20 && !_saving ? () => _setHalMulai(_halMulai + 1) : null,
                  onSubmit: (v) => _setHalMulai(v),
                ),
                const SizedBox(width: 12),
                _stepper(
                  label: 'Halaman Selesai',
                  controller: _halSelesaiCtrl,
                  value: _halSelesai,
                  onMinus: _halSelesai > 1 && !_saving ? () => _setHalSelesai(_halSelesai - 1) : null,
                  onPlus: _halSelesai < 20 && !_saving ? () => _setHalSelesai(_halSelesai + 1) : null,
                  onSubmit: (v) => _setHalSelesai(v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Banner mushaf (Amiri): halaman & awal juz dari metadata mushaf Madinah.
            // Nomor halaman di sini estimasi standar Mushaf Madinah — lihat catatan
            // pada fungsi _halMushaf().
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.secondaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.secondary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MUSHAF STANDAR MADINAH', style: _lb(10.5, FontWeight.w600, _C.secondary, ls: 0.8)),
                      Text('Hal. ${_halMushaf(_juz, _halMulai)} (estimasi)',
                          style: _lb(11, FontWeight.w400, _C.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text('الجزء ${_angkaArab(_juz)}',
                        style: GoogleFonts.amiri(
                            fontSize: 26, fontWeight: FontWeight.w700, color: _C.primary, height: 1.8)),
                  ),
                  Text('Juz $_juz • Halaman $_rentangTeks dari 20', style: _t(13, FontWeight.w600, _C.onSurface)),
                  const SizedBox(height: 2),
                  Text('Juz $_juz dimulai dari QS. ${_awalJuz[_juz]}',
                      style: _lb(10.5, FontWeight.w400, _C.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _C.container.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_tglLengkap(DateTime.now()), style: _t(13, FontWeight.w500, _C.onSurface)),
                  ),
                  Text(_tglHijriah(DateTime.now()), style: _lb(11, FontWeight.w600, _C.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Kualitas Setoran (Tajwid & Kelancaran)'),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.45,
              children: [
                for (final k in _kualitasOptions)
                  _KualitasTile(
                    k: k,
                    selected: _kualitas == k.kode,
                    onTap: _saving ? null : () => setState(() { _kualitas = k.kode; _error = null; }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _FieldLabel('Catatan Makhraj & Tajwid Ustadz'),
                Text('Opsional', style: _lb(11, FontWeight.w400, _C.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _catatan,
              maxLines: 3,
              enabled: !_saving,
              style: _t(13, FontWeight.w400, _C.onSurface),
              decoration: _inputDeco(hint: 'Tuliskan catatan tajwid, kesalahan waqaf, atau apresiasi santri...'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: _t(12, FontWeight.w400, _C.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _simpan,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, size: 20),
                label: Text('Simpan & Sahkan Setoran (Halaman $_rentangTeks)',
                    style: _t(13.5, FontWeight.w700, Colors.white)),
                style: FilledButton.styleFrom(
                  backgroundColor: _C.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Mushaf digital segera hadir.'))),
                icon: const Icon(Icons.auto_stories_outlined, size: 18),
                label: Text('Buka Mushaf Digital Halaman $_halMulai', style: _lb(12.5, FontWeight.w600, _C.primary)),
                style: TextButton.styleFrom(
                  backgroundColor: _C.container,
                  foregroundColor: _C.primary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stepper halaman: tombol +/- di kiri-kanan, angka di tengah bisa DIKETIK
  /// manual (tap lalu ganti angkanya). Nilai divalidasi & di-clamp ke 1..20
  /// saat fokus keluar dari field (onTapOutside) atau saat menekan Enter/Done.
  Widget _stepper({
    required String label,
    required TextEditingController controller,
    required int value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
    required ValueChanged<int> onSubmit,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _C.container,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepBtn(icon: Icons.remove, onTap: onMinus),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !_saving,
                    style: _t(18, FontWeight.w700, _C.primary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                    ),
                    onSubmitted: (v) {
                      final n = int.tryParse(v.trim());
                      onSubmit(n ?? value);
                    },
                    onTapOutside: (_) {
                      final n = int.tryParse(controller.text.trim());
                      onSubmit(n ?? value);
                    },
                  ),
                ),
                _StepBtn(icon: Icons.add, filled: true, onTap: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hint}) {
    final b = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.outlineVariant.withOpacity(0.6)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: _t(12.5, FontWeight.w400, _C.outline.withOpacity(0.7)),
      filled: true,
      fillColor: _C.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: b,
      enabledBorder: b,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.primary),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: _lb(11.5, FontWeight.w600, _C.onSurface));
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _C.primaryContainer : _C.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon,
              size: 17,
              color: onTap == null ? _C.outlineVariant : (filled ? Colors.white : _C.onSurface)),
        ),
      ),
    );
  }
}

class _KualitasTile extends StatelessWidget {
  final _Kualitas k;
  final bool selected;
  final VoidCallback? onTap;
  const _KualitasTile({required this.k, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _C.secondaryContainer.withOpacity(0.2) : _C.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _C.secondary : _C.outlineVariant.withOpacity(0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.label, style: _lb(11.5, FontWeight.w700, selected ? _C.secondary : _C.onSurface)),
                    const SizedBox(height: 1),
                    Text(k.range,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _lb(10.5, FontWeight.w400, selected ? _C.secondary : _C.onSurfaceVariant)
                            .copyWith(height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              selected
                  ? const Icon(Icons.check_circle_outline, size: 18, color: _C.secondary)
                  : Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.outline)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}