import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet layar Pembinaan Karakter. Warna utama ikut identitas pondok (SC),
/// aksen emas dan warna status tetap. Selaras dengan dashboard wali.
class _PC {
  _PC._();

  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFE2C58A);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF7A5B10);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
  static const errorFill = Color(0xFFFCEAE6);
  static const red = Color(0xFFDC2626);
}

const _kPageSize = 5;

const _kBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

const _kBulanPenuh = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const _kHari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];

/// Saran kategori di form (kategori tetap teks bebas).
const _kSaranKategori = ['Kedisiplinan', 'Adab', 'Kejujuran', 'Kebersihan', 'Tanggung Jawab'];

const _sheetShape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)));

// ---------------------------------------------------------------------
// Helper murni
// ---------------------------------------------------------------------
List<Map<String, dynamic>> _asList(dynamic res) {
  final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
  return (raw is List ? raw : const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

DateTime? _tanggal(Map<String, dynamic> k) {
  final s = (k['tanggal'] ?? '').toString();
  if (s.length < 10) return null;
  return DateTime.tryParse(s.substring(0, 10));
}

String _fmtTanggalPenuh(DateTime d) => '${d.day} ${_kBulanPenuh[d.month - 1]} ${d.year}';

String _hariTanggal(DateTime? d) =>
    d == null ? '-' : '${_kHari[d.weekday % 7]}, ${d.day} ${_kBulan[d.month - 1]} ${d.year}';

String _tanggalIndo(DateTime dt) =>
    '${_kHari[dt.weekday % 7]}, ${dt.day} ${_kBulanPenuh[dt.month - 1]} ${dt.year}';

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _initials(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _santriInfo(Map s) {
  final nis = s['nis']?.toString() ?? '-';
  final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
  return 'NIS $nis${kelas != null ? ' • Kelas $kelas' : ''}';
}

IconData _kategoriIcon(String k) {
  final s = k.toLowerCase();
  if (s.contains('adab') || s.contains('sopan') || s.contains('santun')) return Icons.verified_outlined;
  if (s.contains('disiplin') || s.contains('waktu')) return Icons.schedule_rounded;
  if (s.contains('jujur') || s.contains('amanah')) return Icons.favorite_border_rounded;
  if (s.contains('bersih') || s.contains('rapi')) return Icons.cleaning_services_outlined;
  if (s.contains('tanggung')) return Icons.task_alt_rounded;
  return Icons.emoji_events_outlined;
}

/// Kategori bernuansa emas (selebihnya hijau pondok) supaya daftar tidak monoton.
bool _kategoriGold(String k) {
  final s = k.toLowerCase();
  return s.contains('disiplin') || s.contains('waktu') || s.contains('tanggung') || s.contains('jujur');
}

/// "14 September 2026" (+ " • 16:30 WIB" bila jam pencatatan di hari yang sama).
String _tanggalWaktu(Map<String, dynamic> k) {
  final d = _tanggal(k);
  if (d == null) return '-';
  var out = _fmtTanggalPenuh(d);
  final c = DateTime.tryParse((k['createdAt'] ?? '').toString());
  if (c != null) {
    final l = c.toLocal();
    if (l.year == d.year && l.month == d.month && l.day == d.day) {
      out += ' • ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')} WIB';
    }
  }
  return out;
}

BoxDecoration _cardDeco({double radius = 20}) => BoxDecoration(
      color: _PC.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _PC.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 5))],
    );

Widget _grabHandle() => Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: _PC.border, borderRadius: BorderRadius.circular(999)),
      ),
    );

Widget _closeButton(BuildContext context) => InkWell(
      onTap: () => Navigator.of(context).pop(),
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: _PC.surfaceDim, shape: BoxShape.circle),
        child: const Icon(Icons.close_rounded, size: 20, color: _PC.inkSecondary),
      ),
    );

/// Judul section dengan penanda emas.
Widget _goldTitle(String t, {String? trailing}) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(color: _PC.gold, borderRadius: BorderRadius.circular(999)),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(t,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: _PC.ink)),
      ),
      if (trailing != null)
        Text(trailing, style: const TextStyle(fontSize: 11.5, color: _PC.inkSecondary)),
    ],
  );
}

Widget _ornamentDivider() {
  return const Row(
    children: [
      Expanded(child: Divider(color: _PC.goldBorder)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.auto_awesome, size: 14, color: _PC.gold),
      ),
      Expanded(child: Divider(color: _PC.goldBorder)),
    ],
  );
}

