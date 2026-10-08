import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet sama dengan `_NC` di nilai_screen.dart (+ token status kesantrian dari DESIGN.md).
class _KC {
  _KC._();

  // Ikut tema pondok (diatur admin).
  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;

  static const gold = Color(0xFFC5A059);
  static const goldDark = Color(0xFF7A5B10);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const surfaceContainer = Color(0xFFEFEEEA);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);

  // Kotak "Amanah & Kerahasiaan"
  static const noticeBg = Color(0xFFE5E9E3);

  // Chip status
  static const rahasiaBg = Color(0xFFFDE2E1);
  static const tindakBg = Color(0xFFFCE3A0);
  static const tindakFg = Color(0xFF7A5B10);
  static const selesaiBg = Color(0xFFC9EBD7);
  static const selesaiFg = Color(0xFF1B5E20);
  static const umumBg = Color(0xFFECEBE6);

  static const amber = Color(0xFFB78103);
}

const _kPageSize = 5;

const _kBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

enum _Filter { semua, rahasia, tindakLanjut }

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

bool _isPrivat(Map<String, dynamic> k) => k['privat'] != false;

/// Belum ada field status di database. Jika API mengirim `status`, dipakai;
/// kalau tidak, catatan yang punya teks tindak lanjut dianggap masih perlu ditindaklanjuti.
bool _perluTindak(Map<String, dynamic> k) {
  final st = k['status'];
  if (st is String && st.isNotEmpty) return st.toUpperCase() != 'SELESAI';
  return (k['tindakLanjut'] ?? '').toString().trim().isNotEmpty;
}

DateTime? _tanggal(Map<String, dynamic> k) {
  final s = (k['tanggal'] ?? '').toString();
  if (s.length < 10) return null;
  return DateTime.tryParse(s.substring(0, 10));
}

String _fmtTanggal(DateTime? d) => d == null ? '-' : '${d.day.toString().padLeft(2, '0')} ${_kBulan[d.month - 1]} ${d.year}';

String _initials(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _singkatKonselor(String? n) {
  if (n == null || n.trim().isEmpty) return 'Konselor';
  return n.trim().replaceFirst(RegExp(r'^(ustadzah|ustadz|ustaz)\s+', caseSensitive: false), 'Ust. ');
}

Widget _pill(String label, Color bg, Color fg, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ],
    ),
  );
}

List<Widget> _statusChips(Map<String, dynamic> k) {
  return [
    if (_isPrivat(k))
      _pill('Rahasia', _KC.rahasiaBg, _KC.errorText, icon: Icons.lock_outline_rounded)
    else
      _pill('Umum', _KC.umumBg, _KC.inkSecondary),
    if (_perluTindak(k))
      _pill('Perlu Tindak Lanjut', _KC.tindakBg, _KC.tindakFg)
    else
      _pill('Selesai', _KC.selesaiBg, _KC.selesaiFg),
  ];
}

InputDecoration _dec(String label, {String? hint, String? error}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    alignLabelWithHint: true,
    filled: true,
    fillColor: _KC.background,
    labelStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
    hintStyle: const TextStyle(fontSize: 13, color: _KC.inkSecondary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(_KC.inputBorder),
    enabledBorder: b(_KC.inputBorder),
    focusedBorder: b(_KC.primary, 2),
    errorBorder: b(const Color(0xFFDC2626), 1.5),
    focusedErrorBorder: b(const Color(0xFFDC2626), 1.5),
  );
}

Widget _grabHandle() => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: _KC.inputBorder, borderRadius: BorderRadius.circular(999)),
      ),
    );

const _sheetShape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)));

const _kBulanPenuh = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _fmtTanggalPenuh(DateTime d) => '${d.day} ${_kBulanPenuh[d.month - 1]} ${d.year}';

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------
class KonselingScreen extends StatefulWidget {
  const KonselingScreen({super.key});

  @override
  State<KonselingScreen> createState() => _KonselingScreenState();
}

