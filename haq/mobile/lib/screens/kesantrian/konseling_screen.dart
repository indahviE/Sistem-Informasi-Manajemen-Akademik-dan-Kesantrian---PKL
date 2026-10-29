import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

// Layar Konseling Santri.
//
// Pimpinan/Mudir: mode baca saja (tanpa catatan baru dan hapus).

// Warna status kesantrian (tidak ada di SC)
const _kRahasiaBg = Color(0xFFFDE2E1);
const _kTindakBg = Color(0xFFFCE3A0);
const _kTindakFg = Color(0xFF7A5B10);
const _kSelesaiBg = Color(0xFFC9EBD7);
const _kSelesaiFg = Color(0xFF1B5E20);
const _kUmumBg = Color(0xFFECEBE6);
const _kAmber = Color(0xFFB78103);
const _kNoticeBg = Color(0xFFE5E9E3);
const _kRed = Color(0xFFDC2626);

const double _maxW = 480;
const _kPageSize = 5;

const _kBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _kBulanPenuh = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

enum _Filter { semua, rahasia, tindakLanjut }

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

String _singkatKonselor(String? n) {
  if (n == null || n.trim().isEmpty) return 'Konselor';
  return n.trim().replaceFirst(RegExp(r'^(ustadzah|ustadz|ustaz)\s+', caseSensitive: false), 'Ust. ');
}

Widget _pill(String label, Color bg, Color fg, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: sty(10.5, FontWeight.w800, fg)),
        ),
      ],
    ),
  );
}

List<Widget> _statusChips(Map<String, dynamic> k) {
  return [
    if (_isPrivat(k))
      _pill('Rahasia', _kRahasiaBg, SC.errorText, icon: Icons.lock_outline_rounded)
    else
      _pill('Umum', _kUmumBg, SC.inkSecondary),
    if (_perluTindak(k))
      _pill('Perlu Tindak Lanjut', _kTindakBg, _kTindakFg)
    else
      _pill('Selesai', _kSelesaiBg, _kSelesaiFg),
  ];
}

InputDecoration _dec(String hint, {Widget? prefix}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    prefixIcon: prefix,
    filled: true,
    fillColor: SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
}

RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

const _sheetShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)));

