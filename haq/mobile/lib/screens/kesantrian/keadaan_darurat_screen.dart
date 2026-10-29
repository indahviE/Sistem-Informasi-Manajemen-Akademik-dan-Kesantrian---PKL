import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

// Layar Keadaan Darurat.
//
// Endpoint:
//   GET   /keadaan-darurat          -> array laporan (+ santri{kelas})
//   POST  /keadaan-darurat          -> {santriId?, jenis, lokasi?, deskripsi}
//   PATCH /keadaan-darurat/:id      -> {status, tindakLanjut?}
//   GET   /santri?search=&perPage=  -> pencarian santri di form lapor
//
// Hak akses:
//   - Lapor     : semua role kecuali Wali dan Pimpinan/Mudir
//   - Tindaklanjut : Admin dan Musyrif
//   - Pimpinan/Mudir: mode baca saja

const double _maxW = 480;

// Warna status (tidak ada di SC)
const _kBaruBg = Color(0xFFFEE2E2);
const _kBaruFg = Color(0xFF991B1B);
const _kProsesBg = Color(0xFFFDE9B8);
const _kProsesFg = Color(0xFF7A5B10);
const _kSelesaiBg = Color(0xFFD8F0E2);
const _kSelesaiFg = Color(0xFF1B5E20);
const _kDanger = Color(0xFFB91C1C);

const _kBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
class _St {
  final String key;
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
  const _St(this.key, this.label, this.fg, this.bg, this.icon);
}

_St _st(String s) {
  switch (s) {
    case 'DITANGANI':
      return const _St('DITANGANI', 'Ditangani', _kProsesFg, _kProsesBg, Icons.pending_actions_rounded);
    case 'SELESAI':
      return const _St('SELESAI', 'Selesai', _kSelesaiFg, _kSelesaiBg, Icons.check_circle_outline_rounded);
    default:
      return const _St('BARU', 'Baru', _kBaruFg, _kBaruBg, Icons.emergency_rounded);
  }
}

String _statusOf(Map<String, dynamic> d) => (d['status'] as String?) ?? 'BARU';

IconData _jenisIcon(String jenis) {
  final j = jenis.toLowerCase();
  if (j.contains('sakit') || j.contains('demam') || j.contains('alergi')) {
    return Icons.medical_services_outlined;
  }
  if (j.contains('kecelakaan') || j.contains('cedera') || j.contains('luka')) {
    return Icons.personal_injury_outlined;
  }
  if (j.contains('hilang') || j.contains('izin')) return Icons.person_search_outlined;
  if (j.contains('keamanan') || j.contains('pencuri') || j.contains('kebakaran')) {
    return Icons.shield_outlined;
  }
  return Icons.emergency_rounded;
}

String _tgl(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_kBulan[d.month - 1]} ${d.year}';

String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

String _waktuLabel(DateTime? d) {
  if (d == null) return '-';
  final now = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Hari ini, ${_jam(d)}';
  if (diff == 1) return 'Kemarin, ${_jam(d)}';
  return _tgl(d);
}

List<Map<String, dynamic>> _asList(dynamic res) {
  final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
  return (raw is List ? raw : const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Widget _pill(String text, {required Color bg, required Color fg, IconData? icon}) {
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
        Text(text, style: sty(10.5, FontWeight.w800, fg)),
      ],
    ),
  );
}

InputDecoration _dec(String hint, {IconData? icon, Color? iconColor}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted, h: 1.4),
    prefixIcon: icon == null ? null : Icon(icon, size: 19, color: iconColor ?? SC.inkSecondary),
    filled: true,
    fillColor: SC.surface,
    counterText: '',
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: b(SC.border),
    enabledBorder: b(SC.border),
    focusedBorder: b(SC.primary, 1.4),
  );
}

// ---------------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------------
class KeadaanDaruratScreen extends StatefulWidget {
  const KeadaanDaruratScreen({super.key});

  @override
  State<KeadaanDaruratScreen> createState() => _KeadaanDaruratScreenState();
}