class _KonselingScreenState extends State<KonselingScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  _Filter _filter = _Filter.semua;
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _shown = _kPageSize;

  /// Pimpinan/Mudir hanya memantau: tidak bisa membuat atau menghapus catatan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

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
      final res = await AppScope.of(context).api.get(ApiUrl.konseling);
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
          _error = 'Gagal memuat catatan konseling.';
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
    final fg = error ? _KC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _KC.errorBg : _KC.primary,
          elevation: 6,
          // angka 88 = jarak dari bawah (samakan dengan absensi; turunkan jika terlalu tinggi)
          margin: EdgeInsets.fromLTRB(side, 0, side, 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _KC.errorText.withOpacity(0.25) : _KC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _KC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _KC.errorText : _KC.gold,
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
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _FormSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.konseling, result);
      if (!mounted) return;
      final tgl = DateTime.tryParse('${result['tanggal']}');
      _toast('Catatan konseling tersimpan',
          subtitle: tgl == null ? null : _fmtTanggalPenuh(tgl));
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal menyimpan catatan konseling.', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> k) async {
    if (_readOnly) return;
    final nama = (k['santri'] as Map?)?['nama'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _KC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus catatan konseling?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
        content: Text('Catatan konseling $nama akan dihapus.',
            style: const TextStyle(fontSize: 13.5, color: _KC.inkSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _KC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.konseling}/${k['id']}');
      if (!mounted) return;
      _toast('Catatan konseling dihapus', subtitle: nama.toString());
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal menghapus catatan.', error: true);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> k) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.background,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (_) => _DetailSheet(k: k, readOnly: _readOnly),
    );
    if (act == 'hapus' && !_readOnly && mounted) _delete(k);
  }

  // ---------------------------------------------------------------------
  // Turunan data
  // ---------------------------------------------------------------------
  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _list.where((k) {
      if (_filter == _Filter.rahasia && !_isPrivat(k)) return false;
      if (_filter == _Filter.tindakLanjut && !_perluTindak(k)) return false;
      if (q.isEmpty) return true;
      final s = k['santri'] as Map?;
      final hay = '${s?['nama'] ?? ''} ${s?['nis'] ?? ''} ${k['topik'] ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  void _setFilter(_Filter f) => setState(() {
        _filter = f;
        _shown = _kPageSize;
      });

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konseling Santri',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _KC.ink, height: 1.2)),
              SizedBox(height: 2),
              Text('Catatan pembinaan & konseling bersifat rahasia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: _KC.inkSecondary)),
            ],
          ),
        ),
        if (!_readOnly) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _add,
              style: FilledButton.styleFrom(
                backgroundColor: _KC.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.note_add_outlined, size: 20, color: Colors.white),
              label: const Text('Catatan Baru',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _KC.noticeBg, borderRadius: BorderRadius.circular(14)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.lock_outline_rounded, size: 20, color: _KC.ink),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AMANAH & KERAHASIAAN',
                    style: TextStyle(
                        fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
                SizedBox(height: 4),
                Text('Catatan ini hanya dapat diakses pengelola. Jaga amanah pembinaan, jangan dibagikan ke pihak lain.',
                    style: TextStyle(fontSize: 13, color: _KC.ink, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _KC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _KC.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 22, color: _KC.inkSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v;
                _shown = _kPageSize;
              }),
              style: const TextStyle(fontSize: 14, color: _KC.ink),
              decoration: const InputDecoration(
                hintText: 'Cari nama santri / NIS / topik...',
                hintStyle: TextStyle(fontSize: 14, color: _KC.inkSecondary),
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
            icon: const Icon(Icons.cancel_outlined, size: 20, color: _KC.inkSecondary),
            tooltip: 'Bersihkan',
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool on,
    required VoidCallback onTap,
    Widget? leading,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? _KC.primary : _KC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _KC.primary : _KC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 6)],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: on ? Colors.white : _KC.ink)),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(on ? 0.2 : 0.0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? Colors.white : _KC.inkSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            label: 'Semua',
            on: _filter == _Filter.semua,
            count: _list.length,
            onTap: () => _setFilter(_Filter.semua),
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Rahasia',
            on: _filter == _Filter.rahasia,
            leading: Icon(Icons.lock_outline_rounded,
                size: 15, color: _filter == _Filter.rahasia ? Colors.white : _KC.errorText),
            onTap: () => _setFilter(_Filter.rahasia),
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Perlu Tindak Lanjut',
            on: _filter == _Filter.tindakLanjut,
            leading: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _filter == _Filter.tindakLanjut ? Colors.white : _KC.amber,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _setFilter(_Filter.tindakLanjut),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    Color? accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: _KC.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _KC.border),
          boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: accent ?? _KC.inkSecondary)),
                ),
                Icon(icon, size: 18, color: accent ?? _KC.inkSecondary),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accent ?? _KC.ink)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats() {
    final now = DateTime.now();
    final followUp = _list
        .where(_perluTindak)
        .map((k) => (k['santriId'] ?? (k['santri'] as Map?)?['id'] ?? k['id']).toString())
        .toSet()
        .length;
    final bulanIni = _list.where((k) {
      final d = _tanggal(k);
      return d != null && d.year == now.year && d.month == now.month;
    }).length;

    return Row(
      children: [
        _statCard(label: 'Total', value: '${_list.length}', unit: 'sesi', icon: Icons.description_outlined),
        const SizedBox(width: 10),
        _statCard(
          label: 'Follow Up',
          value: '$followUp',
          unit: 'santri',
          icon: Icons.info_outline_rounded,
          accent: _KC.amber,
        ),
        const SizedBox(width: 10),
        _statCard(label: 'Bulan Ini', value: '$bulanIni', unit: 'kasus', icon: Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _catatanCard(Map<String, dynamic> k) {
    final s = (k['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final nis = s['nis']?.toString() ?? '-';
    final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
    final konselor = _singkatKonselor((k['konselor'] as Map?)?['nama']?.toString());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: _KC.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _KC.border),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () => _openDetail(k),
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
                      decoration: BoxDecoration(color: _KC.umumBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(_initials(nama),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _KC.ink)),
                          const SizedBox(height: 2),
                          Text('NIS $nis${kelas != null ? ' • Kelas $kelas' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_fmtTanggal(_tanggal(k)),
                          style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text((k['topik'] ?? '').toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink, height: 1.3)),
                const SizedBox(height: 6),
                Text((k['catatan'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, color: _KC.inkSecondary, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Wrap(spacing: 8, runSpacing: 6, children: _statusChips(k))),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(konselor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: _KC.inkSecondary)),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: _KC.ink),
                        ],
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: _KC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _KC.border),
                boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _KC.ink),
                  SizedBox(width: 8),
                  Text('Memuat Lebih Banyak',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _KC.ink)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text('Menampilkan $tampil dari $total catatan',
            style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(color: _KC.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _KC.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.folder_special_outlined, size: 28, color: _KC.ink),
          ),
          const SizedBox(height: 14),
          const Text('Konseling Personal & Tarbiyah',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
          const SizedBox(height: 6),
          const Text(
            'Catat perkembangan akhlak, bimbingan adab, dan catatan medis santri secara terpusat untuk kelanjutan evaluasi para asatidz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _KC.inkSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _toast('Format khusus segera hadir'),
              style: FilledButton.styleFrom(
                backgroundColor: _KC.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
              label: const Text('Buat Format Khusus',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
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
      backgroundColor: _KC.background,
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
                      color: _KC.primary,
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
                          const SizedBox(height: 14),
                          if (filtered.isEmpty)
                            emptyView(_list.isEmpty
                                ? 'Belum ada catatan konseling.'
                                : 'Tidak ada catatan yang cocok.')
                          else ...[
                            for (final k in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _catatanCard(k),
                              ),
                            const SizedBox(height: 4),
                            _muatLebih(filtered.length),
                          ],
                          if (!_readOnly) ...[
                            const SizedBox(height: 20),
                            _infoCard(),
                          ],
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
  final Map<String, dynamic> k;
  final bool readOnly;
  const _DetailSheet({required this.k, this.readOnly = false});

  static const _tindakBgTint = Color(0xFFFDEBC8);

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _KC.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _KC.border),
          boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      );

  Widget _cardTitle(String text, {IconData? icon, Color? iconBg, Color? color, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg ?? _KC.sage, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color ?? _KC.primary),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: color ?? _KC.ink)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _smallTag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _KC.surfaceContainer, borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
      );

  Widget _darkPill(String label, IconData icon, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ]),
      );

  Widget _metaRow(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: _KC.inkSecondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _KC.ink)),
            ),
          ],
        ),
      );

  String _waktu(dynamic raw) {
    final s = (raw ?? '').toString();
    final d = DateTime.tryParse(s);
    if (d == null) return '-';
    final l = s.length > 10 ? d.toLocal() : d;
    final tgl = _fmtTanggalPenuh(l);
    if (s.length <= 10) return tgl;
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '$tgl • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final s = (k['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final nis = s['nis']?.toString() ?? '-';
    final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
    final asrama = (s['asrama'] as Map?)?['nama']?.toString();
    final konselor = (k['konselor'] as Map?)?['nama']?.toString() ?? '-';
    final pencatat = (k['createdBy'] as Map?)?['nama']?.toString();

    // Field opsional: tampil hanya kalau API mengirimnya.
    final kategori = k['kategori']?.toString();
    final sesiKe = k['sesiKe']?.toString();
    final durasi = k['durasiMenit']?.toString();
    final sikap = k['sikapSantri']?.toString();

    // tindakLanjut (1 string) dipecah per baris jadi daftar bernomor.
    final steps = (k['tindakLanjut'] ?? '')
        .toString()
        .split('\n')
        .map((e) => e.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final privat = _isPrivat(k);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header tetap: handle + judul + tutup
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: _KC.inputBorder, borderRadius: BorderRadius.circular(999)),
                ),
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 22, color: _KC.ink),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Detail Konseling Santri',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _KC.ink)),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: _KC.surfaceContainer, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20, color: _KC.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Isi (scroll)
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, readOnly ? 24 + MediaQuery.of(context).padding.bottom : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [_KC.primary, _KC.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _KC.sage,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: Text(_initials(nama),
                                  style: TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.w800, color: _KC.primary)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('KONSELING SANTRI',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w700,
                                          color: _KC.gold)),
                                  const SizedBox(height: 2),
                                  Text(nama,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                                  const SizedBox(height: 4),
                                  Text('NIS $nis${kelas != null ? ' • Kelas $kelas' : ''}',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFE9C46A))),
                                  if (asrama != null)
                                    Text(asrama, style: const TextStyle(fontSize: 12.5, color: Colors.white60)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          privat
                              ? _darkPill('Rahasia (Private Record)', Icons.lock_outline_rounded, Colors.white, _KC.ink)
                              : _darkPill('Umum', Icons.public, Colors.white, _KC.ink),
                          _perluTindak(k)
                              ? _darkPill('Perlu Tindak Lanjut', Icons.hourglass_bottom_rounded,
                                  const Color(0xFFF3C969), _KC.tindakFg)
                              : _darkPill('Selesai', Icons.check_circle_outline, _KC.selesaiBg, _KC.selesaiFg),
                        ]),
                      ],
                    ),
                  ),

                  // Topik utama
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('TOPIK UTAMA', color: _KC.goldDark),
                        const SizedBox(height: 10),
                        Text((k['topik'] ?? '-').toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500, color: _KC.ink, height: 1.35)),
                        if (kategori != null || sesiKe != null) ...[
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            if (kategori != null) _smallTag('Kategori: $kategori'),
                            if (sesiKe != null) _smallTag('Sesi Ke-$sesiKe'),
                          ]),
                        ],
                      ],
                    ),
                  ),

                  // Catatan pembinaan & dialog
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('CATATAN PEMBINAAN & DIALOG',
                            icon: Icons.lock_outline_rounded,
                            trailing: durasi != null ? _smallTag('$durasi Menit') : null),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(12)),
                          child: Text((k['catatan'] ?? '-').toString(),
                              style: const TextStyle(fontSize: 14, color: _KC.ink, height: 1.6)),
                        ),
                        if (sikap != null && sikap.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.psychology_alt_outlined, size: 16, color: _KC.inkSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Sikap Santri: $sikap',
                                  style: const TextStyle(fontSize: 13, color: _KC.inkSecondary)),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),

                  // Rencana tindak lanjut
                  if (steps.isNotEmpty)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle('RENCANA TINDAK LANJUT',
                              icon: Icons.checklist_rounded, iconBg: _tindakBgTint, color: _KC.goldDark),
                          const SizedBox(height: 12),
                          for (var i = 0; i < steps.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration:
                                  BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i == steps.length - 1 && steps.length > 1
                                          ? _KC.goldDark
                                          : _KC.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(steps[i],
                                        style: const TextStyle(fontSize: 13.5, color: _KC.ink, height: 1.45)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Metadata & audit
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('METADATA & AUDIT LOG',
                            trailing: _pill('Terverifikasi', _KC.sage, _KC.primary)),
                        const SizedBox(height: 12),
                        _metaRow('Tanggal Sesi', _waktu(k['tanggal'])),
                        _metaRow('Pembimbing (Konselor)', konselor),
                        if (pencatat != null) _metaRow('Dicatat Oleh', pencatat),
                        if (k['updatedAt'] != null) _metaRow('Terakhir Diubah', _waktu(k['updatedAt'])),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration:
                              BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hak Akses Berkas:',
                                  style: TextStyle(fontSize: 13, color: _KC.inkSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                privat ? 'Pengelola & Pimpinan Ma\'had' : 'Asatidz & Musyrif Pembina',
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w600, color: _KC.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Catatan audit
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _KC.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_outlined, size: 18, color: _KC.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Setiap akses, pembacaan, dan perubahan data tercatat secara permanen di audit log sistem SIMPesantren demi integritas amanah santri.',
                            style: TextStyle(fontSize: 12, color: _KC.inkSecondary, height: 1.45),
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

          // Bar aksi tetap: tombol Hapus di tengah (tidak untuk Mudir)
          if (!readOnly)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _KC.surface,
                border: const Border(top: BorderSide(color: _KC.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Center(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'hapus'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _KC.errorBg,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20, color: _KC.errorText),
                        label: const Text('Hapus Catatan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.errorText)),
                      ),
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
      final res = await AppScope.of(context).api.get(ApiUrl.santri);
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14, color: _KC.ink),
                  decoration: _dec('Cari nama / NIS').copyWith(
                    labelText: null,
                    hintText: 'Cari nama / NIS…',
                    prefixIcon: const Icon(Icons.search, size: 20, color: _KC.inkSecondary),
                    isDense: true,
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
                                        BoxDecoration(color: _KC.umumBg, borderRadius: BorderRadius.circular(12)),
                                    child: Text(_initials(nama),
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: _KC.ink)),
                                  ),
                                  title: Text(nama,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 14, color: _KC.ink)),
                                  subtitle: Text('NIS ${s['nis']} • ${(s['kelas'] as Map?)?['namaKelas'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
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
  static const _red = Color(0xFFDC2626);
  static const _errFill = Color(0xFFFEE7E7);
  static const _mint = Color(0xFFDDF1E8);
  static const _mintBtn = Color(0xFFE6F4EF);

  final _topik = TextEditingController();
  final _catatan = TextEditingController();
  final _tindak = TextEditingController();

  Map<String, dynamic>? _santri;
  late DateTime _tgl;
  List<Map<String, dynamic>> _konselor = [];
  String? _konselorId;
  bool _privat = true;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _tgl = DateTime(n.year, n.month, n.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadKonselor();
    });
  }

  @override
  void dispose() {
    _topik.dispose();
    _catatan.dispose();
    _tindak.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  /// GET /ustadz hanya boleh untuk Admin/Pimpinan. Untuk role lain gagal (403),
  /// maka konselor ditampilkan sebagai user yang sedang login.
  Future<void> _loadKonselor() async {
    final scope = AppScope.of(context);
    try {
      final list = _asList(await scope.api.get(ApiUrl.ustadz));
      final me = scope.user?.id;
      String? mine;
      for (final u in list) {
        if (me != null && u['userId'] == me) mine = u['id'] as String?;
      }
      if (!mounted) return;
      setState(() {
        _konselor = list;
        _konselorId = mine;
      });
    } catch (_) {}
  }

  Map<String, dynamic>? get _konselorDipilih {
    for (final u in _konselor) {
      if (u['id'] == _konselorId) return u;
    }
    return null;
  }

  String get _konselorNama {
    final u = _konselorDipilih;
    if (u != null) return (u['nama'] ?? '-').toString();
    if (_konselor.isEmpty) return AppScope.of(context).user?.nama ?? '-';
    return 'Pilih konselor';
  }

  String? get _konselorTag {
    final u = _konselorDipilih;
    if (u != null) return u['jenis'] == 'MUSYRIF' ? 'Musyrif' : 'Guru';
    if (_konselor.isEmpty) {
      final me = AppScope.of(context).user;
      if (me == null) return null;
      if (me.isMusyrif) return 'Musyrif';
      if (me.isUstadz) return 'Ustadz';
    }
    return null;
  }

  bool get _konselorError => _tried && _konselor.isNotEmpty && _konselorId == null;

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _pilihSantri() async {
    final s = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.surface,
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
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _KC.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _tgl = DateTime(d.year, d.month, d.day));
  }

  Future<void> _pilihKonselor() async {
    if (_konselor.isEmpty) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: _sheetShape,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text('Pilih Konselor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final u in _konselor)
                    ListTile(
                      title: Text((u['nama'] ?? '-').toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: u['id'] == _konselorId ? FontWeight.w800 : FontWeight.w500,
                            color: _KC.ink,
                          )),
                      subtitle: Text(u['jenis'] == 'MUSYRIF' ? 'Musyrif' : 'Guru',
                          style: const TextStyle(fontSize: 12, color: _KC.inkSecondary)),
                      trailing: u['id'] == _konselorId
                          ? Icon(Icons.check_circle, color: _KC.primary, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, u['id'] as String),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (id != null && mounted) setState(() => _konselorId = id);
  }

  void _submit() {
    setState(() => _tried = true);
    if (_santri == null ||
        _konselorError ||
        _topik.text.trim().isEmpty ||
        _catatan.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop({
      'santriId': _santri!['id'],
      'tanggal': _isoDate(_tgl),
      if (_konselorId != null) 'konselorId': _konselorId,
      'topik': _topik.text.trim(),
      'catatan': _catatan.text.trim(),
      'tindakLanjut': _tindak.text.trim().isEmpty ? null : _tindak.text.trim(),
      'privat': _privat,
    });
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _label(String text, {bool req = false, String? tag, bool err = false}) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: err ? _KC.errorText : _KC.ink),
              children: [
                if (req) const TextSpan(text: ' *', style: TextStyle(color: _red)),
              ],
            ),
          ),
        ),
        if (tag != null)
          Text(tag,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: err ? FontWeight.w700 : FontWeight.w500,
                  color: err ? _KC.errorText : _KC.inkSecondary)),
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
            child: Icon(Icons.warning_amber_rounded, size: 18, color: _KC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(fontSize: 13, color: _KC.errorText, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _readField({
    required IconData icon,
    required String text,
    Widget? trailing,
    VoidCallback? onTap,
    bool placeholder = false,
    bool err = false,
  }) {
    return Material(
      color: _KC.surfaceDim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: err ? const BorderSide(color: _red, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _KC.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15, color: placeholder ? _KC.inkSecondary : _KC.ink)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
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
          color: err ? _KC.errorText.withOpacity(0.65) : _KC.inkSecondary.withOpacity(0.8)),
      filled: true,
      fillColor: err ? _errFill : _KC.surfaceDim,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
      border: b(),
      enabledBorder: b(),
      focusedBorder: b(_KC.primary),
    );
  }

  Widget _santriCard() {
    final s = _santri;
    final err = _tried && s == null;
    final nama = (s?['nama'] ?? '').toString();
    final kelas = (s?['kelas'] as Map?)?['namaKelas']?.toString();

    Widget avatar;
    if (s == null) {
      avatar = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: _KC.umumBg, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.person_search_outlined, size: 26, color: _KC.inkSecondary),
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
              decoration: BoxDecoration(color: _KC.umumBg, borderRadius: BorderRadius.circular(14)),
              child: Text(_initials(nama),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _KC.ink)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _KC.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: _KC.surfaceDim, width: 2),
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
          color: _KC.surfaceDim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: err ? const BorderSide(color: _red, width: 1.5) : BorderSide.none,
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
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _KC.ink)),
                              SizedBox(height: 2),
                              Text('Ketuk untuk memilih dari daftar',
                                  style: TextStyle(fontSize: 12.5, color: _KC.inkSecondary)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 15.5, fontWeight: FontWeight.w700, color: _KC.ink)),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_outlined, size: 16, color: _KC.inkSecondary),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('NIS ${s['nis'] ?? '-'}${kelas != null ? ' • Kelas $kelas' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: _KC.inkSecondary)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: _KC.surface, borderRadius: BorderRadius.circular(999)),
                    child: Text(s == null ? 'Pilih' : 'Ubah',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _KC.ink)),
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

  bool get _isToday {
    final n = DateTime.now();
    return _tgl.year == n.year && _tgl.month == n.month && _tgl.day == n.day;
  }

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: _KC.surface,
        border: const Border(top: BorderSide(color: _KC.border)),
        boxShadow: [BoxShadow(color: _KC.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _mintBtn,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _KC.primary,
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
    final topikErr = _tried && _topik.text.trim().isEmpty;
    final catatanErr = _tried && _catatan.text.trim().isEmpty;
    final tag = _konselorTag;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header tetap
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _KC.inputBorder, borderRadius: BorderRadius.circular(999)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 24, color: _KC.ink),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Catatan Konseling Baru',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _KC.ink)),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: _KC.surfaceContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 22, color: _KC.ink),
                        ),
                      ),
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
                      decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.lock_outline_rounded, size: 20, color: _KC.ink),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 13, color: _KC.ink, height: 1.5),
                                children: [
                                  TextSpan(
                                      text: 'Bersifat Rahasia',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: _KC.primary)),
                                  TextSpan(
                                      text:
                                          ' — Hanya dapat diakses Asatidz & Musyrif Pembina demi privasi dan maslahat santri.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pilih santri
                    _label('Pilih Santri', req: true, tag: _santri != null ? 'NIS Aktif' : null),
                    const SizedBox(height: 8),
                    _santriCard(),
                    const SizedBox(height: 20),

                    // Tanggal
                    _label('Tanggal Sesi Konseling', req: true),
                    const SizedBox(height: 8),
                    _readField(
                      icon: Icons.calendar_today_outlined,
                      text: _fmtTanggalPenuh(_tgl),
                      onTap: _pilihTanggal,
                      trailing: _isToday
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFDEBC8), borderRadius: BorderRadius.circular(999)),
                              child: const Text('Hari ini',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9A6B00))),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Konselor
                    _label('Konselor / Pembimbing', req: true, err: _konselorError),
                    const SizedBox(height: 8),
                    _readField(
                      icon: Icons.person_outline_rounded,
                      text: _konselorNama,
                      placeholder: _konselorDipilih == null && _konselor.isNotEmpty,
                      err: _konselorError,
                      onTap: _konselor.isEmpty ? null : _pilihKonselor,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tag != null)
                            Text(tag, style: const TextStyle(fontSize: 12.5, color: _KC.inkSecondary)),
                          if (_konselor.isNotEmpty)
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: _KC.ink),
                        ],
                      ),
                    ),
                    if (_konselorError) _errorNote('Pilih konselor terlebih dahulu.'),
                    const SizedBox(height: 20),

                    // Topik
                    _label('Topik Konseling', req: true, tag: 'Wajib diisi', err: topikErr),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topik,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15, color: _KC.ink),
                      decoration: _fillDec(
                        'Ketik topik permasalahan santri...',
                        err: topikErr,
                        suffix: topikErr
                            ? const Icon(Icons.error_outline_rounded, size: 22, color: _KC.errorText)
                            : null,
                      ),
                    ),
                    if (topikErr)
                      _errorNote('Topik wajib diisi (contoh: Motivasi belajar menurun, adaptasi asrama).'),
                    const SizedBox(height: 20),

                    // Catatan
                    _label('Catatan Konseling (Rahasia)', req: true, tag: 'Rahasia', err: catatanErr),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatan,
                      onChanged: (_) => setState(() {}),
                      minLines: 5,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15, color: _KC.ink, height: 1.4),
                      decoration: _fillDec(
                        'Tuliskan hasil dialog, kondisi emosional, dan kendala santri secara objektif...',
                        err: catatanErr,
                      ),
                    ),
                    if (catatanErr) _errorNote('Catatan konseling wajib diisi.'),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.shield_outlined, size: 14, color: _KC.ink),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text('Catatan ini bersifat rahasia dan tidak dicantumkan di rapor umum.',
                                style: TextStyle(fontSize: 12.5, color: _KC.ink, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tindak lanjut
                    _label('Rencana Tindak Lanjut', tag: 'Opsional'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tindak,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15, color: _KC.ink, height: 1.4),
                      decoration: _fillDec(
                          'Langkah pembinaan lanjutan (misal: koordinasi musyrif kamar, jadwal konseling kedua pekan depan)...'),
                    ),
                    const SizedBox(height: 20),

                    // Jadikan rahasia
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _KC.surfaceDim, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(color: const Color(0xFFD5EBE2), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.admin_panel_settings_outlined, size: 24, color: _KC.primary),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jadikan Rahasia',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
                                SizedBox(height: 2),
                                Text('Hanya dapat diakses pengelola & pimpinan ma\'had',
                                    style: TextStyle(fontSize: 12.5, color: _KC.inkSecondary, height: 1.4)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _privat,
                            onChanged: (v) => setState(() => _privat = v),
                            activeColor: Colors.white,
                            activeTrackColor: _KC.primary,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: _KC.inputBorder,
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                        ],
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