/// Avatar inisial: cincin emas + isi gradient.
Widget _gradientAvatar(String nama, {double size = 52, double fontSize = 18}) {
  return Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _PC.gold, width: 1.5),
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_PC.primary, _PC.primaryEnd],
        ),
      ),
      child: Text(_initials(nama),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: _PC.goldLight)),
    ),
  );
}

/// Ubin ikon gradient (hijau pondok atau emas).
Widget _iconTile(IconData icon, {double size = 40, bool gold = false}) {
  final c1 = gold ? _PC.gold : _PC.primary;
  final c2 = gold ? _PC.goldDark : _PC.primaryEnd;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.32),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
      boxShadow: [BoxShadow(color: c1.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Icon(icon, size: size * 0.5, color: Colors.white),
  );
}

/// Blok kutipan: bilah emas di kiri + latar krem.
Widget _quote(String text, {int? maxLines, double fontSize = 13, double height = 1.55}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: double.infinity,
      color: _PC.goldSurface,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _PC.gold),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Text(text,
                    maxLines: maxLines,
                    overflow: maxLines == null ? null : TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fontSize, color: _PC.ink, height: height)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Ornamen geometris ala rub el hizb untuk latar gradient.
List<Widget> _ornamen({double scale = 1}) {
  return [
    Positioned(
      right: -26 * scale,
      top: -26 * scale,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 130 * scale,
          height: 130 * scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26 * scale),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.5),
          ),
        ),
      ),
    ),
    Positioned(
      right: 8 * scale,
      top: 8 * scale,
      child: Container(
        width: 70 * scale,
        height: 70 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(color: _PC.gold.withOpacity(0.25), width: 1.2),
        ),
      ),
    ),
    Positioned(
      left: -44 * scale,
      bottom: -54 * scale,
      child: Container(
        width: 140 * scale,
        height: 140 * scale,
        decoration: BoxDecoration(color: _PC.gold.withOpacity(0.12), shape: BoxShape.circle),
      ),
    ),
  ];
}

// ---------------------------------------------------------------------
// Potongan UI layar utama
// ---------------------------------------------------------------------

/// Hero: identitas layar + tiga angka ringkas dalam satu kartu.
class _Hero extends StatelessWidget {
  final int total;
  final int bulanIni;
  final int dibina;
  final bool readOnly;
  const _Hero({required this.total, required this.bulanIni, required this.dibina, required this.readOnly});

