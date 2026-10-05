import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet sama dengan `_KC` di konseling_screen.dart (desain Khadim al-Ma'had).
class _PC {
  _PC._();

  // Ikut tema pondok (diatur admin).
  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;

  static const gold = Color(0xFFC5A059);
  static const goldDark = Color(0xFF7A5B10);
  static const goldTop = Color(0xFFFED488);
  static const sage = Color(0xFFE2ECE9);
  static const mint = Color(0xFFDDF1E8);
  static const avatarBg = Color(0xFFD5EBE2);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const surfaceLow = Color(0xFFF4F4F0);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const chipBg = Color(0xFFECEBE6);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
  static const errorFill = Color(0xFFFCEAE6);
  static const red = Color(0xFFDC2626);

  static const amber = Color(0xFFB78103);
  static const cancelBg = Color(0xFFE3E2DF);
}

const _kPageSize = 5;

const _kBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

const _kBulanPenuh = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

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

String _fmtTanggal(DateTime? d) =>
    d == null ? '-' : '${d.day.toString().padLeft(2, '0')} ${_kBulan[d.month - 1]} ${d.year}';

String _fmtTanggalPenuh(DateTime d) => '${d.day} ${_kBulanPenuh[d.month - 1]} ${d.year}';

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

BoxDecoration _cardDeco({double radius = 16, Color color = _PC.surface}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
    );

Widget _grabHandle() => Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: _PC.inputBorder, borderRadius: BorderRadius.circular(999)),
      ),
    );