Widget _grabHandle({double bottom = 14}) => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: EdgeInsets.only(bottom: bottom),
        decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(999)),
      ),
    );

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
  final _scroll = ScrollController();
  String _query = '';
  int _shown = _kPageSize;

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

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
    _bannerTimer?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.konseling);
      final items = _asList(res)
        ..sort((a, b) => (b['tanggal'] ?? '').toString().compareTo((a['tanggal'] ?? '').toString()));
      if (!mounted) return;
      setState(() {
        _list = items;
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
    } catch (_) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = 'Gagal memuat catatan konseling.';
          _loading = false;
        });
      } else {
        _toast('Gagal memuat catatan konseling.', error: true);
      }
    }
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
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _add() async {
    if (_readOnly) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SC.background,
      constraints: const BoxConstraints(maxWidth: _maxW),
      shape: _sheetShape,
      builder: (_) => const _FormSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.konseling, result);
      if (!mounted) return;
      final tgl = DateTime.tryParse('${result['tanggal']}');
      _toast('Catatan konseling tersimpan', subtitle: tgl == null ? null : _fmtTanggalPenuh(tgl));
      _load(spinner: false);
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
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: SC.errorBg,
            shape: BoxShape.circle,
            border: Border.all(color: SC.gold.withOpacity(0.45)),
          ),
          child: const Icon(Icons.delete_outline_rounded, size: 26, color: SC.errorText),
        ),
        title: Text('Hapus catatan konseling?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text('Catatan konseling $nama akan dihapus.',
            textAlign: TextAlign.center,
            style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SC.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SC.errorText,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Hapus', style: sty(13, FontWeight.w700, Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.konseling}/${k['id']}');
      if (!mounted) return;
      _toast('Catatan konseling dihapus', subtitle: nama.toString());
      _load(spinner: false);
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
      backgroundColor: SC.background,
      constraints: const BoxConstraints(maxWidth: _maxW),
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

  int get _followUpSantri => _list
      .where(_perluTindak)
      .map((k) => (k['santriId'] ?? (k['santri'] as Map?)?['id'] ?? k['id']).toString())
      .toSet()
      .length;

  int get _bulanIni {
    final now = DateTime.now();
    return _list.where((k) {
      final d = _tanggal(k);
      return d != null && d.year == now.year && d.month == now.month;
    }).length;
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    String v(int n) => loaded ? '$n' : '–';
    final fu = loaded ? _followUpSantri : 0;

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
                child: const Icon(Icons.forum_outlined, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Konseling Santri', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      'Pembinaan & bimbingan santri',
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
                stat(Icons.description_outlined, v(_list.length), 'Total sesi'),
                garis(),
                stat(Icons.info_outline_rounded, v(fu), 'Follow up', gold: fu > 0),
                garis(),
                stat(Icons.calendar_today_outlined, v(_bulanIni), 'Bulan ini'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Info amanah
  // ---------------------------------------------------------------------
  Widget _notice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kNoticeBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SC.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.lock_outline_rounded, size: 18, color: SC.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AMANAH & KERAHASIAAN',
                      style: sty(10, FontWeight.w800, SC.inkSecondary)),
                  const SizedBox(height: 3),
                  Text(
                    'Catatan ini hanya dapat diakses pengelola. Jaga amanah pembinaan, jangan dibagikan ke pihak lain.',
                    style: sty(12, FontWeight.w600, SC.ink, h: 1.35),
                  ),
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
          controller: _searchCtrl,
          onChanged: (v) => setState(() {
            _query = v;
            _shown = _kPageSize;
          }),
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari nama santri, NIS, atau topik',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () => setState(() {
                      _searchCtrl.clear();
                      _query = '';
                      _shown = _kPageSize;
                    }),
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

  /// Kontrol segmen Semua / Rahasia / Tindak Lanjut.
  Widget _segmented() {
    final nRahasia = _list.where(_isPrivat).length;
    final nTindak = _list.where(_perluTindak).length;

    Widget seg(_Filter value, String label, int n) {
      final active = _filter == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setFilter(value),
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
            seg(_Filter.semua, 'Semua', _list.length),
            seg(_Filter.rahasia, 'Rahasia', nRahasia),
            seg(_Filter.tindakLanjut, 'Tindak Lanjut', nTindak),
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
    if (_list.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.forum_outlined,
            judul: 'Belum ada catatan konseling',
            pesan: _readOnly
                ? 'Belum ada catatan dari pembimbing.'
                : 'Tekan "Catatan Baru" untuk mencatat sesi konseling.',
          ),
        ),
      ];
    }

    final filtered = _filtered;
    final visible = filtered.take(_shown).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
          child: Row(
            children: [
              Text('Daftar Catatan', style: sty(15, FontWeight.w800, SC.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('${filtered.length}', style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada catatan yang cocok dengan pencarian atau filter ini.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              for (final k in visible) _catatanCard(k),
              const SizedBox(height: 4),
              _muatLebih(filtered.length),
            ]),
          ),
        ),
    ];
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
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
                  child: Icon(icon, size: 38, color: SC.primary),
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
  // Kartu catatan
  // ---------------------------------------------------------------------
  Widget _catatanCard(Map<String, dynamic> k) {
    final s = (k['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString();
    final nis = s['nis']?.toString() ?? '-';
    final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
    final konselor = _singkatKonselor((k['konselor'] as Map?)?['nama']?.toString());
    final perlu = _perluTindak(k);

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
              onTap: () => _openDetail(k),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: perlu ? _kAmber : SC.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                                  decoration:
                                      const BoxDecoration(color: _kUmumBg, shape: BoxShape.circle),
                                  child: Text(_initials(nama),
                                      style: sty(15, FontWeight.w800, SC.ink)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nama,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: sty(15, FontWeight.w800, SC.ink)),
                                      const SizedBox(height: 2),
                                      Text('NIS $nis${kelas != null ? ' • Kelas $kelas' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(_fmtTanggal(_tanggal(k)),
                                      style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text((k['topik'] ?? '').toString(),
                                style: sty(15.5, FontWeight.w800, SC.ink, h: 1.3)),
                            const SizedBox(height: 6),
                            Text((k['catatan'] ?? '').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.4)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: Wrap(spacing: 6, runSpacing: 6, children: _statusChips(k))),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(konselor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
                                      ),
                                      Icon(Icons.chevron_right_rounded, size: 18, color: SC.primary),
                                    ],
                                  ),
                                ),
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

  Widget _muatLebih(int total) {
    final tampil = total < _shown ? total : _shown;
    return Column(
      children: [
        if (total > _shown)
          OutlinedButton.icon(
            onPressed: () => setState(() => _shown += _kPageSize),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SC.border),
              backgroundColor: SC.surface,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: SC.primary),
            label: Text('Memuat Lebih Banyak', style: sty(13, FontWeight.w700, SC.primary)),
          ),
        const SizedBox(height: 10),
        Text('Menampilkan $tampil dari $total catatan',
            style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
      ],
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
        onTap: _add,
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
              Text('Catatan Baru', style: sty(14, FontWeight.w800, Colors.white)),
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
    final loaded = !_loading && _error == null;
    final showControls = loaded && _list.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
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
                    if (loaded) SliverToBoxAdapter(child: _notice()),
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
              if (!_readOnly && loaded) Positioned(right: 16, bottom: 20, child: _tombolBaru()),
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
  final Map<String, dynamic> k;
  final bool readOnly;
  const _DetailSheet({required this.k, this.readOnly = false});

  static const _tindakBgTint = Color(0xFFFDEBC8);

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.border),
          boxShadow: softShadow,
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
            decoration: BoxDecoration(color: iconBg ?? SC.sage, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color ?? SC.primary),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(text, style: sty(10.5, FontWeight.w800, color ?? SC.ink)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _smallTag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: sty(11.5, FontWeight.w600, SC.inkSecondary)),
      );

  Widget _darkPill(String label, IconData icon, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: sty(11.5, FontWeight.w800, fg)),
        ]),
      );

  Widget _metaRow(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right, style: sty(12.5, FontWeight.w700, SC.ink)),
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
                _grabHandle(bottom: 12),
                Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 22, color: SC.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Detail Konseling Santri',
                          style: sty(17, FontWeight.w800, SC.ink)),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: SC.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: SC.border),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: SC.ink),
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
                      boxShadow: softShadow,
                      gradient: LinearGradient(
                        colors: [SC.primary, SC.primaryEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: SC.sage,
                                shape: BoxShape.circle,
                                border: Border.all(color: SC.gold.withOpacity(0.6), width: 2),
                              ),
                              child: Text(_initials(nama),
                                  style: sty(22, FontWeight.w800, SC.primary)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nama,
                                      style: sty(19, FontWeight.w800, Colors.white, h: 1.2)),
                                  const SizedBox(height: 4),
                                  Text('NIS $nis${kelas != null ? ' • Kelas $kelas' : ''}',
                                      style: sty(12.5, FontWeight.w600, const Color(0xFFE9C46A))),
                                  if (asrama != null)
                                    Text(asrama,
                                        style: sty(12, FontWeight.w500, Colors.white60)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          privat
                              ? _darkPill('Rahasia', Icons.lock_outline_rounded, Colors.white, SC.ink)
                              : _darkPill('Umum', Icons.public, Colors.white, SC.ink),
                          _perluTindak(k)
                              ? _darkPill('Perlu Tindak Lanjut', Icons.hourglass_bottom_rounded,
                                  const Color(0xFFF3C969), _kTindakFg)
                              : _darkPill('Selesai', Icons.check_circle_outline, _kSelesaiBg, _kSelesaiFg),
                        ]),
                      ],
                    ),
                  ),

                  // Topik utama
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('TOPIK UTAMA', color: SC.goldDark),
                        const SizedBox(height: 10),
                        Text((k['topik'] ?? '-').toString(),
                            style: sty(17, FontWeight.w700, SC.ink, h: 1.35)),
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

                  // Catatan konseling
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('CATATAN KONSELING',
                            icon: Icons.chat_bubble_outline_rounded,
                            trailing: durasi != null ? _smallTag('$durasi Menit') : null),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                          child: Text((k['catatan'] ?? '-').toString(),
                              style: sty(13.5, FontWeight.w500, SC.ink, h: 1.6)),
                        ),
                        if (sikap != null && sikap.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.psychology_alt_outlined,
                                size: 16, color: SC.inkSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Sikap Santri: $sikap',
                                  style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
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
                              icon: Icons.checklist_rounded,
                              iconBg: _tindakBgTint,
                              color: SC.goldDark),
                          const SizedBox(height: 12),
                          for (var i = 0; i < steps.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i == steps.length - 1 && steps.length > 1
                                          ? SC.goldDark
                                          : SC.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('${i + 1}',
                                        style: sty(12, FontWeight.w800, Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(steps[i],
                                        style: sty(13.5, FontWeight.w500, SC.ink, h: 1.45)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Informasi sesi
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('INFORMASI SESI'),
                        const SizedBox(height: 12),
                        _metaRow('Tanggal Sesi', _waktu(k['tanggal'])),
                        _metaRow('Pembimbing (Konselor)', konselor),
                        if (pencatat != null) _metaRow('Dicatat Oleh', pencatat),
                        if (k['updatedAt'] != null)
                          _metaRow('Terakhir Diubah', _waktu(k['updatedAt'])),
                        _metaRow('Hak Akses',
                            privat ? "Pengelola & Pimpinan Ma'had" : 'Asatidz & Musyrif Pembina'),
                      ],
                    ),
                  ),

                  // Catatan audit
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SC.goldSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SC.gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_outlined, size: 18, color: SC.goldDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Setiap akses, pembacaan, dan perubahan data tercatat secara permanen di audit log sistem SIMPesantren demi integritas amanah santri.',
                            style: sty(11.5, FontWeight.w600, SC.goldDark, h: 1.45),
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

          // Bar aksi tetap: tombol Hapus (tidak untuk Mudir)
          if (!readOnly)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: SC.surface,
                border: const Border(top: BorderSide(color: SC.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SC.errorText,
                      backgroundColor: SC.errorBg.withOpacity(0.5),
                      side: BorderSide(color: SC.errorText.withOpacity(0.25)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 20, color: SC.errorText),
                    label: Text('Hapus Catatan', style: sty(14, FontWeight.w700, SC.errorText)),
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
      final res = await AppScope.of(context).api.get('${ApiUrl.santri}?binaan=true');
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabHandle(),
                Text('Pilih Santri', style: sty(16, FontWeight.w800, SC.ink)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: sty(14, FontWeight.w600, SC.ink),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NIS',
                      hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
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
                                    decoration: const BoxDecoration(
                                        color: _kUmumBg, shape: BoxShape.circle),
                                    child: Text(_initials(nama),
                                        style: sty(13, FontWeight.w800, SC.ink)),
                                  ),
                                  title: Text(nama, style: sty(14, FontWeight.w800, SC.ink)),
                                  subtitle: Text(
                                      'NIS ${s['nis']} • ${(s['kelas'] as Map?)?['namaKelas'] ?? '-'}',
                                      style: sty(12, FontWeight.w500, SC.inkSecondary)),
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
      backgroundColor: SC.background,
      constraints: const BoxConstraints(maxWidth: _maxW),
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
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: SC.primary, onPrimary: Colors.white),
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
      backgroundColor: SC.surface,
      constraints: const BoxConstraints(maxWidth: _maxW),
      shape: _sheetShape,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text('Pilih Konselor', style: sty(15, FontWeight.w800, SC.ink)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final u in _konselor)
                    ListTile(
                      title: Text((u['nama'] ?? '-').toString(),
                          style: sty(14, u['id'] == _konselorId ? FontWeight.w800 : FontWeight.w500,
                              SC.ink)),
                      subtitle: Text(u['jenis'] == 'MUSYRIF' ? 'Musyrif' : 'Guru',
                          style: sty(12, FontWeight.w500, SC.inkSecondary)),
                      trailing: u['id'] == _konselorId
                          ? Icon(Icons.check_circle, color: SC.primary, size: 20)
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
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: sty(13, FontWeight.w800, err ? SC.errorText : SC.ink),
                children: [
                  if (req) const TextSpan(text: ' *', style: TextStyle(color: _kRed)),
                ],
              ),
            ),
          ),
          if (tag != null)
            Text(tag,
                style: sty(11.5, err ? FontWeight.w700 : FontWeight.w500,
                    err ? SC.errorText : SC.inkSecondary)),
        ],
      ),
    );
  }

  Widget _errorNote(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, size: 16, color: SC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: sty(12, FontWeight.w600, SC.errorText, h: 1.4))),
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
      color: SC.surfaceDim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: err ? const BorderSide(color: _kRed, width: 1.4) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 19, color: SC.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(14, FontWeight.w600, placeholder ? SC.inkSecondary : SC.ink)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fillDec(String hint, {bool err = false, Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: sty(13.5, FontWeight.w500, err ? SC.errorText.withOpacity(0.65) : SC.inkMuted, h: 1.4),
      filled: true,
      fillColor: err ? SC.errorBg.withOpacity(0.5) : SC.surfaceDim,
      contentPadding: const EdgeInsets.all(14),
      suffixIcon: suffix,
      border: b(Colors.transparent),
      enabledBorder: b(err ? _kRed : Colors.transparent, err ? 1.4 : 1),
      focusedBorder: b(SC.primary, 1.4),
    );
  }

  Widget _santriCard() {
    final s = _santri;
    final err = _tried && s == null;
    final nama = (s?['nama'] ?? '').toString();
    final kelas = (s?['kelas'] as Map?)?['namaKelas']?.toString();

    final Widget avatar = s == null
        ? Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: _kUmumBg, shape: BoxShape.circle),
            child: const Icon(Icons.person_search_outlined, size: 24, color: SC.inkSecondary),
          )
        : SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _kUmumBg, shape: BoxShape.circle),
                  child: Text(_initials(nama), style: sty(15, FontWeight.w800, SC.ink)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: SC.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: SC.surfaceDim, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: SC.surfaceDim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: err ? const BorderSide(color: _kRed, width: 1.4) : BorderSide.none,
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
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pilih santri', style: sty(14.5, FontWeight.w800, SC.ink)),
                              const SizedBox(height: 2),
                              Text('Ketuk untuk memilih dari daftar',
                                  style: sty(12, FontWeight.w500, SC.inkSecondary)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: sty(14.5, FontWeight.w800, SC.ink)),
                              const SizedBox(height: 2),
                              Text('NIS ${s['nis'] ?? '-'}${kelas != null ? ' • Kelas $kelas' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: sty(12, FontWeight.w500, SC.inkSecondary)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: SC.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: SC.border),
                    ),
                    child: Text(s == null ? 'Pilih' : 'Ubah',
                        style: sty(12, FontWeight.w800, SC.primary)),
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
        color: SC.surface,
        border: const Border(top: BorderSide(color: SC.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SC.border),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('Batal', style: sty(14, FontWeight.w700, SC.inkSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: SC.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 19, color: Colors.white),
                  label: Text('Simpan Catatan', style: sty(14, FontWeight.w700, Colors.white)),
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
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
              child: Column(
                children: [
                  _grabHandle(bottom: 14),
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
                        child: Icon(Icons.forum_outlined, size: 21, color: SC.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Catatan Konseling Baru', style: sty(19, FontWeight.w800, SC.ink)),
                            const SizedBox(height: 2),
                            Text('Catat sesi pembinaan santri',
                                style: sty(12, FontWeight.w500, SC.inkSecondary)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: SC.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: SC.border),
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: SC.ink),
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
                    _label('Pilih Santri', req: true),
                    const SizedBox(height: 8),
                    _santriCard(),
                    const SizedBox(height: 18),

                    _label('Tanggal Sesi Konseling', req: true),
                    const SizedBox(height: 8),
                    _readField(
                      icon: Icons.calendar_today_outlined,
                      text: _fmtTanggalPenuh(_tgl),
                      onTap: _pilihTanggal,
                      trailing: _isToday
                          ? _pill('Hari ini', SC.goldSurface, SC.goldDark)
                          : null,
                    ),
                    const SizedBox(height: 18),

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
                            Text(tag, style: sty(12, FontWeight.w600, SC.inkSecondary)),
                          if (_konselor.isNotEmpty)
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: SC.ink),
                        ],
                      ),
                    ),
                    if (_konselorError) _errorNote('Pilih konselor terlebih dahulu.'),
                    const SizedBox(height: 18),

                    _label('Topik Konseling', req: true, err: topikErr),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topik,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      style: sty(14, FontWeight.w600, SC.ink),
                      decoration: _fillDec(
                        'Ketik topik permasalahan santri...',
                        err: topikErr,
                        suffix: topikErr
                            ? const Icon(Icons.error_outline_rounded, size: 21, color: SC.errorText)
                            : null,
                      ),
                    ),
                    if (topikErr)
                      _errorNote('Topik wajib diisi (contoh: Motivasi belajar menurun, adaptasi asrama).'),
                    const SizedBox(height: 18),

                    _label('Catatan Konseling', req: true, err: catatanErr),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatan,
                      onChanged: (_) => setState(() {}),
                      minLines: 5,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: sty(14, FontWeight.w500, SC.ink, h: 1.4),
                      decoration: _fillDec(
                        'Tuliskan hasil dialog, kondisi emosional, dan kendala santri secara objektif...',
                        err: catatanErr,
                      ),
                    ),
                    if (catatanErr) _errorNote('Catatan konseling wajib diisi.'),
                    const SizedBox(height: 18),

                    _label('Rencana Tindak Lanjut', tag: 'Opsional'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tindak,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: sty(14, FontWeight.w500, SC.ink, h: 1.4),
                      decoration: _fillDec(
                          'Langkah pembinaan lanjutan (misal: koordinasi musyrif kamar, jadwal konseling kedua pekan depan)...'),
                    ),
                    const SizedBox(height: 18),

                    // Jadikan rahasia
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SC.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SC.border),
                        boxShadow: softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
                            child: Icon(Icons.lock_outline_rounded, size: 22, color: SC.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jadikan Rahasia', style: sty(14.5, FontWeight.w800, SC.ink)),
                                const SizedBox(height: 2),
                                Text("Hanya dapat diakses pengelola & pimpinan ma'had",
                                    style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.4)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _privat,
                            onChanged: (v) => setState(() => _privat = v),
                            activeColor: Colors.white,
                            activeTrackColor: SC.primary,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: SC.border,
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