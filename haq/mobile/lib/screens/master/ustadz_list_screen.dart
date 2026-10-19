import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

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
// Komponen kecil untuk dialog
// ---------------------------------------------------------------------------

InputDecoration _dec(String hint, {Widget? suffix}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    filled: true,
    fillColor: SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary)),
    );

Widget _errText(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(text, style: sty(11.5, FontWeight.w600, SC.errorText)),
    );

Widget _btnBatal(VoidCallback onTap) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: SC.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
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

Widget _dialogIcon(IconData icon, Color bg, Color fg) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 18, color: fg),
    );

RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));

const _dialogTitlePad = EdgeInsets.fromLTRB(20, 20, 20, 0);
const _dialogContentPad = EdgeInsets.fromLTRB(20, 16, 20, 4);
const _dialogActionsPad = EdgeInsets.fromLTRB(16, 8, 16, 16);

// ---------------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------------

class UstadzListScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (ada AppBar + tombol kembali).
  final bool showBack;
  const UstadzListScreen({super.key, this.showBack = false});

  @override
  State<UstadzListScreen> createState() => _UstadzListScreenState();
}

class _UstadzListScreenState extends State<UstadzListScreen> {
   /// Pimpinan/Mudir hanya memantau: tombol tambah/ubah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;
  
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _busy = false; // true selama simpan/hapus/buat akun berjalan
  String? _error;