class _KeadaanDaruratScreenState extends State<KeadaanDaruratScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = ''; // '' = semua | BARU | DITANGANI | SELESAI
  final Set<String> _open = {};
  bool _firstLoad = true;
  final _scroll = ScrollController();

  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  dynamic get _user => AppScope.of(context).user;

  /// Wali tidak boleh melapor. Pimpinan/Mudir hanya memantau.
  bool get _bisaLapor => _user?.isWali != true && _user?.isPimpinan != true;

  /// Yang menindaklanjuti laporan: Admin dan Musyrif.
  bool get _bisaTangani => _user?.isAdmin == true || _user?.isMusyrif == true;

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
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load() async {
    if (_items.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.keadaanDarurat);
      if (!mounted) return;
      final list = _asList(res);
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
        if (_firstLoad) {
          // Laporan baru langsung terbuka supaya cepat terbaca.
          for (final d in list) {
            if (_statusOf(d) == 'BARU') _open.add('${d['id']}');
          }
          _firstLoad = false;
        }
      });
    } on ApiException catch (e) {
      _gagalMuat(e.message);
    } catch (_) {
      _gagalMuat('Gagal memuat laporan darurat.');
    }
  }

  void _gagalMuat(String msg) {
    if (!mounted) return;
    if (_items.isEmpty) {
      setState(() {
        _error = msg;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _toast(msg, error: true);
    }
  }

  int _count(String status) => _items.where((e) => _statusOf(e) == status).length;

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
  Future<void> _lapor() async {
    if (!_bisaLapor) return;
    final api = AppScope.of(context).api;
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: _maxW),
      builder: (_) => _LaporSheet(api: api),
    );
    if (payload == null || !mounted) return;
    try {
      await api.post(ApiUrl.keadaanDarurat, payload);
      if (!mounted) return;
      _toast('Laporan darurat dikirim', subtitle: 'Admin & Musyrif akan segera mendapat notifikasi');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal mengirim laporan.', error: true);
    }
  }

  Future<void> _tangani(Map<String, dynamic> item) async {
    if (!_bisaTangani) return;
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: _maxW),
      builder: (_) => _TindakSheet(item: item),
    );
    if (res == null || !mounted) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.keadaanDarurat}/${item['id']}', res);
      if (!mounted) return;
      _toast('Status laporan diperbarui', subtitle: '${item['jenis']} • ${_st(res['status'] as String).label}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal memperbarui laporan.', error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------
  Widget _hero() {
    final loaded = !_loading && _error == null;
    final baru = _count('BARU');

    final String ringkas;
    final bool siaga;
    if (!loaded) {
      ringkas = 'Memuat laporan…';
      siaga = false;
    } else if (baru > 0) {
      ringkas = '$baru laporan menunggu penanganan';
      siaga = true;
    } else {
      ringkas = 'Tidak ada laporan baru, situasi terkendali';
      siaga = false;
    }

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: SC.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text("SIAGA MA'HAD",
                    style: sty(11, FontWeight.w800, SC.gold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white.withOpacity(0.85)),
                    const SizedBox(width: 6),
                    Text(_tgl(DateTime.now()), style: sty(11.5, FontWeight.w700, Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: const Icon(Icons.emergency_outlined, size: 25, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keadaan Darurat', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text('Pantau dan tangani laporan santri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Icon(siaga ? Icons.notification_important_outlined : Icons.verified_user_outlined,
                    size: 18, color: siaga ? SC.gold : Colors.white.withOpacity(0.8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ringkas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w700, siaga ? SC.gold : Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu status (sekaligus filter)
  // ---------------------------------------------------------------------
  Widget _statusTiles() {
    Widget tile(String key) {
      final st = _st(key);
      final n = _count(key);
      final on = _filter == key;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _filter = on ? '' : key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              color: on ? st.bg : SC.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: on ? st.fg.withOpacity(0.4) : SC.border, width: on ? 1.4 : 1),
              boxShadow: softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: on ? Colors.white.withOpacity(0.7) : st.bg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(st.icon, size: 16, color: st.fg),
                ),
                const SizedBox(height: 10),
                Text('$n', style: sty(24, FontWeight.w800, st.fg, h: 1)),
                const SizedBox(height: 3),
                Text(st.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(11.5, FontWeight.w700, on ? st.fg : SC.inkSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          tile('BARU'),
          const SizedBox(width: 10),
          tile('DITANGANI'),
          const SizedBox(width: 10),
          tile('SELESAI'),
        ],
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
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, _load)))];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.verified_user_outlined,
            judul: 'Belum ada laporan darurat',
            pesan: _bisaLapor
                ? 'Tekan "Lapor Darurat" bila ada situasi yang perlu penanganan segera.'
                : 'Laporan dari ustadz dan musyrif akan muncul di sini.',
          ),
        ),
      ];
    }

    final tampil = _filter.isEmpty ? _items : _items.where((e) => _statusOf(e) == _filter).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 10),
          child: Row(
            children: [
              Text('Daftar Laporan', style: sty(15, FontWeight.w800, SC.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: SC.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('${tampil.length}', style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
              const Spacer(),
              if (_filter.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _filter = ''),
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
                        Text(_st(_filter).label, style: sty(11, FontWeight.w800, SC.goldDark)),
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
            icon: Icons.search_off_rounded,
            judul: 'Tidak ada laporan',
            pesan: 'Belum ada laporan dengan status ini.',
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, _bisaLapor ? 110 : 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([for (final d in tampil) _card(d)]),
          ),
        ),
    ];
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 120),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: SC.sage,
              shape: BoxShape.circle,
              border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, size: 38, color: SC.primary),
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
  // Kartu laporan
  // ---------------------------------------------------------------------
  Widget _card(Map<String, dynamic> d) {
    final id = '${d['id']}';
    final status = _statusOf(d);
    final st = _st(status);
    final jenis = (d['jenis'] as String?) ?? 'Darurat';
    final santri = (d['santri'] as Map?)?.cast<String, dynamic>();
    final kelas = (santri?['kelas'] as Map?)?['namaKelas'];
    final lokasi = ((d['lokasi'] as String?) ?? '').trim();
    final deskripsi = (d['deskripsi'] as String?) ?? '';
    final tindak = ((d['tindakLanjut'] as String?) ?? '').trim();
    final dt = DateTime.tryParse('${d['tanggal']}')?.toLocal();
    final open = _open.contains(id);
    final baru = status == 'BARU';

    final nama = santri == null ? 'Umum' : '${santri['nama']}';
    final sub = kelas != null ? '$nama • $kelas' : nama;

    void toggle() => setState(() => open ? _open.remove(id) : _open.add(id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baru ? _kBaruFg.withOpacity(0.28) : SC.border),
          boxShadow: softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: toggle,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(14)),
                      child: Icon(_jenisIcon(jenis), size: 23, color: st.fg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jenis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: sty(16, FontWeight.w800, SC.ink, h: 1.25)),
                          const SizedBox(height: 3),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sty(12.5, FontWeight.w600, SC.inkSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _pill(st.label.toUpperCase(), bg: st.bg, fg: st.fg),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _meta(Icons.schedule_rounded, _waktuLabel(dt)),
                  if (lokasi.isNotEmpty) _meta(Icons.location_on_outlined, lokasi, iconColor: SC.goldDark),
                ],
              ),
              const SizedBox(height: 10),
              if (open)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: SC.surfaceDim, borderRadius: BorderRadius.circular(14)),
                  child: Text(deskripsi, style: sty(13.5, FontWeight.w500, SC.ink, h: 1.5)),
                )
              else
                Text(deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.4)),
              if (open && tindak.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SC.sage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 14, color: SC.primary),
                          const SizedBox(width: 6),
                          Text('TINDAK LANJUT', style: sty(10, FontWeight.w800, SC.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(tindak, style: sty(13, FontWeight.w500, SC.ink, h: 1.45)),
                    ],
                  ),
                ),
              ],
              if (open && _bisaTangani) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _tangani(d),
                    icon: Icon(Icons.edit_note_rounded, size: 20, color: SC.goldDark),
                    label: Text('Update Tindak Lanjut', style: sty(13.5, FontWeight.w800, SC.goldDark)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kProsesBg,
                      minimumSize: const Size.fromHeight(46),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ] else if (open && status != 'SELESAI') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: SC.inkMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Tindak lanjut dilakukan oleh Admin & Musyrif.',
                          style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: toggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(open ? 'Sembunyikan' : 'Lihat Penanganan',
                            style: sty(12, FontWeight.w800, SC.primary)),
                        Icon(open ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                            size: 18, color: SC.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? SC.inkMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sty(12, FontWeight.w600, SC.inkSecondary)),
        ),
      ],
    );
  }

  Widget _tombolLapor() {
    return Material(
      color: _kDanger,
      elevation: 6,
      shadowColor: Colors.black45,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _lapor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.add_alert_rounded, size: 15, color: _kDanger),
              ),
              const SizedBox(width: 10),
              Text('Lapor Darurat', style: sty(14, FontWeight.w800, Colors.white)),
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
                onRefresh: _load,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    if (loaded && _items.isNotEmpty) SliverToBoxAdapter(child: _statusTiles()),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (_bisaLapor && loaded) Positioned(right: 16, bottom: 20, child: _tombolLapor()),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kerangka bottom sheet (form Lapor & Tindak Lanjut)