  Widget _pill(IconData icon, String text, {required Color bg, required Color fg, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: _PC.goldLight),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.72))),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 44, color: Colors.white.withOpacity(0.16));

  @override
  Widget build(BuildContext context) {
    final tn = AppScope.of(context).user?.tenantNama;
    final pondok = (tn != null && tn.isNotEmpty) ? tn : 'Pondok Pesantren';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_PC.primary, _PC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._ornamen(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: _PC.gold.withOpacity(0.7)),
                      ),
                      child: const Icon(Icons.spa_outlined, size: 19, color: _PC.goldLight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(pondok,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('AKHLAK & ADAB SANTRI',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: _PC.goldLight)),
                const SizedBox(height: 4),
                const Text('Pembinaan Karakter',
                    style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.4,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('Catat dan pantau perkembangan akhlak santri secara rutin dan berkelanjutan.',
                    style: TextStyle(fontSize: 12, height: 1.45, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.calendar_today_outlined, _tanggalIndo(DateTime.now()),
                        bg: Colors.white.withOpacity(0.12), fg: Colors.white),
                    if (readOnly)
                      _pill(Icons.visibility_outlined, 'Mode Pantau',
                          bg: _PC.gold.withOpacity(0.18),
                          fg: _PC.goldLight,
                          border: _PC.gold.withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      _stat('$total', 'Total Catatan', Icons.description_outlined),
                      _vDivider(),
                      _stat('$bulanIni', 'Bulan Ini', Icons.calendar_month_outlined),
                      _vDivider(),
                      _stat('$dibina', 'Santri Dibina', Icons.groups_2_outlined),
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
}

/// Cincin progres melingkar.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({required this.progress, required this.color, required this.track, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.stroke != stroke;
}

// ---------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------
class PembinaanKarakterScreen extends StatefulWidget {
  const PembinaanKarakterScreen({super.key});

  @override
  State<PembinaanKarakterScreen> createState() => _PembinaanKarakterScreenState();
}

class _PembinaanKarakterScreenState extends State<PembinaanKarakterScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  String? _kategori; // null = Semua
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _shown = _kPageSize;

  bool get _isWali => AppScope.of(context).user?.isWali == true;

  /// Wali dan Pimpinan/Mudir hanya melihat: tidak bisa menambah atau menghapus catatan.
  bool get _readOnly => _isWali || AppScope.of(context).user?.isPimpinan == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      final res = await AppScope.of(context).api.get(ApiUrl.pembinaanKarakter);
      final items = _asList(res)
        ..sort((a, b) => (b['tanggal'] ?? '').toString().compareTo((a['tanggal'] ?? '').toString()));
      if (!mounted) return;
      setState(() {
        _list = items;
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
          _error = 'Gagal memuat catatan pembinaan karakter.';
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------
  // Notifikasi
  // ---------------------------------------------------------------------
  /// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
  /// Sama dengan `_toast` di absensi_screen.dart.
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _PC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _PC.errorBg : _PC.primary,
          elevation: 6,
          // angka 88 = jarak dari bawah (samakan dengan absensi; turunkan jika terlalu tinggi)
          margin: EdgeInsets.fromLTRB(side, 0, side, 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _PC.errorText.withOpacity(0.25) : _PC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _PC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _PC.errorText : _PC.gold,
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

  Future<void> _add() async {
    if (_readOnly) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.background,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (_) => const _FormSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.pembinaanKarakter, result);
      if (!mounted) return;
      final tgl = DateTime.tryParse('${result['tanggal']}');
      _toast('Pembinaan karakter dicatat',
          subtitle: tgl == null ? null : _fmtTanggalPenuh(tgl));
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal menyimpan catatan.', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    if (_readOnly) return;
    final nama = (p['santri'] as Map?)?['nama'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _PC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: _PC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, size: 26, color: _PC.errorText),
        ),
        title: const Text('Hapus catatan pembinaan?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _PC.ink)),
        content: Text('Catatan pembinaan karakter $nama akan dihapus.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: _PC.inkSecondary, height: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, color: _PC.inkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _PC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.pembinaanKarakter}/${p['id']}');
      if (!mounted) return;
      _toast('Catatan pembinaan dihapus', subtitle: nama.toString());
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal menghapus catatan.', error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> p) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.background,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (_) => _DetailSheet(p: p, canDelete: !_readOnly),
    );
    if (act == 'hapus' && !_readOnly && mounted) _delete(p);
  }

  // ---------------------------------------------------------------------
  // Turunan data
  // ---------------------------------------------------------------------
  /// Kategori unik dari data, diurutkan dari yang paling sering dipakai.
  List<MapEntry<String, int>> get _kategoriStats {
    final count = <String, int>{};
    final label = <String, String>{};
    for (final p in _list) {
      final raw = (p['kategori'] ?? '').toString().trim();
      if (raw.isEmpty) continue;
      final key = raw.toLowerCase();
      count[key] = (count[key] ?? 0) + 1;
      label.putIfAbsent(key, () => raw);
    }
    final keys = count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
    return [for (final k in keys) MapEntry(label[k]!, count[k]!)];
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _list.where((p) {
      if (_kategori != null && (p['kategori'] ?? '').toString().trim().toLowerCase() != _kategori!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      final s = p['santri'] as Map?;
      final hay = '${s?['nama'] ?? ''} ${s?['nis'] ?? ''} ${p['kategori'] ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  void _setKategori(String? k) => setState(() {
        _kategori = k;
        _shown = _kPageSize;
      });

  bool _isKategoriAktif(String k) => _kategori != null && _kategori!.toLowerCase() == k.toLowerCase();

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------

  /// Kartu insight: kategori yang paling sering dibina, lengkap dengan cincin persentase.
  Widget _fokusCard(List<MapEntry<String, int>> stats) {
    final total = _list.length;
    final top = stats.first;
    final pct = total == 0 ? 0 : ((top.value / total) * 100).round();
    final aktif = _isKategoriAktif(top.key);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco(radius: 22),
      child: Material(
        color: _PC.surface,
        child: InkWell(
          onTap: () => _setKategori(aktif ? null : top.key),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(76, 76),
                        painter: _RingPainter(
                          progress: total == 0 ? 0 : (pct / 100).clamp(0.0, 1.0).toDouble(),
                          color: _PC.gold,
                          track: _PC.surfaceDim,
                          stroke: 8,
                        ),
                      ),
                      Text('$pct%',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _PC.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.insights_outlined, size: 13, color: _PC.gold),
                          SizedBox(width: 5),
                          Text('FOKUS PEMBINAAN UTAMA',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: _PC.goldDark)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(top.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _PC.primary)),
                      const SizedBox(height: 3),
                      Text('${top.value} dari $total catatan',
                          style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: aktif ? _PC.primary : _PC.goldSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: aktif ? _PC.primary : _PC.goldBorder),
                        ),
                        child: Text(aktif ? 'Filter aktif' : 'Saring kategori ini',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: aktif ? Colors.white : _PC.goldDark)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sebaran(List<MapEntry<String, int>> stats) {
    final shown = stats.take(5).toList();
    final total = _list.length;
    final maxV = shown.isEmpty ? 1 : shown.first.value;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDeco(radius: 22),
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++)
            Builder(builder: (context) {
              final e = shown[i];
              final aktif = _isKategoriAktif(e.key);
              final gold = _kategoriGold(e.key);
              final frac = (e.value / maxV).clamp(0.06, 1.0).toDouble();
              final pct = total == 0 ? 0 : ((e.value / total) * 100).round();
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _setKategori(aktif ? null : e.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: aktif ? _PC.goldSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: aktif ? _PC.goldBorder : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      _iconTile(_kategoriIcon(e.key), size: 38, gold: gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(e.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w800, color: _PC.ink)),
                                ),
                                Text('${e.value}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: gold ? _PC.goldDark : _PC.primary)),
                                const SizedBox(width: 6),
                                Text('$pct%',
                                    style: const TextStyle(fontSize: 11, color: _PC.inkSecondary)),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: _PC.surfaceDim,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: frac,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: gold ? [_PC.goldLight, _PC.gold] : [_PC.primary, _PC.primaryEnd],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _PC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PC.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 21, color: _PC.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v;
                _shown = _kPageSize;
              }),
              style: const TextStyle(fontSize: 14, color: _PC.ink),
              decoration: const InputDecoration(
                hintText: 'Cari nama santri, NIS, atau kategori...',
                hintStyle: TextStyle(fontSize: 13.5, color: _PC.inkSecondary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () => setState(() {
                _searchCtrl.clear();
                _query = '';
                _shown = _kPageSize;
              }),
              icon: const Icon(Icons.close_rounded, size: 19, color: _PC.inkSecondary),
              tooltip: 'Bersihkan',
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool on,
    required VoidCallback onTap,
    int? count,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? _PC.primary : _PC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _PC.primary : _PC.border),
          boxShadow: on
              ? [BoxShadow(color: _PC.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: on ? _PC.goldLight : _PC.gold),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _PC.inkSecondary)),
            if (count != null) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: on ? Colors.white.withOpacity(0.2) : _PC.surfaceDim,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: on ? _PC.goldLight : _PC.ink)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters(List<MapEntry<String, int>> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'Semua',
            icon: Icons.apps_rounded,
            on: _kategori == null,
            count: _list.length,
            onTap: () => _setKategori(null),
          ),
          for (final e in stats.take(8)) ...[
            const SizedBox(width: 8),
            _chip(
              label: e.key,
              icon: _kategoriIcon(e.key),
              count: e.value,
              on: _isKategoriAktif(e.key),
              onTap: () => _setKategori(e.key),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 12),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 15, color: _PC.gold),
          const SizedBox(width: 7),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: _PC.goldDark, letterSpacing: 0.8)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: _PC.goldBorder, height: 1)),
        ],
      ),
    );
  }

  /// Penanda tanggal di sisi kiri timeline.
  Widget _dateBadge(DateTime? d) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: _PC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PC.goldBorder),
        boxShadow: [BoxShadow(color: _PC.gold.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(d == null ? '-' : '${d.day}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.1, color: _PC.primary)),
          const SizedBox(height: 1),
          Text(d == null ? '' : _kBulan[d.month - 1].toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: _PC.goldDark)),
        ],
      ),
    );
  }

  /// Satu baris timeline: tanggal + garis penghubung di kiri, kartu catatan di kanan.
  Widget _timelineItem(Map<String, dynamic> p, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                _dateBadge(_tanggal(p)),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: last ? Colors.transparent : _PC.goldBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _catatanCard(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catatanCard(Map<String, dynamic> p) {
    final s = (p['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final kategori = (p['kategori'] ?? '-').toString();
    final catatan = (p['catatan'] ?? '').toString().trim();
    final gold = _kategoriGold(kategori);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco(radius: 20),
      child: Material(
        color: _PC.surface,
        child: InkWell(
          onTap: () => _openDetail(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _gradientAvatar(nama, size: 44, fontSize: 15),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14.5, fontWeight: FontWeight.w800, color: _PC.ink)),
                              const SizedBox(height: 2),
                              Text(_santriInfo(s),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: _PC.inkSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
                      decoration: BoxDecoration(
                        color: gold ? _PC.goldSurface : _PC.mint.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: gold ? _PC.goldBorder : _PC.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_kategoriIcon(kategori), size: 14, color: gold ? _PC.goldDark : _PC.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(kategori,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: gold ? _PC.goldDark : _PC.primary)),
                          ),
                        ],
                      ),
                    ),
                    if (catatan.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _quote(catatan, maxLines: 2, fontSize: 12.5),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: const BoxDecoration(
                  color: _PC.surfaceDim,
                  border: Border(top: BorderSide(color: _PC.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_outlined, size: 14, color: _PC.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_hariTanggal(_tanggal(p)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: _PC.inkSecondary)),
                    ),
                    const Text('Detail',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _PC.goldDark)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: _PC.goldDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _muatLebih(int total) {
    final tampil = total < _shown ? total : _shown;
    return Column(
      children: [
        if (total > _shown)
          OutlinedButton.icon(
            onPressed: () => setState(() => _shown += _kPageSize),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: _PC.surface,
              side: const BorderSide(color: _PC.goldBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            icon: Icon(Icons.expand_more_rounded, size: 19, color: _PC.primary),
            label: Text('Muat Lebih Banyak',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _PC.primary)),
          ),
        const SizedBox(height: 10),
        Text('Menampilkan $tampil dari $total catatan',
            style: const TextStyle(fontSize: 11.5, color: _PC.inkSecondary)),
      ],
    );
  }

  Widget _emptyState(bool noData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: _cardDeco(radius: 24),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _PC.goldSurface,
              shape: BoxShape.circle,
              border: Border.all(color: _PC.goldBorder),
            ),
            child: Icon(noData ? Icons.edit_note_rounded : Icons.search_off_rounded, color: _PC.gold, size: 34),
          ),
          const SizedBox(height: 14),
          Text(noData ? 'Belum ada catatan pembinaan' : 'Tidak ada catatan yang cocok',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _PC.ink)),
          const SizedBox(height: 5),
          Text(
            noData
                ? (_readOnly
                    ? 'Catatan perkembangan akhlak santri akan tampil di sini.'
                    : 'Mulai catat perkembangan akhlak dan adab santri agar bisa dievaluasi bersama.')
                : 'Coba ubah kata kunci atau pilih kategori lain.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _PC.inkSecondary, height: 1.45),
          ),
          if (noData && !_readOnly) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _add,
              style: FilledButton.styleFrom(
                backgroundColor: _PC.primary,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20, color: _PC.goldLight),
              label: const Text('Tambah Catatan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _PC.goldSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _PC.goldBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: _PC.goldDark),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Catatan pembinaan bersifat rahasia dan hanya dapat dilihat oleh pihak yang berwenang (Asatidz, Musyrif, dan Pimpinan).',
                  style: TextStyle(fontSize: 11.5, color: _PC.goldDark, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _ornamentDivider(),
        const SizedBox(height: 12),
        const Text(
          'إِنَّمَا بُعِثْتُ لِأُتَمِّمَ مَكَارِمَ الْأَخْلَاقِ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: _PC.gold),
        ),
        const SizedBox(height: 6),
        const Text(
          '"Sesungguhnya aku diutus untuk menyempurnakan akhlak yang mulia."',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _PC.inkSecondary),
        ),
      ],
    );
  }

  Widget _tombolTambah() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_PC.primary, _PC.primaryEnd],
        ),
        border: Border.all(color: _PC.gold.withOpacity(0.7)),
        boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _add,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 20, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 21, color: _PC.goldLight),
                SizedBox(width: 8),
                Text('Catatan Baru',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _daftarCatatan(List<Map<String, dynamic>> visible) {
    final out = <Widget>[];
    String? lastKey;
    for (int i = 0; i < visible.length; i++) {
      final p = visible[i];
      final d = _tanggal(p);
      final key = d == null ? '-' : '${d.year}-${d.month}';
      if (key != lastKey) {
        out.add(_monthLabel(d == null ? 'Tanpa Tanggal' : '${_kBulanPenuh[d.month - 1]} ${d.year}'));
        lastKey = key;
      }
      out.add(_timelineItem(p, last: i == visible.length - 1));
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final visible = filtered.take(_shown).toList();
    final stats = _kategoriStats;

    final now = DateTime.now();
    final bulanIni = _list.where((p) {
      final d = _tanggal(p);
      return d != null && d.year == now.year && d.month == now.month;
    }).length;
    final dibina = _list
        .map((p) => (p['santriId'] ?? (p['santri'] as Map?)?['id'] ?? p['id']).toString())
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: _PC.background,
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _load,
                          color: _PC.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, _readOnly ? 32 : 104),
                            children: [
                              _Hero(
                                total: _list.length,
                                bulanIni: bulanIni,
                                dibina: dibina,
                                readOnly: _readOnly,
                              ),
                              const SizedBox(height: 24),
                              if (_list.isNotEmpty && stats.isNotEmpty) ...[
                                _goldTitle('Ringkasan Pembinaan', trailing: 'Ketuk untuk menyaring'),
                                const SizedBox(height: 12),
                                _fokusCard(stats),
                                const SizedBox(height: 12),
                                _sebaran(stats),
                                const SizedBox(height: 26),
                              ],
                              _goldTitle('Riwayat Pembinaan', trailing: '${filtered.length} catatan'),
                              const SizedBox(height: 12),
                              _searchField(),
                              if (stats.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _filters(stats),
                              ],
                              const SizedBox(height: 6),
                              if (filtered.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _emptyState(_list.isEmpty),
                                )
                              else ...[
                                ..._daftarCatatan(visible),
                                const SizedBox(height: 2),
                                _muatLebih(filtered.length),
                              ],
                              const SizedBox(height: 28),
                              _footer(),
                            ],
                          ),
                        ),
                        if (!_readOnly && _list.isNotEmpty)
                          Positioned(right: 16, bottom: 18, child: _tombolTambah()),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: detail catatan