Widget _closeButton(BuildContext context) => InkWell(
      onTap: () => Navigator.of(context).pop(),
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: _PC.surfaceContainer, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 21, color: _PC.ink),
      ),
    );

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
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
      _snack('Pembinaan karakter dicatat.');
      _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Gagal menyimpan catatan.');
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final nama = (p['santri'] as Map?)?['nama'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _PC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus catatan pembinaan?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _PC.ink)),
        content: Text('Catatan pembinaan karakter $nama akan dihapus.',
            style: const TextStyle(fontSize: 13.5, color: _PC.inkSecondary, height: 1.4)),
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
      _snack('Catatan pembinaan dihapus.');
      _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Gagal menghapus catatan.');
    }
  }

  Future<void> _openDetail(Map<String, dynamic> p) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.background,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (_) => _DetailSheet(p: p, canDelete: !_isWali),
    );
    if (act == 'hapus' && mounted) _delete(p);
  }

  // ---------------------------------------------------------------------
  // Turunan data
  // ---------------------------------------------------------------------
  /// Kategori unik dari data, diurutkan dari yang paling sering dipakai.
  List<String> get _kategoriList {
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
    return [for (final k in keys.take(8)) label[k]!];
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

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pembinaan Karakter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _PC.primary, height: 1.2)),
              SizedBox(height: 2),
              Text('Pantau perkembangan akhlak dan adab santri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: _PC.inkSecondary)),
            ],
          ),
        ),
        if (!_isWali) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 42,
            child: FilledButton.icon(
              onPressed: _add,
              style: FilledButton.styleFrom(
                backgroundColor: _PC.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.note_add_outlined, size: 18, color: Colors.white),
              label: const Text('+ Catatan Baru',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: 14, color: _PC.surfaceContainer),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _PC.avatarBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.spa_outlined, size: 20, color: _PC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PEMBINAAN BERKELANJUTAN',
                    style: TextStyle(
                        fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: _PC.primary)),
                SizedBox(height: 3),
                Text('Catat perkembangan akhlak santri secara rutin agar bisa dievaluasi bersama para asatidz dan musyrif.',
                    style: TextStyle(fontSize: 13, color: _PC.inkSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 50,
      decoration: _cardDeco(radius: 14),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 21, color: _PC.inkSecondary),
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
                hintText: 'Cari nama santri / NIS / kategori...',
                hintStyle: TextStyle(fontSize: 14, color: _PC.inkSecondary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _searchCtrl.clear();
              _query = '';
              _shown = _kPageSize;
            }),
            icon: const Icon(Icons.close, size: 19, color: _PC.inkSecondary),
            tooltip: 'Bersihkan',
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool on, required VoidCallback onTap, int? count}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? _PC.primary : _PC.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: on
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: on ? Colors.white : _PC.ink)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(on ? 0.2 : 0.0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? Colors.white : _PC.inkSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final cats = _kategoriList;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(label: 'Semua', on: _kategori == null, count: _list.length, onTap: () => _setKategori(null)),
          for (final c in cats) ...[
            const SizedBox(width: 8),
            _chip(
              label: c,
              on: _kategori != null && _kategori!.toLowerCase() == c.toLowerCase(),
              onTap: () => _setKategori(c),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String unit,
    Color? accent,
    bool topBar = false,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: _cardDeco(radius: 14),
          child: Stack(
            children: [
              if (topBar)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(height: 4, color: _PC.goldTop),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600, color: accent ?? _PC.inkSecondary)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent ?? _PC.primary)),
                      Text(unit,
                          style: TextStyle(fontSize: 10.5, color: (accent ?? _PC.inkSecondary).withOpacity(0.85))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stats() {
    final now = DateTime.now();
    final dibina = _list
        .map((p) => (p['santriId'] ?? (p['santri'] as Map?)?['id'] ?? p['id']).toString())
        .toSet()
        .length;
    final bulanIni = _list.where((p) {
      final d = _tanggal(p);
      return d != null && d.year == now.year && d.month == now.month;
    }).length;

    return Row(
      children: [
        _statCard(label: 'Total', value: '${_list.length}', unit: 'catatan'),
        const SizedBox(width: 8),
        _statCard(label: 'Santri Dibina', value: '$dibina', unit: 'santri', accent: _PC.goldDark, topBar: true),
        const SizedBox(width: 8),
        _statCard(label: 'Bulan Ini', value: '$bulanIni', unit: 'catatan'),
      ],
    );
  }

  Widget _catatanCard(Map<String, dynamic> p) {
    final s = (p['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final kategori = (p['kategori'] ?? '-').toString();

    return Container(
      decoration: _cardDeco(radius: 18),
      child: Material(
        color: _PC.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(p),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _PC.avatarBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(_initials(nama),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _PC.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _PC.ink)),
                          const SizedBox(height: 2),
                          Text(_santriInfo(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmtTanggal(_tanggal(p)),
                        style: TextStyle(fontSize: 11.5, color: _PC.inkSecondary.withOpacity(0.8))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(_kategoriIcon(kategori), size: 18, color: _PC.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(kategori,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _PC.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text((p['catatan'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _PC.inkSecondary, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: _PC.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                        child: Text(kategori,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _PC.ink)),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 21, color: Color(0xFFC0C8C3)),
                  ],
                ),
              ],
            ),
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
          InkWell(
            onTap: () => setState(() => _shown += _kPageSize),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(color: _PC.surfaceLow, borderRadius: BorderRadius.circular(999)),
              alignment: Alignment.center,
              child: Text('Memuat Lebih Banyak',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _PC.primary)),
            ),
          ),
        const SizedBox(height: 8),
        Text('Menampilkan $tampil dari $total catatan',
            style: TextStyle(fontSize: 11.5, color: _PC.inkSecondary.withOpacity(0.8))),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: _cardDeco(radius: 20, color: _PC.surfaceContainer),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: _cardDeco(radius: 16),
            child: Icon(Icons.auto_stories_outlined, size: 24, color: _PC.primary),
          ),
          const SizedBox(height: 12),
          Text('Pembinaan Karakter & Adab',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _PC.primary)),
          const SizedBox(height: 6),
          const Text(
            'Mencatat dan mengawal adab santri sehari-hari demi terwujudnya insan bertakwa yang berakhlak karimah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _PC.inkSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(bool noData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(color: _PC.surfaceLow, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFE9E8E4), shape: BoxShape.circle),
            child: Icon(Icons.inbox_outlined, size: 22, color: _PC.inkSecondary.withOpacity(0.7)),
          ),
          const SizedBox(height: 10),
          Text(noData ? 'Belum ada catatan pembinaan karakter' : 'Tidak ada catatan yang cocok',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _PC.ink)),
          const SizedBox(height: 4),
          Text(
            noData
                ? (_isWali
                    ? 'Catatan perkembangan santri akan tampil di sini.'
                    : 'Gunakan tombol "+ Catatan Baru" di atas untuk menambahkan catatan perkembangan santri.')
                : 'Coba ubah kata kunci atau pilih kategori lain.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: _PC.inkSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final visible = filtered.take(_shown).toList();

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
                    child: RefreshIndicator(
                      onRefresh: _load,
                      color: _PC.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                        children: [
                          _header(),
                          const SizedBox(height: 14),
                          _notice(),
                          const SizedBox(height: 14),
                          _searchField(),
                          const SizedBox(height: 12),
                          _filters(),
                          const SizedBox(height: 14),
                          _stats(),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            _emptyCard(_list.isEmpty)
                          else ...[
                            for (final p in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _catatanCard(p),
                              ),
                            const SizedBox(height: 4),
                            _muatLebih(filtered.length),
                          ],
                          const SizedBox(height: 22),
                          _infoCard(),
                        ],
                      ),
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
        decoration: _cardDeco(radius: 16),
        child: child,
      );

  Widget _cardTitle(String text, IconData icon) => Row(
        children: [
          Icon(icon, size: 17, color: _PC.inkSecondary),
          const SizedBox(width: 8),
          Text(text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: _PC.inkSecondary)),
        ],
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: _PC.inkSecondary)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _PC.ink)),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF0EFEA));

  Widget _watermark() {
    final c = Colors.white.withOpacity(0.06);
    return Positioned(
      right: -22,
      bottom: -22,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
                width: 58, height: 58, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            Transform.rotate(
              angle: 0.785398,
              child: Container(
                  width: 58, height: 58, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 3)),
            ),
          ],
        ),
      ),
    );
  }

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
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
            child: Column(
              children: [
                _grabHandle(),
                Row(
                  children: [
                    Expanded(
                      child: Text('Detail Pembinaan Karakter',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _PC.primary)),
                    ),
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
                  // Hero
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [_PC.primary, _PC.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        _watermark(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(_initials(nama),
                                    style: const TextStyle(
                                        fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFF3D690))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PEMBINAAN KARAKTER',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFF3D690))),
                                    const SizedBox(height: 2),
                                    Text(nama,
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                                    const SizedBox(height: 3),
                                    Text(_santriInfo(s),
                                        style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFF3D690), shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(kategori,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
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

                  // Kategori & tanggal
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('KATEGORI PEMBINAAN',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      letterSpacing: 0.6,
                                      fontWeight: FontWeight.w700,
                                      color: _PC.inkSecondary)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _PC.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 13, color: _PC.goldDark),
                                  const SizedBox(width: 5),
                                  Text(tanggal == null ? '-' : _fmtTanggalPenuh(tanggal),
                                      style: const TextStyle(
                                          fontSize: 11.5, fontWeight: FontWeight.w600, color: _PC.goldDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration:
                                  BoxDecoration(color: _PC.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                              child: Icon(_kategoriIcon(kategori), size: 20, color: _PC.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(kategori,
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800, color: _PC.primary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Catatan pembinaan
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('Catatan Pembinaan', Icons.edit_note_rounded),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _PC.surfaceLow, borderRadius: BorderRadius.circular(12)),
                          child: Text((p['catatan'] ?? '-').toString(),
                              style: const TextStyle(fontSize: 14, color: _PC.ink, height: 1.65)),
                        ),
                      ],
                    ),
                  ),

                  // Informasi pembinaan
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('Informasi Pembinaan', Icons.info_outline_rounded),
                        const SizedBox(height: 6),
                        _infoRow('Tanggal', _tanggalWaktu(p)),
                        _divider(),
                        _infoRow('Kategori', kategori),
                        _divider(),
                        _infoRow('Santri', kelas != null ? '$nama ($kelas)' : nama),
                      ],
                    ),
                  ),

                  // Catatan akses
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _PC.sage, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 19, color: _PC.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catatan pembinaan hanya dapat dilihat oleh pihak yang berwenang (Asatidz dan Musyrif).',
                            style: TextStyle(fontSize: 12.5, color: _PC.primary, height: 1.45),
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

          // Bar aksi tetap (tombol Hapus di tengah)
          if (canDelete)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _PC.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 50,
                        width: 300,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, 'hapus'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _PC.errorBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 20, color: _PC.errorText),
                          label: const Text('Hapus Catatan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _PC.errorText)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Akses Asatidz & Musyrif Pengasuhan',
                          style: TextStyle(fontSize: 11.5, color: _PC.inkSecondary.withOpacity(0.85))),
                    ],
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
      final res = await AppScope.of(context).api.get(ApiUrl.santri, query: {'perPage': '100'});
      final items = _asList(res);
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
                const Text('Pilih Santri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _PC.ink)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14, color: _PC.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari nama / NIS…',
                    hintStyle: const TextStyle(fontSize: 14, color: _PC.inkSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20, color: _PC.inkSecondary),
                    isDense: true,
                    filled: true,
                    fillColor: _PC.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _PC.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _PC.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _PC.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : list.isEmpty
                          ? emptyView('Santri tidak ditemukan.')
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (ctx, i) {
                                final s = list[i];
                                final nama = (s['nama'] ?? '-').toString();
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration:
                                        BoxDecoration(color: _PC.avatarBg, borderRadius: BorderRadius.circular(12)),
                                    child: Text(_initials(nama),
                                        style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: _PC.primary)),
                                  ),
                                  title: Text(nama,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 14, color: _PC.ink)),
                                  subtitle: Text('NIS ${s['nis']} • ${(s['kelas'] as Map?)?['namaKelas'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
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
  Widget _label(String text, {bool req = false, String? tag, bool err = false, Widget? tagWidget}) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: err ? _PC.errorText : _PC.ink),
              children: [if (req) const TextSpan(text: ' *', style: TextStyle(color: _PC.red))],
            ),
          ),
        ),
        if (tagWidget != null)
          tagWidget
        else if (tag != null)
          Text(tag, style: const TextStyle(fontSize: 12, color: _PC.inkSecondary)),
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
            child: Icon(Icons.warning_amber_rounded, size: 18, color: _PC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: _PC.errorText, height: 1.4))),
        ],
      ),
    );
  }

  InputDecoration _fillDec(String hint, {bool err = false, Widget? suffix}) {
    OutlineInputBorder b([Color? c, double w = 2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 14.5,
          height: 1.4,
          color: err ? _PC.errorText.withOpacity(0.65) : _PC.inkSecondary.withOpacity(0.8)),
      filled: true,
      fillColor: err ? _PC.errorFill : _PC.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
      border: b(),
      enabledBorder: b(),
      focusedBorder: b(_PC.primary),
    );
  }

  Widget _santriCard() {
    final s = _santri;
    final err = _tried && s == null;
    final nama = (s?['nama'] ?? '').toString();

    Widget avatar;
    if (s == null) {
      avatar = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: _PC.chipBg, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.person_search_outlined, size: 26, color: _PC.inkSecondary),
      );
    } else {
      avatar = SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _PC.avatarBg, borderRadius: BorderRadius.circular(26)),
              child: Text(_initials(nama),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _PC.primary)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _PC.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: _PC.surfaceDim, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: _PC.surfaceDim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: err ? const BorderSide(color: _PC.red, width: 1.5) : BorderSide.none,
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: _pilihSantri,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: s == null
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pilih santri',
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _PC.ink)),
                              SizedBox(height: 2),
                              Text('Ketuk untuk memilih dari daftar',
                                  style: TextStyle(fontSize: 12.5, color: _PC.inkSecondary)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _PC.ink)),
                              const SizedBox(height: 2),
                              Text(_santriInfo(s),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: _PC.inkSecondary)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: _PC.surface, borderRadius: BorderRadius.circular(999)),
                    child: Text(s == null ? 'Pilih' : 'Ubah',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _PC.ink)),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pilihTanggal,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 20, color: _PC.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_fmtTanggalPenuh(_tgl),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _PC.ink)),
              ),
              if (_isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFDEBC8), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Hari ini',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9A6B00))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saranChip(String label) {
    final on = _kategori.text.trim().toLowerCase() == label.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _kategori.text = label),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? _PC.primary : _PC.chipBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? Colors.white : _PC.ink)),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: _PC.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
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
                      backgroundColor: _PC.cancelBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _PC.ink)),
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
                    icon: const Icon(Icons.save_outlined, size: 20, color: Colors.white),
                    label: const Text('Simpan Catatan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: const Color(0xFFBFEBD8), borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.edit_note_rounded, size: 24, color: _PC.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Catatan Pembinaan Baru',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _PC.ink)),
                            SizedBox(height: 1),
                            Text('Evaluasi Akhlaq & Adab Harian',
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: _PC.mint, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.spa_outlined, size: 20, color: _PC.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Catatan dipakai untuk memantau perkembangan akhlak santri.',
                                style: TextStyle(fontSize: 13, color: _PC.ink, height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pilih santri
                    _label(
                      'Pilih Santri',
                      req: true,
                      tagWidget: _santri == null
                          ? null
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration:
                                  BoxDecoration(color: const Color(0xFFBFEBD8), borderRadius: BorderRadius.circular(999)),
                              child: Text('Terpilih Aktif',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _PC.primary)),
                            ),
                    ),
                    const SizedBox(height: 8),
                    _santriCard(),
                    const SizedBox(height: 20),

                    // Tanggal
                    _label('Tanggal Pembinaan', req: true),
                    const SizedBox(height: 8),
                    _tanggalField(),
                    const SizedBox(height: 20),

                    // Kategori
                    _label('Kategori', req: true, tag: 'Bisa ketik atau pilih chip', err: kategoriErr),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kategori,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 15, color: _PC.ink),
                      decoration: _fillDec(
                        'Contoh: Kedisiplinan',
                        err: kategoriErr,
                        suffix: kategoriErr
                            ? const Icon(Icons.error_outline_rounded, size: 22, color: _PC.errorText)
                            : null,
                      ),
                    ),
                    if (kategoriErr) _errorNote('Kategori wajib diisi.'),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [for (final c in _kSaranKategori) _saranChip(c)]),
                    const SizedBox(height: 20),

                    // Catatan
                    _label(
                      'Catatan',
                      req: true,
                      err: catatanErr,
                      tagWidget: catatanErr
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 15, color: _PC.errorText),
                                SizedBox(width: 4),
                                Text('Wajib Diisi',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _PC.errorText)),
                              ],
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatan,
                      onChanged: (_) => setState(() {}),
                      minLines: 5,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15, color: _PC.ink, height: 1.4),
                      decoration: _fillDec(
                        'Tuliskan perkembangan, kejadian, atau pembinaan yang diberikan...',
                        err: catatanErr,
                      ),
                    ),
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