// ---------------------------------------------------------------------------
class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget body;
  final Widget footer;

  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: (mq.size.height - mq.viewInsets.bottom) * 0.94),
        child: Container(
          decoration: BoxDecoration(
            color: SC.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SC.border, borderRadius: BorderRadius.circular(999)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: SC.gold.withOpacity(0.45)),
                      ),
                      child: Icon(icon, size: 21, color: iconFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: sty(19, FontWeight.w800, SC.ink)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.3)),
                        ],
                      ),
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
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: body,
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + mq.padding.bottom),
                decoration: BoxDecoration(
                  color: SC.surface,
                  border: Border(top: BorderSide(color: SC.border)),
                ),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _footerButtons({
  required BuildContext context,
  required String submitLabel,
  required IconData submitIcon,
  required VoidCallback onSubmit,
  Color? warna,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
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
          onPressed: onSubmit,
          icon: Icon(submitIcon, size: 19, color: Colors.white),
          label: Text(submitLabel, style: sty(14, FontWeight.w800, Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: warna ?? SC.primary,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ),
    ],
  );
}

Widget _label(String text, {bool req = false, String? tag, String? kanan}) {
  return Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Row(
      children: [
        Text.rich(
          TextSpan(
            text: text,
            style: sty(13, FontWeight.w800, SC.ink),
            children: [if (req) const TextSpan(text: ' *', style: TextStyle(color: _kDanger))],
          ),
        ),
        const Spacer(),
        if (tag != null) Text(tag, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
        if (kanan != null) Text(kanan, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
      ],
    ),
  );
}

Widget _errorNote(String msg) => Padding(
      padding: const EdgeInsets.only(top: 8, left: 2),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 15, color: SC.errorText),
          const SizedBox(width: 6),
          Expanded(child: Text(msg, style: sty(12, FontWeight.w700, SC.errorText))),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// Sheet: Lapor Keadaan Darurat
// ---------------------------------------------------------------------------
class _LaporSheet extends StatefulWidget {
  final ApiClient api;
  const _LaporSheet({required this.api});

  @override
  State<_LaporSheet> createState() => _LaporSheetState();
}

class _LaporSheetState extends State<_LaporSheet> {
  static const _opsi = <(String, IconData)>[
    ('Sakit Mendadak', Icons.medical_services_outlined),
    ('Kecelakaan/Cedera', Icons.personal_injury_outlined),
    ('Kehilangan Santri', Icons.person_search_outlined),
    ('Keamanan Pondok', Icons.shield_outlined),
    ('Lainnya', Icons.more_horiz_rounded),
  ];
  static const _maxDeskripsi = 500;

  final _cari = TextEditingController();
  final _jenisLain = TextEditingController();
  final _lokasi = TextEditingController();
  final _deskripsi = TextEditingController();
  Timer? _debounce;

  Map<String, dynamic>? _santri;
  List<Map<String, dynamic>> _hasil = [];
  bool _mencari = false;
  String? _jenis;
  bool _tampilError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _cari.dispose();
    _jenisLain.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  void _onCari(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _hasil = [];
        _mencari = false;
      });
      return;
    }
    setState(() => _mencari = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await widget.api.get(ApiUrl.santri, query: {'search': q.trim(), 'perPage': '6'});
        if (!mounted) return;
        setState(() {
          _hasil = _asList(res);
          _mencari = false;
        });
      } catch (_) {
        if (mounted) setState(() => _mencari = false);
      }
    });
  }

  String get _jenisFinal => _jenis == 'Lainnya' ? _jenisLain.text.trim() : (_jenis ?? '');

  void _kirim() {
    setState(() => _tampilError = true);
    if (_jenisFinal.isEmpty || _deskripsi.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'santriId': _santri?['id'],
      'jenis': _jenisFinal,
      'lokasi': _lokasi.text.trim().isEmpty ? null : _lokasi.text.trim(),
      'deskripsi': _deskripsi.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Lapor Darurat',
      subtitle: 'Admin dan Musyrif akan segera diberi tahu',
      icon: Icons.emergency_rounded,
      iconBg: SC.errorBg,
      iconFg: SC.errorText,
      footer: _footerButtons(
        context: context,
        submitLabel: 'Kirim Laporan',
        submitIcon: Icons.send_rounded,
        onSubmit: _kirim,
        warna: _kDanger,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SC.goldSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SC.gold.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: SC.goldDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gunakan hanya untuk situasi kritis: penanganan medis, keselamatan santri, atau pengamanan pondok.',
                    style: sty(12, FontWeight.w600, SC.goldDark, h: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _label('Santri Terkait', tag: 'Opsional'),
          if (_santri != null)
            _santriTerpilih()
          else ...[
            TextField(
              controller: _cari,
              onChanged: _onCari,
              style: sty(14, FontWeight.w600, SC.ink),
              decoration: _dec('Cari nama atau NIS, atau kosongkan', icon: Icons.search_rounded),
            ),
            if (_mencari)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(color: SC.primary, minHeight: 2),
              ),
            if (_hasil.isNotEmpty) _hasilCari(),
          ],
          const SizedBox(height: 18),

          _label('Jenis Kedaruratan', req: true),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [for (final o in _opsi) SizedBox(width: w, child: _jenisTile(o.$1, o.$2))],
              );
            },
          ),
          if (_jenis == 'Lainnya') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _jenisLain,
              onChanged: (_) => setState(() {}),
              style: sty(14, FontWeight.w600, SC.ink),
              decoration: _dec('Tulis jenis kedaruratan'),
            ),
          ],
          if (_tampilError && _jenisFinal.isEmpty) _errorNote('Pilih jenis kedaruratan.'),
          const SizedBox(height: 18),

          _label('Lokasi Kejadian', tag: 'Opsional'),
          TextField(
            controller: _lokasi,
            style: sty(14, FontWeight.w600, SC.ink),
            decoration: _dec('Contoh: Asrama Putra Blok B, Kamar 04',
                icon: Icons.location_on_outlined, iconColor: SC.goldDark),
          ),
          const SizedBox(height: 18),

          _label('Kronologi & Kondisi', req: true, kanan: '${_deskripsi.text.length} / $_maxDeskripsi'),
          TextField(
            controller: _deskripsi,
            maxLines: 5,
            minLines: 4,
            maxLength: _maxDeskripsi,
            onChanged: (_) => setState(() {}),
            style: sty(13.5, FontWeight.w500, SC.ink, h: 1.4),
            decoration: _dec('Ceritakan apa yang terjadi, kondisi santri, dan tindakan awal yang sudah dilakukan.'),
          ),
          if (_tampilError && _deskripsi.text.trim().isEmpty) _errorNote('Deskripsi wajib diisi.'),
        ],
      ),
    );
  }

  Widget _jenisTile(String label, IconData icon) {
    final sel = _jenis == label;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _jenis = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? SC.primary : SC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? SC.primary : SC.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: sel ? SC.gold : SC.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12.5, FontWeight.w700, sel ? Colors.white : SC.ink)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _santriTerpilih() {
    final s = _santri!;
    final kelas = (s['kelas'] as Map?)?['namaKelas'];
    final nis = s['nis'];
    final info = [if (nis != null) 'NIS $nis', if (kelas != null) '$kelas'].join(' • ');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: SC.sage, shape: BoxShape.circle),
            child: Icon(Icons.school_outlined, size: 20, color: SC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['nama']}', style: sty(14, FontWeight.w800, SC.ink)),
                if (info.isNotEmpty) Text(info, style: sty(12, FontWeight.w500, SC.inkSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ganti santri',
            onPressed: () => setState(() {
              _santri = null;
              _hasil = [];
              _cari.clear();
            }),
            icon: const Icon(Icons.close_rounded, size: 18, color: SC.inkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _hasilCari() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _hasil.length; i++) ...[
            if (i > 0) Divider(height: 1, color: SC.border),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() {
                _santri = _hasil[i];
                _hasil = [];
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_hasil[i]['nama']}', style: sty(13.5, FontWeight.w700, SC.ink)),
                    ),
                    Text('${(_hasil[i]['kelas'] as Map?)?['namaKelas'] ?? ''}',
                        style: sty(12, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet: Tindak Lanjuti Laporan (Admin / Musyrif)
// ---------------------------------------------------------------------------
class _TindakSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  const _TindakSheet({required this.item});

  @override
  State<_TindakSheet> createState() => _TindakSheetState();
}

class _TindakSheetState extends State<_TindakSheet> {
  late String _status = _statusOf(widget.item);
  late final TextEditingController _tindak =
      TextEditingController(text: widget.item['tindakLanjut'] as String? ?? '');

  static const _hint = {
    'BARU': 'Laporan belum ditangani.',
    'DITANGANI': 'Pilih "Ditangani" saat tindakan medis atau penanganan awal dimulai.',
    'SELESAI': 'Pilih "Selesai" setelah kondisi santri pulih dan kasus ditutup.',
  };

  @override
  void dispose() {
    _tindak.dispose();
    super.dispose();
  }

  void _tambah(String teks) {
    final cur = _tindak.text.trim();
    setState(() {
      _tindak.text = cur.isEmpty ? teks : '$cur\n$teks';
      _tindak.selection = TextSelection.collapsed(offset: _tindak.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.item;
    final santri = (d['santri'] as Map?)?.cast<String, dynamic>();
    final kelas = (santri?['kelas'] as Map?)?['namaKelas'];
    final lokasi = (d['lokasi'] as String?)?.trim();
    final dt = DateTime.tryParse('${d['tanggal']}')?.toLocal();
    final stAwal = _st(_statusOf(d));
    final ringkas = [
      santri == null ? 'Umum' : '${santri['nama']}',
      if (kelas != null) '$kelas',
      if (lokasi != null && lokasi.isNotEmpty) lokasi,
    ].join(' • ');

    return _SheetShell(
      title: 'Tindak Lanjuti',
      subtitle: 'Perbarui status dan catatan penanganan',
      icon: Icons.edit_note_rounded,
      iconBg: SC.goldSurface,
      iconFg: SC.gold,
      footer: _footerButtons(
        context: context,
        submitLabel: 'Simpan Status',
        submitIcon: Icons.check_circle_outline_rounded,
        onSubmit: () => Navigator.pop(context, {
          'status': _status,
          'tindakLanjut': _tindak.text.trim().isEmpty ? null : _tindak.text.trim(),
        }),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SC.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SC.border),
              boxShadow: softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${d['jenis']}', style: sty(16, FontWeight.w800, SC.ink)),
                    ),
                    _pill(stAwal.label.toUpperCase(), bg: stAwal.bg, fg: stAwal.fg),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ringkas, style: sty(12.5, FontWeight.w500, SC.inkSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: SC.goldDark),
                    const SizedBox(width: 6),
                    Text(dt == null ? '-' : '${_tgl(dt)}, ${_jam(dt)}',
                        style: sty(12, FontWeight.w600, SC.inkSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _label('Status Penanganan', req: true),
          Row(
            children: [
              for (final s in const ['BARU', 'DITANGANI', 'SELESAI']) ...[
                Expanded(child: _statusTile(s)),
                if (s != 'SELESAI') const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: SC.goldDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_hint[_status] ?? '',
                    style: sty(12, FontWeight.w600, SC.goldDark, h: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _label('Tindakan & Perkembangan', kanan: '${_tindak.text.length} karakter'),
          TextField(
            controller: _tindak,
            maxLines: 6,
            minLines: 4,
            onChanged: (_) => setState(() {}),
            style: sty(13.5, FontWeight.w500, SC.ink, h: 1.4),
            decoration: _dec('Tulis tindakan yang sudah dilakukan dan perkembangan kondisi santri.'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quick('+ Hubungi Wali', 'Wali santri telah dihubungi.'),
              _quick('+ Rujuk Poskestren', 'Santri dirujuk ke Poskestren.'),
              _quick('+ Rujuk RSUD', 'Santri dirujuk ke RSUD.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String s) {
    final st = _st(s);
    final sel = _status == s;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _status = s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: sel ? st.bg : SC.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? st.fg.withOpacity(0.4) : SC.border, width: sel ? 1.4 : 1),
        ),
        child: Column(
          children: [
            Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 21, color: sel ? st.fg : SC.inkMuted),
            const SizedBox(height: 6),
            Text(st.label, style: sty(11.5, FontWeight.w800, sel ? st.fg : SC.inkSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _quick(String label, String teks) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _tambah(teks),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SC.border),
        ),
        child: Text(label, style: sty(12, FontWeight.w700, SC.primary)),
      ),
    );
  }
}