// ---------------------------------------------------------------------
class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> p;
  final bool canDelete;
  const _DetailSheet({required this.p, required this.canDelete});

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: _cardDeco(radius: 20),
        child: child,
      );

  Widget _cardTitle(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 17, color: _PC.gold),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: _PC.inkSecondary)),
        ],
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: _PC.surfaceDim, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: _PC.inkSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: _PC.inkSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800, color: _PC.ink, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _PC.border);

  @override
  Widget build(BuildContext context) {
    final s = (p['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
    final kategori = (p['kategori'] ?? '-').toString();
    final tanggal = _tanggal(p);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header tetap
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
            child: Column(
              children: [
                _grabHandle(),
                Row(
                  children: [
                    Expanded(child: _goldTitle('Detail Pembinaan')),
                    _closeButton(context),
                  ],
                ),
              ],
            ),
          ),

          // Isi (scroll)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero identitas
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [_PC.primary, _PC.primaryEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: _PC.primary.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ..._ornamen(scale: 0.8),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _gradientAvatar(nama, size: 70, fontSize: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PEMBINAAN KARAKTER',
                                        style: TextStyle(
                                            fontSize: 9.5,
                                            letterSpacing: 1.0,
                                            fontWeight: FontWeight.w800,
                                            color: _PC.goldLight)),
                                    const SizedBox(height: 3),
                                    Text(nama,
                                        style: const TextStyle(
                                            fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                                    const SizedBox(height: 3),
                                    Text(_santriInfo(s),
                                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    const SizedBox(height: 9),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _PC.mint,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_kategoriIcon(kategori), size: 13, color: _PC.primary),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(kategori,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: _PC.primary)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Catatan pembinaan
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle(Icons.edit_note_rounded, 'CATATAN PEMBINAAN'),
                        const SizedBox(height: 12),
                        _quote((p['catatan'] ?? '-').toString(), fontSize: 14, height: 1.7),
                      ],
                    ),
                  ),

                  // Informasi pembinaan
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle(Icons.info_outline_rounded, 'INFORMASI PEMBINAAN'),
                        const SizedBox(height: 4),
                        _infoRow(Icons.event_available_outlined, 'Dicatat pada', _tanggalWaktu(p)),
                        _divider(),
                        _infoRow(
                            Icons.today_outlined, 'Tanggal pembinaan', tanggal == null ? '-' : _hariTanggal(tanggal)),
                        _divider(),
                        _infoRow(_kategoriIcon(kategori), 'Kategori', kategori),
                        _divider(),
                        _infoRow(Icons.person_outline_rounded, 'Santri', kelas != null ? '$nama ($kelas)' : nama),
                      ],
                    ),
                  ),

                  // Catatan akses
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _PC.goldSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _PC.goldBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: _PC.goldDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catatan pembinaan hanya dapat dilihat oleh pihak yang berwenang (Asatidz, Musyrif, dan Pimpinan).',
                            style: TextStyle(fontSize: 11.5, color: _PC.goldDark, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bar aksi tetap
          if (canDelete)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _PC.surface,
                border: const Border(top: BorderSide(color: _PC.border)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'hapus'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _PC.errorBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20, color: _PC.errorText),
                      label: const Text('Hapus Catatan',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _PC.errorText)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: pilih santri
// ---------------------------------------------------------------------
class _PilihSantriSheet extends StatefulWidget {
  const _PilihSantriSheet();

  @override
  State<_PilihSantriSheet> createState() => _PilihSantriSheetState();
}

class _PilihSantriSheetState extends State<_PilihSantriSheet> {
  List<Map<String, dynamic>> _santri = [];
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
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      var items = _asList(res);

      // Ustadz: hanya santri dari kelas yang diampu (dari /dashboard).
      // Role lain tidak punya `kelasDiampu`, jadi daftar tetap lengkap.
      try {
        final dash = await api.get(ApiUrl.dashboard);
        final kd = dash is Map ? dash['kelasDiampu'] : null;
        if (kd is List) {
          final diampu = kd
              .whereType<Map>()
              .map((k) => (k['namaKelas'] ?? '').toString().trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toSet();
          items = items.where((s) {
            final n = ((s['kelas'] as Map?)?['namaKelas'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            return diampu.contains(n);
          }).toList();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _santri = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? _santri
        : _santri.where((s) {
            final nama = (s['nama'] ?? '').toString().toLowerCase();
            final nis = (s['nis'] ?? '').toString().toLowerCase();
            return nama.contains(q) || nis.contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabHandle(),
                _goldTitle('Pilih Santri', trailing: _loading ? null : '${list.length} santri'),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14, color: _PC.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari nama / NIS…',
                    hintStyle: const TextStyle(fontSize: 14, color: _PC.inkSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: _PC.primary),
                    isDense: true,
                    filled: true,
                    fillColor: _PC.surfaceDim,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _PC.primary, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : list.isEmpty
                          ? emptyView('Santri tidak ditemukan.')
                          : ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _PC.border),
                              itemBuilder: (ctx, i) {
                                final s = list[i];
                                final nama = (s['nama'] ?? '-').toString();
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                                  leading: _gradientAvatar(nama, size: 46, fontSize: 14),
                                  title: Text(nama,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800, fontSize: 14, color: _PC.ink)),
                                  subtitle: Text('NIS ${s['nis']} • ${(s['kelas'] as Map?)?['namaKelas'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: _PC.gold),
                                  onTap: () => Navigator.of(context).pop(s),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: form catatan baru
// ---------------------------------------------------------------------
class _FormSheet extends StatefulWidget {
  const _FormSheet();

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _kategori = TextEditingController();
  final _catatan = TextEditingController();

  Map<String, dynamic>? _santri;
  late DateTime _tgl;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _tgl = DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _kategori.dispose();
    _catatan.dispose();
    super.dispose();
  }

  bool get _isToday {
    final n = DateTime.now();
    return _tgl.year == n.year && _tgl.month == n.month && _tgl.day == n.day;
  }

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _pilihSantri() async {
    final s = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (_) => const _PilihSantriSheet(),
    );
    if (s != null && mounted) setState(() => _santri = s);
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _tgl,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _PC.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _tgl = DateTime(d.year, d.month, d.day));
  }

  void _submit() {
    setState(() => _tried = true);
    if (_santri == null || _kategori.text.trim().isEmpty || _catatan.text.trim().isEmpty) return;
    Navigator.of(context).pop({
      'santriId': _santri!['id'],
      'tanggal': _isoDate(_tgl),
      'kategori': _kategori.text.trim(),
      'catatan': _catatan.text.trim(),
    });
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _sectionTitle(int no, String text, {bool req = false, String? hint}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _PC.primary.withOpacity(0.12), shape: BoxShape.circle),
          child: Text('$no',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _PC.primary)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.ink),
              children: [if (req) const TextSpan(text: ' *', style: TextStyle(color: _PC.red))],
            ),
          ),
        ),
        if (hint != null) Text(hint, style: const TextStyle(fontSize: 11.5, color: _PC.inkSecondary)),
      ],
    );
  }

  Widget _errorNote(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, size: 16, color: _PC.red),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 12.5, color: _PC.red, height: 1.4))),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, {bool err = false}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, height: 1.4, color: _PC.inkSecondary),
      filled: true,
      fillColor: err ? _PC.errorFill : _PC.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: b(err ? _PC.red : _PC.border),
      enabledBorder: b(err ? _PC.red : _PC.border),
      focusedBorder: b(err ? _PC.red : _PC.primary, 1.6),
    );
  }

  Widget _santriField() {
    final s = _santri;
    final err = _tried && s == null;
    final nama = (s?['nama'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: s == null ? _PC.surface : _PC.goldSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: err ? _PC.red : (s == null ? _PC.border : _PC.goldBorder), width: err ? 1.5 : 1),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onTap: _pilihSantri,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (s == null)
                    _iconTile(Icons.person_add_alt_1_outlined, size: 48, gold: true)
                  else
                    _gradientAvatar(nama, size: 52, fontSize: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: s == null
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pilih santri',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _PC.ink)),
                              SizedBox(height: 2),
                              Text('Ketuk untuk memilih dari daftar',
                                  style: TextStyle(fontSize: 12, color: _PC.inkSecondary)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _PC.ink)),
                              const SizedBox(height: 2),
                              Text(_santriInfo(s),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _PC.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _PC.goldBorder),
                    ),
                    child: Text(s == null ? 'Pilih' : 'Ubah',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _PC.goldDark)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (err) _errorNote('Pilih santri terlebih dahulu.'),
      ],
    );
  }

  Widget _tanggalField() {
    return Material(
      color: _PC.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _PC.border),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: _pilihTanggal,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _iconTile(Icons.calendar_today_outlined, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_fmtTanggalPenuh(_tgl),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _PC.ink)),
              ),
              if (_isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: _PC.goldSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _PC.goldBorder),
                  ),
                  child: const Text('Hari ini',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _PC.goldDark)),
                )
              else
                const Icon(Icons.edit_calendar_outlined, size: 18, color: _PC.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saranChip(String label) {
    final on = _kategori.text.trim().toLowerCase() == label.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _kategori.text = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        decoration: BoxDecoration(
          color: on ? _PC.primary : _PC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _PC.primary : _PC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_kategoriIcon(label), size: 15, color: on ? _PC.goldLight : _PC.gold),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _PC.inkSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: _PC.surface,
        border: const Border(top: BorderSide(color: _PC.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _PC.surfaceDim,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _PC.inkSecondary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _PC.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 20, color: _PC.goldLight),
                    label: const Text('Simpan Catatan',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
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
    final kategoriErr = _tried && _kategori.text.trim().isEmpty;
    final catatanErr = _tried && _catatan.text.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header tetap
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
              child: Column(
                children: [
                  _grabHandle(),
                  Row(
                    children: [
                      _iconTile(Icons.edit_note_rounded, size: 46),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Catatan Pembinaan Baru',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: _PC.ink)),
                            SizedBox(height: 1),
                            Text('Evaluasi akhlak & adab harian',
                                style: TextStyle(fontSize: 12.5, color: _PC.inkSecondary)),
                          ],
                        ),
                      ),
                      _closeButton(context),
                    ],
                  ),
                ],
              ),
            ),

            // Isi form (scroll)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _PC.goldSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _PC.goldBorder),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.spa_outlined, size: 18, color: _PC.goldDark),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Catatan dipakai untuk memantau perkembangan akhlak santri dan dievaluasi bersama asatidz serta musyrif.',
                              style: TextStyle(fontSize: 12, color: _PC.goldDark, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    _sectionTitle(1, 'Pilih Santri', req: true),
                    const SizedBox(height: 10),
                    _santriField(),
                    const SizedBox(height: 22),

                    _sectionTitle(2, 'Tanggal Pembinaan', req: true),
                    const SizedBox(height: 10),
                    _tanggalField(),
                    const SizedBox(height: 22),

                    _sectionTitle(3, 'Kategori', req: true, hint: 'Ketik atau pilih chip'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _kategori,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 14.5, color: _PC.ink),
                      decoration: _dec('Contoh: Kedisiplinan', err: kategoriErr),
                    ),
                    if (kategoriErr) _errorNote('Kategori wajib diisi.'),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [for (final c in _kSaranKategori) _saranChip(c)]),
                    const SizedBox(height: 22),

                    _sectionTitle(4, 'Catatan', req: true, hint: '${_catatan.text.length} karakter'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _catatan,
                      onChanged: (_) => setState(() {}),
                      minLines: 5,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 14.5, color: _PC.ink, height: 1.5),
                      decoration: _dec(
                        'Tuliskan perkembangan, kejadian, atau pembinaan yang diberikan...',
                        err: catatanErr,
                      ),
                    ),
                    if (catatanErr) _errorNote('Catatan wajib diisi.'),
                  ],
                ),
              ),
            ),

            // Bar aksi tetap
            _bottomBar(),
          ],
        ),
      ),
    );
  }
}