  String _filter = 'SEMUA'; // SEMUA | GURU | MUSYRIF
  bool _hanyaTanpaAkun = false;
  String _q = '';
  final _searchC = TextEditingController();

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

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
      final res = await AppScope.of(context).api.get(ApiUrl.ustadz);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
        _error = null;
        // Semua akun sudah dibuat -> lepas filter "tanpa akun" supaya daftar tidak kosong.
        if (_hanyaTanpaAkun && _tanpaAkunCount == 0) _hanyaTanpaAkun = false;
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
          _error = 'Gagal memuat daftar ustadz.';
          _loading = false;
        });
      } else {
        _toast('Gagal memuat ulang daftar ustadz.', error: true);
      }
    }
  }

  /// Aksi tulis ke server dengan satu pola: kunci tombol, tangkap error,
  /// tampilkan banner, lalu muat ulang daftar tanpa spinner penuh.
  Future<void> _jalankan(Future<void> Function() aksi, String sukses, {String? sub}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await aksi();
      _toast(sukses, subtitle: sub);
      await _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic>? _akun(Map<String, dynamic> u) =>
      u['akun'] is Map ? Map<String, dynamic>.from(u['akun'] as Map) : null;

  List<String> _kelasWali(Map<String, dynamic> u) {
    final k = u['kelasDiampu'];
    if (k is! List) return const [];
    return k
        .whereType<Map>()
        .map((e) => '${e['namaKelas'] ?? ''}'.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _isMusyrif(Map<String, dynamic> u) => (u['jenis'] ?? '').toString() == 'MUSYRIF';

  int get _musyrifCount => _items.where(_isMusyrif).length;
  int get _guruCount => _items.length - _musyrifCount;
  int get _tanpaAkunCount => _items.where((u) => _akun(u) == null).length;
  int get _waliKelasCount => _items.where((u) => _kelasWali(u).isNotEmpty).length;

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    final out = _items.where((u) {
      if (_filter == 'GURU' && _isMusyrif(u)) return false;
      if (_filter == 'MUSYRIF' && !_isMusyrif(u)) return false;
      if (_hanyaTanpaAkun && _akun(u) != null) return false;
      if (q.isEmpty) return true;
      final email = '${_akun(u)?['email'] ?? ''}'.toLowerCase();
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['noHp'] ?? '').toString().toLowerCase().contains(q) ||
          email.contains(q);
    }).toList();
    out.sort((a, b) => (a['nama'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['nama'] ?? '').toString().toLowerCase()));
    return out;
  }

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _tambah() async {
    if (_busy) return;
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _UstadzFormDialog(),
    );
    if (res == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.post(ApiUrl.ustadz, res);
    }, 'Ustadz ditambahkan', sub: res['nama']);
  }

  Future<void> _edit(Map<String, dynamic> u) async {
    if (_busy) return;
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _UstadzFormDialog(existing: u),
    );
    if (res == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.patch('${ApiUrl.ustadz}/${u['id']}', res);
    }, 'Data ustadz diperbarui', sub: res['nama']);
  }

  Future<void> _hapus(Map<String, dynamic> u) async {
    if (_busy) return;
    final kelas = _kelasWali(u);
    final catatan = <String>[
      '"${u['nama']}" akan dihapus.',
      if (kelas.isNotEmpty)
        'Kelas yang dia pegang sebagai wali (${kelas.join(', ')}) akan menjadi tanpa wali kelas.',
      if (_akun(u) != null) 'Akun login-nya tidak ikut terhapus (kelola di menu pengguna).',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
        ),
        title: Text('Hapus ustadz?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          catatan.join('\n\n'),
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(ctx, false)),
          _btnUtama('Ya, hapus', () => Navigator.pop(ctx, true), warna: SC.errorText),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.delete('${ApiUrl.ustadz}/${u['id']}');
    }, '${u['nama']} dihapus');
  }

  Future<void> _buatAkun(Map<String, dynamic> u) async {
    if (_busy) return;
    final jenis = (u['jenis'] ?? 'GURU').toString();
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AkunDialog(nama: '${u['nama'] ?? ''}', jenis: jenis),
    );
    if (res == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.post(ApiUrl.users, {
        'nama': u['nama'],
        'email': res['email'],
        'password': res['password'],
        'role': jenis == 'MUSYRIF' ? 'MUSYRIF' : 'USTADZ',
        'ustadzId': u['id'],
      });
    }, 'Akun dibuat', sub: '${u['nama']} sekarang bisa login');
  }

  // ---------------------------------------------------------------------
  // Banner inline
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
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
                          Text(_bannerSub!,
                              style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75))),
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
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showControls = !_loading && _error == null && _items.isNotEmpty;

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              RefreshIndicator(
                color: SC.primary,
                onRefresh: () => _load(spinner: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedBar(
                        height: showControls ? 118 : 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _searchBar(),
                            if (showControls) _segmented(),
                          ],
                        ),
                      ),
                    ),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (_busy)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: SC.gold,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (!_readOnly)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _busy ? null : _tambah,
                  tooltip: 'Tambah ustadz',
                  backgroundColor: SC.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: SC.gold.withOpacity(0.6)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: SC.gold),
                  label: Text('Ustadz baru', style: sty(13, FontWeight.w700, Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final loaded = !_loading && _error == null;
    String ringkasan;
    if (_error != null) {
      ringkasan = 'Data tidak dapat dimuat';
    } else if (!loaded) {
      ringkasan = 'Memuat data...';
    } else if (_items.isEmpty) {
      ringkasan = 'Belum ada ustadz terdaftar';
    } else {
      ringkasan = '$_guruCount guru  •  $_musyrifCount musyrif';
    }
    String v(int n) => loaded ? '$n' : '–';

    Widget stat(String value, String label, {bool warn = false}) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: sty(21, FontWeight.w800, warn ? SC.gold : Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72))),
            ],
          ),
        );

    Widget garis() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.18));

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBack) ...[
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
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.assignment_ind_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ustadz & Pembina',
                        style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      ringkasan,
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
          // Satu strip kaca dengan pemisah (beda dari tiga kotak terpisah di daftar santri).
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                stat(v(_items.length), 'Total'),
                garis(),
                stat(v(_waliKelasCount), 'Wali kelas'),
                garis(),
                stat(v(_tanpaAkunCount), 'Belum ada akun',
                    warn: loaded && _tanpaAkunCount > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _searchC,
          onChanged: (v) => setState(() => _q = v),
          textInputAction: TextInputAction.search,
          style: sty(14, FontWeight.w600, SC.ink),
          decoration: InputDecoration(
            hintText: 'Cari nama, no. HP, atau email',
            hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 21, color: SC.primary),
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
                    onPressed: () {
                      _searchC.clear();
                      setState(() => _q = '');
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

  /// Kontrol segmen Semua / Guru / Musyrif (beda dari deretan chip kelas di daftar santri).
  Widget _segmented() {
    Widget seg(String value, String label, int n) {
      final active = _filter == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _filter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? SC.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$label ($n)',
              style: sty(12, FontWeight.w700, active ? Colors.white : SC.inkSecondary),
            ),
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
            seg('SEMUA', 'Semua', _items.length),
            seg('GURU', 'Guru', _guruCount),
            seg('MUSYRIF', 'Musyrif', _musyrifCount),
          ],
        ),
      ),
    );
  }

  /// Pengingat akun: muncul hanya kalau ada ustadz yang belum punya akun login.
  Widget _noticeAkun() {
        final n = _tanpaAkunCount;
    if (n == 0 || _readOnly) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Material(
        color: SC.goldSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: SC.gold.withOpacity(0.4)),
        ),
        child: InkWell(
          onTap: () => setState(() => _hanyaTanpaAkun = !_hanyaTanpaAkun),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, size: 18, color: SC.goldDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _hanyaTanpaAkun
                        ? 'Menampilkan $n ustadz tanpa akun login'
                        : '$n ustadz belum punya akun login',
                    style: sty(12, FontWeight.w700, SC.goldDark),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_hanyaTanpaAkun ? 'Semua' : 'Lihat',
                    style: sty(12, FontWeight.w800, SC.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bodySlivers() {
    if (_loading) {
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: loadingView()))];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.assignment_ind_outlined,
            judul: 'Belum ada ustadz',
                        pesan: _readOnly
                ? 'Belum ada ustadz atau musyrif terdaftar.'
                : 'Tambahkan ustadz atau musyrif lewat tombol "Ustadz baru" di bawah.',
          ),
        ),
      ];
    }

    final list = _filtered;
    return [
      SliverToBoxAdapter(child: _noticeAkun()),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada hasil',
            pesan: 'Tidak ada ustadz yang cocok dengan pencarian atau filter ini.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _ustadzTile(list[i]),
              ),
              childCount: list.length,
            ),
          ),
        ),
    ];
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 96),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: SC.sage,
              shape: BoxShape.circle,
              border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, size: 36, color: SC.primary),
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

  Widget _infoRow(IconData icon, String text, {Color? color, FontWeight? weight}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? SC.inkMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(11.5, weight ?? FontWeight.w600, color ?? SC.inkSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _ustadzTile(Map<String, dynamic> u) {
    final nama = (u['nama'] ?? '-').toString().trim();
    final musyrif = _isMusyrif(u);
    final hp = (u['noHp'] ?? '').toString().trim();
    final akun = _akun(u);
    final aktif = akun != null && (akun['status'] ?? '').toString() == 'AKTIF';
    final kelasWali = _kelasWali(u);
    final inisial = nama.isEmpty ? '?' : nama.substring(0, 1).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: akun == null ? SC.gold.withOpacity(0.5) : SC.border),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
            onTap: (_busy || _readOnly) ? null : () => _edit(u),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: musyrif ? SC.goldSurface : SC.sage,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: musyrif ? SC.gold.withOpacity(0.55) : SC.primary.withOpacity(0.18),
                    ),
                  ),
                  child: Text(inisial,
                      style: sty(17, FontWeight.w800, musyrif ? SC.goldDark : SC.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sty(14.5, FontWeight.w800, SC.ink),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: musyrif ? SC.goldSurface : SC.mint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(musyrif ? 'Musyrif' : 'Guru',
                            style: sty(10.5, FontWeight.w800, musyrif ? SC.goldDark : SC.primary)),
                      ),
                      if (hp.isNotEmpty) _infoRow(Icons.phone_outlined, hp),
                      if (kelasWali.isNotEmpty)
                        _infoRow(Icons.class_outlined, 'Wali kelas ${kelasWali.join(', ')}',
                            color: SC.ink, weight: FontWeight.w700),
                      if (akun != null)
                        _infoRow(
                          Icons.verified_user_outlined,
                          '${akun['email']} • ${aktif ? 'Aktif' : 'Nonaktif'}',
                          color: aktif ? null : SC.errorText,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Belum punya akun login',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: sty(11.5, FontWeight.w700, SC.goldDark)),
                              ),
                              const SizedBox(width: 8),
                              if (!_readOnly)
                              OutlinedButton(
                                onPressed: _busy ? null : () => _buatAkun(u),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SC.primary,
                                  side: BorderSide(color: SC.primary.withOpacity(0.4)),
                                  minimumSize: Size.zero,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999)),
                                ),
                                child: Text('Buat akun',
                                    style: sty(11.5, FontWeight.w800, SC.primary)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                 if (!_readOnly)
                PopupMenuButton<String>(
                  tooltip: 'Opsi',
                  enabled: !_busy,
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: SC.inkSecondary),
                  color: SC.surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (v) {
                    if (v == 'edit') _edit(u);
                    if (v == 'akun') _buatAkun(u);
                    if (v == 'hapus') _hapus(u);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined, size: 18, color: SC.ink),
                        const SizedBox(width: 10),
                        Text('Edit data', style: sty(13, FontWeight.w600, SC.ink)),
                      ]),
                    ),
                    if (akun == null)
                      PopupMenuItem(
                        value: 'akun',
                        child: Row(children: [
                          const Icon(Icons.lock_person_outlined, size: 18, color: SC.ink),
                          const SizedBox(width: 10),
                          Text('Buat akun login', style: sty(13, FontWeight.w600, SC.ink)),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'hapus',
                      child: Row(children: [
                        const Icon(Icons.delete_outline, size: 18, color: SC.errorText),
                        const SizedBox(width: 10),
                        Text('Hapus', style: sty(13, FontWeight.w600, SC.errorText)),
                      ]),
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
}

// ---------------------------------------------------------------------------
// Dialog tambah/edit ustadz
// ---------------------------------------------------------------------------

class _UstadzFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _UstadzFormDialog({this.existing});

  @override
  State<_UstadzFormDialog> createState() => _UstadzFormDialogState();
}

class _UstadzFormDialogState extends State<_UstadzFormDialog> {
  late final TextEditingController _nama;
  late final TextEditingController _hp;
  late String _jenis;
  String? _err;

  /// Jenis dikunci kalau sudah punya akun, karena role akun (USTADZ/MUSYRIF)
  /// harus sejalan dengan jenisnya.
  bool get _terkunci => widget.existing?['userId'] != null;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?['nama']?.toString() ?? '');
    _hp = TextEditingController(text: widget.existing?['noHp']?.toString() ?? '');
    _jenis = widget.existing?['jenis']?.toString() == 'MUSYRIF' ? 'MUSYRIF' : 'GURU';
  }

  @override
  void dispose() {
    _nama.dispose();
    _hp.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      setState(() => _err = 'Nama wajib diisi.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {
      'nama': _nama.text.trim(),
      'jenis': _jenis,
      'noHp': _hp.text.trim(),
    });
  }

  Widget _jenisChip(String value, String label) {
    final selected = _jenis == value;
    return Expanded(
      child: GestureDetector(
        onTap: _terkunci ? null : () => setState(() => _jenis = value),
        child: Opacity(
          opacity: _terkunci && !selected ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? SC.primary : SC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? SC.primary : SC.border),
            ),
            child: Text(label,
                style: sty(12.5, FontWeight.w700, selected ? Colors.white : SC.inkSecondary)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      titlePadding: _dialogTitlePad,
      contentPadding: _dialogContentPad,
      actionsPadding: _dialogActionsPad,
      title: Row(
        children: [
          _dialogIcon(Icons.assignment_ind_rounded, SC.sage, SC.primary),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit ustadz' : 'Tambah ustadz',
              style: sty(16, FontWeight.w800, SC.ink)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nama'),
              TextField(
                controller: _nama,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Nama lengkap'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) _errText(_err!),
              const SizedBox(height: 12),
              _label('Jenis'),
              Row(
                children: [
                  _jenisChip('GURU', 'Guru'),
                  const SizedBox(width: 8),
                  _jenisChip('MUSYRIF', 'Musyrif'),
                ],
              ),
              if (_terkunci)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text('Jenis dikunci karena sudah punya akun login.',
                      style: sty(11, FontWeight.w500, SC.inkSecondary)),
                ),
              const SizedBox(height: 12),
              _label('No. HP (opsional)'),
              TextField(
                controller: _hp,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Contoh: 0812xxxxxxx'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        _btnBatal(() => Navigator.pop(context)),
        _btnUtama('Simpan', _submit),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog buat akun login untuk ustadz yang sudah ada datanya
// ---------------------------------------------------------------------------

class _AkunDialog extends StatefulWidget {
  final String nama;
  final String jenis;
  const _AkunDialog({required this.nama, required this.jenis});

  @override
  State<_AkunDialog> createState() => _AkunDialogState();
}

class _AkunDialogState extends State<_AkunDialog> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _show = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Format email tidak valid.');
      return;
    }
    if (_pass.text.length < 6) {
      setState(() => _err = 'Password minimal 6 karakter.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {'email': email, 'password': _pass.text});
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.jenis == 'MUSYRIF' ? 'Musyrif / Pembina' : 'Ustadz / Guru';
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      titlePadding: _dialogTitlePad,
      contentPadding: _dialogContentPad,
      actionsPadding: _dialogActionsPad,
      title: Row(
        children: [
          _dialogIcon(Icons.lock_person, SC.goldSurface, SC.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Buat akun login', style: sty(16, FontWeight.w800, SC.ink)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.nama} • $roleLabel',
                  style: sty(12.5, FontWeight.w600, SC.inkSecondary)),
              const SizedBox(height: 14),
              _label('Email'),
              TextField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('nama@pondok.id'),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              const SizedBox(height: 12),
              _label('Password'),
              TextField(
                controller: _pass,
                obscureText: !_show,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec(
                  'Minimal 6 karakter',
                  suffix: IconButton(
                    tooltip: _show ? 'Sembunyikan password' : 'Tampilkan password',
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: SC.inkSecondary,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_err != null) setState(() => _err = null);
                },
              ),
              if (_err != null) _errText(_err!),
            ],
          ),
        ),
      ),
      actions: [
        _btnBatal(() => Navigator.pop(context)),
        _btnUtama('Buat akun', _submit),
      ],
    );
  }
}